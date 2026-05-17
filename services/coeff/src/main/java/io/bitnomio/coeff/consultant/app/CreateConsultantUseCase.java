package io.bitnomio.coeff.consultant.app;

import io.bitnomio.coeff.consultant.domain.ConsultantAction;
import io.bitnomio.coeff.consultant.domain.Consultant;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

@Singleton
public class CreateConsultantUseCase {
    private final ConsultantAction consultantAction;

    @Inject
    public CreateConsultantUseCase(@Named("consultantCommand") ConsultantAction consultantAction) {
        this.consultantAction = consultantAction;
    }

    public Consultant execute(String name, String client, String position,
                              double tariff, double coef, String startDate, String endDate, Double fees) {
        var c = Consultant.create(name, client, position, tariff, coef, startDate, endDate, fees);
        consultantAction.save(c);
        return c;
    }
}
