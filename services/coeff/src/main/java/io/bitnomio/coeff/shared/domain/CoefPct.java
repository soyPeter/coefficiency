package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a coefficient percentage. Wraps a non-negative {@code double}.
 *
 * @param value the coefficient percentage, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record CoefPct(double value) {
    public CoefPct {
        if (value < 0) throw new IllegalArgumentException("CoefPct must be non-negative: " + value);
    }
}
