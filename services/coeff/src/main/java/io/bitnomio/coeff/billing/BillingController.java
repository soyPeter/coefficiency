package io.bitnomio.coeff.billing;

import io.jooby.annotation.GET;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/billing")
public class BillingController {

    private final BillingService billingService;

    @Inject
    public BillingController(BillingService billingService) { this.billingService = billingService; }

    @GET @Path("/summary")
    public Map<String, Object> summary() { return billingService.summary(); }

    @GET @Path("/monthly")
    public List<Map<String, Object>> monthly() { return billingService.monthly(); }
}
