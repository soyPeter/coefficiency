package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.infra.data.dto.Update__ENTITY__Req;
import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

@Singleton
public class Update__ENTITY__UseCase {

    private final __ENTITY__CommandAction commandAction;

    @Inject
    public Update__ENTITY__UseCase(__ENTITY__CommandAction commandAction) {
        this.commandAction = commandAction;
    }

    public __ENTITY__ execute(String id, Update__ENTITY__Req request) {
        __ENTITY__ entity = commandAction.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("__ENTITY__ not found: " + id));

        __ENTITY__ updated = entity.update(request.name(), request.description());
        commandAction.save(updated);
        return updated;
    }
}
