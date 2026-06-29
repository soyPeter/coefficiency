package io.bitnomio.coeff.bonusbreakdown.app;

import io.bitnomio.coeff.bonusbreakdown.domain.BonusBreakdownRow;
import io.bitnomio.coeff.quarterlybonus.app.QuarterlyBonusService;
import io.bitnomio.coeff.shared.util.RoundingUtil;
import io.bitnomio.coeff.shared.util.SettingsHelper;
import io.bitnomio.coeff.tenurebonus.app.TenureBonusService;

import java.time.LocalDate;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Singleton
public class BonusBreakdownCacheService {

    private static final String[] MONTHS = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

    private final Jdbi jdbi;
    private final TenureBonusService tenureBonusService;
    private final QuarterlyBonusService quarterlyBonusService;

    public BonusBreakdownCacheService(Jdbi jdbi, TenureBonusService tenureBonusService,
                                       QuarterlyBonusService quarterlyBonusService) {
        this.jdbi = jdbi;
        this.tenureBonusService = tenureBonusService;
        this.quarterlyBonusService = quarterlyBonusService;
    }

    public void rebuildAsync() {
        CompletableFuture.runAsync(() -> {
            try { rebuild(); }
            catch (Exception e) { /* log */ }
        });
    }

    public void rebuild() {
        var consultants = jdbi.withHandle(h ->
            h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
             .mapToMap().list());

        LocalDate now = LocalDate.now();
        int currentYear = now.getYear();
        int currentMonth = now.getMonthValue();
        int earliestYear = consultants.stream()
            .mapToInt(r -> parseDate((String) r.get("start_date")).getYear())
            .min().orElse(currentYear);

        double bonusAmount = SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.tenure_bonus_amount", 300.0);
        int tenureMonths = SettingsHelper.readIntOrDefault(jdbi, "fiscal.tenure_bonus_months", 3);
        var consultantRecords = consultants.stream()
            .map(r -> new TenureBonusService.ConsultantRecord(
                ((Number) r.get("id")).intValue(),
                parseDate((String) r.get("start_date")),
                r.get("end_date") != null ? parseDate((String) r.get("end_date")) : null))
            .toList();
        tenureBonusService.ensureBonusesForConsultants(consultantRecords, bonusAmount, tenureMonths);

        int delta = SettingsHelper.readIntOrDefault(jdbi, "fiscal.delta_annual", 0);
        double qBonusAmount = SettingsHelper.readDoubleOrDefault(jdbi, "fiscal.quarterly_bonus_amount", 500.0);
        int bonusStartDay = SettingsHelper.readIntOrDefault(jdbi, "fiscal.mng_bonus_start_day", 14);
        int bonusEndDay = SettingsHelper.readIntOrDefault(jdbi, "fiscal.mng_bonus_end_day", 21);

        List<BonusBreakdownRow> rows = new ArrayList<>();
        for (int year = earliestYear; year <= currentYear; year++) {
            var monthlyBonusCounts = tenureBonusService.getMonthlyBonusCounts(year);
            quarterlyBonusService.calculate(consultantRecords, delta, qBonusAmount, year);
            var qBonuses = quarterlyBonusService.getQuarterlyBonuses(year);
            Map<Integer, Double> qBonusByMonth = qBonuses.stream()
                .filter(qb -> qb.earned())
                .collect(Collectors.toMap(qb -> qb.quarter() * 3, qb -> qb.amount()));
            var excludedMonths = List.of(8);

            for (int month = 1; month <= 12; month++) {
                double bonusSum = 0;
                if (!excludedMonths.contains(month)) {
                    for (var r : consultants) {
                        var start = parseDate((String) r.get("start_date"));
                        var end = r.get("end_date") != null ? parseDate((String) r.get("end_date")) : null;
                        var monthStart = LocalDate.of(year, month, 1);
                        var monthEnd = monthStart.plusMonths(1).minusDays(1);
                        boolean active = !start.isAfter(monthEnd) && (end == null || !end.isBefore(monthStart));
                        if (active) {
                            var mb = (Double) r.get("manager_bonus");
                            if (mb != null) bonusSum += mb;
                        }
                    }
                }

                int tbCount = monthlyBonusCounts.getOrDefault(month, 0);
                double tbAmount = RoundingUtil.round2(tbCount * bonusAmount);

                int projectedCount = 0;
                if (year == currentYear && month >= currentMonth) {
                    for (var cr : consultantRecords) {
                if (cr.startDate() == null) continue;
                    var milestoneDate = cr.startDate().plusMonths(tenureMonths);
                    if (cr.endDate() != null && cr.endDate().isBefore(milestoneDate)) continue;
                        var paidDate = milestoneDate.plusMonths(1);
                        if (paidDate.isAfter(now) && paidDate.getYear() == year && paidDate.getMonthValue() == month)
                            projectedCount++;
                    }
                }
                double projectedAmount = RoundingUtil.round2(projectedCount * bonusAmount);
                double qbAmount = qBonusByMonth.getOrDefault(month, 0.0);
                int qCount = qBonusByMonth.containsKey(month) ? 1 : 0;
                double managerBonus = RoundingUtil.round2(bonusSum);
                double total = RoundingUtil.round2(managerBonus + tbAmount + projectedAmount + qbAmount);
                String label = MONTHS[month - 1] + " " + year;
                rows.add(new BonusBreakdownRow(0, year, label, managerBonus, tbCount, tbAmount, projectedCount, projectedAmount, qCount, qbAmount, total));
            }
        }

        jdbi.useHandle(h -> {
            h.execute("DELETE FROM bonus_breakdown_cache");
            var batch = h.prepareBatch("INSERT INTO bonus_breakdown_cache (year, month_label, manager_bonus, tenure_count, tenure_amount, projected_tenure_count, projected_tenure_amount, quarterly_count, quarterly_amount, total_bonus) VALUES (:y, :m, :mb, :tc, :ta, :ptc, :pta, :qc, :qa, :tb)");
            for (var row : rows) {
                batch.bind("y", row.year()).bind("m", row.month())
                    .bind("mb", row.managerBonus()).bind("tc", row.tenureCount())
                    .bind("ta", row.tenureAmount()).bind("ptc", row.projectedTenureCount())
                    .bind("pta", row.projectedTenureAmount()).bind("qc", row.quarterlyCount())
                    .bind("qa", row.quarterlyAmount()).bind("tb", row.totalBonus())
                    .add();
            }
            batch.execute();
        });
    }

    public List<BonusBreakdownRow> findByYear(Integer year) {
        String sql = "SELECT id, year, month_label, manager_bonus, tenure_count, tenure_amount, projected_tenure_count, projected_tenure_amount, quarterly_count, quarterly_amount, total_bonus FROM bonus_breakdown_cache";
        if (year != null) sql += " WHERE year = :y";
        sql += " ORDER BY id";
        final String finalSql = sql;
        return jdbi.withHandle(h -> {
            var q = h.createQuery(finalSql);
            if (year != null) q.bind("y", year);
            return q.mapToMap().list().stream().map(this::mapRow).toList();
        });
    }

    private BonusBreakdownRow mapRow(Map<String, Object> r) {
        return new BonusBreakdownRow(
            ((Number) r.get("id")).intValue(), ((Number) r.get("year")).intValue(),
            (String) r.get("month_label"), ((Number) r.get("manager_bonus")).doubleValue(),
            ((Number) r.get("tenure_count")).intValue(), ((Number) r.get("tenure_amount")).doubleValue(),
            ((Number) r.get("projected_tenure_count")).intValue(), ((Number) r.get("projected_tenure_amount")).doubleValue(),
            ((Number) r.get("quarterly_count")).intValue(), ((Number) r.get("quarterly_amount")).doubleValue(),
            ((Number) r.get("total_bonus")).doubleValue());
    }

    private static LocalDate parseDate(String s) {
        return s != null ? LocalDate.parse(s) : LocalDate.now();
    }
}
