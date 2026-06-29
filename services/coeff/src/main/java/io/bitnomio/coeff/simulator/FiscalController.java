package io.bitnomio.coeff.simulator;

import io.jooby.annotation.GET;
import io.jooby.annotation.PUT;
import io.jooby.annotation.Path;
import io.jooby.annotation.PathParam;
import io.jooby.value.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

/**
 * REST controller exposing fiscal settings at dedicated endpoints.
 *
 * <p>Thin routing layer that delegates all storage to {@link SettingsController}.
 * Mirrors Javalin's {@code FiscalController}.
 *
 * @since 1.0
 * @see SettingsController
 */
@Singleton @Path("/api")
public class FiscalController {

    private final SettingsController settingsController;

    @Inject
    public FiscalController(SettingsController settingsController) {
        this.settingsController = settingsController;
    }

    @GET @Path("/fiscal")
    public Map<String, Object> allFiscal() {
        return settingsController.allFiscal();
    }

    @GET @Path("/fiscal/{key}")
    public String getFiscal(@PathParam String key) {
        return settingsController.getFiscal(key);
    }

    @PUT @Path("/fiscal/{key}")
    public Map<String, String> upsertFiscal(@PathParam String key, SettingsController.FiscalUpsert body) {
        settingsController.upsertFiscal(key, body);
        return Map.of("ok", "true");
    }

    @GET @Path("/fiscal/working-days")
    public List<Integer> workingDays() {
        return settingsController.workingDays();
    }

    @PUT @Path("/fiscal/working-days")
    public void upsertWorkingDays(Value body) {
        settingsController.upsertWorkingDays(body);
    }
}
