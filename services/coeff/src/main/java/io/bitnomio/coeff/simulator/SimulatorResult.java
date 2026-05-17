package io.bitnomio.coeff.simulator;

public record SimulatorResult(
    double coefPercentage,
    double monthlyMargin,
    double monthlyFees,
    double managerBonus,
    Breakdown breakdown
) {
    public record Breakdown(
        double salary,
        double irpf,
        double socialSecurity,
        double totalCost,
        double annualFees
    ) {}
}
