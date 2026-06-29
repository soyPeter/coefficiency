package io.bitnomio.coeff.report.domain;

public record PeerBenchmark(String role, double p25, double p50, double p75, int peerCount, double absoluteThreshold) {
    public boolean hasSufficientPeers() { return peerCount >= 3; }
}
