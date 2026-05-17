package io.bitnomio.coeff.billing;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Aggregates billing and profitability data from the consultants database.
 *
 * <p>The {@link #summary()} method returns a single snapshot with daily/monthly/
 * annual billing totals, COEF averages, hire/termination counts, and expected
 * changes. The {@link #monthly()} method breaks down hires, terminations, COEF,
 * and bonuses per calendar month.
 *
 * @since 1.0
 */
@Singleton
public class BillingService {

    private final Jdbi jdbi;

    @Inject
    public BillingService(Jdbi jdbi) { this.jdbi = jdbi; }

    /**
     * Returns a single aggregate snapshot of all active consultants.
     *
     * <p>Active consultants are those without an end date or whose end date
     * is in the future. Fields include billing totals (daily/monthly/annual),
     * COEF aggregates, hire/termination counts for the current year, and
     * expected near-term changes.
     *
     * @return map with all billing summary fields
     */
    public Map<String, Object> summary() {
        return jdbi.withHandle(h -> {
            var daily = h.createQuery("SELECT COALESCE(SUM(tariff),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var cdm = h.createQuery("SELECT COALESCE(value,'21') FROM settings WHERE key='fiscal.coefDaysMonth'").mapTo(String.class).findOne().orElse("21");
            var cdy = h.createQuery("SELECT COALESCE(value,'252') FROM settings WHERE key='fiscal.coefDaysYear'").mapTo(String.class).findOne().orElse("252");
            var delta = h.createQuery("SELECT COALESCE(value,'0') FROM settings WHERE key='annualDelta'").mapTo(String.class).findOne().orElse("0");
            var hires = h.createQuery("SELECT COUNT(*) FROM consultants WHERE strftime('%Y',start_date)=strftime('%Y','now')").mapTo(Long.class).one();
            var terms = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date IS NOT NULL AND strftime('%Y',end_date)=strftime('%Y','now')").mapTo(Long.class).one();
            var expH = h.createQuery("SELECT COUNT(*) FROM consultants WHERE start_date > date('now')").mapTo(Long.class).one();
            var expT = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date > date('now')").mapTo(Long.class).one();
            var totalFees = h.createQuery("SELECT COALESCE(SUM(fees),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var avgCoef = h.createQuery("SELECT COALESCE(AVG(coef_percentage),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var totalMargin = h.createQuery("SELECT COALESCE(SUM(coef_margin),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var totalBonus = h.createQuery("SELECT COALESCE(SUM(manager_bonus),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var count = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Long.class).one();
            var result = new HashMap<String, Object>();
            result.put("daily", daily);
            result.put("monthly", daily * Double.parseDouble(cdm));
            result.put("annual", daily * Double.parseDouble(cdy));
            result.put("hires", hires);
            result.put("terminations", terms);
            result.put("netChange", hires - terms);
            result.put("annualDelta", Double.parseDouble(delta));
            result.put("expectedHires", expH);
            result.put("expectedTerminations", expT);
            result.put("totalFees", totalFees);
            result.put("avgCoefPct", avgCoef);
            result.put("totalCoefMargin", totalMargin);
            result.put("totalManagerBonus", totalBonus);
            result.put("coefDaysMonth", Double.parseDouble(cdm));
            result.put("coefDaysYear", Double.parseDouble(cdy));
            result.put("consultantCount", count);
            return result;
        });
    }

    /**
     * Returns monthly breakdown of hires, terminations (currently static 0),
     * average COEF, and total manager bonuses, grouped by calendar month.
     *
     * @return list of month snapshots ordered chronologically
     */
    public List<Map<String, Object>> monthly() {
        return jdbi.withHandle(h -> h.createQuery(
            "SELECT strftime('%Y-%m',start_date) as month, COUNT(*) as hires, 0 as terminations, COALESCE(AVG(coef_percentage),0) as avgCoef, COALESCE(SUM(manager_bonus),0) as totalBonus FROM consultants WHERE start_date IS NOT NULL GROUP BY strftime('%Y-%m',start_date) ORDER BY month")
            .mapToMap().list());
    }
}
