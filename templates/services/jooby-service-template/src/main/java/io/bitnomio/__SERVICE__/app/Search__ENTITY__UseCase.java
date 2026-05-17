package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.infra.data.dto.Search__ENTITY__Req;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__Row;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import java.util.List;

@Singleton
public class Search__ENTITY__UseCase {

    private final Search__ENTITY__Query query;

    @Inject
    public Search__ENTITY__UseCase(Search__ENTITY__Query query) {
        this.query = query;
    }

    public List<__ENTITY__> execute(Search__ENTITY__Req request) {
        return query.search(
            request.nameFilter(),
            request.descriptionFilter(),
            request.page() * request.size(),
            request.size()
        ).stream()
            .map(__ENTITY__Row::toDomain)
            .toList();
    }

    public long count(Search__ENTITY__Req request) {
        return query.count(request.nameFilter(), request.descriptionFilter());
    }
}
