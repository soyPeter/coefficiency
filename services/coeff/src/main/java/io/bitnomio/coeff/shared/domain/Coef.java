package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a consultant's coefficient. Wraps a non-negative {@code double}.
 *
 * @param value the coefficient, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record Coef(double value) {
    public Coef {
        if (value < 0) throw new IllegalArgumentException("Coef must be non-negative: " + value);
    }
}
