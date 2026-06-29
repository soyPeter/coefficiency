package io.bitnomio.coeff.report.infra.rest;

import io.bitnomio.coeff.report.app.ReportService;
import io.jooby.annotation.GET;
import io.jooby.annotation.Path;
import io.jooby.annotation.QueryParam;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

@Singleton @Path("/api/report")
public class ReportController {

    private final ReportService reportService;

    @Inject
    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GET
    public List<Map<String, Object>> getReport(@QueryParam Integer year, @QueryParam String from, @QueryParam String to) {
        return reportService.getFullReport(year, from, to);
    }

    @GET @Path("/years")
    public List<Integer> getYears() {
        return reportService.getAvailableYears();
    }

    @GET @Path("/profitability")
    public List<Map<String, Object>> getProfitability(@QueryParam Integer year, @QueryParam String from, @QueryParam String to) {
        return reportService.getProfitability(year, from, to);
    }

    @GET @Path("/targets")
    public Map<String, Object> getTargets(@QueryParam Integer year) {
        return reportService.getTargets(year);
    }

    @GET @Path("/client-timeline")
    public List<Map<String, Object>> getClientTimeline(@QueryParam String client, @QueryParam Integer year) {
        return reportService.getClientTimeline(client, year);
    }

    @GET @Path("/clients")
    public List<String> getClients() {
        return reportService.getDistinctClients();
    }

    @GET @Path("/role-aggregation")
    public List<Map<String, Object>> getRoleAggregation() {
        return reportService.getRoleAggregation();
    }

    @GET @Path("/per-consultant")
    public List<Map<String, Object>> getPerConsultant(@QueryParam String search, @QueryParam String sortBy, @QueryParam String sortDir) {
        return reportService.getPerConsultant(search, sortBy, sortDir);
    }

    @GET @Path("/forecast")
    public Map<String, Object> getForecast() {
        return reportService.getForecast();
    }

    @GET @Path("/yoy")
    public List<Map<String, Object>> getYoy() {
        return reportService.getYoy();
    }

    @GET @Path("/benchmarks")
    public List<Map<String, Object>> getBenchmarks() {
        return reportService.getBenchmarks();
    }
}
