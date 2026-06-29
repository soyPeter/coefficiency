package io.bitnomio.coeff.auth;

import jakarta.inject.Singleton;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Authentication logic: password hashing (SHA-256 with salt), token creation
 * and validation (HMAC-SHA256 with expiry).
 *
 * <p>Tokens embed {@code username:expiry_timestamp:signature} then are
 * base64-encoded. The HMAC secret is loaded from {@code data/.hmac-secret}
 * and auto-generated if the file does not exist.
 *
 * @since 1.0
 */
@Singleton
public class AuthService {

    private static final long TOKEN_EXPIRY_SECONDS = 86400;
    private static final int SALT_SIZE = 16;
    private static final int HMAC_KEY_SIZE = 32;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final String hmacSecret;

    public AuthService() {
        this.hmacSecret = loadOrCreateHmacSecret();
    }

    private static String hmacSecretFile() {
        var dir = System.getProperty("coeff.data.dir");
        if (dir != null) return dir + "/.hmac-secret";
        var userDir = System.getProperty("user.dir");
        var base = userDir.contains("services/coeff") ? userDir : userDir + "/services/coeff";
        return base + "/data/.hmac-secret";
    }

    private static String loadOrCreateHmacSecret() {
        try {
            var file = new File(hmacSecretFile());
            if (file.exists()) {
                return Files.readString(file.toPath()).trim();
            }
            file.getParentFile().mkdirs();
            var bytes = new byte[HMAC_KEY_SIZE];
            SECURE_RANDOM.nextBytes(bytes);
            var secret = HexFormat.of().formatHex(bytes);
            try (var out = new FileOutputStream(file)) {
                out.write(secret.getBytes(StandardCharsets.UTF_8));
            }
            return secret;
        } catch (Exception e) {
            throw new RuntimeException("Failed to load/create HMAC secret", e);
        }
    }

    /**
     * Hashes a password with BCrypt. If a hex salt is provided (non-BCrypt fallback),
     * uses SHA-256 for backward compatibility with legacy hashes.
     */
    public String hashPassword(String password, String salt) {
        if (salt == null || salt.isEmpty() || salt.startsWith("$2a$")) {
            return BCrypt.hashpw(password, salt != null && salt.startsWith("$2a$") ? salt : BCrypt.gensalt());
        }
        try {
            var md = MessageDigest.getInstance("SHA-256");
            md.update(HexFormat.of().parseHex(salt));
            md.update(password.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(md.digest());
        } catch (Exception e) {
            throw new RuntimeException("Failed to hash password", e);
        }
    }

    /**
     * Verifies a password against a stored hash. Supports both BCrypt ($2a$) and
     * legacy SHA-256 hex hashes. If a SHA-256 hash is detected and matches, the
     * password is auto-migrated to BCrypt for next time.
     */
    public boolean checkPassword(String password, String storedHash, String salt) {
        if (storedHash.startsWith("$2a$")) {
            return BCrypt.checkpw(password, storedHash);
        }
        var legacy = hashPassword(password, salt);
        return MessageDigest.isEqual(legacy.getBytes(StandardCharsets.UTF_8), storedHash.getBytes(StandardCharsets.UTF_8));
    }

    public String generateSalt() {
        return BCrypt.gensalt(10, SECURE_RANDOM);
    }

    public String migrateToBCrypt(String password, String existingHash, String salt) {
        if (existingHash.startsWith("$2a$")) return existingHash;
        return BCrypt.hashpw(password, BCrypt.gensalt());
    }

    /**
     * Creates an HMAC-SHA256 signed token embedding username and expiry.
     * The token is base64-encoded as {@code base64(username:expiry:signature)}.
     *
     * @param username the authenticated user
     * @return base64-encoded bearer token valid for 24 hours
     */
    public String createToken(String username) {
        try {
            var expiry = Instant.now().getEpochSecond() + TOKEN_EXPIRY_SECONDS;
            var data = username + ":" + expiry;
            var mac = Mac.getInstance("HmacSHA256");
            var key = new SecretKeySpec(hmacSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(key);
            var signature = HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
            return Base64.getEncoder().withoutPadding().encodeToString((data + ":" + signature).getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new RuntimeException("Failed to create token", e);
        }
    }

    /**
     * Validates a token's HMAC signature and expiry timestamp.
     *
     * @param token the base64-encoded token
     * @return true if signature matches and token is not expired
     */
    public boolean validateToken(String token) {
        try {
            var decoded = new String(Base64.getDecoder().decode(token), StandardCharsets.UTF_8);
            var parts = decoded.split(":");
            if (parts.length < 3) return false;
            var username = parts[0];
            var expiry = Long.parseLong(parts[1]);
            if (Instant.now().getEpochSecond() > expiry) return false;
            var expectedSig = parts[2];
            var mac = Mac.getInstance("HmacSHA256");
            var key = new SecretKeySpec(hmacSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(key);
            var actualSig = HexFormat.of().formatHex(mac.doFinal((username + ":" + expiry).getBytes(StandardCharsets.UTF_8)));
            return MessageDigest.isEqual(expectedSig.getBytes(StandardCharsets.UTF_8), actualSig.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            return false;
        }
    }

    public String extractUsername(String token) {
        try {
            var decoded = new String(Base64.getDecoder().decode(token), StandardCharsets.UTF_8);
            return decoded.split(":")[0];
        } catch (Exception e) {
            return null;
        }
    }
}
