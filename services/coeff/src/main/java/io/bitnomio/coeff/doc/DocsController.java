package io.bitnomio.coeff.doc;

import io.jooby.annotation.GET;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api")
public class DocsController {

    @Inject
    public DocsController() {}

    @GET @Path("/docs")
    public Map<String, Object> getDocs() {
        return Map.of(
            "endpoints", List.of(
                endpoint("GET", "/api/auth/status", "Check auth status"),
                endpoint("POST", "/api/auth/setup", "First-time setup"),
                endpoint("POST", "/api/auth/login", "Login"),
                endpoint("POST", "/api/auth/logout", "Logout"),
                endpoint("GET", "/api/consultants", "List consultants (paginated)"),
                endpoint("POST", "/api/consultants", "Create consultant"),
                endpoint("PUT", "/api/consultants/{id}", "Update consultant"),
                endpoint("DELETE", "/api/consultants/{id}", "Delete consultant"),
                endpoint("GET", "/api/billing/summary", "Billing summary"),
                endpoint("GET", "/api/billing/monthly", "Monthly billing"),
                endpoint("GET", "/api/clients", "Client summaries"),
                endpoint("GET", "/api/clients/financial", "Client financial data"),
                endpoint("POST", "/api/files/upload", "Import consultants CSV"),
                endpoint("GET", "/api/settings", "All settings"),
                endpoint("PUT", "/api/settings", "Upsert setting"),
                endpoint("GET", "/api/fiscal", "All fiscal settings"),
                endpoint("GET", "/api/fiscal/{key}", "Get fiscal setting"),
                endpoint("PUT", "/api/fiscal/{key}", "Upsert fiscal setting"),
                endpoint("GET", "/api/fiscal/working-days", "Get working days"),
                endpoint("PUT", "/api/fiscal/working-days", "Upsert working days"),
                endpoint("GET", "/api/simulator/defaults", "Simulator defaults"),
                endpoint("POST", "/api/simulator/calculate", "Run simulation"),
                endpoint("GET", "/api/concepts", "List cost concepts"),
                endpoint("POST", "/api/concepts", "Create concept"),
                endpoint("PUT", "/api/concepts/{id}", "Update concept"),
                endpoint("DELETE", "/api/concepts/{id}", "Delete concept")
            ),
            "entities", List.of(
                entity("Consultant", List.of(
                    field("id", "Long", "Unique identifier"),
                    field("name", "String", "Consultant name"),
                    field("client", "String", "Client company name"),
                    field("position", "String", "Job position"),
                    field("coef", "double", "COEF value"),
                    field("tariff", "double", "Daily rate"),
                    field("startDate", "String", "Start date (yyyy-MM-dd)"),
                    field("endDate", "String", "End date (nullable)"),
                    field("fees", "Double", "Monthly fees"),
                    field("coefPercentage", "Double", "COEF percentage"),
                    field("coefMargin", "Double", "COEF margin"),
                    field("managerBonus", "Double", "Manager bonus"),
                    field("simulationInputs", "String", "Saved simulation inputs (JSON)")
                ))
            ),
            "config", List.of(
                config("fiscal.coefDaysMonth", "21", "Working days per month for COEF calculation"),
                config("fiscal.coefDaysYear", "252", "Working days per year for COEF calculation"),
                config("fiscal.coefAlertThreshold", "0.15", "Minimum COEF% threshold for alerts"),
                config("fiscal.irpfTable", "[]", "IRPF brackets table"),
                config("fiscal.ssRate", "0.30", "Social Security employer rate"),
                config("fiscal.workingDays", "[21,21,22,22,21,22,22,21,22,21,22,21]", "Working days per month")
            ),
            "csvFormat", Map.of(
                "columns", List.of("name", "client", "position", "tariff", "startDate", "endDate"),
                "example", "John Doe,Acme Corp,Developer,450,2025-01-15,"
            )
        );
    }

    private static Map<String, String> endpoint(String method, String path, String description) {
        return Map.of("method", method, "path", path, "description", description,
            "requestBody", "-", "responseBody", "-");
    }

    private static Map<String, Object> entity(String name, List<Map<String, String>> fields) {
        return Map.of("name", name, "fields", fields);
    }

    private static Map<String, String> field(String name, String type, String description) {
        return Map.of("name", name, "type", type, "description", description);
    }

    private static Map<String, String> config(String key, String value, String description) {
        return Map.of("key", key, "value", value, "description", description);
    }
}
