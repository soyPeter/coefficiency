package io.bitnomio.coeff.tenurebonus.domain;

public record TenureBonus(int id, int consultantId, double amount, String paidMonth, String createdAt) {
    public TenureBonus {
        if (amount < 0) throw new IllegalArgumentException("amount must be non-negative");
    }
}
