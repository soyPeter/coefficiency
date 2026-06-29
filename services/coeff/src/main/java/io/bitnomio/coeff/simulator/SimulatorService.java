package io.bitnomio.coeff.simulator;

import io.bitnomio.coeff.shared.util.RoundingUtil;
import jakarta.inject.Singleton;

import java.util.List;

@Singleton
public class SimulatorService {

    private static double nvl(Double v) { return v != null ? v : 0.0; }
    private static int nvli(Integer v) { return v != null ? v : 0; }
    private static boolean nvlb(Boolean v) { return v != null && v; }

    public record CoefConfig(
        double coefMultiplier,
        double mngBonusPct,
        int seguroMonths,
        int mealCardDays,
        int coefDaysMonth,
        int coefDaysYear
    ) {}

    public SimulatorResult calculate(SimulatorInput input, TaxEngine engine, double lirpfExpenses,
                                     CoefConfig coefConfig) {
        double fees = nvl(input.fees());
        double grossAnnualSalary = nvl(input.grossAnnualSalary());
        double grossMonthlySalary = grossAnnualSalary / 12.0;

        double dailyMealCard = nvl(input.dailyMealCard());
        double annualBonus = nvl(input.annualPerformanceBonus());
        double annualChildSupport = nvl(input.annualChildSupport());
        double annualTraining = nvl(input.annualTraining());
        boolean hasLaptop = nvlb(input.hasLaptop());
        double monthlyLaptop = nvl(input.monthlyLaptop());
        boolean hasHealthInsurance = nvlb(input.hasHealthInsurance());
        double monthlyHealthInsurance = nvl(input.monthlyHealthInsurance());
        double monthlyExtraIT = nvl(input.monthlyExtraIT());
        double monthlyLicenses = nvl(input.monthlyLicenses());
        double otherCosts = nvl(input.otherCosts());
        int children = nvli(input.children());
        int ascendants = nvli(input.ascendants());
        int disability = nvli(input.disability());
        String familySituation = input.familySituation() != null ? input.familySituation() : (nvlb(input.married()) ? "married" : "single");
        String category = input.category();
        double otherIncomeIRPF = nvl(input.otherIncomeIRPF());
        double otherIncomeSS = nvl(input.otherIncomeSS());

        double mult = coefConfig.coefMultiplier();
        int cm = coefConfig.coefDaysMonth();
        int cy = coefConfig.coefDaysYear();

        double annualFees = (fees / cm) * cy;

        double totalAnnualCost =
            grossAnnualSalary * mult
            + dailyMealCard * cy * mult
            + annualBonus * mult
            + annualChildSupport * mult
            + annualTraining
            + (hasLaptop ? monthlyLaptop * 12 : 0)
            + (hasHealthInsurance ? monthlyHealthInsurance * coefConfig.seguroMonths() : 0)
            + monthlyExtraIT * 12
            + monthlyLicenses * 12
            + otherCosts;

        double annualMargin = annualFees - totalAnnualCost;
        double coefMargin = RoundingUtil.round2((annualMargin / cy * cm));
        double coef = fees > 0 ? RoundingUtil.round4((coefMargin / fees)) : 0;
        double managerBonus = RoundingUtil.round2(coefMargin * coefConfig.mngBonusPct());
        double totalConsultantCost = RoundingUtil.round2((fees - coefMargin));

        TaxEngine.FamilyResult family = engine.calculateFamilyDeductions(children, ascendants, disability, familySituation);
        double ssBase = grossAnnualSalary + otherIncomeSS;
        TaxEngine.SSResult ss = engine.calculateSS(ssBase, category);

        double irpfBase = grossAnnualSalary + otherIncomeIRPF - ss.annual() - lirpfExpenses;
        TaxEngine.TaxResult irpf = engine.calculateIRPF(irpfBase, grossAnnualSalary, family);

        double monthlyIrpf = RoundingUtil.round2(irpf.total() / 12.0);
        double monthlySs = ss.monthly();
        double netMonthly = RoundingUtil.round2((grossMonthlySalary - monthlyIrpf - monthlySs));
        double netAnnual = RoundingUtil.round2(netMonthly * 12.0);

        double grossMonthlySalaryRounded = RoundingUtil.round2(grossMonthlySalary);

        List<SimulatorResult.MonthlyRow> projection = buildMonthlyProjection(
            grossAnnualSalary, dailyMealCard, annualBonus, annualChildSupport,
            annualTraining, cy, ss, irpf, mult, coefConfig);

        return new SimulatorResult(
            grossMonthlySalaryRounded, netMonthly, netAnnual,
            monthlySs, monthlyIrpf, irpf.rate(), ss.rate(),
            totalConsultantCost, coef, coefMargin, managerBonus, projection
        );
    }

    private List<SimulatorResult.MonthlyRow> buildMonthlyProjection(
            double grossAnnualSalary, double dailyMealCard, double annualBonus,
            double annualChildSupport, double annualTraining, int cy,
            TaxEngine.SSResult ss, TaxEngine.TaxResult irpf,
            double mult, CoefConfig coefConfig) {
        double grossMonthly = RoundingUtil.round2(grossAnnualSalary / 12.0);
        double monthlyMeal = RoundingUtil.round2(dailyMealCard * coefConfig.mealCardDays());
        double monthlyBonus = RoundingUtil.round2(annualBonus / 12.0);
        double monthlyChild = RoundingUtil.round2(annualChildSupport / 12.0);
        double monthlyTraining = RoundingUtil.round2(annualTraining / 12.0);
        double monthlySs = ss.monthly();
        double monthlyIrpfAmt = RoundingUtil.round2(irpf.total() / 12.0);

        String[] monthNames = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
        var rows = new java.util.ArrayList<SimulatorResult.MonthlyRow>();
        for (int i = 0; i < 12; i++) {
            double gross = grossMonthly + monthlyMeal * mult + monthlyBonus * mult
                         + monthlyChild * mult + monthlyTraining;
            double neto = RoundingUtil.round2(grossMonthly - monthlySs - monthlyIrpfAmt);
            rows.add(new SimulatorResult.MonthlyRow(
                monthNames[i], null, gross, monthlyMeal, monthlyChild,
                monthlyBonus, monthlyTraining, monthlySs, monthlyIrpfAmt, neto
            ));
        }
        return rows;
    }
}
