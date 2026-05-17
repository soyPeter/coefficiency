package io.bitnomio.coeff.shared.exceptions;

import io.jooby.Jooby;
import io.jooby.StatusCode;
import jakarta.inject.Singleton;

@Singleton
public class ExceptionMapper {

    public void configure(Jooby app) {
        app.errorCode(NotFoundException.class, StatusCode.NOT_FOUND);
        app.errorCode(BadRequestException.class, StatusCode.BAD_REQUEST);
        app.errorCode(IllegalStateException.class, StatusCode.SERVICE_UNAVAILABLE);
        app.error((ctx, cause, statusCode) -> {
            if (ctx.isResponseStarted()) return;
            ctx.setResponseHeader("Content-Type", "application/json");
            ctx.send(switch (statusCode.value()) {
                case 400 -> "{\"error\":\"Bad Request\",\"status\":400}";
                case 401 -> "{\"error\":\"Unauthorized\",\"status\":401}";
                case 404 -> "{\"error\":\"Not Found\",\"status\":404}";
                case 503 -> "{\"error\":\"Service Unavailable\",\"status\":503}";
                default -> "{\"error\":\"Internal Server Error\",\"status\":500}";
            });
        });
    }
}
