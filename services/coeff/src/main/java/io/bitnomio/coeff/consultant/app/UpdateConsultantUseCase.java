package io.bitnomio.coeff.consultant.app;

import io.bitnomio.coeff.consultant.domain.ConsultantAction;
import io.bitnomio.coeff.consultant.domain.Consultant;
import io.bitnomio.coeff.shared.exceptions.NotFoundException;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

@Singleton
public class UpdateConsultantUseCase {
    private final ConsultantAction consultantAction;

    @Inject
    public UpdateConsultantUseCase(@Named("consultantCommand") ConsultantAction consultantAction) {
        this.consultantAction = consultantAction;
    }

    public Consultant execute(long id, String name, String client, String position,
                              double tariff, double coef, String startDate, String endDate, Double fees) {
        var existing = consultantAction.findById(id)
            .orElseThrow(() -> new NotFoundException("Consultant not found: " + id));
        var updated = existing.update(name, client, position, tariff, coef, startDate, endDate, fees);
        consultantAction.update(updated);
        return updated;
    }
}
