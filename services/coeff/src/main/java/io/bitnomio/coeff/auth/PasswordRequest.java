package io.bitnomio.coeff.auth;

public record PasswordRequest(String oldPassword, String newPassword) {}
