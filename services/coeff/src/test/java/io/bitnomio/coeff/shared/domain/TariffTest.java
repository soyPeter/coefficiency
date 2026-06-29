package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TariffTest {
    @Test void wrapsNonNegativeValue() { assertEquals(350.0, new Tariff(350.0).value(), 0.0001); }
    @Test void wrapsZero() { assertEquals(0.0, new Tariff(0.0).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new Tariff(-1.0));
        assertTrue(ex.getMessage().contains("Tariff must be non-negative"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new Tariff(400.0), new Tariff(400.0));
        assertNotEquals(new Tariff(400.0), new Tariff(500.0));
    }
}
