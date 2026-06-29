package io.bitnomio.coeff.billing.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class MomBillingRowTest {

    @Test
    void constructsWithValidValues() {
        var row = new MomBillingRow("Ene 2025", 1000.0, 21, 21000.0, null, null, false);
        assertEquals("Ene 2025", row.month());
        assertEquals(1000.0, row.dailyBilling(), 0.0001);
        assertEquals(21, row.workingDays());
        assertEquals(21000.0, row.monthlyBilling(), 0.0001);
        assertNull(row.billingDelta());
        assertNull(row.momGrowthPct());
        assertFalse(row.projected());
    }

    @Test
    void constructsWithNullBillingDelta() {
        var row = new MomBillingRow("Feb 2025", 1100.0, 21, 23100.0, null, null, false);
        assertNull(row.billingDelta());
        assertNull(row.momGrowthPct());
    }

    @Test
    void constructsWithBillingDeltaAndGrowth() {
        var row = new MomBillingRow("Feb 2025", 1100.0, 21, 23100.0, 2100.0, 10.0, false);
        assertEquals(2100.0, row.billingDelta(), 0.0001);
        assertEquals(10.0, row.momGrowthPct(), 0.0001);
    }

    @Test
    void rejectsNegativeWorkingDays() {
        var ex = assertThrows(IllegalArgumentException.class,
            () -> new MomBillingRow("Ene 2025", 1000.0, -1, 21000.0, null, null, false));
        assertTrue(ex.getMessage().contains("non-negative"));
    }

    @Test
    void allowsZeroWorkingDays() {
        var row = new MomBillingRow("Ene 2025", 0.0, 0, 0.0, null, null, true);
        assertEquals(0, row.workingDays());
        assertTrue(row.projected());
    }
}
