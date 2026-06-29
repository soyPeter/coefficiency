package io.bitnomio.coeff.bonusbreakdown.domain;

public record BonusBreakdownRow(int id, int year, String month, double managerBonus,
                                 int tenureCount, double tenureAmount,
                                 int projectedTenureCount, double projectedTenureAmount,
                                 int quarterlyCount, double quarterlyAmount,
                                 double totalBonus) {}
