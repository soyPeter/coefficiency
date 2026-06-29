package io.bitnomio.coeff.admin.app;

import io.bitnomio.coeff.shared.db.DbEncryption;
import io.bitnomio.coeff.shared.db.SqliteConnection;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import javax.crypto.Cipher;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.File;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.security.SecureRandom;
import java.sql.DriverManager;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Stream;

@Singleton
public class AdminService {

    private static final String BACKUP_DIR = "data/backups";
    private static final String BACKUP_PREFIX = "app.db.enc.";
    private static final String DUMP_PREFIX = "app.db.dump.";
    private static final DateTimeFormatter TIMESTAMP_FMT = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneId.systemDefault());
    private static final int PBKDF2_ITERATIONS = 100_000;
    private static final int KEY_SIZE_BITS = 256;
    private static final int SALT_SIZE = 16;
    private static final int IV_SIZE = 12;
    private static final List<String> DATA_TABLES = List.of("consultants", "cost_concepts", "settings", "tenure_bonuses", "quarterly_bonuses", "bonus_breakdown_cache");

    private final Jdbi jdbi;
    private final SqliteConnection sqliteConnection;
    private final DbEncryption dbEncryption;

    public AdminService(Jdbi jdbi, SqliteConnection sqliteConnection, DbEncryption dbEncryption) {
        this.jdbi = jdbi;
        this.sqliteConnection = sqliteConnection;
        this.dbEncryption = dbEncryption;
    }

    private static String dbDir() {
        var dir = System.getProperty("coeff.data.dir");
        if (dir != null) return dir;
        var userDir = System.getProperty("user.dir");
        return userDir.contains("services/coeff") ? userDir + "/data" : userDir + "/services/coeff/data";
    }

    public record BackupEntry(String filename, long size, Instant createdAt) {}
    public record TableInfo(String name, int rowCount) {}
    public record SystemHealth(String jvmVersion, long uptime, int availableProcessors,
                                long totalMemory, long freeMemory, long maxMemory,
                                long diskFreeBytes, long diskTotalBytes) {}
    public record DatabaseHealth(boolean connected, long fileSizeBytes, List<TableInfo> tables) {}
    public record HealthResponse(String status, SystemHealth system, DatabaseHealth database) {}

    public HealthResponse health() {
        var runtime = Runtime.getRuntime();
        var jvmUptime = ManagementFactory.getRuntimeMXBean().getUptime();
        var dataDir = new File(dbDir());

        var system = new SystemHealth(
            System.getProperty("java.version"), jvmUptime,
            runtime.availableProcessors(), runtime.totalMemory(),
            runtime.freeMemory(), runtime.maxMemory(),
            dataDir.getFreeSpace(), dataDir.getTotalSpace()
        );

        var tables = new ArrayList<TableInfo>();
        if (sqliteConnection.isConnected()) {
            for (var table : List.of("consultants", "users", "settings", "cost_concepts")) {
                try {
                    int count = jdbi.withHandle(h ->
                        h.createQuery("SELECT COUNT(*) FROM " + table).mapTo(Integer.class).one());
                    tables.add(new TableInfo(table, count));
                } catch (Exception ignored) {}
            }
        }

        long fileSize = 0;
        try { fileSize = Files.size(Path.of(sqliteConnection.dbPath())); }
        catch (IOException ignored) {}

        var db = new DatabaseHealth(sqliteConnection.isConnected(), fileSize, tables);
        return new HealthResponse("ok", system, db);
    }

    public BackupEntry createBackup() throws IOException {
        Files.createDirectories(Path.of(dbDir(), "backups"));
        var timestamp = TIMESTAMP_FMT.format(Instant.now());
        var filename = BACKUP_PREFIX + timestamp;
        Files.copy(Path.of(dbDir(), "app.db.enc"), Path.of(dbDir(), "backups", filename));
        enforceRetention(BACKUP_PREFIX, 5);
        var target = Path.of(dbDir(), "backups", filename);
        return new BackupEntry(filename, Files.size(target), Instant.now());
    }

    public List<BackupEntry> listBackups() throws IOException {
        var dir = Path.of(dbDir(), "backups");
        if (!Files.isDirectory(dir)) return List.of();
        try (var files = Files.list(dir)) {
            return files.filter(p -> p.getFileName().toString().startsWith(BACKUP_PREFIX))
                .map(p -> { try { var a = Files.readAttributes(p, BasicFileAttributes.class);
                    return new BackupEntry(p.getFileName().toString(), a.size(), a.lastModifiedTime().toInstant());
                } catch (IOException e) { return null; }})
                .filter(e -> e != null)
                .sorted(Comparator.<BackupEntry, Instant>comparing(e -> e.createdAt).reversed())
                .toList();
        }
    }

    public void restoreBackup(String filename) throws Exception {
        if (filename.contains("..") || filename.contains("/")) throw new IllegalArgumentException("Invalid filename");
        var backup = Path.of(dbDir(), "backups", filename);
        if (!Files.isRegularFile(backup)) throw new IllegalArgumentException("Backup not found");
        if (sqliteConnection.isConnected()) sqliteConnection.close();
        Files.deleteIfExists(Path.of(sqliteConnection.dbPath()));
        Files.copy(backup, Path.of(dbDir(), "app.db.enc"), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        var dbPath = sqliteConnection.dbPath();
        dbEncryption.decryptDirect(dbPath);
        sqliteConnection.reinit();
    }

    public BackupEntry createDumpBackup(String password) throws Exception {
        Files.createDirectories(Path.of(dbDir(), "backups"));
        var timestamp = TIMESTAMP_FMT.format(Instant.now());
        var filename = DUMP_PREFIX + timestamp;
        var sql = generateSqlDump();
        var encrypted = encryptBytes(sql.getBytes(StandardCharsets.UTF_8), password);
        Files.write(Path.of(dbDir(), "backups", filename), encrypted);
        return new BackupEntry(filename, encrypted.length, Instant.now());
    }

    public void restoreDumpBackup(String filename, String password) throws Exception {
        if (filename.contains("..") || filename.contains("/")) throw new IllegalArgumentException("Invalid filename");
        var dumpPath = Path.of(dbDir(), "backups", filename);
        if (!Files.isRegularFile(dumpPath)) throw new IllegalArgumentException("Dump backup not found");
        var encrypted = Files.readAllBytes(dumpPath);
        var decrypted = decryptBytes(encrypted, password);
        var sql = new String(decrypted, StandardCharsets.UTF_8);

        var usersSql = dumpUsersData();

        sqliteConnection.close();
        Files.deleteIfExists(Path.of(sqliteConnection.dbPath()));
        Files.deleteIfExists(Path.of(dbDir(), "app.db.enc"));

        try (var freshConn = DriverManager.getConnection("jdbc:sqlite:" + sqliteConnection.dbPath());
             var stmt = freshConn.createStatement()) {
            for (var statement : sql.split(";(?=([^']*'[^']*')*[^']*$)")) {
                var trimmed = statement.trim();
                if (!trimmed.isEmpty()) {
                    try { stmt.execute(trimmed); }
                    catch (Exception e) { throw new RuntimeException("SQL restore failed: " + e.getMessage()); }
                }
            }
            if (!usersSql.isEmpty()) {
                stmt.execute(usersSql);
            }
            migrateSchema(stmt);
        }
        dbEncryption.encrypt();
        dbEncryption.decryptDirect(sqliteConnection.dbPath());
        sqliteConnection.reinit();
    }

    public void pruneDatabase() {
        jdbi.useHandle(h -> {
            h.execute("PRAGMA foreign_keys = OFF");
            for (var table : DATA_TABLES) {
                h.execute("DELETE FROM " + table);
            }
            h.execute("DELETE FROM sqlite_sequence");
            h.execute("PRAGMA foreign_keys = ON");
        });
        seedDefaults();
    }

    public List<BackupEntry> listDumpBackups() throws IOException {
        var dir = Path.of(dbDir(), "backups");
        if (!Files.isDirectory(dir)) return List.of();
        try (var files = Files.list(dir)) {
            return files.filter(p -> p.getFileName().toString().startsWith(DUMP_PREFIX))
                .map(p -> { try { var a = Files.readAttributes(p, BasicFileAttributes.class);
                    return new BackupEntry(p.getFileName().toString(), a.size(), a.lastModifiedTime().toInstant());
                } catch (IOException e) { return null; }})
                .filter(e -> e != null)
                .sorted(Comparator.<BackupEntry, Instant>comparing(e -> e.createdAt).reversed())
                .toList();
        }
    }

    /**
     * Restores the database from an uploaded encrypted backup file.
     *
     * @param uploadedFile the uploaded encrypted backup bytes
     * @throws Exception if restore fails
     */
    public void restoreFromUpload(byte[] uploadedFile) throws Exception {
        if (uploadedFile == null || uploadedFile.length == 0) {
            throw new IllegalArgumentException("No file uploaded");
        }
        if (sqliteConnection.isConnected()) sqliteConnection.close();
        Files.deleteIfExists(Path.of(sqliteConnection.dbPath()));
        Files.write(Path.of(dbDir(), "app.db.enc"), uploadedFile);
        var dbPath = sqliteConnection.dbPath();
        dbEncryption.decryptDirect(dbPath);
        sqliteConnection.reinit();
    }

    /**
     * Restores the database from an uploaded encrypted dump backup file.
     *
     * @param uploadedFile the uploaded encrypted dump bytes
     * @param password     the password to decrypt the dump
     * @throws Exception if restore fails
     */
    public void restoreDumpFromUpload(byte[] uploadedFile, String password) throws Exception {
        if (uploadedFile == null || uploadedFile.length == 0) {
            throw new IllegalArgumentException("No file uploaded");
        }
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        var decrypted = decryptBytes(uploadedFile, password);
        var sql = new String(decrypted, StandardCharsets.UTF_8);

        var usersSql = dumpUsersData();

        sqliteConnection.close();
        Files.deleteIfExists(Path.of(sqliteConnection.dbPath()));
        Files.deleteIfExists(Path.of(dbDir(), "app.db.enc"));

        try (var freshConn = DriverManager.getConnection("jdbc:sqlite:" + sqliteConnection.dbPath());
             var stmt = freshConn.createStatement()) {
            for (var statement : sql.split(";(?=([^']*'[^']*')*[^']*$)")) {
                var trimmed = statement.trim();
                if (trimmed.isEmpty()) continue;
                // Run every statement. If it fails, try adding missing columns and retry
                try { stmt.execute(trimmed); }
                catch (Exception e) {
                    var up = trimmed.toUpperCase();
                    if (up.contains("ALTER TABLE") || up.contains("DROP TABLE") || up.contains("PRAGMA") || up.contains("BEGIN") || up.contains("COMMIT")) continue;
                    // Add columns that Javalin's ALTER TABLE added but its sqlite_master CREATE TABLE doesn't include
                    for (var alt : new String[]{"ALTER TABLE users ADD COLUMN token_version INTEGER NOT NULL DEFAULT 0"}) {
                        try { stmt.execute(alt); } catch (Exception ignored) {}
                    }
                    try { stmt.execute(trimmed); } catch (Exception e2) { /* skip if still fails */ }
                }
            }
            if (!usersSql.isEmpty()) {
                stmt.execute(usersSql);
            }
            migrateSchema(stmt);
        }
        dbEncryption.encrypt();
        dbEncryption.decryptDirect(sqliteConnection.dbPath());
        sqliteConnection.reinit();
    }

    private void enforceRetention(String prefix, int max) throws IOException {
        var dir = Path.of(dbDir(), "backups");
        if (!Files.isDirectory(dir)) return;
        try (var stream = Files.list(dir)) {
            var backups = stream.filter(p -> p.getFileName().toString().startsWith(prefix))
                .sorted(Comparator.comparingLong((Path p) -> p.toFile().lastModified()).reversed())
                .toList();
            if (backups.size() > max) {
                for (int i = max; i < backups.size(); i++) Files.deleteIfExists(backups.get(i));
            }
        }
    }

    private static void migrateSchema(java.sql.Statement stmt) {
        var migrations = List.of(
            "ALTER TABLE users ADD COLUMN salt TEXT DEFAULT ''",
            "ALTER TABLE users ADD COLUMN created_at TEXT",
            "ALTER TABLE users ADD COLUMN token_version INTEGER DEFAULT 0",
            "ALTER TABLE consultants ADD COLUMN end_date TEXT",
            "ALTER TABLE consultants ADD COLUMN fees REAL",
            "ALTER TABLE consultants ADD COLUMN coef_percentage REAL",
            "ALTER TABLE consultants ADD COLUMN coef_margin REAL",
            "ALTER TABLE consultants ADD COLUMN manager_bonus REAL",
            "ALTER TABLE consultants ADD COLUMN simulation_inputs TEXT",
            "ALTER TABLE consultants ADD COLUMN profitability_status TEXT DEFAULT 'INSUFFICIENT_DATA'",
            "ALTER TABLE consultants ADD COLUMN gross_monthly_salary REAL",
            "ALTER TABLE consultants ADD COLUMN net_monthly_salary REAL",
            "ALTER TABLE consultants ADD COLUMN net_annual_salary REAL",
            "ALTER TABLE consultants ADD COLUMN monthly_ss REAL",
            "ALTER TABLE consultants ADD COLUMN monthly_irpf REAL",
            "ALTER TABLE consultants ADD COLUMN irpf_rate REAL",
            "ALTER TABLE consultants ADD COLUMN ss_rate REAL",
            "ALTER TABLE consultants ADD COLUMN coef_projection TEXT",
            "ALTER TABLE consultants ADD COLUMN created_at TEXT",
            "ALTER TABLE consultants ADD COLUMN updated_at TEXT",
            "ALTER TABLE settings ADD COLUMN updated_at TEXT",
            "ALTER TABLE cost_concepts ADD COLUMN updated_at TEXT",
            "CREATE INDEX IF NOT EXISTS idx_consultants_client ON consultants(client)",
            "CREATE INDEX IF NOT EXISTS idx_consultants_start_date ON consultants(start_date)",
            "CREATE INDEX IF NOT EXISTS idx_consultants_end_date ON consultants(end_date)",
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_cost_concepts_name ON cost_concepts(name)"
        );
        for (var m : migrations) {
            try { stmt.execute(m); } catch (Exception ignored) {}
        }
    }

    private void seedDefaults() {
        jdbi.useHandle(h -> {
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.coefDaysMonth','21', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.coefDaysYear','252', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.personal_minimum','5550', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.deduction_child','2400', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.deduction_asc','1150', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.deduction_dis','3000', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.deduction_spouse','2150', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.coef_multiplier','1.7', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.mng_bonus_pct','0.05', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.insurance_months','6', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.meal_card_days','22', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.ss_rate','0.0635', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.lirpf_expenses','2000', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.tenure_bonus_amount','300', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.tenure_bonus_months','3', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.quarterly_bonus_amount','500', datetime('now'))");
            h.execute("INSERT OR IGNORE INTO settings VALUES ('annualDelta','0', datetime('now'))");
        });
    }

    private String dumpUsersData() {
        var sb = new StringBuilder();
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT id, username, password_hash, salt, created_at FROM users")
                .map((rs, ctx) -> List.of(
                    rs.getObject("id"),
                    rs.getString("username"),
                    rs.getString("password_hash"),
                    rs.getString("salt"),
                    rs.getString("created_at")
                )).list());
        if (rows.isEmpty()) return "";
        for (var row : rows) {
            sb.append("INSERT OR REPLACE INTO users (id, username, password_hash, salt, created_at) VALUES(");
            for (int i = 0; i < row.size(); i++) {
                if (i > 0) sb.append(",");
                var val = row.get(i);
                if (val == null) sb.append("NULL");
                else if (val instanceof Number) sb.append(val);
                else sb.append("'").append(val.toString().replace("'", "''")).append("'");
            }
            sb.append(");\n");
        }
        return sb.toString();
    }

    private String generateSqlDump() throws Exception {
        var sb = new StringBuilder();
        sb.append("PRAGMA foreign_keys = OFF;\nBEGIN TRANSACTION;\n");
        var allTables = List.of("users", "settings", "cost_concepts", "consultants", "tenure_bonuses", "quarterly_bonuses", "bonus_breakdown_cache");
        try (var handle = sqliteConnection.jdbi().open()) {
            var conn = handle.getConnection();
            for (var table : allTables) {
                try (var s = conn.createStatement(); var rs = s.executeQuery("SELECT sql FROM sqlite_master WHERE type='table' AND tbl_name='" + table + "'")) {
                    if (rs.next()) sb.append(rs.getString("sql")).append(";\n");
                }
                try (var s = conn.createStatement(); var rs = s.executeQuery("SELECT * FROM \"" + table + "\"")) {
                    var meta = rs.getMetaData();
                    int cols = meta.getColumnCount();
                    while (rs.next()) {
                        sb.append("INSERT INTO \"").append(table).append("\" VALUES(");
                        for (int i = 1; i <= cols; i++) {
                            if (i > 1) sb.append(",");
                            var val = rs.getObject(i);
                            if (val == null) sb.append("NULL");
                            else if (val instanceof Number) sb.append(val);
                            else sb.append("'").append(rs.getString(i).replace("'", "''")).append("'");
                        }
                        sb.append(");\n");
                    }
                }
            }
        }
        sb.append("COMMIT;\nPRAGMA foreign_keys = ON;\n");
        return sb.toString();
    }

    private static byte[] deriveKey(String password, byte[] salt) throws Exception {
        var factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        var spec = new PBEKeySpec(password.toCharArray(), salt, PBKDF2_ITERATIONS, KEY_SIZE_BITS);
        var tmp = factory.generateSecret(spec);
        Arrays.fill(spec.getPassword(), '\0');
        return tmp.getEncoded();
    }

    private static byte[] encryptBytes(byte[] plaintext, String password) throws Exception {
        var salt = new byte[SALT_SIZE];
        new SecureRandom().nextBytes(salt);
        var key = deriveKey(password, salt);
        var iv = new byte[IV_SIZE];
        new SecureRandom().nextBytes(iv);
        var cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(128, iv));
        var ct = cipher.doFinal(plaintext);
        var result = new byte[salt.length + iv.length + ct.length];
        System.arraycopy(salt, 0, result, 0, salt.length);
        System.arraycopy(iv, 0, result, salt.length, iv.length);
        System.arraycopy(ct, 0, result, salt.length + iv.length, ct.length);
        return result;
    }

    private static byte[] decryptBytes(byte[] ct, String password) throws Exception {
        var salt = new byte[SALT_SIZE];
        var iv = new byte[IV_SIZE];
        System.arraycopy(ct, 0, salt, 0, SALT_SIZE);
        System.arraycopy(ct, SALT_SIZE, iv, 0, IV_SIZE);
        var enc = new byte[ct.length - SALT_SIZE - IV_SIZE];
        System.arraycopy(ct, SALT_SIZE + IV_SIZE, enc, 0, enc.length);
        var key = deriveKey(password, salt);
        var cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(128, iv));
        return cipher.doFinal(enc);
    }
}
