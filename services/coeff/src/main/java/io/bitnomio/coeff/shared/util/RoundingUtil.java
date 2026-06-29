package io.bitnomio.coeff.shared.util;

public class RoundingUtil {
    private static final double STANDARD_SCALE = 100.0;
    private static final double PERCENTAGE_SCALE = 10000.0;

    public static double round2(double value) {
        return Math.round(value * STANDARD_SCALE) / STANDARD_SCALE;
    }

    public static double round4(double value) {
        return Math.round(value * PERCENTAGE_SCALE) / PERCENTAGE_SCALE;
    }
}
