package io.bitnomio.coeff.shared.db;

import io.avaje.inject.PostConstruct;
import io.avaje.inject.PreDestroy;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.sqlobject.SqlObjectPlugin;
import org.flywaydb.core.Flyway;
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
        Flyway.configure()
            .dataSource("jdbc:sqlite:" + dbDir() + "/coeff.db", "", "")
            .locations("classpath:db/migration")
            .baselineOnMigrate(true)
            .load()
            .migrate();
        initSchema();
        initialized = true;
    }

    public synchronized Jdbi jdbi() {
        if (!initialized) init();
        return jdbi;
    }

    public boolean isInitialized() { return initialized; }

    public boolean isConnected() { return initialized && jdbi != null; }

    public String dbPath() { return dbDir() + "/coeff.db"; }

    private void initSchema() {
        jdbi.useHandle(h -> {
            try { h.execute("ALTER TABLE consultants ADD COLUMN profitability_status TEXT DEFAULT 'INSUFFICIENT_DATA'"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN gross_monthly_salary REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN net_monthly_salary REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN net_annual_salary REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN monthly_ss REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN monthly_irpf REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN irpf_rate REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN ss_rate REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN coef_projection TEXT"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN coef_percentage REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN coef_margin REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN manager_bonus REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN fees REAL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN end_date TEXT"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN created_at TEXT"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE consultants ADD COLUMN updated_at TEXT"); } catch (Exception ignored) {}
            try { h.execute("UPDATE consultants SET coef_percentage = coef_pct WHERE coef_percentage IS NULL AND coef_pct IS NOT NULL"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE users ADD COLUMN salt TEXT DEFAULT ''"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE users ADD COLUMN created_at TEXT"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE users ADD COLUMN token_version INTEGER DEFAULT 0"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE settings ADD COLUMN updated_at TEXT"); } catch (Exception ignored) {}
            try { h.execute("ALTER TABLE cost_concepts ADD COLUMN updated_at TEXT"); } catch (Exception ignored) {}
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
