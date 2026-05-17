package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

@Singleton
public class Delete__ENTITY__UseCase {

    private final __ENTITY__CommandAction commandAction;

    @Inject
    public Delete__ENTITY__UseCase(__ENTITY__CommandAction commandAction) {
        this.commandAction = commandAction;
    }

    public void execute(String id, String deletedBy) {
        __ENTITY__ entity = commandAction.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("__ENTITY__ not found: " + id));

        __ENTITY__ deleted = entity.markAsDeleted(deletedBy);
        commandAction.save(deleted);
    }
}
