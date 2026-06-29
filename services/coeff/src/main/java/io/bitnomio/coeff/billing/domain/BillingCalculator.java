package io.bitnomio.coeff.billing.domain;

import io.bitnomio.coeff.shared.util.RoundingUtil;

import java.time.LocalDate;
import java.util.List;

public class BillingCalculator {

    public static boolean isActiveInRange(String startDateStr, String endDateStr, LocalDate rangeStart, LocalDate rangeEnd) {
        if (startDateStr == null) return false;
        var start = LocalDate.parse(startDateStr);
        if (start.isAfter(rangeEnd)) return false;
        if (endDateStr == null || endDateStr.isEmpty()) return true;
        var end = LocalDate.parse(endDateStr);
        return !end.isBefore(rangeStart);
    }

    public static double monthDaily(List<RawConsultant> consultants, int year, int month) {
        var monthStart = LocalDate.of(year, month, 1);
        var monthEnd = monthStart.withDayOfMonth(monthStart.lengthOfMonth());
        return consultants.stream()
            .filter(c -> isActiveInRange(c.startDate, c.endDate, monthStart, monthEnd))
            .mapToDouble(c -> c.tariff)
            .sum();
    }

    public static double currentDaily(List<RawConsultant> consultants) {
        var now = LocalDate.now();
        return monthDaily(consultants, now.getYear(), now.getMonthValue());
    }

    public static int remainingDays(int currentMonth, int cm, int cy) {
        return cy - currentMonth * cm;
    }

    public static double ytdBilling(List<RawConsultant> consultants, int year, int month, int cm) {
        double total = 0;
        for (int m = 1; m <= month; m++) {
            total += monthDaily(consultants, year, m) * cm;
        }
        return total;
    }

    public static double annualProjected(List<RawConsultant> consultants, int currentMonth, int cm, int cy) {
        int year = LocalDate.now().getYear();
        double ytd = ytdBilling(consultants, year, currentMonth, cm);
        double daily = currentDaily(consultants);
        return ytd + daily * remainingDays(currentMonth, cm, cy);
    }

    public static double[] trailingMonthDailies(List<RawConsultant> consultants, int year, int currentMonth, int lookback) {
        double[] trail = new double[lookback];
        for (int i = 0; i < lookback; i++) {
            trail[i] = monthDaily(consultants, year, currentMonth - lookback + 1 + i);
        }
        return trail;
    }

    public static double trailingAvg(double[] trail) {
        double sum = 0;
        for (double d : trail) sum += d;
        return sum / trail.length;
    }

    public static double avgGrowthRate(double[] trail) {
        if (trail.length < 2) return 0;
        double totalGrowth = 0;
        int pairs = 0;
        for (int i = 1; i < trail.length; i++) {
            if (trail[i - 1] > 0) {
                totalGrowth += (trail[i] / trail[i - 1]) - 1;
                pairs++;
            }
        }
        if (pairs == 0) return 0;
        double avg = totalGrowth / pairs;
        if (avg > 0.5) return 0.5;
        if (avg < -0.5) return -0.5;
        return avg;
    }

    public static double projectedRemaining(double trailingAvg, double avgGrowth, int remainingMonths, int cm) {
        double projected = 0;
        double daily = trailingAvg;
        for (int i = 0; i < remainingMonths; i++) {
            if (i > 0) daily *= (1 + avgGrowth);
            projected += daily * cm;
        }
        return projected;
    }

    public static double avgCoefPct(List<RawConsultant> consultants) {
        if (consultants.isEmpty()) return 0.0;
        double hasPctCount = consultants.stream().mapToDouble(c -> c.coefPercentage() != null ? c.coefPercentage() : 0).filter(v -> v > 0).count();
        double avg = hasPctCount > 0
            ? consultants.stream().mapToDouble(c -> c.coefPercentage() != null ? c.coefPercentage() : 0).average().orElse(0.0)
            : consultants.stream().mapToDouble(c -> c.coef()).average().orElse(0.0);
        return RoundingUtil.round2(avg);
    }

    public record RawConsultant(
        int id, String name, String client, String position,
        double coef, double tariff, String startDate, String endDate,
        Double fees, Double coefPercentage, Double coefMargin, Double managerBonus
    ) {}
}
