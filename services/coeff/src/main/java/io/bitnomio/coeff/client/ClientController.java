package io.bitnomio.coeff.client;

import io.jooby.annotation.GET;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/clients")
public class ClientController {

    private final ClientService clientService;

    @Inject
    public ClientController(ClientService clientService) { this.clientService = clientService; }

    @GET
    public List<Map<String, Object>> summary() { return clientService.summary(); }

    @GET @Path("/financial")
    public List<Map<String, Object>> financial() { return clientService.financial(); }
}
