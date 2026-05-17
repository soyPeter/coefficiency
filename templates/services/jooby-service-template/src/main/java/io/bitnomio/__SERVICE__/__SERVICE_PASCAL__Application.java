package __PACKAGE__.__SERVICE__;

import io.jooby.Jooby;
import io.jooby.avaje.AvajeInjectModule;
import io.jooby.flyway.FlywayModule;
import io.jooby.jdbi.JdbiModule;
import jakarta.inject.Singleton;

@Singleton
public class __SERVICE_PASCAL__Application extends Jooby {

    public __SERVICE_PASCAL__Application() {
        install(AvajeInjectModule.of());
        install(new JdbiModule());
        install(new FlywayModule());

        mvc(__PACKAGE__.__SERVICE__.infra.io.rest.__ENTITY__CommandController.class);
    }

    public static void main(String[] args) {
        Jooby.runApp(args, __SERVICE_PASCAL__Application::new);
    }
}
