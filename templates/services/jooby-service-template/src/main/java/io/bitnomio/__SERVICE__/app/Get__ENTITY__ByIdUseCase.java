package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import java.util.Optional;

@Singleton
public class Get__ENTITY__ByIdUseCase {

    private final __ENTITY__CommandAction commandAction;

    @Inject
    public Get__ENTITY__ByIdUseCase(__ENTITY__CommandAction commandAction) {
        this.commandAction = commandAction;
    }

    public Optional<__ENTITY__> execute(String id) {
        return commandAction.findById(id);
    }
}
