package io.bitnomio.coeff.shared.domain;

/**
 * Value object for a bonus amount. Wraps a non-negative {@code double}.
 *
 * @param value the bonus amount, must be {@code >= 0}
 * @throws IllegalArgumentException if {@code value < 0}
 */
public record Bonus(double value) {
    public Bonus {
        if (value < 0) throw new IllegalArgumentException("Bonus must be non-negative: " + value);
    }
}
