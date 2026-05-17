package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__Row;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import java.util.List;

@Singleton
public class List__ENTITY__UseCase {

    private final List__ENTITY__Query query;

    @Inject
    public List__ENTITY__UseCase(List__ENTITY__Query query) {
        this.query = query;
    }

    public List<__ENTITY__> execute(int page, int size) {
        return query.findAll(page * size, size).stream()
            .map(__ENTITY__Row::toDomain)
            .toList();
    }

    public long count() {
        return query.count();
    }
}
