package io.bitnomio.coeff.shared.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class SalaryTest {
    @Test void wrapsNonNegativeValue() { assertEquals(30000.0, new Salary(30000.0).value(), 0.0001); }
    @Test void wrapsZero() { assertEquals(0.0, new Salary(0.0).value(), 0.0001); }
    @Test void rejectsNegativeValue() {
        var ex = assertThrows(IllegalArgumentException.class, () -> new Salary(-1.0));
        assertTrue(ex.getMessage().contains("Salary must be non-negative"));
    }
    @Test void equalsAndHashCode() {
        assertEquals(new Salary(50000.0), new Salary(50000.0));
        assertNotEquals(new Salary(50000.0), new Salary(60000.0));
    }
}
