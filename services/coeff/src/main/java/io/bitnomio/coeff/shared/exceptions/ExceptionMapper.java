package io.bitnomio.coeff.shared.exceptions;

import io.jooby.Jooby;
import io.jooby.StatusCode;
import jakarta.inject.Singleton;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class ExceptionMapper {

    private static final Logger log = LoggerFactory.getLogger(ExceptionMapper.class);

    public void configure(Jooby app) {
        app.errorCode(NotFoundException.class, StatusCode.NOT_FOUND);
        app.errorCode(BadRequestException.class, StatusCode.BAD_REQUEST);
        app.errorCode(IllegalStateException.class, StatusCode.SERVICE_UNAVAILABLE);
        app.error((ctx, cause, statusCode) -> {
            if (ctx.isResponseStarted()) return;
            log.error("Error occurred while processing request, cause: {}", cause.getMessage(), cause);
            ctx.setResponseHeader("Content-Type", "application/json");
            var msg = cause != null ? cause.getMessage() : switch (statusCode.value()) {
                case 400 -> "Bad Request";
                case 401 -> "Unauthorized";
                case 404 -> "Not Found";
                case 503 -> "Service Unavailable";
                default -> "Internal Server Error";
            };
            ctx.send("{\"error\":\"" + escapeJson(msg) + "\",\"status\":" + statusCode.value() + "}");
        });
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}
