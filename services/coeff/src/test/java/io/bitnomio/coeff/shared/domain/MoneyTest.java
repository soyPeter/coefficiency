package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class MoneyTest {

    @Test
    void wrapsNonNegativeValue() {
        var m = new Money(100.0);
        assertEquals(100.0, m.value(), 0.0001);
    }

    @Test
    void wrapsZero() {
        var m = new Money(0.0);
        assertEquals(0.0, m.value(), 0.0001);
    }

    @Test
    void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new Money(-1.0));
        assertTrue(ex.getMessage().contains("Money must be non-negative"));
    }

    @Test
    void equalsAndHashCode() {
        var a = new Money(50.0);
        var b = new Money(50.0);
        var c = new Money(100.0);
        assertEquals(a, b);
        assertEquals(a.hashCode(), b.hashCode());
        assertNotEquals(a, c);
    }

    @Test
    void toStringContainsValue() {
        var m = new Money(42.5);
        assertTrue(m.toString().contains("42.5"));
    }
}
