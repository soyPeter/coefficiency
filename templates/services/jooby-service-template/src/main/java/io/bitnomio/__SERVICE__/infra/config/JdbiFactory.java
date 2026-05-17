package __PACKAGE__.__SERVICE__.infra.config;

import __PACKAGE__.__SERVICE__.app.List__ENTITY__Query;
import __PACKAGE__.__SERVICE__.app.Search__ENTITY__Query;
import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__SqlCommandRepo;
import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__SqlQueryRepo;
import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__SqlSearchRepo;
import io.avaje.inject.Bean;
import io.avaje.inject.Factory;
import jakarta.inject.Named;
import org.jdbi.v3.core.Jdbi;

@Factory
public class JdbiFactory {

    @Bean
    @Named("command")
    public __ENTITY__CommandAction commandRepo(Jdbi jdbi) {
        return jdbi.onDemand(__ENTITY__SqlCommandRepo.class);
    }

    @Bean
    @Named("query")
    public List__ENTITY__Query listQuery(Jdbi jdbi) {
        return jdbi.onDemand(__ENTITY__SqlQueryRepo.class);
    }

    @Bean
    @Named("search")
    public  Search__ENTITY__Query searchQuery(Jdbi jdbi) {
        return jdbi.onDemand(__ENTITY__SqlSearchRepo.class);
    }
}
