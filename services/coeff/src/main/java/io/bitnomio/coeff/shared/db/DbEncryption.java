package io.bitnomio.coeff.shared.db;

import jakarta.inject.Singleton;

import javax.crypto.Cipher;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * AES-256 GCM encryption layer for the SQLite database file.
 *
 * <p>On setup a PBKDF2-derived key is stored in {@code .db-key} (salt + SHA-256
 * verifier). The key is kept in memory after creation or login so that periodic
 * background syncs can re-encrypt without prompting for the password again.
 *
 * <p><b>Lifecycle (first run / setup):</b>
 * <ol>
 *   <li>{@link #createKeyFile(String)} derives a key, writes salt+verifier to disk</li>
 *   <li>{@link #encrypt()} reads the decrypted DB, encrypts it to {@code app.db.enc}</li>
 *   <li>{@link #startPeriodicSync()} re-encrypts every 5 min</li>
 * </ol>
 *
 * <p><b>Lifecycle (subsequent runs / login):</b>
 * <ol>
 *   <li>{@link #verifyPassword(String)} checks password against stored verifier</li>
 *   <li>{@link #decrypt(String)} derives key again, decrypts {@code app.db.enc} to {@code coeff.db}</li>
 *   <li>{@link #startPeriodicSync()} resumes background encryption</li>
 * </ol>
 *
 * <p><b>Thread Safety:</b> Not thread-safe. Callers must ensure no concurrent
 * encrypt/decrypt operations. The periodic sync uses a single-threaded scheduler.
 *
 * @since 1.0
 */
@Singleton
public class DbEncryption {

    private static final int GCM_IV_SIZE = 12;
    private static final int GCM_TAG_SIZE = 128;
    private static final int PBKDF2_ITERATIONS = 100_000;
    private static final int KEY_SIZE = 256;
    private static final int SALT_SIZE = 16;
    private static final long PERIODIC_SYNC_MINUTES = 5;

    private static String dbDir() {
        var dir = System.getProperty("coeff.data.dir");
        if (dir != null) return dir;
        var userDir = System.getProperty("user.dir");
        if (userDir.contains("services/coeff")) return userDir + "/data";
        return userDir + "/services/coeff/data";
    }

    private final File dataDir = new File(dbDir());
    private final File encFile = new File(dataDir, "app.db.enc");
    private final File keyFile = new File(dataDir, ".db-key");
    private final File dbFile = new File(dataDir, "coeff.db");

    private byte[] encryptionKey;
    private ScheduledExecutorService scheduler;

    public boolean isEncrypted() { return encFile.exists(); }
    public boolean hasKeyFile() { return keyFile.exists(); }

    public String loadSalt() {
        try {
            var content = Files.readString(keyFile.toPath()).trim();
            return content.split(":")[0];
        } catch (Exception e) {
            throw new RuntimeException("Failed to load key file", e);
        }
    }

    /**
     * Derives an encryption key from the password using PBKDF2, writes
     * {@code salt:verifier} to the key file, and keeps the key in memory.
     *
     * @param password the master password chosen during setup
     */
    public void createKeyFile(String password) {
        try {
            var salt = new byte[SALT_SIZE];
            new SecureRandom().nextBytes(salt);
            encryptionKey = deriveKey(password, salt);
            var verifier = sha256Hex(encryptionKey);
            dataDir.mkdirs();
            try (var out = new FileOutputStream(keyFile)) {
                out.write((HexFormat.of().formatHex(salt) + ":" + verifier).getBytes());
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to create key file", e);
        }
    }

    /**
     * Verifies a password against the stored salt + verifier in {@code .db-key}.
     *
     * @param password the password to check
     * @return true if the derived key matches the stored verifier
     */
    public boolean verifyPassword(String password) {
        try {
            var content = Files.readString(keyFile.toPath()).trim();
            var parts = content.split(":");
            var salt = HexFormat.of().parseHex(parts[0]);
            var storedVerifier = parts[1];
            var key = deriveKey(password, salt);
            var verifier = sha256Hex(key);
            return MessageDigest.isEqual(verifier.getBytes(), storedVerifier.getBytes());
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Decrypts {@code app.db.enc} into {@code coeff.db} using the key derived
     * from the password. Stores the key in memory for later re-encryption.
     *
     * @param password the master password
     */
    public void decrypt(String password) {
        try {
            var content = Files.readString(keyFile.toPath()).trim();
            var salt = HexFormat.of().parseHex(content.split(":")[0]);
            encryptionKey = deriveKey(password, salt);
            if (!encFile.exists()) return;
            var encrypted = Files.readAllBytes(encFile.toPath());
            var decrypted = aesGcmDecrypt(encrypted, encryptionKey);
            try (var out = new FileOutputStream(dbFile)) {
                out.write(decrypted);
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to decrypt database", e);
        }
    }

    /**
     * Encrypts the current {@code coeff.db} to {@code app.db.enc} using the
     * in-memory encryption key. Checkpoints the SQLite WAL first to ensure
     * no data loss.
     */
    public void encrypt() {
        if (encryptionKey == null) return;
        try {
            try {
                var jdbi = org.jdbi.v3.core.Jdbi.create("jdbc:sqlite:" + dbFile.getAbsolutePath());
                jdbi.useHandle(h -> h.execute("PRAGMA wal_checkpoint(TRUNCATE)"));
            } catch (Exception ignored) {}
            var data = Files.readAllBytes(dbFile.toPath());
            var encrypted = aesGcmEncrypt(data, encryptionKey);
            var tmpFile = new File(dataDir, "coeff.db.tmp");
            try (var out = new FileOutputStream(tmpFile)) {
                out.write(encrypted);
            }
            tmpFile.renameTo(encFile);
        } catch (Exception e) {
            throw new RuntimeException("Failed to encrypt database", e);
        }
    }

    public void startPeriodicSync() {
        scheduler = Executors.newSingleThreadScheduledExecutor();
        scheduler.scheduleAtFixedRate(this::encrypt, PERIODIC_SYNC_MINUTES, PERIODIC_SYNC_MINUTES, TimeUnit.MINUTES);
    }

    public void stopPeriodicSync() {
        if (scheduler != null) { scheduler.shutdown(); scheduler = null; }
    }

    public void deleteDecryptedDb() { dbFile.delete(); }

    public void decryptDirect(String targetPath) {
        if (encryptionKey == null) return;
        try {
            if (!encFile.exists()) return;
            var encrypted = Files.readAllBytes(encFile.toPath());
            var decrypted = aesGcmDecrypt(encrypted, encryptionKey);
            try (var out = new FileOutputStream(targetPath)) {
                out.write(decrypted);
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to decrypt database directly", e);
        }
    }

    private byte[] deriveKey(String password, byte[] salt) throws Exception {
        var factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        var spec = new PBEKeySpec(password.toCharArray(), salt, PBKDF2_ITERATIONS, KEY_SIZE);
        return factory.generateSecret(spec).getEncoded();
    }

    private byte[] aesGcmEncrypt(byte[] plaintext, byte[] key) throws Exception {
        var cipher = Cipher.getInstance("AES/GCM/NoPadding");
        var iv = new byte[GCM_IV_SIZE];
        new SecureRandom().nextBytes(iv);
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(GCM_TAG_SIZE, iv));
        var ct = cipher.doFinal(plaintext);
        var result = new byte[GCM_IV_SIZE + ct.length];
        System.arraycopy(iv, 0, result, 0, GCM_IV_SIZE);
        System.arraycopy(ct, 0, result, GCM_IV_SIZE, ct.length);
        return result;
    }

    private byte[] aesGcmDecrypt(byte[] encrypted, byte[] key) throws Exception {
        var cipher = Cipher.getInstance("AES/GCM/NoPadding");
        var iv = new byte[GCM_IV_SIZE];
        System.arraycopy(encrypted, 0, iv, 0, GCM_IV_SIZE);
        var ct = new byte[encrypted.length - GCM_IV_SIZE];
        System.arraycopy(encrypted, GCM_IV_SIZE, ct, 0, ct.length);
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(GCM_TAG_SIZE, iv));
        return cipher.doFinal(ct);
    }

    private String sha256Hex(byte[] data) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(data));
    }
}
