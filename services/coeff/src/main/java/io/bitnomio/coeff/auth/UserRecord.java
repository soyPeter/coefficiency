package io.bitnomio.coeff.auth;

public record UserRecord(
    String username,
    String passwordHash,
    String salt
) {}
