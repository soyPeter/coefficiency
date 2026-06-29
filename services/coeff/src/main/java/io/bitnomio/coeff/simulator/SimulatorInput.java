package io.bitnomio.coeff.simulator;

import java.util.List;

public record SimulatorInput(
    Double fees,
    Integer annualWorkdays,
    String name,
    Integer age,
    String category,
    Double grossAnnualSalary,
    Double dailyMealCard,
    Double annualPerformanceBonus,
    String bonusCalendar,
    Double annualChildSupport,
    Double annualTraining,
    Boolean hasLaptop,
    Double monthlyLaptop,
    Boolean hasHealthInsurance,
    Double monthlyHealthInsurance,
    Double monthlyExtraIT,
    Double monthlyLicenses,
    Double otherCosts,
    List<Integer> workingDays,
    Boolean married,
    Integer children,
    Integer ascendants,
    Integer disability,
    String familySituation,
    Double otherIncomeIRPF,
    Double otherIncomeSS,
    Double taxFreeRemuneration
) {}
