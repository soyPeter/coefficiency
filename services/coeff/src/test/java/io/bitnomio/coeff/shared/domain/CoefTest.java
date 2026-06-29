package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CoefTest {
    @Test void wrapsNonNegativeValue() { assertEquals(1.5, new Coef(1.5).value(), 0.0001); }
    @Test void wrapsZero() { assertEquals(0.0, new Coef(0.0).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new Coef(-0.1));
        assertTrue(ex.getMessage().contains("Coef must be non-negative"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new Coef(1.0), new Coef(1.0));
        assertNotEquals(new Coef(1.0), new Coef(2.0));
    }
}
