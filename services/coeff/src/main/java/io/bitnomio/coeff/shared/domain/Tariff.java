package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a daily tariff. Wraps a non-negative {@code double}.
 *
 * @param value the daily tariff, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record Tariff(double value) {
    public Tariff {
        if (value < 0) throw new IllegalArgumentException("Tariff must be non-negative: " + value);
    }
}
