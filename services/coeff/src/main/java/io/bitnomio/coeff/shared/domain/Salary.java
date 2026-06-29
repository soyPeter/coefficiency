package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a salary amount. Wraps a non-negative {@code double}.
 *
 * @param value the salary amount, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record Salary(double value) {
    public Salary {
        if (value < 0) throw new IllegalArgumentException("Salary must be non-negative: " + value);
    }
}
