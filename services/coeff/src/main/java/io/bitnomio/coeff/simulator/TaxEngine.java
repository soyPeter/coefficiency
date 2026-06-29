package io.bitnomio.coeff.simulator;

import io.bitnomio.coeff.shared.util.RoundingUtil;

import java.util.List;

public class TaxEngine {

    public record TaxBracket(double from, double to, double rate) {}

    public record TaxResult(double total, double rate) {}

    public record SSResult(double annual, double monthly, double rate) {}

    public record SsCategory(String category, double baseMin, double baseMax, double rate) {}

    public record FamilyResult(
        double base,
        double spouse,
        double descendants,
        double ascendants,
        double disability,
        double total
    ) {}

    public record Config(
        double personalMinimum,
        double deductionChild,
        double deductionAsc,
        double deductionDis,
        double deductionSpouse,
        double ssRate
    ) {}

    private final List<TaxBracket> brackets;
    private final List<TaxBracket> regionalBrackets;
    private final List<SsCategory> ssCategories;
    private final Config config;

    public TaxEngine(List<TaxBracket> brackets, Config config) {
        this(brackets, null, null, config);
    }

    public TaxEngine(List<TaxBracket> brackets, List<TaxBracket> regionalBrackets, Config config) {
        this(brackets, regionalBrackets, null, config);
    }

    public TaxEngine(List<TaxBracket> brackets, List<TaxBracket> regionalBrackets,
                     List<SsCategory> ssCategories, Config config) {
        this.brackets = brackets;
        this.regionalBrackets = regionalBrackets != null && !regionalBrackets.isEmpty() ? regionalBrackets : brackets;
        this.ssCategories = ssCategories != null ? ssCategories : List.of();
        this.config = config;
    }

    public TaxResult calculateIRPF(double baseAnual, double grossAnual, FamilyResult family) {
        double baseForBrackets = Math.max(0, baseAnual - (family.total() - family.base()));

        double estatal = 0;
        double remaining = baseForBrackets;
        for (TaxBracket bracket : brackets) {
            if (remaining <= 0) break;
            double taxable = Math.min(remaining, bracket.to() - bracket.from());
            estatal += taxable * bracket.rate();
            remaining -= taxable;
        }

        double regional = 0;
        remaining = baseForBrackets;
        for (TaxBracket bracket : regionalBrackets) {
            if (remaining <= 0) break;
            double taxable = Math.min(remaining, bracket.to() - bracket.from());
            regional += taxable * bracket.rate();
            remaining -= taxable;
        }

        double total = estatal + regional;

        double lowestRate = brackets.isEmpty() ? 0 : brackets.get(0).rate();
        total -= family.base() * lowestRate * 2;

        total = Math.max(0, RoundingUtil.round2(total));
        double tasaEfectiva = grossAnual > 0 ? total / grossAnual : 0;
        return new TaxResult(total, RoundingUtil.round4(tasaEfectiva));
    }

    public SSResult calculateSS(double grossAnnualSalary, String category) {
        double rate = config.ssRate();
        double capped = grossAnnualSalary;
        if (category != null && !ssCategories.isEmpty()) {
            for (SsCategory sc : ssCategories) {
                if (sc.category().equals(category)) {
                    double monthlySalary = grossAnnualSalary / 12.0;
                    double cappedMonthly = Math.max(sc.baseMin(), Math.min(monthlySalary, sc.baseMax()));
                    capped = RoundingUtil.round2(cappedMonthly * 12.0);
                    rate = sc.rate();
                    break;
                }
            }
        }
        double annual = RoundingUtil.round2(capped * rate);
        double monthly = RoundingUtil.round2(annual / 12.0);
        return new SSResult(annual, monthly, rate);
    }

    public SSResult calculateSS(double grossAnnualSalary) {
        return calculateSS(grossAnnualSalary, null);
    }

    public FamilyResult calculateFamilyDeductions(int children, int ascendants, int disability, String familySituation) {
        boolean married = "married".equals(familySituation);
        return calculateFamilyDeductions(children, ascendants, disability, married);
    }

    public FamilyResult calculateFamilyDeductions(int children, int ascendants, int disability, boolean married) {
        double spouse = married ? config.deductionSpouse() : 0;
        double descendants = children * config.deductionChild();
        double asc = ascendants * config.deductionAsc();
        double dis = disability * config.deductionDis();
        double total = config.personalMinimum() + spouse + descendants + asc + dis;
        return new FamilyResult(config.personalMinimum(), spouse, descendants, asc, dis, total);
    }

    public FamilyResult calculateFamilyDeductions(int children, int ascendants, int disability) {
        return calculateFamilyDeductions(children, ascendants, disability, false);
    }

    public static final List<String> CATEGORIES = List.of(
        "Ingenieros y Licenciados",
        "Ingenieros Técnicos, Peritos y Ayudantes Titulados",
        "Jefes Administrativos y de taller",
        "Ayudantes no Titulados",
        "Oficiales Administrativos",
        "Subalternos",
        "Auxiliares Administrativos"
    );

    public static final List<String> BONUS_SCHEDULES = List.of(
        "Trimestral (Mar/Jun/Set/Dic)",
        "Semestral (Jun/Dic)",
        "Anual (Dic)"
    );
}
