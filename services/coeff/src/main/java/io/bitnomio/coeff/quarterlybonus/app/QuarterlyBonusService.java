package io.bitnomio.coeff.quarterlybonus.app;

import io.bitnomio.coeff.quarterlybonus.domain.QuarterlyBonus;
import io.bitnomio.coeff.tenurebonus.app.TenureBonusService;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.List;

@Singleton
public class QuarterlyBonusService {

    private final Jdbi jdbi;

    public QuarterlyBonusService(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public void calculate(List<TenureBonusService.ConsultantRecord> consultants, int annualDelta, double bonusAmount, int year) {
        int quarterlyTarget = (int) Math.ceil((double) annualDelta / 4.0);
        for (int qi = 1; qi <= 4; qi++) {
            int qStartMonth = (qi - 1) * 3 + 1;
            int qEndMonth = qi * 3;
            int hires = 0, terminations = 0;
            for (var c : consultants) {
                if (c.startDate() != null && c.startDate().getYear() == year) {
                    int m = c.startDate().getMonthValue();
                    if (m >= qStartMonth && m <= qEndMonth) hires++;
                }
                if (c.endDate() != null && c.endDate().getYear() == year) {
                    int m = c.endDate().getMonthValue();
                    if (m >= qStartMonth && m <= qEndMonth) terminations++;
                }
            }
            int netHires = hires - terminations;
            boolean earned = netHires >= quarterlyTarget;
            int fq = qi;
            jdbi.useHandle(h -> h.createUpdate(
                "INSERT INTO quarterly_bonuses (year, quarter, amount, net_hires, target_hires, earned) VALUES (:y, :q, :a, :nh, :th, :e) " +
                "ON CONFLICT(year, quarter) DO UPDATE SET amount = :a2, net_hires = :nh2, target_hires = :th2, earned = :e2")
                .bind("y", year).bind("q", fq).bind("a", bonusAmount)
                .bind("nh", netHires).bind("th", quarterlyTarget).bind("e", earned ? 1 : 0)
                .bind("a2", bonusAmount).bind("nh2", netHires).bind("th2", quarterlyTarget).bind("e2", earned ? 1 : 0)
                .execute());
        }
    }

    public List<QuarterlyBonus> getQuarterlyBonuses(int year) {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT id, year, quarter, amount, net_hires, target_hires, earned, created_at FROM quarterly_bonuses WHERE year = :y ORDER BY quarter")
             .bind("y", year)
             .mapToMap().list().stream()
             .map(r -> new QuarterlyBonus(
                 ((Number) r.get("id")).intValue(),
                 ((Number) r.get("year")).intValue(),
                 ((Number) r.get("quarter")).intValue(),
                 ((Number) r.get("amount")).doubleValue(),
                 ((Number) r.get("net_hires")).intValue(),
                 ((Number) r.get("target_hires")).intValue(),
                 ((Number) r.get("earned")).intValue() == 1,
                 (String) r.get("created_at")
             )).toList());
    }

    public double getTotalEarned(int year) {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT COALESCE(SUM(amount), 0) FROM quarterly_bonuses WHERE year = :y AND earned = 1")
             .bind("y", year).mapTo(Double.class).one());
    }

    public int getCountEarned(int year) {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT COUNT(*) FROM quarterly_bonuses WHERE year = :y AND earned = 1")
             .bind("y", year).mapTo(Integer.class).one());
    }
}
