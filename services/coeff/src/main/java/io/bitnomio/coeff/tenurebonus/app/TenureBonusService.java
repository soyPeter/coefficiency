package io.bitnomio.coeff.tenurebonus.app;

import io.bitnomio.coeff.tenurebonus.domain.TenureBonus;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Singleton
public class TenureBonusService {

    private static final DateTimeFormatter YEAR_MONTH = DateTimeFormatter.ofPattern("yyyy-MM");
    private final Jdbi jdbi;

    public TenureBonusService(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public void ensureBonusesForConsultants(List<ConsultantRecord> consultants, double amount, int tenureMonths) {
        LocalDate now = LocalDate.now();
        for (var c : consultants) {
            if (c.startDate == null) continue;
            var milestoneDate = c.startDate.plusMonths(tenureMonths);
            if (c.endDate != null && c.endDate.isBefore(milestoneDate)) continue;
            var paidDate = milestoneDate.plusMonths(1);
            if (paidDate.isAfter(now)) continue;
            var paidMonth = paidDate.format(YEAR_MONTH);
            jdbi.useHandle(h -> h.createUpdate(
                "INSERT OR IGNORE INTO tenure_bonuses (consultant_id, amount, paid_month) VALUES (:cid, :amount, :pm)")
                .bind("cid", c.id).bind("amount", amount).bind("pm", paidMonth).execute());
        }
    }

    public record ConsultantRecord(int id, LocalDate startDate, LocalDate endDate) {}

    public Map<Integer, Integer> getMonthlyBonusCounts(int year) {
        var bonuses = jdbi.withHandle(h ->
            h.createQuery("SELECT * FROM tenure_bonuses WHERE paid_month LIKE :prefix ORDER BY paid_month")
             .bind("prefix", year + "-%")
             .mapToMap().list());
        Map<Integer, Integer> counts = new HashMap<>();
        for (int m = 1; m <= 12; m++) counts.put(m, 0);
        for (var b : bonuses) {
            var pm = (String) b.get("paid_month");
            var parts = pm.split("-");
            if (parts.length == 2) {
                int month = Integer.parseInt(parts[1]);
                counts.merge(month, 1, Integer::sum);
            }
        }
        return counts;
    }

    public double getTotalTenureBonuses(int year) {
        var result = jdbi.withHandle(h ->
            h.createQuery("SELECT COALESCE(SUM(amount), 0) FROM tenure_bonuses WHERE paid_month LIKE :prefix")
             .bind("prefix", year + "-%")
             .mapTo(Double.class).one());
        return result;
    }

    public int getTotalTenureBonusCount(int year) {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT COUNT(*) FROM tenure_bonuses WHERE paid_month LIKE :prefix")
             .bind("prefix", year + "-%")
             .mapTo(Integer.class).one());
    }
}
