package io.bitnomio.coeff.consultant.domain;

import io.bitnomio.coeff.shared.domain.*;

import java.time.LocalDate;

public record Consultant(
    Long id, String name, String client, String position,
    Coef coef, Tariff tariff, String startDate, String endDate,
    Money fees, CoefPct coefPercentage, CoefPct coefMargin, Bonus managerBonus,
    String simulationInputs,
    ProfitabilityStatus profitabilityStatus,
    Money grossMonthlySalary, Money netMonthlySalary, Money netAnnualSalary,
    Money monthlySs, Money monthlyIrpf, TaxRate irpfRate, TaxRate ssRate,
    String coefProjection,
    String createdAt, String updatedAt
) {
    // REQ-CONSULTANT-FACTORIES: create() accepts raw doubles, constructs typed VOs internally
    public static Consultant create(String name, String client, String position,
            double tariff, double coef, String startDate, String endDate, Double fees) {
        var now = LocalDate.now().toString();
        return new Consultant(null, name, client, position,
            new Coef(coef), new Tariff(tariff), startDate, endDate,
            fees != null ? new Money(fees) : null, null, null, null, null,
            ProfitabilityStatus.INSUFFICIENT_DATA,
            null, null, null, null, null, null, null, null,
            now, now);
    }

    // REQ-CONSULTANT-FACTORIES: update() accepts raw doubles, constructs typed VOs internally
    public Consultant update(String name, String client, String position,
            double tariff, double coef, String startDate, String endDate, Double fees) {
        var now = LocalDate.now().toString();
        return new Consultant(id, name, client, position,
            new Coef(coef), new Tariff(tariff), startDate, endDate,
            fees != null ? new Money(fees) : null,
            coefPercentage, coefMargin, managerBonus, simulationInputs,
            profitabilityStatus,
            grossMonthlySalary, netMonthlySalary, netAnnualSalary,
            monthlySs, monthlyIrpf, irpfRate, ssRate, coefProjection,
            createdAt, now);
    }

    public int daysInRole() {
        try { return (int) java.time.temporal.ChronoUnit.DAYS.between(LocalDate.parse(startDate), LocalDate.now()); }
        catch (Exception e) { return 0; }
    }

    public boolean isActive() {
        return endDate == null || endDate.isEmpty() || LocalDate.parse(endDate).isAfter(LocalDate.now());
    }

    public boolean canEarnManagerBonus(int year, int month) {
        return canEarnManagerBonus(year, month, 14, 21);
    }

    public boolean canEarnManagerBonus(int year, int month, int bonusStartDay, int bonusEndDay) {
        if (startDate != null) {
            try {
                var sd = LocalDate.parse(startDate);
                if (sd.getYear() == year && sd.getMonthValue() == month && sd.getDayOfMonth() > bonusStartDay) {
                    return false;
                }
            } catch (Exception ignored) {}
        }
        if (endDate != null && !endDate.isEmpty()) {
            try {
                var ed = LocalDate.parse(endDate);
                return ed.getYear() != year || ed.getMonthValue() != month || ed.getDayOfMonth() >= bonusEndDay;
            } catch (Exception ignored) {}
        }
        return true;
    }
}
