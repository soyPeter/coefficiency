<!-- Migrated from adrs/adr-002-observability-propagation.md on 2026-02-23 -->

# End-to-End Trace Context Propagation and Logging Correlation

## Status

Accepted

## Context and Problem Statement

Effective observability is crucial for understanding microservice interactions, debugging distributed systems, and monitoring system health. This requires consistent trace context propagation (Trace ID, Span ID) and correlated logging across all services, including the gateway (B2F-Proxy) and the `myinvestor-08086` microservices.

## Decision Drivers

* Enable end-to-end request tracing across services
* Facilitate debugging of distributed system issues
* Correlate logs from multiple services for single request
* Support centralized observability platform integration
* Maintain trace context across security boundary

## Considered Options

* **Per-service trace generation** - Each service generates its own trace IDs (fragmented tracing)
* **Centralized trace context propagation** - B2F-Proxy generates and propagates context via headers (chosen)
* **External trace collection service** - Separate observability microservice (adds latency)

## Decision Outcome

Chosen option: **Centralized trace context propagation via B2F-Proxy**, because it enables seamless end-to-end tracing, maintains request context across service boundaries, and leverages existing observability infrastructure.

### Structure

Establish consistent observability strategy with:

1. B2F-Proxy as trace context originator/propagator - generates/receives Trace ID, Span ID, Request ID
2. Header-based context consumption - `myinvestor-08086` services consume propagated headers
3. MDC integration - extracted context placed into SLF4j MDC by service filters
4. Consistent logging - both B2F-Proxy and services include trace context in logs
5. Standardized headers/MDC keys - ensure seamless data flow and correlation

### Consequences

**Good:**
* End-to-end traceability - track requests across services for debugging
* Correlated logging - group logs from single request for analysis
* Simplified observability - consistent approach reduces cognitive load
* Leverages existing infrastructure - builds on robust observability in shared libraries

**Bad:**
* Reliance on B2F-Proxy - integrity depends on correct implementation
* Potential for mismatches - if header names/MDC keys misaligned, correlation fails
* Performance overhead - trace generation and propagation adds minor cost

## Implementation Notes

* Verify B2F-Proxy generates and injects trace context headers (`X-B2F-Trace-ID`, `X-Request-ID`, `traceparent`)
* Test end-to-end trace correlation with sample requests
* Align headers with filter expectations in `myinvestor-08086` services
* Ensure MDC keys consistent across logging correlation
* Configure logging aggregation to leverage trace context

## References

* B2F-Proxy MDCLoggingFilter implementation
* Myinvestor correlation filters and MDC handling
* OpenTelemetry trace context specification
* `documentation/adr/0001-hexagonal-architecture.md`
