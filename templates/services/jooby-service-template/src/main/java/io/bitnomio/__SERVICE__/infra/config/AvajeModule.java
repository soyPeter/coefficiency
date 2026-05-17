package __PACKAGE__.__SERVICE__.infra.config;

import io.avaje.inject.InjectModule;
import org.jdbi.v3.core.Jdbi;

@InjectModule(requires = Jdbi.class)
public class AvajeModule {}
