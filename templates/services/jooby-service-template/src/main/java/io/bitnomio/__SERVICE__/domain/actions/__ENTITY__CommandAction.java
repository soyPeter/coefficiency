package __PACKAGE__.__SERVICE__.domain.actions;

import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import java.util.Optional;

public interface __ENTITY__CommandAction {

    void save(__ENTITY__ entity);

    void update(__ENTITY__ entity);

    void delete(String id);

    Optional<__ENTITY__> findById(String id);
}
