package __PACKAGE__.__SERVICE__.infra.io.rest;

import __PACKAGE__.__SERVICE__.app.Create__ENTITY__UseCase;
import __PACKAGE__.__SERVICE__.app.Update__ENTITY__UseCase;
import __PACKAGE__.__SERVICE__.app.Delete__ENTITY__UseCase;
import __PACKAGE__.__SERVICE__.app.Get__ENTITY__ByIdUseCase;
import __PACKAGE__.__SERVICE__.app.List__ENTITY__UseCase;
import __PACKAGE__.__SERVICE__.app.Search__ENTITY__UseCase;
import __PACKAGE__.__SERVICE__.infra.data.dto.Create__ENTITY__Req;
import __PACKAGE__.__SERVICE__.infra.data.dto.Update__ENTITY__Req;
import __PACKAGE__.__SERVICE__.infra.data.dto.Search__ENTITY__Req;
import __PACKAGE__.__SERVICE__.infra.data.dto.__ENTITY__Res;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import io.jooby.annotation.*;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;

@Singleton
@Path("/api/v1/__TABLE_URL__")
public class __ENTITY__CommandController {

    private final Create__ENTITY__UseCase createUseCase;
    private final Update__ENTITY__UseCase updateUseCase;
    private final Delete__ENTITY__UseCase deleteUseCase;
    private final Get__ENTITY__ByIdUseCase getByIdUseCase;
    private final List__ENTITY__UseCase listUseCase;
    private final Search__ENTITY__UseCase searchUseCase;

    @Inject
    public __ENTITY__CommandController(
            Create__ENTITY__UseCase createUseCase,
            Update__ENTITY__UseCase updateUseCase,
            Delete__ENTITY__UseCase deleteUseCase,
            Get__ENTITY__ByIdUseCase getByIdUseCase,
            List__ENTITY__UseCase listUseCase,
            Search__ENTITY__UseCase searchUseCase) {
        this.createUseCase = createUseCase;
        this.updateUseCase = updateUseCase;
        this.deleteUseCase = deleteUseCase;
        this.getByIdUseCase = getByIdUseCase;
        this.listUseCase = listUseCase;
        this.searchUseCase = searchUseCase;
    }

    @POST
    public __ENTITY__Res create(@Body Create__ENTITY__Req request) {
        __ENTITY__ created = createUseCase.execute(request);
        return __ENTITY__Res.from(created);
    }

    @GET
    @Path("/{id}")
    public __ENTITY__Res getById(@PathParam String id) {
        return getByIdUseCase.execute(id)
            .map(__ENTITY__Res::from)
            .orElse(null);
    }

    @PUT
    @Path("/{id}")
    public __ENTITY__Res update(@PathParam String id, @Body Update__ENTITY__Req request) {
        __ENTITY__ updated = updateUseCase.execute(id, request);
        return __ENTITY__Res.from(updated);
    }

    @DELETE
    @Path("/{id}")
    public void delete(@PathParam String id, @QueryParam String deletedBy) {
        deleteUseCase.execute(id, deletedBy != null ? deletedBy : "system");
    }

    @GET
    public List<__ENTITY__Res> list(
            @QueryParam int page,
            @QueryParam int size) {
        List<__ENTITY__> entities = listUseCase.execute(page, size);
        return entities.stream().map(__ENTITY__Res::from).toList();
    }

    @GET
    @Path("/search")
    public List<__ENTITY__Res> search(
            @QueryParam String name,
            @QueryParam String description,
            @QueryParam int page,
            @QueryParam int size) {
        Search__ENTITY__Req request = new Search__ENTITY__Req(name, description, page, size);
        List<__ENTITY__> entities = searchUseCase.execute(request);
        return entities.stream().map(__ENTITY__Res::from).toList();
    }
}
