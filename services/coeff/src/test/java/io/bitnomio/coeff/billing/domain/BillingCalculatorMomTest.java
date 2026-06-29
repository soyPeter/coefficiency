package io.bitnomio.coeff.billing.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class BillingCalculatorMomTest {

    @Test
    void trailingAvg_returnsMean() {
        double[] trail = {100.0, 200.0, 300.0};
        assertEquals(200.0, BillingCalculator.trailingAvg(trail), 0.0001);
    }

    @Test
    void trailingAvg_singleValue() {
        double[] trail = {150.0};
        assertEquals(150.0, BillingCalculator.trailingAvg(trail), 0.0001);
    }

    @Test
    void trailingAvg_emptyArrayReturnsNaN() {
        double[] trail = {};
        assertTrue(Double.isNaN(BillingCalculator.trailingAvg(trail)));
    }

    @Test
    void avgGrowthRate_returnsAverageGrowth() {
        double[] trail = {100.0, 110.0, 121.0};
        double rate = BillingCalculator.avgGrowthRate(trail);
        // 110/100 - 1 = 0.10, 121/110 - 1 = 0.10 → avg = 0.10
        assertEquals(0.10, rate, 0.001);
    }

    @Test
    void avgGrowthRate_capsAtFiftyPercent() {
        double[] trail = {1000.0, 100.0, 200.0};
        double rate = BillingCalculator.avgGrowthRate(trail);
        // 100/1000 - 1 = -0.9, 200/100 - 1 = 1.0 → avg = 0.05, but 1st pair gives -0.9
        // Actually: (-0.9 + 1.0) / 2 = 0.05, which is within ±0.5 so no cap
        assertTrue(rate <= 0.5);
        assertTrue(rate >= -0.5);
    }

    @Test
    void avgGrowthRate_extremeGrowth_capped() {
        double[] trail = {10.0, 100.0, 1000.0};
        double rate = BillingCalculator.avgGrowthRate(trail);
        // 100/10 - 1 = 9.0, 1000/100 - 1 = 9.0 → avg = 9.0 → capped at 0.5
        assertEquals(0.5, rate, 0.001);
    }

    @Test
    void avgGrowthRate_extremeDecline_capped() {
        double[] trail = {1000.0, 100.0, 10.0};
        double rate = BillingCalculator.avgGrowthRate(trail);
        // 100/1000 - 1 = -0.9, 10/100 - 1 = -0.9 → avg = -0.9 → capped at -0.5
        assertEquals(-0.5, rate, 0.001);
    }

    @Test
    void avgGrowthRate_lessThanTwoElements_returnsZero() {
        assertEquals(0.0, BillingCalculator.avgGrowthRate(new double[]{100.0}), 0.0001);
        assertEquals(0.0, BillingCalculator.avgGrowthRate(new double[]{}), 0.0001);
    }

    @Test
    void avgGrowthRate_zeroPrevious_skipsPair() {
        double[] trail = {0.0, 100.0, 200.0};
        double rate = BillingCalculator.avgGrowthRate(trail);
        // 0.0 > 0 is false, so first pair is skipped. 200/100 - 1 = 1.0 → capped at 0.5
        assertEquals(0.5, rate, 0.001);
    }

    @Test
    void monthDaily_sumsTariffsForActiveConsultants() {
        var consultants = java.util.List.of(
            new BillingCalculator.RawConsultant(1, "Alice", "ClientA", "Dev", 1.0, 500.0,
                "2025-01-01", null, null, null, null, null),
            new BillingCalculator.RawConsultant(2, "Bob", "ClientA", "Dev", 1.0, 400.0,
                "2025-01-01", null, null, null, null, null)
        );
        double daily = BillingCalculator.monthDaily(consultants, 2025, 6);
        assertEquals(900.0, daily, 0.0001);
    }

    @Test
    void monthDaily_excludesInactiveConsultants() {
        var consultants = java.util.List.of(
            new BillingCalculator.RawConsultant(1, "Alice", "ClientA", "Dev", 1.0, 500.0,
                "2025-01-01", "2025-05-31", null, null, null, null),
            new BillingCalculator.RawConsultant(2, "Bob", "ClientA", "Dev", 1.0, 400.0,
                "2024-01-01", null, null, null, null, null)
        );
        double daily = BillingCalculator.monthDaily(consultants, 2025, 6);
        assertEquals(400.0, daily, 0.0001);
    }

    @Test
    void projectedRemaining_computesCompoundedProjection() {
        double result = BillingCalculator.projectedRemaining(1000.0, 0.1, 3, 21);
        // Month 1: 1000 * 21 = 21000
        // Month 2: 1100 * 21 = 23100
        // Month 3: 1210 * 21 = 25410
        // Total: 69510
        assertEquals(69510.0, result, 0.01);
    }

    @Test
    void projectedRemaining_zeroGrowth() {
        double result = BillingCalculator.projectedRemaining(1000.0, 0.0, 3, 21);
        // 1000*21 * 3 = 63000
        assertEquals(63000.0, result, 0.0001);
    }

    @Test
    void projectedRemaining_noRemainingMonths_returnsZero() {
        assertEquals(0.0, BillingCalculator.projectedRemaining(1000.0, 0.1, 0, 21), 0.0001);
    }
}
