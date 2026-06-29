package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CoefPctTest {
    @Test void wrapsNonNegativeValue() { assertEquals(0.75, new CoefPct(0.75).value(), 0.0001); }
    @Test void wrapsZero() { assertEquals(0.0, new CoefPct(0.0).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new CoefPct(-0.01));
        assertTrue(ex.getMessage().contains("CoefPct must be non-negative"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new CoefPct(0.5), new CoefPct(0.5));
        assertNotEquals(new CoefPct(0.5), new CoefPct(0.6));
    }
}
