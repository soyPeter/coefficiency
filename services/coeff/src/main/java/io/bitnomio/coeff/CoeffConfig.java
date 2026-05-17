package io.bitnomio.coeff;

import io.bitnomio.coeff.auth.AuthService;
import io.bitnomio.coeff.shared.db.DbEncryption;
import io.bitnomio.coeff.shared.exceptions.BadRequestException;
import io.bitnomio.coeff.shared.exceptions.ConflictException;
import io.bitnomio.coeff.shared.exceptions.NotFoundException;
import io.jooby.Jooby;
import io.jooby.StatusCode;
import io.jooby.exception.StatusCodeException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.awt.*;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
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

    private static final Set<String> EXEMPT_PATHS = Set.of(
            "/api/auth/status", "/api/auth/setup", "/api/auth/login", "/api/auth/logout", "/api/health");
    private static final Set<String> EXEMPT_PREFIXES = Set.of("/api/auth/", "/openapi", "/swagger", "/redoc");

    static void install(Jooby app) {
        errorHandling(app);
        authFilter(app);
        staticAssets(app);
        lifecycle(app);
    }

    private static void errorHandling(Jooby app) {
        app.errorCode(NotFoundException.class, StatusCode.NOT_FOUND);
        app.errorCode(BadRequestException.class, StatusCode.BAD_REQUEST);
        app.errorCode(ConflictException.class, StatusCode.CONFLICT);
        app.errorCode(IllegalStateException.class, StatusCode.SERVICE_UNAVAILABLE);

        app.error((ctx, cause, statusCode) -> {
            if (ctx.isResponseStarted()) return;
            log.error("[{}] {} - {}", statusCode.value(), ctx.getRequestPath(), cause.getMessage(), cause);
            ctx.setResponseHeader("Content-Type", "application/json");
            ctx.send(switch (statusCode.value()) {
                case 400 -> "{\"error\":\"Bad Request\",\"status\":400}";
                case 401 -> "{\"error\":\"Unauthorized\",\"status\":401}";
                case 404 -> "{\"error\":\"Not Found\",\"status\":404}";
                case 409 -> "{\"error\":\"Conflict\",\"status\":409}";
                case 503 -> "{\"error\":\"Service Unavailable\",\"status\":503}";
                default -> "{\"error\":\"Internal Server Error\",\"status\":500}";
            });
        });
    }

    private static void authFilter(Jooby app) {
        app.before(ctx -> {
            ctx.setResponseHeader("Access-Control-Allow-Origin", "*");
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
}
