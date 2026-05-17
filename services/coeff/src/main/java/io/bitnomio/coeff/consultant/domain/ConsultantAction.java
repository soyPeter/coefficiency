package io.bitnomio.coeff.consultant.domain;

import java.util.Optional;

public interface ConsultantAction {
    void save(Consultant consultant);
    void update(Consultant consultant);
    void delete(long id);
    Optional<Consultant> findById(long id);
}
