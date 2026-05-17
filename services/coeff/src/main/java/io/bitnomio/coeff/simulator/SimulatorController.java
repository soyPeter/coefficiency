package io.bitnomio.coeff.simulator;

import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.Map;

@Singleton @Path("/api/simulator")
public class SimulatorController {

    private final SimulatorService simulatorService;

    @Inject
    public SimulatorController(SimulatorService simulatorService) { this.simulatorService = simulatorService; }

    @GET @Path("/defaults")
    public Map<String, Object> defaults() { return simulatorService.defaults(); }

    @POST @Path("/calculate")
    public SimulatorResult calculate(SimulatorInput input) { return simulatorService.calculate(input); }
}
