package io.bitnomio.coeff.auth;

import io.bitnomio.coeff.shared.db.DbEncryption;
import io.bitnomio.coeff.shared.db.SqliteConnection;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import java.util.Map;

/**
 * Authentication REST controller: setup (first-run), login, logout, and status.
 *
 * <p>All endpoints are exempt from the bearer-token filter configured in
 * {@link io.bitnomio.coeff.CoeffConfig}. The controller coordinates the
 * encryption lifecycle via {@link DbEncryption}.
 *
 * @since 1.0
 * @see AuthService
 * @see DbEncryption
 */
@Singleton
@Path("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final AuthRepository authRepository;
    private final DbEncryption dbEncryption;
    private final SqliteConnection sqliteConnection;

    @Inject
    public AuthController(
            AuthService authService,
            @Named("auth") AuthRepository authRepository,
            DbEncryption dbEncryption,
            SqliteConnection sqliteConnection) {
        this.authService = authService;
        this.authRepository = authRepository;
        this.dbEncryption = dbEncryption;
        this.sqliteConnection = sqliteConnection;
    }

    /**
     * Returns whether a user has been set up. Used by the frontend to decide
     * whether to show the setup form or the login form.
     */
    @GET
    @Path("/status")
    public Map<String, Object> status() {
        var hasUser = dbEncryption.hasKeyFile() || authRepository.exists();
        return Map.of("hasUser", hasUser, "authenticated", false);
    }

    /**
     * First-run setup: creates an encryption key from the password, hashes it
     * for the users table, encrypts the database, and starts periodic sync.
     *
     * @param req username and password
     * @return bearer token for immediate login
     * @throws io.bitnomio.coeff.shared.exceptions.ConflictException if a user already exists
     */
    @POST
    @Path("/setup")
    public Map<String, String> setup(SetupRequest req) {
        if (req.username().length() < 3) throw new IllegalArgumentException("Username must be at least 3 characters");
        if (req.password().length() < 4) throw new IllegalArgumentException("Password must be at least 4 characters");
        if (authRepository.exists()) throw new io.bitnomio.coeff.shared.exceptions.ConflictException("Setup already completed");
        dbEncryption.createKeyFile(req.password());
        var salt = authService.generateSalt();
        var hash = authService.hashPassword(req.password(), salt);
        authRepository.save(req.username(), hash, salt);
        dbEncryption.encrypt();
        dbEncryption.startPeriodicSync();
        return Map.of("token", authService.createToken(req.username()));
    }

    /**
     * Authenticates against the stored password hash. If the database is encrypted,
     * decrypts it first and re-initializes the JDBI connection.
     *
     * @param req username and password
     * @return bearer token
     */
    @POST
    @Path("/login")
    public Map<String, String> login(LoginRequest req) {
        if (!dbEncryption.verifyPassword(req.password())) throw new IllegalStateException("Invalid credentials");
        if (dbEncryption.isEncrypted()) {
            sqliteConnection.close();
            dbEncryption.decrypt(req.password());
            sqliteConnection.reinit();
        }
        var user = authRepository.findByUsername(req.username())
            .orElseThrow(() -> new IllegalStateException("Invalid credentials"));
        var hash = authService.hashPassword(req.password(), user.salt());
        if (!hash.equals(user.passwordHash())) throw new IllegalStateException("Invalid credentials");
        dbEncryption.startPeriodicSync();
        return Map.of("token", authService.createToken(req.username()));
    }

    /**
     * Stops periodic sync and re-encrypts the database, then deletes the
     * plaintext copy.
     */
    @POST
    @Path("/logout")
    public void logout() {
        dbEncryption.stopPeriodicSync();
        dbEncryption.encrypt();
        dbEncryption.deleteDecryptedDb();
    }
}
