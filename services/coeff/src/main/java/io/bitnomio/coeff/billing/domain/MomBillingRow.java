package io.bitnomio.coeff.billing.domain;

// REQ-MOM-DOMAIN-001, REQ-MOM-DOMAIN-003
public record MomBillingRow(
    String month,
    double dailyBilling,
    int workingDays,
    double monthlyBilling,
    Double billingDelta,
    Double momGrowthPct,
    boolean projected
) {
    public MomBillingRow {
        if (workingDays < 0) throw new IllegalArgumentException("workingDays must be non-negative");
    }
}
