package io.bitnomio.coeff.auth;

import org.jdbi.v3.sqlobject.config.RegisterConstructorMapper;
import org.jdbi.v3.sqlobject.statement.SqlQuery;
import org.jdbi.v3.sqlobject.statement.SqlUpdate;

import java.util.Optional;

@RegisterConstructorMapper(UserRecord.class)
public interface SqliteAuthRepository extends AuthRepository {

    @Override
    @SqlQuery("SELECT username, password_hash AS passwordHash, salt FROM users WHERE username = :username")
    Optional<UserRecord> findByUsername(String username);

    @Override
    @SqlUpdate("INSERT INTO users (username, password_hash, salt) VALUES (:username, :passwordHash, :salt)")
    void save(String username, String passwordHash, String salt);

    @Override
    @SqlQuery("SELECT COUNT(*) > 0 FROM users")
    boolean exists();
}
