package io.bitnomio.coeff.consultant.app;

import io.bitnomio.coeff.consultant.domain.Consultant;
import io.bitnomio.coeff.consultant.domain.ConsultantAction;
import io.bitnomio.coeff.shared.domain.*;
import io.bitnomio.coeff.shared.exceptions.NotFoundException;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import java.time.LocalDate;

@Singleton
public class SaveCoefUseCase {
    private final ConsultantAction consultantAction;

    @Inject
    public SaveCoefUseCase(@Named("consultantCommand") ConsultantAction consultantAction) {
        this.consultantAction = consultantAction;
    }

    public Consultant execute(long id, double fees, double tariff, double coefPercentage,
                              double coefMargin, double managerBonus, String simulationInputs,
                              Double grossMonthlySalary, Double netMonthlySalary, Double netAnnualSalary,
                              Double monthlySs, Double monthlyIrpf, Double irpfRate, Double ssRate,
                              String coefProjection) {
        var existing = consultantAction.findById(id)
            .orElseThrow(() -> new NotFoundException("Consultant not found: " + id));
        var now = LocalDate.now().toString();
        // REQ-USE-CASE-SIGNATURES: accept raw doubles, convert to typed VOs internally
        var updated = new Consultant(
            existing.id(), existing.name(), existing.client(), existing.position(),
            existing.coef(), new Tariff(tariff), existing.startDate(), existing.endDate(),
            new Money(fees), new CoefPct(coefPercentage), new CoefPct(coefMargin), new Bonus(managerBonus),
            simulationInputs,
            existing.profitabilityStatus(),
            grossMonthlySalary != null ? new Money(grossMonthlySalary) : null,
            netMonthlySalary != null ? new Money(netMonthlySalary) : null,
            netAnnualSalary != null ? new Money(netAnnualSalary) : null,
            monthlySs != null ? new Money(monthlySs) : null,
            monthlyIrpf != null ? new Money(monthlyIrpf) : null,
            irpfRate != null ? new TaxRate(irpfRate) : null,
            ssRate != null ? new TaxRate(ssRate) : null,
            coefProjection,
            existing.createdAt(), now);
        consultantAction.update(updated);
        return updated;
    }
}
