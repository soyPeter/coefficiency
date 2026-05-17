package io.bitnomio.coeff.auth;

import jakarta.inject.Singleton;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.HexFormat;

/**
 * Authentication logic: password hashing (SHA-256 with salt), token creation
 * and validation (HMAC-SHA256 with expiry).
 *
 * <p>Tokens embed {@code username:expiry_timestamp:signature} then are
 * hex-encoded. The HMAC secret is hardcoded; in production this would be
 * loaded from a configurable secret store.
 *
 * @since 1.0
 */
@Singleton
public class AuthService {

    private static final String HMAC_SECRET = "coeff-hmac-secret-2026";
    private static final long TOKEN_EXPIRY_SECONDS = 86400;
    private static final int SALT_SIZE = 16;

    /**
     * SHA-256 hash of password with a hex salt.
     *
     * @param password raw password
     * @param salt     hex-encoded salt
     * @return hex-encoded SHA-256 digest
     */
    public String hashPassword(String password, String salt) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            md.update(HexFormat.of().parseHex(salt));
            md.update(password.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(md.digest());
        } catch (Exception e) {
            throw new RuntimeException("Failed to hash password", e);
        }
    }

    public String generateSalt() {
        var bytes = new byte[SALT_SIZE];
        new SecureRandom().nextBytes(bytes);
        return HexFormat.of().formatHex(bytes);
    }

    /**
     * Creates an HMAC-SHA256 signed token embedding username and expiry.
     * The token is hex-encoded as {@code hex(username:expiry:signature)}.
     *
     * @param username the authenticated user
     * @return hex-encoded bearer token valid for 24 hours
     */
    public String createToken(String username) {
        try {
            var expiry = Instant.now().getEpochSecond() + TOKEN_EXPIRY_SECONDS;
            var data = username + ":" + expiry;
            var mac = Mac.getInstance("HmacSHA256");
            var key = new SecretKeySpec(HMAC_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(key);
            var signature = HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
            return HexFormat.of().formatHex((data + ":" + signature).getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new RuntimeException("Failed to create token", e);
        }
    }

    /**
     * Validates a token's HMAC signature and expiry timestamp.
     *
     * @param token the hex-encoded token
     * @return true if signature matches and token is not expired
     */
    public boolean validateToken(String token) {
        try {
            var decoded = new String(HexFormat.of().parseHex(token), StandardCharsets.UTF_8);
            var parts = decoded.split(":");
            if (parts.length < 3) return false;
            var username = parts[0];
            var expiry = Long.parseLong(parts[1]);
            if (Instant.now().getEpochSecond() > expiry) return false;
            var expectedSig = parts[2];
            var mac = Mac.getInstance("HmacSHA256");
            var key = new SecretKeySpec(HMAC_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(key);
            var actualSig = HexFormat.of().formatHex(mac.doFinal((username + ":" + expiry).getBytes(StandardCharsets.UTF_8)));
            return MessageDigest.isEqual(expectedSig.getBytes(StandardCharsets.UTF_8), actualSig.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            return false;
        }
    }

    public String extractUsername(String token) {
        try {
            var decoded = new String(HexFormat.of().parseHex(token), StandardCharsets.UTF_8);
            return decoded.split(":")[0];
        } catch (Exception e) {
            return null;
        }
    }
}
