<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: observability
description: Observability patterns for distributed systems - logging, metrics, tracing, correlation IDs, and alerting. Use when debugging production issues or setting up monitoring.
---

# Observability Skill

Patterns for logging, metrics, tracing, and alerting in distributed systems.

## When to Use

- Debugging production issues
- Setting up monitoring
- Investigating performance problems
- Tracing requests across services

## Three Pillars

| Pillar | Purpose | Tool |
|--------|---------|------|
| **Logs** | Discrete events | ELK, Loki, OpenObserve |
| **Metrics** | Aggregated measurements | Prometheus, Datadog |
| **Traces** | Request flow across services | Jaeger, Zipkin |

## Correlation ID Pattern

**Trace requests across service boundaries.**

### Implementation

```java
// Controller - extract or generate correlation ID
@GetMapping("/api/users/{id}")
public UserRes getUser(
    @RequestHeader(value = "X-Correlation-ID", required = false) String corrId) {
    
    String correlationId = corrId != null ? corrId : UUID.randomUUID().toString();
    
    // Add to MDC for logging
    MDC.put("correlationId", correlationId);
    
    try {
        User user = getUserUseCase.execute(id);
        return UserRes.from(user);
    } finally {
        MDC.remove("correlationId");
    }
}
```

### Log Format (JSON with MDC)
```json
{
  "timestamp": "2026-04-15T10:30:00Z",
  "level": "INFO",
  "correlationId": "abc-123-def",
  "service": "user-service",
  "message": "User retrieved",
  "userId": "user-456"
}
```

## Health Checks

### Endpoint Pattern
```java
@GetMapping("/actuator/health")
public Map<String, Object> health() {
    return Map.of(
        "status", healthService.isHealthy() ? "UP" : "DOWN",
        "components", healthService.getComponents()
    );
}
```

### Kubernetes Probes
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```

## Structured Logging

### Good Log Messages
```java
// ✅ GOOD - Structured with context
logger.info("Order created: orderId={}, customerId={}, amount={}", 
    order.getId(), order.getCustomerId(), order.getAmount());

// ❌ BAD - Unstructured
logger.info("Order created for " + customer.getName());
```

### Log Levels
| Level | Use When |
|-------|----------|
| ERROR | Operation failed, needs attention |
| WARN | Degraded performance, recoverable issue |
| INFO | Major lifecycle events |
| DEBUG | Detailed flow for debugging |

## Metrics

### Key Metrics to Track

| Category | Metrics |
|----------|---------|
| **Request** | latencies, throughput, error rate |
| **Business** | orders created, users signed up |
| **System** | CPU, memory, connections |
| **Custom** | cache hit rate, queue depth |

### Prometheus Metrics
```java
private final Counter orderCreatedCounter = Counter.builder()
    .name("orders_created_total")
    .description("Total orders created")
    .register(meterRegistry);

public void createOrder(Order order) {
    orderRepo.save(order);
    orderCreatedCounter.increment();
}
```

## Alerting

### SLI/SLO Targets

| Service Type | Availability | Latency |
|--------------|-------------|---------|
| Critical API | 99.9% | < 200ms p99 |
| Background Job | 99.0% | N/A |
| Internal Tool | 95.0% | < 1s p99 |

### Alert Rules
```yaml
groups:
- name: api-alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m])) 
      / sum(rate(http_requests_total[5m])) > 0.01
    for: 5m
    labels:
      severity: critical
```

## Distributed Tracing

### Span Creation
```java
Span span = tracer.startSpan("process-order");
try (Span ignored = span) {
    span.tag("order.id", order.getId());
    // Process order
} catch (Exception e) {
    span.recordException(e);
    throw e;
}
```

## Debugging Checklist

1. **Get correlation ID** from failing request
2. **Search logs** for correlation ID
3. **Check trace** across services
4. **Identify slow span** if latency issue
5. **Check metrics** for resource exhaustion
6. **Review recent changes** if new issue
