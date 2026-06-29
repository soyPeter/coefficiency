package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a tax rate. Wraps a {@code double} in {@code [0, 1]}.
 *
 * @param value the tax rate, must be {@code 0 <= value <= 1}
 * @throws IllegalArgumentException if {@code value < 0} or {@code value > 1}
 */
public record TaxRate(double value) {
    public TaxRate {
        if (value < 0 || value > 1) throw new IllegalArgumentException("TaxRate must be between 0 and 1: " + value);
    }
}
