package io.bitnomio.coeff.simulator;

import java.util.List;

public record SimulatorResult(
    Double grossMonthlySalary,
    Double netMonthlySalary,
    Double netAnnualSalary,
    Double monthlySSC,
    Double monthlyIRPF,
    Double irpfRate,
    Double ssRate,
    Double totalConsultantCost,
    Double coef,
    Double coefMargin,
    Double managerBonus,
    List<MonthlyRow> monthlyProjection
) {
    public record MonthlyRow(
        String month, Integer workingDays,
        Double gross, Double mealCard, Double childSupport,
        Double bonus, Double training,
        Double ss, Double irpf, Double neto
    ) {}
}
