package io.bitnomio.coeff.simulator;

import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.PUT;
import io.jooby.annotation.Path;
import io.jooby.annotation.PathParam;
import io.jooby.value.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * REST controller for application settings stored in the {@code settings} table.
 *
 * <p>Supports CRUD on individual keys, batch retrieval of all {@code fiscal.*}
 * settings (with JSON value parsing), and a dedicated endpoint for the
 * working-days array used by the simulator.
 *
 * @since 1.0
 */
@Singleton @Path("/api")
public class SettingsController {

    private final Jdbi jdbi;

    @Inject
    public SettingsController(Jdbi jdbi) { this.jdbi = jdbi; }

    @GET @Path("/settings")
    public List<Map<String, Object>> all() {
        return jdbi.withHandle(h -> h.createQuery("SELECT key, value FROM settings ORDER BY key").mapToMap().list());
    }

    @PUT @Path("/settings")
    public void upsert(Value body) {
        var key = body.get("key").value();
        var value = body.get("value").value();
        jdbi.useHandle(h -> h.createUpdate(
            "INSERT INTO settings (key, value, updated_at) VALUES (:key, :value, datetime('now')) " +
            "ON CONFLICT(key) DO UPDATE SET value = :value, updated_at = datetime('now')")
            .bind("key", key).bind("value", value).execute());
    }

    @GET @Path("/fiscal")
    public Map<String, Object> allFiscal() {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT key, value FROM settings WHERE key LIKE 'fiscal.%'")
             .mapToMap().list());
        var result = new HashMap<String, Object>();
        for (var row : rows) {
            var k = ((String) row.get("key")).replace("fiscal.", "");
            var v = (String) row.get("value");
            if (v != null) {
                try { result.put(k, new com.fasterxml.jackson.databind.ObjectMapper().readTree(v)); }
                catch (Exception e) { result.put(k, v); }
            }
        }
        return result;
    }

    @GET @Path("/fiscal/{key}")
    public String getFiscal(@PathParam String key) {
        return jdbi.withHandle(h -> h.createQuery(
            "SELECT value FROM settings WHERE key = :key")
            .bind("key", "fiscal." + key)
            .mapTo(String.class).findOne().orElse(null));
    }

    @PUT @Path("/fiscal/{key}")
    public void upsertFiscal(@PathParam String key, Value body) {
        jdbi.useHandle(h -> h.createUpdate(
            "INSERT INTO settings (key, value, updated_at) VALUES (:key, :value, datetime('now')) " +
            "ON CONFLICT(key) DO UPDATE SET value = :value, updated_at = datetime('now')")
            .bind("key", "fiscal." + key)
            .bind("value", body.get("value").value())
            .execute());
    }

    @GET @Path("/fiscal/working-days")
    public List<Integer> workingDays() {
        var val = jdbi.withHandle(h -> h.createQuery(
            "SELECT value FROM settings WHERE key = 'fiscal.workingDays'")
            .mapTo(String.class).findOne().orElse("[]"));
        try { return new com.fasterxml.jackson.databind.ObjectMapper().readValue(val,
            new com.fasterxml.jackson.core.type.TypeReference<List<Integer>>() {}); }
        catch (Exception e) { return List.of(); }
    }

    @PUT @Path("/fiscal/working-days")
    public void upsertWorkingDays(Value body) {
        var raw = body.get("value");
        var json = raw.isArray() ? raw.toString() : raw.value();
        jdbi.useHandle(h -> h.createUpdate(
            "INSERT INTO settings (key, value, updated_at) VALUES (:key, :value, datetime('now')) " +
            "ON CONFLICT(key) DO UPDATE SET value = :value, updated_at = datetime('now')")
            .bind("key", "fiscal.workingDays").bind("value", json).execute());
    }
}
