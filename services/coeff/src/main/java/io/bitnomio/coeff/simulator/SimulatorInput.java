package io.bitnomio.coeff.simulator;

public record SimulatorInput(
    double salary,
    double dailyRate,
    String category,
    int age,
    double fixedCosts,
    double benefits,
    TaxEngine.FamilyDeductions deductions
) {}
