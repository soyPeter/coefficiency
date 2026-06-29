package io.bitnomio.coeff.auth;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class AuthServiceTest {

    @Test
    void hashPassword_bcrypt() {
        var service = new AuthService();
        var hash = service.hashPassword("test1234", "");
        assertTrue(hash.startsWith("$2a$"));
    }

    @Test
    void hashPassword_withExistingBcryptSalt() {
        var service = new AuthService();
        var hash = service.hashPassword("test1234", "");
        var hash2 = service.hashPassword("test1234", hash);
        assertTrue(hash2.startsWith("$2a$"));
    }

    @Test
    void checkPassword_bcrypt() {
        var service = new AuthService();
        var hash = service.hashPassword("test1234", "");
        assertTrue(service.checkPassword("test1234", hash, ""));
        assertFalse(service.checkPassword("wrong", hash, ""));
    }

    @Test
    void generateSalt_returnsBcryptSalt() {
        var service = new AuthService();
        var salt = service.generateSalt();
        assertTrue(salt.startsWith("$2a$"));
    }

    @Test
    void createAndValidateToken() {
        var service = new AuthService();
        var token = service.createToken("admin");
        assertNotNull(token);
        assertTrue(service.validateToken(token));
    }

    @Test
    void validateToken_wrongToken() {
        var service = new AuthService();
        assertFalse(service.validateToken("invalid-token"));
        assertFalse(service.validateToken(""));
    }

    @Test
    void extractUsername_fromToken() {
        var service = new AuthService();
        var token = service.createToken("admin");
        assertEquals("admin", service.extractUsername(token));
    }

    @Test
    void migrateToBCrypt_returnsBcrypt() {
        var service = new AuthService();
        var migrated = service.migrateToBCrypt("password", "some-hex-hash", "aabb");
        assertTrue(migrated.startsWith("$2a$"));
    }

    @Test
    void migrateToBCrypt_alreadyBcrypt() {
        var service = new AuthService();
        var bcryptHash = service.hashPassword("test1234", "");
        var same = service.migrateToBCrypt("test1234", bcryptHash, "");
        assertEquals(bcryptHash, same);
    }
}
