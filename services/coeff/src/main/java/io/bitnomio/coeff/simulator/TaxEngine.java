package io.bitnomio.coeff.simulator;

import jakarta.inject.Singleton;

import java.util.List;
import java.util.Map;

/**
 * Spanish income tax (IRPF) and Social Security contribution calculator.
 *
 * <p>Calculates progressive state and regional tax brackets for IRPF, and
 * employee Social Security contributions based on gross salary and category
 * (which determines the contribution base cap).
 *
 * <p><b>IRPF:</b> Progressive brackets with state (19-47%) and regional
 * (9.5-25.5%) rates, applied after deducting personal/family allowances.
 *
 * <p><b>Social Security:</b> Flat employee rate (~12.7%) applied to the
 * monthly gross salary capped by professional category.
 *
 * @since 1.0
 */
@Singleton
public class TaxEngine {

    private static final List<Bracket> STATE_BRACKETS = List.of(
        new Bracket(0, 12450, 0.19),
        new Bracket(12450, 20200, 0.24),
        new Bracket(20200, 35200, 0.30),
        new Bracket(35200, 60000, 0.37),
        new Bracket(60000, 300000, 0.45),
        new Bracket(300000, Double.MAX_VALUE, 0.47)
    );

    private static final List<Bracket> REGIONAL_BRACKETS = List.of(
        new Bracket(0, 12450, 0.095),
        new Bracket(12450, 20200, 0.121),
        new Bracket(20200, 35200, 0.152),
        new Bracket(35200, 60000, 0.189),
        new Bracket(60000, 300000, 0.225),
        new Bracket(300000, Double.MAX_VALUE, 0.255)
    );

    private static final Map<String, Double> SS_BASE_CAPS = Map.of(
        "junior", 4500.0, "semi-senior", 4800.0, "senior", 5300.0, "lead", 5900.0, "manager", 6500.0
    );

    private static final double SS_RATE = 6.35;
    private static final double SS_CONTINGENCIES = 4.7;
    private static final double SS_UNEMPLOYMENT = 1.55;
    private static final double SS_TRAINING = 0.1;

    private static final double PERSONAL_MINIMUM = 5550;
    private static final double CHILD_DEDUCTION = 2400;
    private static final double ASCENDANT_DEDUCTION = 1150;
    private static final double DISABILITY_DEDUCTION = 3000;
    private static final double LIRPF_EXPENSES = 2000;

    public record Bracket(double from, double to, double rate) {}

    /**
     * Family circumstances that reduce taxable income.
     *
     * @param children     number of dependent children
     * @param ascendants   number of dependent ascendants
     * @param disabilities number of dependants with disabilities
     */
    public record FamilyDeductions(int children, int ascendants, int disabilities) {}

    public record IrpfResult(double stateTax, double regionalTax, double totalIrpf, double taxableIncome) {}

    public record SsResult(double employeeSs, double totalRate, double applicableBase) {}

    /**
     * Calculates total IRPF (state + regional) after applying personal and
     * family deductions to the gross annual salary.
     *
     * @param grossSalary gross annual salary in EUR
     * @param deductions  family circumstances
     * @return IRPF breakdown
     */
    public IrpfResult calculateIrpf(double grossSalary, FamilyDeductions deductions) {
        var ded = deductions.children() * CHILD_DEDUCTION
                + deductions.ascendants() * ASCENDANT_DEDUCTION
                + deductions.disabilities() * DISABILITY_DEDUCTION
                + PERSONAL_MINIMUM + LIRPF_EXPENSES;
        var taxable = Math.max(0, grossSalary - ded);
        var stateTax = applyBrackets(taxable, STATE_BRACKETS);
        var regionalTax = applyBrackets(taxable, REGIONAL_BRACKETS);
        return new IrpfResult(stateTax, regionalTax, stateTax + regionalTax, taxable);
    }

    /**
     * Calculates monthly employee Social Security contribution.
     * The contribution base is capped by professional category.
     *
     * @param grossSalary gross annual salary in EUR
     * @param category    professional category (junior, senior, etc.)
     * @return SS breakdown
     */
    public SsResult calculateSs(double grossSalary, String category) {
        var baseCap = SS_BASE_CAPS.getOrDefault(category.toLowerCase(), 5300.0);
        var applicableBase = Math.min(grossSalary / 12, baseCap);
        var totalRate = SS_RATE + SS_CONTINGENCIES + SS_UNEMPLOYMENT + SS_TRAINING;
        var employeeSs = applicableBase * totalRate / 100;
        return new SsResult(employeeSs, totalRate, applicableBase);
    }

    private double applyBrackets(double income, List<Bracket> brackets) {
        var tax = 0.0;
        for (var b : brackets) {
            if (income <= b.from()) break;
            var taxable = Math.min(income, b.to()) - b.from();
            tax += taxable * b.rate();
        }
        return tax;
    }
}
