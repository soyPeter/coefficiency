package io.bitnomio.coeff.shared.db;

import io.avaje.inject.PostConstruct;
import io.avaje.inject.PreDestroy;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.SqlObjectPlugin;
import org.sqlite.SQLiteDataSource;

import java.io.File;

/**
 * Manages the SQLite connection lifecycle: initialization, schema creation,
 * and reconnection after database decrypt/encrypt cycles.
 *
 * <p>Uses a fixed {@code data/coeff.db} path resolved via the system property
 * {@code coeff.data.dir} or the project directory structure.
 *
 * <p><b>Thread Safety:</b> All public methods are synchronized to prevent
 * concurrent reinit/init races.
 *
 * @since 1.0
 * @see CoefJdbiFactory
 */
@Singleton
public class SqliteConnection {

    private Jdbi jdbi;
    private boolean initialized;

    private static String dbDir() {
        var dir = System.getProperty("coeff.data.dir");
        if (dir != null) return dir;
        var userDir = System.getProperty("user.dir");
        if (userDir.contains("services/coeff")) return userDir + "/data";
        return userDir + "/services/coeff/data";
    }

    @PostConstruct
    public synchronized void init() {
        if (initialized) return;
        new File(dbDir()).mkdirs();
        var ds = new SQLiteDataSource();
        ds.setUrl("jdbc:sqlite:" + dbDir() + "/coeff.db");
        jdbi = Jdbi.create(ds);
        jdbi.installPlugin(new SqlObjectPlugin());
        initSchema();
        initialized = true;
    }

    public synchronized Jdbi jdbi() {
        if (!initialized) init();
        return jdbi;
    }

    public boolean isInitialized() { return initialized; }

    private void initSchema() {
        jdbi.useHandle(h -> {
            h.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, salt TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now')))");
            h.execute("CREATE TABLE IF NOT EXISTS consultants (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, client TEXT NOT NULL, position TEXT NOT NULL, coef REAL NOT NULL, tariff REAL NOT NULL, start_date TEXT NOT NULL, end_date TEXT, fees REAL, coef_percentage REAL, coef_margin REAL, manager_bonus REAL, simulation_inputs TEXT, created_at TEXT NOT NULL DEFAULT (datetime('now')), updated_at TEXT NOT NULL DEFAULT (datetime('now')))");
            h.execute("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT (datetime('now')))");
            h.execute("CREATE TABLE IF NOT EXISTS cost_concepts (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL CHECK(type IN ('monthly','yearly','onetime')), default_value REAL NOT NULL DEFAULT 0, updated_at TEXT NOT NULL DEFAULT (datetime('now')))");
            h.execute("CREATE VIEW IF NOT EXISTS v_client_financials AS SELECT client, COUNT(*) as consultant_count, COALESCE(SUM(fees),0) as total_fees, COALESCE(SUM(coef_margin),0) as total_margin, COALESCE(SUM(manager_bonus),0) as total_bonus, COALESCE(AVG(julianday('now')-julianday(start_date)),0) as avg_tenure, COALESCE(MAX(julianday('now')-julianday(start_date)),0) as max_tenure FROM consultants WHERE end_date IS NULL OR end_date > datetime('now') GROUP BY client");
            h.execute("CREATE VIEW IF NOT EXISTS v_position_profitability AS SELECT position, COUNT(*) as consultant_count, COALESCE(SUM(fees),0) as total_fees, COALESCE(AVG(coef_percentage),0) as avg_coef, COALESCE(SUM(coef_margin),0) as total_margin FROM consultants WHERE end_date IS NULL OR end_date > datetime('now') GROUP BY position");
        });
    }

    /**
     * Closes and re-initializes the connection. Used after {@code DbEncryption}
     * decrypts the database file on login (the old JDBI handle becomes stale).
     */
    public synchronized void reinit() {
        initialized = false;
        jdbi = null;
        init();
    }

    @PreDestroy
    public void close() { initialized = false; jdbi = null; }
}
