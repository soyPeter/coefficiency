package io.bitnomio.coeff.report.app;

import io.bitnomio.coeff.shared.util.RoundingUtil;
import io.bitnomio.coeff.shared.util.SettingsHelper;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

@Singleton
public class ReportService {

    private static final String[] MONTHS = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};

    // Map-key constants (API contract)
    private static final String KEY_SECTION = "section";
    private static final String KEY_DATA = "data";
    private static final String KEY_MONTH = "month";
    private static final String KEY_FEES = "fees";
    private static final String KEY_MARGIN = "margin";
    private static final String KEY_COEF_PCT = "avgCoefPct";
    private static final String KEY_ACTIVE_COUNT = "activeCount";
    private static final String KEY_ROLE = "role";
    private static final String KEY_CONSULTANT_COUNT = "consultantCount";
    private static final String KEY_TOTAL_DAILY = "totalDaily";

    // Settings-key constants
    private static final String SETTING_COEF_DAYS_MONTH = "fiscal.coefDaysMonth";
    private static final String SETTING_REPORT_TARGET_REVENUE = "fiscal.report_target_revenue";
    private static final String SETTING_REPORT_TARGET_MARGIN = "fiscal.report_target_margin";

    private final Jdbi jdbi;
    private final PeerBenchmarkService peerBenchmarkService;

    public ReportService(Jdbi jdbi, PeerBenchmarkService peerBenchmarkService) {
        this.jdbi = jdbi;
        this.peerBenchmarkService = peerBenchmarkService;
    }

    public List<Integer> getAvailableYears() {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT start_date, end_date FROM consultants").mapToMap().list());
        var years = new TreeSet<Integer>();
        years.add(LocalDate.now().getYear());
        for (var r : rows) {
            if (r.get("start_date") != null) years.add(LocalDate.parse((String) r.get("start_date")).getYear());
            if (r.get("end_date") != null) years.add(LocalDate.parse((String) r.get("end_date")).getYear());
        }
        return List.copyOf(years);
    }

    public List<Map<String, Object>> getFullReport(Integer year, String from, String to) {
        var range = resolveRange(year, from, to);
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM consultants").mapToMap().list());
        var filtered = filterByRange(consultants, range);
        var summary = computeSummary(filtered);
        var monthly = computeMonthly(filtered, range);
        var clients = computeClientFinancials(filtered);
        return List.of(
            Map.of(KEY_SECTION, "consultants", KEY_DATA, filtered),
            Map.of(KEY_SECTION, "summary", KEY_DATA, summary),
            Map.of(KEY_SECTION, "monthly", KEY_DATA, monthly),
            Map.of(KEY_SECTION, "clients", KEY_DATA, clients)
        );
    }

    public List<Map<String, Object>> getProfitability(Integer year, String from, String to) {
        var range = resolveRange(year, from, to);
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM consultants").mapToMap().list());
        var months = new ArrayList<Map<String, Object>>();
        var y = range.start().getYear(); var m = range.start().getMonthValue();
        var endY = range.end().getYear(); var endM = range.end().getMonthValue();
        while (y < endY || (y == endY && m <= endM)) {
            var ms = LocalDate.of(y, m, 1);
            var me = ms.plusMonths(1).minusDays(1);
            double fees = 0, margin = 0, coefSum = 0;
            int active = 0, coefCount = 0;
            for (var c : consultants) {
                if (isActive(c, ms, me)) {
                    active++;
                    fees += nd(c, "fees");
                    margin += nd(c, "coef_margin");
                    coefSum += nd(c, "coef_percentage");
                    if (nd(c, "coef_percentage") > 0) coefCount++;
                }
            }
            double mp = fees > 0 ? Math.round(margin / fees * 10000.0) / 100.0 : 0;
            double avgCoef = active > 0 ? Math.round((coefCount > 0 ? coefSum : 0) / active * 10000.0) / 100.0 : 0;
            months.add(Map.of(KEY_MONTH, MONTHS[m - 1] + " " + y, "marginPct", mp, "totalFees", RoundingUtil.round2(fees), KEY_COEF_PCT, avgCoef));
            if (++m > 12) { m = 1; y++; }
        }
        return months;
    }

    public Map<String, Object> getTargets(Integer year) {
        var summary = computeSummary(jdbi.withHandle(h -> h.createQuery("SELECT * FROM consultants").mapToMap().list()));
        double targetRevenue = SettingsHelper.readDoubleOrDefault(jdbi, SETTING_REPORT_TARGET_REVENUE, 500000);
        double targetMarginPct = SettingsHelper.readDoubleOrDefault(jdbi, SETTING_REPORT_TARGET_MARGIN, 25.0);
        double actualMarginPct = nd(summary, "totalFees") > 0
            ? Math.round(nd(summary, "totalCoefMargin") / nd(summary, "totalFees") * 10000.0) / 100.0 : 0;
        return Map.of("targetRevenue", targetRevenue, "actualRevenue", nd(summary, "annual"),
            "targetMarginPct", targetMarginPct, "actualMarginPct", actualMarginPct);
    }

    public List<Map<String, Object>> getClientTimeline(String client, Integer year) {
        int y = year != null ? year : LocalDate.now().getYear();
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM consultants").mapToMap().list());
        var clientCs = client != null && !client.isBlank()
            ? consultants.stream().filter(c -> client.equalsIgnoreCase((String) c.get("client"))).toList()
            : consultants;
        var months = new ArrayList<Map<String, Object>>();
        for (int m = 1; m <= 12; m++) {
            var ms = LocalDate.of(y, m, 1);
            var me = ms.plusMonths(1).minusDays(1);
            double fees = 0, margin = 0; int active = 0;
            for (var c : clientCs) {
                if (isActive(c, ms, me)) {
                    active++; fees += nd(c, "fees"); margin += nd(c, "coef_margin");
                }
            }
            months.add(Map.of(KEY_MONTH, MONTHS[m - 1] + " " + y, KEY_FEES, RoundingUtil.round2(fees),
                KEY_MARGIN, RoundingUtil.round2(margin), "activeConsultants", active));
        }
        return months;
    }

    public List<String> getDistinctClients() {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT DISTINCT client FROM consultants ORDER BY client")
             .mapTo(String.class).list());
    }

    public List<Map<String, Object>> getRoleAggregation() {
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT position, tariff, coef_percentage, coef_margin FROM consultants WHERE end_date IS NULL OR end_date > date('now')")
             .mapToMap().list());
        var benchmarks = peerBenchmarkService.computeAllBenchmarks();
        var byRole = consultants.stream()
            .filter(r -> r.get("position") != null && !((String) r.get("position")).isBlank())
            .collect(Collectors.groupingBy(r -> (String) r.get("position")));
        var roles = new ArrayList<Map<String, Object>>();
        for (var e : byRole.entrySet()) {
            var cs = e.getValue();
            double daily = cs.stream().mapToDouble(r -> nd(r, "tariff")).sum();
            double margin = cs.stream().mapToDouble(r -> nd(r, "coef_margin")).sum();
            double avgCoef = cs.stream().mapToDouble(r -> nd(r, "coef_percentage")).filter(v -> v > 0).average().orElse(0);
            var b = benchmarks.get(e.getKey());
            roles.add(Map.of(KEY_ROLE, e.getKey(), KEY_CONSULTANT_COUNT, cs.size(),
                KEY_TOTAL_DAILY, RoundingUtil.round2(daily), KEY_COEF_PCT, RoundingUtil.round2(avgCoef),
                "totalMargin", RoundingUtil.round2(margin),
                "peerCount", b != null ? b.peerCount() : null,
                "p25", b != null ? RoundingUtil.round2(b.p25()) : null,
                "p50", b != null ? RoundingUtil.round2(b.p50()) : null,
                "p75", b != null ? RoundingUtil.round2(b.p75()) : null));
        }
        roles.sort(Comparator.comparingDouble(r -> -nd(r, "totalMargin")));
        return roles;
    }

    public List<Map<String, Object>> getPerConsultant(String search, String sortBy, String sortDir) {
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM consultants").mapToMap().list()).stream()
            .filter(c -> search == null || search.isBlank()
                || (c.get("name") != null && ((String) c.get("name")).toLowerCase().contains(search.toLowerCase()))
                || (c.get("client") != null && ((String) c.get("client")).toLowerCase().contains(search.toLowerCase())))
            .map(c -> Map.<String, Object>of(
                "id", c.get("id"), "name", c.get("name") != null ? c.get("name") : "", "client", c.get("client") != null ? c.get("client") : "",
                "position", c.get("position") != null ? c.get("position") : "",
                "tariff", nd(c, "tariff"), "fees", nd(c, "fees"),
                "coefMargin", nd(c, "coef_margin"), "managerBonus", nd(c, "manager_bonus")))
            .collect(Collectors.toCollection(ArrayList::new));
        var sorters = new java.util.HashMap<>(Map.<String, Comparator<Map<String, Object>>>of(
            "tariff", Comparator.comparingDouble(r -> nd(r, "tariff")),
            "fees", Comparator.comparingDouble(r -> nd(r, "fees")),
            "coefMargin", Comparator.comparingDouble(r -> nd(r, "coefMargin")),
            "managerBonus", Comparator.comparingDouble(r -> nd(r, "managerBonus"))));
        boolean asc = sortDir == null || "asc".equals(sortDir);
        Comparator<Map<String, Object>> nameComp = Comparator.comparing(r -> (String) r.get("name"), String.CASE_INSENSITIVE_ORDER);
        var comp = sortBy != null ? sorters.getOrDefault(sortBy, nameComp) : nameComp;
        consultants.sort(asc ? comp : comp.reversed());
        return consultants;
    }

    public Map<String, Object> getForecast() {
        int cy = LocalDate.now().getYear();
        int cm = LocalDate.now().getMonthValue();
        int cdm = (int) SettingsHelper.readDoubleOrDefault(jdbi, SETTING_COEF_DAYS_MONTH, 21);
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT tariff, start_date, end_date FROM consultants").mapToMap().list());
        double currentDaily = rows.stream()
            .filter(r -> isActive(r, LocalDate.now().withDayOfMonth(1), LocalDate.now()))
            .mapToDouble(r -> nd(r, "tariff")).sum();
        int ytdDays = cm * cdm;
        int remainingMonths = 12 - cm;
        double ytd = currentDaily * ytdDays;
        double projectedRem = currentDaily * remainingMonths * cdm;
        double projectedTotal = ytd + projectedRem;
        double avgGrowthRatePct = 0;
        if (cm >= 2) {
            int lookback = Math.min(3, cm);
            double[] trail = new double[lookback];
            for (int i = 0; i < lookback; i++) {
                int m = cm - lookback + i;
                var ms = LocalDate.of(cy, m, 1);
                var me = ms.plusMonths(1).minusDays(1);
                double daily = rows.stream()
                    .filter(r -> isActive(r, ms, me))
                    .mapToDouble(r -> nd(r, "tariff")).sum();
                trail[i] = daily;
            }
            avgGrowthRatePct = io.bitnomio.coeff.billing.domain.BillingCalculator.avgGrowthRate(trail) * 100;
        }
        return Map.ofEntries(
            Map.entry("currentDailyBilling", RoundingUtil.round2(currentDaily)),
            Map.entry("ytdWorkingDays", ytdDays),
            Map.entry("ytdBilling", RoundingUtil.round2(ytd)),
            Map.entry("remainingWorkingDays", remainingMonths * cdm),
            Map.entry("projectedRemaining", RoundingUtil.round2(projectedRem)),
            Map.entry("projectedTotal", RoundingUtil.round2(projectedTotal)),
            Map.entry("currentYear", cy),
            Map.entry("avgGrowthRatePct", RoundingUtil.round2(avgGrowthRatePct)));
    }

    public List<Map<String, Object>> getYoy() {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT tariff, start_date, end_date, coef_percentage, coef_margin, manager_bonus FROM consultants")
             .mapToMap().list());
        int cy = LocalDate.now().getYear();
        var years = new ArrayList<Map<String, Object>>();
        for (int y = getAvailableYears().get(0); y <= cy; y++) {
            var ys = LocalDate.of(y, 1, 1);
            var ye = LocalDate.of(y, 12, 31);
            var active = rows.stream().filter(r -> isActive(r, ys, ye)).toList();
            double daily = active.stream().mapToDouble(r -> nd(r, "tariff")).sum();
            double annual = daily * 252;
            long hires = active.stream().filter(r -> {
                var sd = r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")) : null;
                return sd != null && !sd.isBefore(ys) && !sd.isAfter(ye);
            }).count();
            long terms = active.stream().filter(r -> {
                var ed = r.get("end_date") != null ? LocalDate.parse((String) r.get("end_date")) : null;
                return ed != null && !ed.isBefore(ys) && !ed.isAfter(ye);
            }).count();
            double avgCoef = active.stream().mapToDouble(r -> nd(r, "coef_percentage")).filter(v -> v > 0).average().orElse(0);
            years.add(Map.of("year", y, "daily", RoundingUtil.round2(daily),
                "monthly", RoundingUtil.round2(daily * 21), "annual", RoundingUtil.round2(annual),
                "headcount", active.size(), "hires", (int) hires, "terminations", (int) terms,
                "avgCoefPct", RoundingUtil.round2(avgCoef)));
        }
        return years;
    }

    public List<Map<String, Object>> getBenchmarks() {
        return peerBenchmarkService.computeAllBenchmarks().values().stream()
            .sorted((a, b) -> a.role().compareToIgnoreCase(b.role()))
            .map(b -> Map.<String, Object>of("role", b.role(), "p25", b.p25(), "p50", b.p50(),
                "p75", b.p75(), "peerCount", b.peerCount()))
            .toList();
    }

    // --- Helpers ---

    record DateRange(LocalDate start, LocalDate end) {}

    private static DateRange resolveRange(Integer year, String from, String to) {
        if (from != null && to != null) return new DateRange(LocalDate.parse(from), LocalDate.parse(to));
        if (year != null) return new DateRange(LocalDate.of(year, 1, 1), LocalDate.of(year, 12, 31));
        return new DateRange(LocalDate.of(2000, 1, 1), LocalDate.of(2099, 12, 31));
    }

    private static boolean isActive(Map<String, Object> r, LocalDate start, LocalDate end) {
        var sd = r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")) : null;
        var ed = r.get("end_date") != null ? LocalDate.parse((String) r.get("end_date")) : null;
        if (sd == null || sd.isAfter(end)) return false;
        return ed == null || !ed.isBefore(start);
    }

    private static List<Map<String, Object>> filterByRange(List<Map<String, Object>> consultants, DateRange range) {
        return consultants.stream().filter(c -> isActive(c, range.start(), range.end())).toList();
    }

    private static double nd(Map<String, Object> r, String key) {
        var v = r.get(key);
        if (v instanceof Number n) return n.doubleValue();
        return 0.0;
    }

    private static Map<String, Object> computeSummary(List<Map<String, Object>> consultants) {
        double daily = consultants.stream().mapToDouble(r -> nd(r, "tariff")).sum();
        int count = consultants.size();
        double fees = consultants.stream().mapToDouble(r -> nd(r, "fees")).sum();
        double margin = consultants.stream().mapToDouble(r -> nd(r, "coef_margin")).sum();
        double bonus = consultants.stream().mapToDouble(r -> nd(r, "manager_bonus")).sum();
        double avgCoef = consultants.stream().mapToDouble(r -> nd(r, "coef_percentage")).filter(v -> v > 0).average().orElse(0);
        return Map.of("daily", RoundingUtil.round2(daily), "monthly", RoundingUtil.round2(daily * 21),
            "annual", RoundingUtil.round2(daily * 252), "consultantCount", count,
            "totalFees", RoundingUtil.round2(fees), "avgCoefPct", RoundingUtil.round2(avgCoef),
            "totalCoefMargin", RoundingUtil.round2(margin), "totalManagerBonus", RoundingUtil.round2(bonus));
    }

    private List<Map<String, Object>> computeMonthly(List<Map<String, Object>> consultants, DateRange range) {
        var months = new ArrayList<Map<String, Object>>();
        int y = range.start().getYear(), m = range.start().getMonthValue();
        int endY = range.end().getYear(), endM = range.end().getMonthValue();
        while (y < endY || (y == endY && m <= endM)) {
            var ms = LocalDate.of(y, m, 1);
            var me = ms.plusMonths(1).minusDays(1);
            double fees = 0, margin = 0;
            int active = 0;
            for (var c : consultants) {
                if (isActive(c, ms, me)) { active++; fees += nd(c, "fees"); margin += nd(c, "coef_margin"); }
            }
            months.add(Map.of(KEY_MONTH, MONTHS[m - 1] + " " + y, KEY_FEES, RoundingUtil.round2(fees),
                KEY_MARGIN, RoundingUtil.round2(margin), KEY_ACTIVE_COUNT, active));
            if (++m > 12) { m = 1; y++; }
        }
        return months;
    }

    private List<Map<String, Object>> computeClientFinancials(List<Map<String, Object>> consultants) {
        var byClient = consultants.stream().collect(Collectors.groupingBy(r -> (String) r.get("client")));
        var result = new ArrayList<Map<String, Object>>();
        for (var e : byClient.entrySet()) {
            var cs = e.getValue();
            double daily = cs.stream().mapToDouble(r -> nd(r, "tariff")).sum();
            double margin = cs.stream().mapToDouble(r -> nd(r, "coef_margin")).sum();
            double bonus = cs.stream().mapToDouble(r -> nd(r, "manager_bonus")).sum();
            var startDates = cs.stream().map(r -> r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")) : null)
                .filter(d -> d != null).toList();
            double avgTenure = startDates.stream().mapToLong(d -> ChronoUnit.DAYS.between(d, LocalDate.now())).average().orElse(0);
            result.add(Map.of("client", e.getKey(), "consultants", cs.size(),
                "daily", RoundingUtil.round2(daily), "margin", RoundingUtil.round2(margin),
                "bonus", RoundingUtil.round2(bonus), "avgTenureDays", (long) avgTenure));
        }
        return result;
    }
}
