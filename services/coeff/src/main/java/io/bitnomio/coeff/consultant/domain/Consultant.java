package io.bitnomio.coeff.consultant.domain;

import java.time.LocalDate;

public record Consultant(
    Long id, String name, String client, String position,
    double coef, double tariff, String startDate, String endDate,
    Double fees, Double coefPercentage, Double coefMargin, Double managerBonus,
    String simulationInputs, String createdAt, String updatedAt
) {
    public static Consultant create(String name, String client, String position,
            double tariff, double coef, String startDate, String endDate, Double fees) {
        var now = LocalDate.now().toString();
        var money = tariff * coef;
        return new Consultant(null, name, client, position, coef, tariff, startDate, endDate,
            fees, coef, money, null, null, now, now);
    }

    public Consultant update(String name, String client, String position,
            double tariff, double coef, String startDate, String endDate, Double fees) {
        var money = tariff * coef;
        return new Consultant(id, name, client, position, coef, tariff, startDate, endDate,
            fees, coef, money, managerBonus, simulationInputs, createdAt, LocalDate.now().toString());
    }

    public int daysInRole() {
        try { return (int) java.time.temporal.ChronoUnit.DAYS.between(LocalDate.parse(startDate), LocalDate.now()); }
        catch (Exception e) { return 0; }
    }

    public boolean isActive() {
        return endDate == null || endDate.isEmpty() || LocalDate.parse(endDate).isAfter(LocalDate.now());
    }
}
