package io.bitnomio.coeff.auth;

import io.bitnomio.coeff.shared.db.DbEncryption;
import io.bitnomio.coeff.shared.db.SqliteConnection;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import java.io.File;
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
        if (req.password().length() < 8) throw new IllegalArgumentException("Password must be at least 8 characters");
        if (authRepository.exists()) throw new io.bitnomio.coeff.shared.exceptions.ConflictException("Setup already completed");
        dbEncryption.createKeyFile(req.password());
        var hash = authService.hashPassword(req.password(), "");
        authRepository.save(req.username(), hash, "");
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
        if (!authService.checkPassword(req.password(), user.passwordHash(), user.salt())) {
            throw new IllegalStateException("Invalid credentials");
        }
        if (!user.passwordHash().startsWith("$2a$")) {
            var newHash = authService.migrateToBCrypt(req.password(), user.passwordHash(), user.salt());
            authRepository.save(req.username(), newHash, "");
        }
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

    @POST @Path("/password")
    public Map<String, Object> changePassword(PasswordRequest req) {
        if (req.newPassword() == null || req.newPassword().length() < 8) {
            throw new IllegalArgumentException("Password must be at least 8 characters");
        }
        var user = authRepository.findByUsername(
            java.util.Optional.ofNullable(authService.extractUsername(
                java.util.Optional.ofNullable(org.slf4j.MDC.get("token")).orElse("")))
            .orElse("admin"))
            .orElseThrow(() -> new IllegalStateException("User not found"));
        if (!authService.checkPassword(req.oldPassword(), user.passwordHash(), user.salt())) {
            throw new IllegalArgumentException("Invalid current password");
        }
        dbEncryption.encrypt();
        dbEncryption.createKeyFile(req.newPassword());
        dbEncryption.deleteDecryptedDb();
        sqliteConnection.reinit();
        dbEncryption.decrypt(req.newPassword());
        sqliteConnection.reinit();
        var newHash = authService.hashPassword(req.newPassword(), "");
        authRepository.save(user.username(), newHash, "");
        dbEncryption.startPeriodicSync();
        return Map.of("ok", true);
    }

    @POST @Path("/reset-database")
    public Map<String, Object> resetDatabase() {
        dbEncryption.stopPeriodicSync();
        dbEncryption.deleteDecryptedDb();
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of("data/app.db.enc")); } catch (Exception ignored) {}
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of("data/.db-key")); } catch (Exception ignored) {}
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of("data/.hmac-secret")); } catch (Exception ignored) {}
        return Map.of("ok", true, "message", "Database reset. Please restart.");
    }
}
