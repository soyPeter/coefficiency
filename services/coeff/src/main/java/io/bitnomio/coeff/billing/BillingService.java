package io.bitnomio.coeff.billing;

import io.bitnomio.coeff.billing.domain.BillingCalculator;
import io.bitnomio.coeff.billing.domain.MomBillingResponse;
import io.bitnomio.coeff.billing.domain.MomBillingRow;
import io.bitnomio.coeff.quarterlybonus.app.QuarterlyBonusService;
import io.bitnomio.coeff.shared.util.RoundingUtil;
import io.bitnomio.coeff.shared.util.SettingsHelper;
import io.bitnomio.coeff.tenurebonus.app.TenureBonusService;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Singleton
public class BillingService {

    private static final String[] MONTHS = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};

    // Map-key constants (API contract)
    private static final String KEY_DAILY = "daily";
    private static final String KEY_MONTHLY = "monthly";
    private static final String KEY_ANNUAL = "annual";
    private static final String KEY_HIRES = "hires";
    private static final String KEY_TERMINATIONS = "terminations";
    private static final String KEY_NET_CHANGE = "netChange";
    private static final String KEY_ANNUAL_DELTA = "annualDelta";
    private static final String KEY_EXPECTED_HIRES = "expectedHires";
    private static final String KEY_EXPECTED_TERMS = "expectedTerminations";
    private static final String KEY_TOTAL_FEES = "totalFees";
    private static final String KEY_AVG_COEF_PCT = "avgCoefPct";
    private static final String KEY_TOTAL_COEF_MARGIN = "totalCoefMargin";
    private static final String KEY_TOTAL_MANAGER_BONUS = "totalManagerBonus";
    private static final String KEY_COEF_DAYS_MONTH = "coefDaysMonth";
    private static final String KEY_COEF_DAYS_YEAR = "coefDaysYear";
    private static final String KEY_CONSULTANT_COUNT = "consultantCount";
    private static final String KEY_ACTIVE_COUNT = "activeCount";
    private static final String KEY_MONTH = "month";
    private static final String KEY_AVG_COEF = "avgCoef";
    private static final String KEY_TOTAL_BONUS = "totalBonus";
    private static final String KEY_TENURE_BONUSES = "tenureBonuses";
    private static final String KEY_TENURE_BONUS_AMOUNT = "tenureBonusAmount";
    private static final String KEY_TENURE_BONUS_COUNT = "tenureBonusCount";
    private static final String KEY_QUARTERLY_BONUS_AMOUNT = "quarterlyBonusAmount";
    private static final String KEY_QUARTERLY_BONUS_COUNT = "quarterlyBonusCount";
    private static final String KEY_ACTIVE_TARIFFS = "activeTariffs";

    // Settings-key constants
    private static final String SETTING_COEF_DAYS_MONTH = "fiscal.coefDaysMonth";
    private static final String SETTING_COEF_DAYS_YEAR = "fiscal.coefDaysYear";
    private static final String SETTING_ANNUAL_DELTA = "annualDelta";
    private static final String SETTING_TENURE_BONUS_AMOUNT = "fiscal.tenure_bonus_amount";
    private static final String SETTING_TENURE_BONUS_MONTHS = "fiscal.tenure_bonus_months";
    private static final String SETTING_QUARTERLY_BONUS_AMOUNT = "fiscal.quarterly_bonus_amount";

    private final Jdbi jdbi;
    private final TenureBonusService tenureBonusService;
    private final QuarterlyBonusService quarterlyBonusService;

    @Inject
    public BillingService(Jdbi jdbi, TenureBonusService tenureBonusService,
                           QuarterlyBonusService quarterlyBonusService) {
        this.jdbi = jdbi;
        this.tenureBonusService = tenureBonusService;
        this.quarterlyBonusService = quarterlyBonusService;
    }

    public Map<String, Object> summary() {
        return jdbi.withHandle(h -> {
            var daily = h.createQuery("SELECT COALESCE(SUM(tariff),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var cdm = h.createQuery("SELECT COALESCE(value,'21') FROM settings WHERE key='" + SETTING_COEF_DAYS_MONTH + "'").mapTo(String.class).findOne().orElse("21");
            var cdy = h.createQuery("SELECT COALESCE(value,'252') FROM settings WHERE key='" + SETTING_COEF_DAYS_YEAR + "'").mapTo(String.class).findOne().orElse("252");
            var delta = h.createQuery("SELECT COALESCE(value,'0') FROM settings WHERE key='" + SETTING_ANNUAL_DELTA + "'").mapTo(String.class).findOne().orElse("0");
            var hires = h.createQuery("SELECT COUNT(*) FROM consultants WHERE strftime('%Y',start_date)=strftime('%Y','now')").mapTo(Long.class).one();
            var terms = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date IS NOT NULL AND strftime('%Y',end_date)=strftime('%Y','now')").mapTo(Long.class).one();
            var expH = h.createQuery("SELECT COUNT(*) FROM consultants WHERE start_date > date('now')").mapTo(Long.class).one();
            var expT = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date > date('now')").mapTo(Long.class).one();
            var totalFees = h.createQuery("SELECT COALESCE(SUM(fees),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var avgCoef = h.createQuery("SELECT COALESCE(AVG(coef_percentage),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var totalMargin = h.createQuery("SELECT COALESCE(SUM(coef_margin),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var totalBonus = h.createQuery("SELECT COALESCE(SUM(manager_bonus),0) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Double.class).one();
            var count = h.createQuery("SELECT COUNT(*) FROM consultants").mapTo(Long.class).one();
            var activeCount = h.createQuery("SELECT COUNT(*) FROM consultants WHERE end_date IS NULL OR end_date > date('now')").mapTo(Long.class).one();

            int currentYear = LocalDate.now().getYear();
            double tenureAmount = RoundingUtil.round2(tenureBonusService.getTotalTenureBonuses(currentYear));
            int tenureCount = tenureBonusService.getTotalTenureBonusCount(currentYear);
            int deltaVal = Integer.parseInt(delta);
            quarterlyBonusService.calculate(getConsultantRecords(), deltaVal,
                SettingsHelper.readDoubleOrDefault(jdbi, SETTING_QUARTERLY_BONUS_AMOUNT, 500.0), currentYear);
            double quarterlyAmount = RoundingUtil.round2(quarterlyBonusService.getTotalEarned(currentYear));
            int quarterlyCount = quarterlyBonusService.getCountEarned(currentYear);

            var result = new HashMap<String, Object>();
            result.put(KEY_DAILY, daily);
            result.put(KEY_MONTHLY, daily * Double.parseDouble(cdm));
            result.put(KEY_ANNUAL, daily * Double.parseDouble(cdy));
            result.put(KEY_HIRES, hires);
            result.put(KEY_TERMINATIONS, terms);
            result.put(KEY_NET_CHANGE, hires - terms);
            result.put(KEY_ANNUAL_DELTA, (double) deltaVal);
            result.put(KEY_EXPECTED_HIRES, expH);
            result.put(KEY_EXPECTED_TERMS, expT);
            result.put(KEY_TOTAL_FEES, totalFees);
            result.put(KEY_AVG_COEF_PCT, avgCoef);
            result.put(KEY_TOTAL_COEF_MARGIN, totalMargin);
            result.put(KEY_TOTAL_MANAGER_BONUS, totalBonus);
            result.put(KEY_COEF_DAYS_MONTH, Double.parseDouble(cdm));
            result.put(KEY_COEF_DAYS_YEAR, Double.parseDouble(cdy));
            result.put(KEY_CONSULTANT_COUNT, count);
            result.put(KEY_ACTIVE_COUNT, activeCount);
            result.put(KEY_TENURE_BONUS_COUNT, tenureCount);
            result.put(KEY_TENURE_BONUS_AMOUNT, tenureAmount);
            result.put(KEY_QUARTERLY_BONUS_COUNT, quarterlyCount);
            result.put(KEY_QUARTERLY_BONUS_AMOUNT, quarterlyAmount);
            return result;
        });
    }

    public List<Map<String, Object>> monthly() {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
             .mapToMap().list());

        int currentYear = LocalDate.now().getYear();
        int earliestYear = rows.stream()
            .mapToInt(r -> r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")).getYear() : currentYear)
            .min().orElse(currentYear);

        double tbAmount = SettingsHelper.readDoubleOrDefault(jdbi, SETTING_TENURE_BONUS_AMOUNT, 300.0);
        int tenureMonths = SettingsHelper.readIntOrDefault(jdbi, SETTING_TENURE_BONUS_MONTHS, 3);
        var consultantRecords = rows.stream()
            .map(r -> new TenureBonusService.ConsultantRecord(
                ((Number) r.get("id")).intValue(),
                r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")) : null,
                r.get("end_date") != null ? LocalDate.parse((String) r.get("end_date")) : null))
            .toList();
        tenureBonusService.ensureBonusesForConsultants(consultantRecords, tbAmount, tenureMonths);

        int delta = SettingsHelper.readIntOrDefault(jdbi, SETTING_ANNUAL_DELTA, 0);
        double qbAmount = SettingsHelper.readDoubleOrDefault(jdbi, SETTING_QUARTERLY_BONUS_AMOUNT, 500.0);

        var consultants = rows.stream().map(r -> new BillingCalculator.RawConsultant(
            ((Number) r.get("id")).intValue(), (String) r.get("name"), (String) r.get("client"),
            (String) r.get("position"), ((Number) r.get("coef")).doubleValue(),
            ((Number) r.get("tariff")).doubleValue(), (String) r.get("start_date"),
            (String) r.get("end_date"),
            r.get("fees") != null ? ((Number) r.get("fees")).doubleValue() : null,
            r.get("coef_percentage") != null ? ((Number) r.get("coef_percentage")).doubleValue() : null,
            r.get("coef_margin") != null ? ((Number) r.get("coef_margin")).doubleValue() : null,
            r.get("manager_bonus") != null ? ((Number) r.get("manager_bonus")).doubleValue() : null)).toList();

        var months = new ArrayList<Map<String, Object>>();
        for (int year = earliestYear; year <= currentYear; year++) {
            var monthlyBonusCounts = tenureBonusService.getMonthlyBonusCounts(year);
            quarterlyBonusService.calculate(consultantRecords, delta, qbAmount, year);
            var qBonuses = quarterlyBonusService.getQuarterlyBonuses(year);
            Map<Integer, Double> qBonusByMonth = new HashMap<>();
            for (var qb : qBonuses) {
                if (qb.earned()) qBonusByMonth.put(qb.quarter() * 3, qb.amount());
            }

            for (int month = 1; month <= 12; month++) {
                if (year == currentYear && month > LocalDate.now().getMonthValue()) break;
                var monthStart = LocalDate.of(year, month, 1);
                var monthEnd = monthStart.plusMonths(1).minusDays(1);

                int hires = 0, terminations = 0;
                double bonusSum = 0, tariffSum = 0, coefSum = 0;
                int activeCount = 0, coefCount = 0;

                for (var c : consultants) {
                    if (!BillingCalculator.isActiveInRange(c.startDate(), c.endDate(), monthStart, monthEnd)) continue;
                    var sd = c.startDate() != null ? LocalDate.parse(c.startDate()) : null;
                    var ed = c.endDate() != null && !c.endDate().isEmpty() ? LocalDate.parse(c.endDate()) : null;
                    if (sd != null && sd.getYear() == year && sd.getMonthValue() == month) hires++;
                    if (ed != null && ed.getYear() == year && ed.getMonthValue() == month) terminations++;
                    activeCount++;
                    tariffSum += c.tariff();
                    if (c.managerBonus() != null) {
                        boolean eligible = true;
                        if (sd != null && sd.getYear() == year && sd.getMonthValue() == month && sd.getDayOfMonth() > 14) eligible = false;
                        if (eligible && ed != null && ed.getYear() == year && ed.getMonthValue() == month && ed.getDayOfMonth() < 21) eligible = false;
                        if (eligible && month != 8) bonusSum += c.managerBonus();
                    }
                    coefSum += c.coefPercentage() != null ? c.coefPercentage() : 0;
                    if (c.coefPercentage() != null && c.coefPercentage() > 0) coefCount++;
                }

                double avgCoef = activeCount > 0
                    ? Math.round((coefCount > 0 ? coefSum : 0) / activeCount * 10000.0) / 10000.0
                    : 0;
                int tbCount = monthlyBonusCounts.getOrDefault(month, 0);
                double tbAmt = RoundingUtil.round2(tbCount * tbAmount);
                double qbAmt = qBonusByMonth.getOrDefault(month, 0.0);

                var m = new HashMap<String, Object>();
                m.put(KEY_MONTH, MONTHS[month - 1] + " " + year);
                m.put(KEY_HIRES, hires);
                m.put(KEY_TERMINATIONS, terminations);
                m.put(KEY_AVG_COEF, avgCoef);
                m.put(KEY_TOTAL_BONUS, RoundingUtil.round2(bonusSum));
                m.put(KEY_TENURE_BONUSES, tbCount);
                m.put(KEY_TENURE_BONUS_AMOUNT, tbAmt);
                m.put(KEY_QUARTERLY_BONUS_AMOUNT, qbAmt);
                m.put(KEY_ACTIVE_TARIFFS, RoundingUtil.round2(tariffSum));
                months.add(m);
            }
        }
        return months;
    }

    private List<TenureBonusService.ConsultantRecord> getConsultantRecords() {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT id, start_date, end_date FROM consultants")
             .mapToMap().list().stream()
             .map(r -> new TenureBonusService.ConsultantRecord(
                 ((Number) r.get("id")).intValue(),
                 r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")) : null,
                 r.get("end_date") != null ? LocalDate.parse((String) r.get("end_date")) : null))
             .toList());
    }

    // REQ-MOM-CALC-001
    private int readCoefDaysMonth() {
        return SettingsHelper.readIntOrDefault(jdbi, SETTING_COEF_DAYS_MONTH, 21);
    }

    // REQ-MOM-CALC-001, REQ-MOM-CALC-002, REQ-MOM-CALC-003
    private MomBillingRow buildActualMomRow(List<Map<String, Object>> rows, int year, int month, int cm, MomBillingRow prev) {
        var consultants = rows.stream().map(r -> new BillingCalculator.RawConsultant(
            ((Number) r.get("id")).intValue(), (String) r.get("name"), (String) r.get("client"),
            (String) r.get("position"), ((Number) r.get("coef")).doubleValue(),
            ((Number) r.get("tariff")).doubleValue(), (String) r.get("start_date"),
            (String) r.get("end_date"),
            r.get("fees") != null ? ((Number) r.get("fees")).doubleValue() : null,
            r.get("coef_percentage") != null ? ((Number) r.get("coef_percentage")).doubleValue() : null,
            r.get("coef_margin") != null ? ((Number) r.get("coef_margin")).doubleValue() : null,
            r.get("manager_bonus") != null ? ((Number) r.get("manager_bonus")).doubleValue() : null)).toList();

        double dailyBilling = RoundingUtil.round2(BillingCalculator.monthDaily(consultants, year, month));
        double monthlyBilling = RoundingUtil.round2(dailyBilling * cm);
        Double billingDelta = prev != null ? RoundingUtil.round2(monthlyBilling - prev.monthlyBilling()) : null;
        Double momGrowthPct = prev != null && prev.monthlyBilling() != 0
            ? Math.round(((monthlyBilling - prev.monthlyBilling()) / prev.monthlyBilling()) * 1000.0) / 10.0
            : null;
        String label = MONTHS[month - 1] + " " + year;
        return new MomBillingRow(label, dailyBilling, cm, monthlyBilling, billingDelta, momGrowthPct, false);
    }

    // REQ-MOM-CALC-004, REQ-MOM-CALC-005, REQ-MOM-PROJ-001, REQ-MOM-PROJ-002, REQ-MOM-ENDPOINT-002
    public MomBillingResponse getMomBilling(int year) {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
             .mapToMap().list());

        List<MomBillingRow> result = new ArrayList<>();
        MomBillingRow prev = null;
        int cm = readCoefDaysMonth();
        int currentMonth = LocalDate.now().getMonthValue();
        int currentYear = LocalDate.now().getYear();
        boolean isCurrentYear = year == currentYear;

        int maxMonth = isCurrentYear ? currentMonth : 12;
        for (int month = 1; month <= maxMonth; month++) {
            var row = buildActualMomRow(rows, year, month, cm, prev);
            result.add(row);
            prev = row;
        }

        if (isCurrentYear) {
            int lookback = Math.min(3, result.size());
            double[] trail = new double[lookback];
            for (int i = 0; i < lookback; i++) {
                trail[i] = result.get(result.size() - lookback + i).dailyBilling();
            }
            double trailingAvg = BillingCalculator.trailingAvg(trail);
            double avgGrowth = BillingCalculator.avgGrowthRate(trail);

            double projectedDaily = trailingAvg;
            for (int month = currentMonth + 1; month <= 12; month++) {
                projectedDaily *= (1 + avgGrowth);
                projectedDaily = RoundingUtil.round2(projectedDaily);

                double monthlyBilling = RoundingUtil.round2(projectedDaily * cm);
                Double bd = prev != null ? RoundingUtil.round2(monthlyBilling - prev.monthlyBilling()) : null;
                Double mgp = prev != null && prev.monthlyBilling() != 0
                    ? Math.round(((monthlyBilling - prev.monthlyBilling()) / prev.monthlyBilling()) * 1000.0) / 10.0
                    : null;
                String label = MONTHS[month - 1] + " " + year;
                var row = new MomBillingRow(label, projectedDaily, cm, monthlyBilling, bd, mgp, true);
                result.add(row);
                prev = row;
            }
        }

        return new MomBillingResponse(year, result);
    }

    // REQ-MOM-ENDPOINT-003
    public MomBillingResponse getMomBilling() {
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT id, name, client, position, coef, tariff, start_date, end_date, fees, coef_percentage, coef_margin, manager_bonus FROM consultants")
             .mapToMap().list());

        int currentYear = LocalDate.now().getYear();
        int earliestYear = rows.stream()
            .mapToInt(r -> r.get("start_date") != null ? LocalDate.parse((String) r.get("start_date")).getYear() : currentYear)
            .min().orElse(currentYear);

        List<MomBillingRow> allRows = new ArrayList<>();
        MomBillingRow prev = null;
        int cm = readCoefDaysMonth();

        for (int year = earliestYear; year <= currentYear; year++) {
            int maxMonth = year == currentYear ? LocalDate.now().getMonthValue() : 12;
            for (int month = 1; month <= maxMonth; month++) {
                var row = buildActualMomRow(rows, year, month, cm, prev);
                allRows.add(row);
                prev = row;
            }
        }

        return new MomBillingResponse(0, allRows);
    }
}
