package __PACKAGE__.__SERVICE__.app;

import __PACKAGE__.__SERVICE__.infra.data.dto.Create__ENTITY__Req;
import __PACKAGE__.__SERVICE__.domain.actions.__ENTITY__CommandAction;
import __PACKAGE__.__SERVICE__.domain.model.vo.__ENTITY__;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

@Singleton
public class Create__ENTITY__UseCase {

    private final __ENTITY__CommandAction commandAction;

    @Inject
    public Create__ENTITY__UseCase(__ENTITY__CommandAction commandAction) {
        this.commandAction = commandAction;
    }

    public __ENTITY__ execute(Create__ENTITY__Req request) {
        __ENTITY__ entity = __ENTITY__.create(
            request.name(),
            request.description()
        );
        commandAction.save(entity);
        return entity;
    }
}
