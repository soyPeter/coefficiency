package io.bitnomio.coeff.auth;

import java.util.Optional;

public interface AuthRepository {
    Optional<UserRecord> findByUsername(String username);
    void save(String username, String passwordHash, String salt);
    boolean exists();
}
