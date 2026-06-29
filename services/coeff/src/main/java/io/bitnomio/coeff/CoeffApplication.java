package io.bitnomio.coeff;

import io.bitnomio.coeff.shared.exceptions.ExceptionMapper;
import io.jooby.Jooby;
import io.jooby.OpenAPIModule;
import io.jooby.ServerOptions;
import io.jooby.avaje.inject.AvajeInjectModule;
import io.jooby.jackson.Jackson2Module;
import io.jooby.netty.NettyServer;

public class CoeffApplication extends Jooby {

    public CoeffApplication() {
        install(AvajeInjectModule.of());
        install(new Jackson2Module());

        install(new OpenAPIModule()
                .swaggerUI("/swagger")
                .redoc("/redoc")
        );

        new ExceptionMapper().configure(this);
        CoeffConfig.install(this);

        mvc(new io.bitnomio.coeff.auth.AuthController_());
        mvc(new io.bitnomio.coeff.consultant.infra.rest.ConsultantController_());
        mvc(new io.bitnomio.coeff.billing.BillingController_());
        mvc(new io.bitnomio.coeff.client.ClientController_());
        mvc(new io.bitnomio.coeff.file.FileImportController_());
        mvc(new io.bitnomio.coeff.simulator.SimulatorController_());
        mvc(new io.bitnomio.coeff.simulator.SettingsController_());
        mvc(new io.bitnomio.coeff.simulator.FiscalController_());
        mvc(new io.bitnomio.coeff.simulator.ConceptsController_());
        mvc(new io.bitnomio.coeff.doc.DocsController_());
        mvc(new io.bitnomio.coeff.bonusbreakdown.infra.rest.BonusBreakdownController_());
        mvc(new io.bitnomio.coeff.report.infra.rest.ReportController_());
        mvc(new io.bitnomio.coeff.admin.infra.rest.AdminController_());
    }

    public static void main(String[] args) {
        var options = new ServerOptions().setPort(62226)
                .setIoThreads(16)
                .setWorkerThreads(64)
                .setMaxRequestSize(10485760)
                .setHttp2(true);
        Jooby.runApp(args, new NettyServer(options), CoeffApplication::new);
    }
}
