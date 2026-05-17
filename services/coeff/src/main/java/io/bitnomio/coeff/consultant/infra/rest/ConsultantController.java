package io.bitnomio.coeff.consultant.infra.rest;

import io.bitnomio.coeff.consultant.app.CreateConsultantUseCase;
import io.bitnomio.coeff.consultant.app.DeleteConsultantUseCase;
import io.bitnomio.coeff.consultant.app.UpdateConsultantUseCase;
import io.bitnomio.coeff.consultant.infra.data.sql.ListConsultantsQuery;
import io.bitnomio.coeff.consultant.infra.data.dto.ConsultantRes;
import io.bitnomio.coeff.consultant.infra.data.dto.CreateConsultantReq;
import io.bitnomio.coeff.consultant.infra.data.dto.UpdateConsultantReq;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.PUT;
import io.jooby.annotation.DELETE;
import io.jooby.annotation.Path;
import io.jooby.annotation.PathParam;
import io.jooby.annotation.QueryParam;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import java.util.Map;

/**
 * REST controller for consultant CRUD operations.
 *
 * <p>Returns paginated lists, single consultant details, and delegates
 * write operations to dedicated use cases.
 *
 * @since 1.0
 */
@Singleton
@Path("/api/consultants")
public class ConsultantController {

    private final CreateConsultantUseCase createUseCase;
    private final UpdateConsultantUseCase updateUseCase;
    private final DeleteConsultantUseCase deleteUseCase;
    private final ListConsultantsQuery listQuery;

    @Inject
    public ConsultantController(
            CreateConsultantUseCase createUseCase,
            UpdateConsultantUseCase updateUseCase,
            DeleteConsultantUseCase deleteUseCase,
            @Named("consultantQuery") ListConsultantsQuery listQuery) {
        this.createUseCase = createUseCase;
        this.updateUseCase = updateUseCase;
        this.deleteUseCase = deleteUseCase;
        this.listQuery = listQuery;
    }

    /**
     * Lists consultants with pagination, sorting, and optional text search.
     *
     * @param page   page number (1-based, defaults to 1)
     * @param size   page size (defaults to 100)
     * @param sort   field to sort by (defaults to "name")
     * @param order  sort direction "asc" or "desc" (defaults to "asc")
     * @param search optional text filter applied to name/client/position
     * @return paginated result with {@code items}, {@code total}, {@code page}, {@code size}
     */
    @GET
    public Map<String, Object> list(
            @QueryParam Integer page, @QueryParam Integer size,
            @QueryParam String sort, @QueryParam String order, @QueryParam String search) {
        var p = page != null ? page : 1;
        var s = size != null ? size : 100;
        var offset = (p - 1) * s;
        var rows = listQuery.findAll(offset, s,
            sort != null ? sort : "name", order != null ? order : "asc",
            search != null ? search : "");
        var items = rows.stream().map(r -> ConsultantRes.from(r.toDomain())).toList();
        var total = listQuery.count(search != null ? search : "");
        return Map.of("items", items, "total", total, "page", p, "size", s);
    }

    @POST
    public ConsultantRes create(CreateConsultantReq req) {
        return ConsultantRes.from(createUseCase.execute(
            req.name(), req.client(), req.position(), req.tariff(), req.coef(),
            req.startDate(), req.endDate(), req.fees()));
    }

    @PUT @Path("/{id}")
    public ConsultantRes update(@PathParam long id, UpdateConsultantReq req) {
        return ConsultantRes.from(updateUseCase.execute(
            id, req.name(), req.client(), req.position(), req.tariff(), req.coef(),
            req.startDate(), req.endDate(), req.fees()));
    }

    @DELETE @Path("/{id}")
    public void delete(@PathParam long id) { deleteUseCase.execute(id); }
}
