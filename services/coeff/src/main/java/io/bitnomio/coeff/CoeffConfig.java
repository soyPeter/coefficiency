package io.bitnomio.coeff;

import io.bitnomio.coeff.auth.AuthService;
import io.bitnomio.coeff.shared.db.DbEncryption;
import io.bitnomio.coeff.shared.exceptions.ConflictException;
import io.jooby.Jooby;
import io.jooby.StatusCode;
import io.jooby.exception.StatusCodeException;
import org.jdbi.v3.core.Jdbi;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.awt.*;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

/**
 * Shared cross-cutting configuration installed by {@link CoeffApplication}.
 *
 * <p>Configures:
 * <ul>
 *   <li>Error-code mapping and a JSON error handler with stack-trace logging</li>
 *   <li>CORS headers and Bearer-token authentication filter for API routes</li>
 *   <li>Static asset routing (dev: filesystem, prod: classpath)</li>
 *   <li>Lifecycle hooks (browser open on start, DB encryption on stop)</li>
 * </ul>
 *
 * @since 1.0
 * @see CoeffApplication
 */
class CoeffConfig {

    private static final Logger log = LoggerFactory.getLogger(CoeffConfig.class);

    private static final Set<String> EXEMPT_PATHS = Set.of("/api/health");
    private static final Set<String> EXEMPT_PREFIXES = Set.of("/api/auth/", "/openapi", "/swagger", "/redoc");

    static void install(Jooby app) {
        requestLogging(app);
        errorHandling(app);
        authFilter(app);
        staticAssets(app);
        lifecycle(app);
        seedIfEmpty(app);
    }

    private static void requestLogging(Jooby app) {
        app.before(ctx -> log.info("→ {} {}", ctx.getMethod(), ctx.getRequestPath()));
    }

    private static void errorHandling(Jooby app) {
        app.errorCode(ConflictException.class, StatusCode.CONFLICT);
        app.errorCode(IllegalArgumentException.class, StatusCode.BAD_REQUEST);

        app.error((ctx, cause, statusCode) -> {
            if (ctx.isResponseStarted()) return;
            log.error("[{}] {} - {}", statusCode.value(), ctx.getRequestPath(), cause != null ? cause.toString() : "null");
            if (cause != null) log.error("Caused by:", cause);
            ctx.setResponseHeader("Content-Type", "application/json");
            var msg = cause != null ? cause.getMessage() : switch (statusCode.value()) {
                case 400 -> "Bad Request";
                case 401 -> "Unauthorized";
                case 404 -> "Not Found";
                case 409 -> "Conflict";
                case 503 -> "Service Unavailable";
                default -> "Internal Server Error";
            };
            ctx.send("{\"error\":\"" + (msg != null ? msg.replace("\\", "\\\\").replace("\"", "\\\"") : "") + "\",\"status\":" + statusCode.value() + "}");
        });
    }

    private static void authFilter(Jooby app) {
        app.before(ctx -> {
            var origin = ctx.header("Origin").toOptional().orElse("");
            if (origin.contains("localhost") || origin.contains("127.0.0.1") || origin.isBlank()) {
                ctx.setResponseHeader("Access-Control-Allow-Origin", origin.isBlank() ? "*" : origin);
            } else {
                ctx.setResponseHeader("Access-Control-Allow-Origin", "http://localhost:62226");
            }
            ctx.setResponseHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
            ctx.setResponseHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

            var path = ctx.getRequestPath();
            if (!path.startsWith("/api/")) return;
            if (isExempt(path)) return;
            var authHeader = ctx.header("Authorization");
            if (authHeader == null || !authHeader.toOptional().orElse("").startsWith("Bearer ")) {
                throw new StatusCodeException(StatusCode.UNAUTHORIZED, "Unauthorized");
            }
            var authService = app.require(AuthService.class);
            var token = authHeader.value().substring(7);
            if (!authService.validateToken(token)) {
                throw new StatusCodeException(StatusCode.UNAUTHORIZED, "Unauthorized");
            }
        });
    }

    private static void staticAssets(Jooby app) {
        var devDir = Paths.get("frontend/dist");
        if (!Files.exists(devDir)) devDir = Paths.get("services/coeff/frontend/dist");
        if (Files.exists(devDir)) {
            app.assets("/assets/*", devDir.resolve("assets"));
            app.assets("/media/*", devDir.resolve("media"));
            app.assets("/index.html", devDir.resolve("index.html"));
        } else {
            app.assets("/assets/*", "/static/assets");
            app.assets("/media/*", "/static/media");
            app.assets("/index.html", "/static/index.html");
        }
        app.get("/", ctx -> ctx.sendRedirect("/index.html"));
    }

    private static void lifecycle(Jooby app) {
        app.onStop(() -> {
            try {
                var dbEnc = app.require(DbEncryption.class);
                dbEnc.stopPeriodicSync();
                dbEnc.encrypt();
            } catch (Exception ignored) {
            }
        });
        app.onStarting(() -> {
            var port = app.getServerOptions().getPort();
            if (Desktop.isDesktopSupported())
                Desktop.getDesktop().browse(URI.create("http://localhost:" + port));
        });
    }

    private static boolean isExempt(String path) {
        if (EXEMPT_PATHS.contains(path)) return true;
        for (var p : EXEMPT_PREFIXES) if (path.startsWith(p)) return true;
        return false;
    }

    /**
     * Seeds default settings, concepts, IRPF brackets and SS bases on first startup
     * (when no user exists yet).  Idempotent — uses INSERT OR IGNORE.
     *
     * @param app the Jooby application
     */
    // REQ-SEEDING-001: seed defaults on first startup
    private static void seedIfEmpty(Jooby app) {
        app.onStarting(() -> {
            try {
                Jdbi jdbi = app.require(Jdbi.class);
                var userCount = jdbi.withHandle(h ->
                    h.createQuery("SELECT COUNT(*) FROM users").mapTo(Integer.class).one());
                if (userCount > 0) return;
                log.info("First startup detected — seeding default data");

                jdbi.useHandle(h -> {
                    // Default settings
                    h.execute("INSERT OR IGNORE INTO settings VALUES ('delta_annual','12', datetime('now'))");
                    h.execute("INSERT OR IGNORE INTO settings VALUES ('auto_logout_timeout','15', datetime('now'))");
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
                    h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.workingDays','[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21]', datetime('now'))");
                    h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.report_target_revenue','500000', datetime('now'))");
                    h.execute("INSERT OR IGNORE INTO settings VALUES ('fiscal.report_target_margin','25.0', datetime('now'))");

                    // Default cost concepts
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('mealCard','monthly',180.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('training','yearly',500.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('laptop','yearly',800.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('healthInsurance','monthly',60.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('phone','monthly',30.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('travel','yearly',1200.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('office','monthly',150.0)");
                    h.execute("INSERT OR IGNORE INTO cost_concepts (name, type, default_value) VALUES ('software','yearly',600.0)");
                });
            } catch (Exception e) {
                log.warn("DB seeding skipped (database not ready yet): {}", e.getMessage());
            }
        });
    }
}
