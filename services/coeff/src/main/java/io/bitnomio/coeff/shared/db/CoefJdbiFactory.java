package io.bitnomio.coeff.shared.db;

import io.avaje.inject.Bean;
import io.avaje.inject.Factory;
import io.bitnomio.coeff.auth.AuthRepository;
import io.bitnomio.coeff.auth.SqliteAuthRepository;
import io.bitnomio.coeff.consultant.domain.ConsultantAction;
import io.bitnomio.coeff.consultant.infra.data.sql.ConsultantRow;
import io.bitnomio.coeff.consultant.infra.data.sql.ConsultantSqlCommandRepo;
import io.bitnomio.coeff.consultant.infra.data.sql.ListConsultantsQuery;
import io.bitnomio.coeff.consultant.infra.data.sql.SqliteConsultantQueryRepo;
import jakarta.inject.Named;
import org.jdbi.v3.core.Jdbi;
import org.jdbi.v3.core.mapper.reflect.ConstructorMapper;

/**
 * Avaje {@link Factory} that exposes JDBI-based repository beans for DI.
 *
 * <p>All repositories share the same {@link Jdbi} instance from
 * {@link SqliteConnection}, ensuring they operate on the same connection
 * pool and SQLite database file.
 *
 * @since 1.0
 * @see SqliteConnection
 */
@Factory
public class CoefJdbiFactory {

    @Bean public Jdbi jdbi(SqliteConnection connection) {
        var jdbi = connection.jdbi();
        jdbi.getConfig(org.jdbi.v3.core.statement.SqlStatements.class).setUnusedBindingAllowed(true);
        jdbi.registerRowMapper(ConsultantRow.class, ConstructorMapper.of(ConsultantRow.class));
        return jdbi;
    }

    @Bean @Named("auth")
    public AuthRepository authRepository(Jdbi jdbi) { return jdbi.onDemand(SqliteAuthRepository.class); }

    @Bean @Named("consultantCommand")
    public ConsultantAction consultantCommandRepo(Jdbi jdbi) { return new ConsultantSqlCommandRepo(jdbi); }

    @Bean @Named("consultantQuery")
    public ListConsultantsQuery consultantQueryRepo(Jdbi jdbi) { return new SqliteConsultantQueryRepo(jdbi); }
}
