package io.bitnomio.coeff.simulator;

import io.jooby.annotation.DELETE;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.PUT;
import io.jooby.annotation.Path;
import io.jooby.annotation.PathParam;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/concepts")
public class ConceptsController {

    private final Jdbi jdbi;

    @Inject
    public ConceptsController(Jdbi jdbi) { this.jdbi = jdbi; }

    @GET
    public List<Map<String, Object>> list() {
        return jdbi.withHandle(h -> h.createQuery("SELECT * FROM cost_concepts ORDER BY name").mapToMap().list());
    }

    @POST
    public void create(ConceptReq req) {
        jdbi.useHandle(h -> h.createUpdate("INSERT INTO cost_concepts (name, type, default_value, updated_at) VALUES (:name, :type, :value, datetime('now'))")
            .bind("name", req.name()).bind("type", req.type()).bind("value", req.defaultValue()).execute());
    }

    @PUT @Path("/{id}")
    public void update(@PathParam int id, ConceptReq req) {
        jdbi.useHandle(h -> h.createUpdate("UPDATE cost_concepts SET name=:name, type=:type, default_value=:value, updated_at=datetime('now') WHERE id=:id")
            .bind("id", id).bind("name", req.name()).bind("type", req.type()).bind("value", req.defaultValue()).execute());
    }

    @DELETE @Path("/{id}")
    public void delete(@PathParam int id) {
        jdbi.useHandle(h -> h.createUpdate("DELETE FROM cost_concepts WHERE id=:id").bind("id", id).execute());
    }

    public record ConceptReq(String name, String type, double defaultValue) {}
}
