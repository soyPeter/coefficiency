package io.bitnomio.coeff.quarterlybonus.domain;

public record QuarterlyBonus(int id, int year, int quarter, double amount, int netHires, int targetHires, boolean earned, String createdAt) {
    public QuarterlyBonus {
        if (quarter < 1 || quarter > 4) throw new IllegalArgumentException("quarter must be 1-4");
        if (amount < 0) throw new IllegalArgumentException("amount must be non-negative");
        if (netHires < 0) throw new IllegalArgumentException("netHires must be non-negative");
        if (targetHires < 0) throw new IllegalArgumentException("targetHires must be non-negative");
    }

    public boolean meetsTarget() { return targetHires > 0 && netHires >= targetHires; }
}
