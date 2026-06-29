package io.bitnomio.coeff.report.app;

import io.bitnomio.coeff.report.domain.PeerBenchmark;
import jakarta.inject.Singleton;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Singleton
public class PeerBenchmarkService {

    private final Jdbi jdbi;

    public PeerBenchmarkService(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public Map<String, PeerBenchmark> computeAllBenchmarks() {
        double absoluteThreshold = 0.15;
        var rows = jdbi.withHandle(h ->
            h.createQuery("SELECT position, tariff FROM consultants WHERE end_date IS NULL OR end_date > date('now')")
             .mapToMap().list());

        var byRole = rows.stream()
            .filter(r -> r.get("position") != null && !((String) r.get("position")).isBlank())
            .collect(Collectors.groupingBy(r -> (String) r.get("position")));

        return byRole.entrySet().stream()
            .collect(Collectors.toMap(Map.Entry::getKey, e -> {
                var peers = e.getValue();
                var tariffs = peers.stream()
                    .map(r -> ((Number) r.get("tariff")).doubleValue())
                    .sorted().toList();
                int pc = tariffs.size();
                if (pc < 3) {
                    return new PeerBenchmark(e.getKey(), absoluteThreshold, absoluteThreshold, absoluteThreshold, pc, absoluteThreshold);
                }
                double p25 = percentile(tariffs, 25);
                double p50 = percentile(tariffs, 50);
                double p75 = percentile(tariffs, 75);
                double threshold = p75 < 0 ? p75 * -1 : p75;
                return new PeerBenchmark(e.getKey(), p25, p50, p75, pc, threshold);
            }));
    }

    private static double percentile(List<Double> sorted, int pct) {
        int n = sorted.size();
        if (n == 0) return 0;
        if (n == 1) return sorted.get(0);
        double rank = (pct / 100.0) * (n - 1);
        int lower = (int) Math.floor(rank);
        int upper = (int) Math.ceil(rank);
        if (lower == upper) return sorted.get(lower);
        double fraction = rank - lower;
        return sorted.get(lower) + fraction * (sorted.get(upper) - sorted.get(lower));
    }
}
