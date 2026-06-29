package io.bitnomio.coeff.shared.util;

import org.jdbi.v3.core.Jdbi;

import java.util.Optional;

public class SettingsHelper {

    public static Optional<String> getSetting(Jdbi jdbi, String key) {
        return jdbi.withHandle(h ->
            h.createQuery("SELECT value FROM settings WHERE key = :key")
             .bind("key", key)
             .mapTo(String.class).findOne());
    }

    public static int readIntOrDefault(Jdbi jdbi, String key, int def) {
        return getSetting(jdbi, key).map(Integer::parseInt).orElse(def);
    }

    public static double readDoubleOrDefault(Jdbi jdbi, String key, double def) {
        return getSetting(jdbi, key).map(Double::parseDouble).orElse(def);
    }
}
