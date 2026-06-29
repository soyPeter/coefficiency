package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TaxRateTest {
    @Test void wrapsZero() { assertEquals(0.0, new TaxRate(0.0).value(), 0.0001); }
    @Test void wrapsOne() { assertEquals(1.0, new TaxRate(1.0).value(), 0.0001); }
    @Test void wrapsMidRange() { assertEquals(0.25, new TaxRate(0.25).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new TaxRate(-0.01));
        assertTrue(ex.getMessage().contains("TaxRate must be between 0 and 1"));
    }
    @Test void rejectsAboveOne() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new TaxRate(1.01));
        assertTrue(ex.getMessage().contains("TaxRate must be between 0 and 1"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new TaxRate(0.2), new TaxRate(0.2));
        assertNotEquals(new TaxRate(0.2), new TaxRate(0.3));
    }
}
