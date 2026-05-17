package io.bitnomio.coeff.consultant.app;

import io.bitnomio.coeff.consultant.domain.ConsultantAction;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

@Singleton
public class DeleteConsultantUseCase {
    private final ConsultantAction consultantAction;

    @Inject
    public DeleteConsultantUseCase(@Named("consultantCommand") ConsultantAction consultantAction) {
        this.consultantAction = consultantAction;
    }

    public void execute(long id) { consultantAction.delete(id); }
}
