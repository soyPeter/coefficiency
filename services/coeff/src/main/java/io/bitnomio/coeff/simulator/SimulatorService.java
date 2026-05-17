package io.bitnomio.coeff.simulator;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.Map;

/**
 * Orchestrates the COEF simulator: loads defaults from DB, runs tax + cost
 * calculations, and returns profitability metrics for a consultant scenario.
 *
 * <p>The simulator takes a daily rate, gross salary, category, fixed costs,
 * benefits, and family deductions, then computes:
 * <ul>
 *   <li>Gross/net monthly/annual totals</li>
 *   <li>IRPF and Social Security contributions</li>
 *   <li>COEF percentage and margin</li>
 *   <li>Manager bonus (5% of monthly margin)</li>
 * </ul>
 *
 * @since 1.0
 * @see TaxEngine
 * @see SimulatorInput
 * @see SimulatorResult
 */
@Singleton
public class SimulatorService {

    private static final double COEF_MULTIPLIER = 1.7;
    private static final double MNG_BONUS_PCT = 0.05;
    private static final int COEF_DAYS_MONTH = 21;
    private static final int COEF_DAYS_YEAR = 252;

    private final Jdbi jdbi;
    private final TaxEngine taxEngine;

    @Inject
    public SimulatorService(Jdbi jdbi, TaxEngine taxEngine) {
        this.jdbi = jdbi;
        this.taxEngine = taxEngine;
    }

    /**
     * Returns simulator defaults: working-day constants, professional categories,
     * and available cost concepts from the database.
     */
    public Map<String, Object> defaults() {
        var concepts = jdbi.withHandle(h -> h.createQuery("SELECT * FROM cost_concepts ORDER BY name").mapToMap().list());
        return Map.of(
            "coefDaysMonth", COEF_DAYS_MONTH,
            "coefDaysYear", COEF_DAYS_YEAR,
            "categories", new String[]{"junior", "semi-senior", "senior", "lead", "manager"},
            "concepts", concepts
        );
    }

    /**
     * Runs the full simulation: computes IRPF, Social Security, total consultant
     * cost, annual fees, COEF percentage, monthly margin, and manager bonus.
     *
     * @param input simulation parameters
     * @return detailed result with breakdown
     */
    public SimulatorResult calculate(SimulatorInput input) {
        var annualFees = input.dailyRate() * COEF_DAYS_YEAR;
        var grossSalary = input.salary();

        var irpf = taxEngine.calculateIrpf(grossSalary, input.deductions());
        var ss = taxEngine.calculateSs(grossSalary, input.category());

        var totalCost = (grossSalary * COEF_MULTIPLIER)
                + (input.benefits() * COEF_MULTIPLIER)
                + input.fixedCosts()
                + ss.employeeSs()
                + irpf.totalIrpf();

        var annualMargin = annualFees - totalCost;
        var monthlyMargin = annualMargin / COEF_DAYS_YEAR * COEF_DAYS_MONTH;
        var monthlyFees = annualFees / COEF_DAYS_YEAR * COEF_DAYS_MONTH;
        var coefPct = monthlyFees > 0 ? monthlyMargin / monthlyFees : 0;
        var managerBonus = monthlyMargin * MNG_BONUS_PCT;

        return new SimulatorResult(
            coefPct, monthlyMargin, monthlyFees, managerBonus,
            new SimulatorResult.Breakdown(grossSalary, irpf.totalIrpf(), ss.employeeSs(), totalCost, annualFees)
        );
    }
}
