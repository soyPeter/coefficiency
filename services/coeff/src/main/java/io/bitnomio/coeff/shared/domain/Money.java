package io.bitnomio.coeff.shared.domain;

/**
 * Value object for monetary amounts. Wraps a non-negative {@code double}.
 *
 * @param value the monetary amount, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record Money(double value) {
    public Money {
        if (value < 0) throw new IllegalArgumentException("Money must be non-negative: " + value);
    }
}
