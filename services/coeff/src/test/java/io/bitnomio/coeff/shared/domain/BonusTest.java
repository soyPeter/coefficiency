package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class BonusTest {
    @Test void wrapsNonNegativeValue() { assertEquals(5000.0, new Bonus(5000.0).value(), 0.0001); }
    @Test void wrapsZero() { assertEquals(0.0, new Bonus(0.0).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new Bonus(-100.0));
        assertTrue(ex.getMessage().contains("Bonus must be non-negative"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new Bonus(2000.0), new Bonus(2000.0));
        assertNotEquals(new Bonus(2000.0), new Bonus(3000.0));
    }
}
