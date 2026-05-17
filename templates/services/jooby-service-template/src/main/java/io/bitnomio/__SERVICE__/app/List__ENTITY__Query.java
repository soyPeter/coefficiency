package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.infra.data.persistence.sql.__ENTITY__Row;
import java.util.List;

public interface List__ENTITY__Query {

    List<__ENTITY__Row> findAll(int offset, int limit);

    long count();
}
