package io.bitnomio.coeff.bonusbreakdown.infra.rest;

import io.bitnomio.coeff.bonusbreakdown.app.BonusBreakdownCacheService;
import io.bitnomio.coeff.bonusbreakdown.domain.BonusBreakdownRow;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import io.jooby.annotation.QueryParam;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/billing")
public class BonusBreakdownController {

    private final BonusBreakdownCacheService cacheService;

    @Inject
    public BonusBreakdownController(BonusBreakdownCacheService cacheService) {
        this.cacheService = cacheService;
    }

    @GET @Path("/bonus-breakdown")
    public List<BonusBreakdownRow> getBreakdown(@QueryParam Integer year) {
        var rows = cacheService.findByYear(year);
        if (rows.isEmpty()) {
            cacheService.rebuild();
            rows = cacheService.findByYear(year);
        }
        return rows;
    }

    @POST @Path("/bonus-breakdown/refresh")
    public Map<String, Object> refresh() {
        cacheService.rebuildAsync();
        return Map.of("ok", true, "status", "rebuilding");
    }
}
