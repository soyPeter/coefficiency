# Resilience4j for Fault Tolerance Patterns

## Status

Accepted

## Context and Problem Statement

Microservices depend on external services (databases, APIs, message brokers) that can fail or become slow. We need fault tolerance patterns to prevent cascading failures, handle transient errors, and maintain system stability.

## Decision Drivers

* **Prevent cascading failures**: One slow service shouldn't bring down the entire system
* **Handle transient errors**: Temporary failures should be retried automatically
* **Protect resources**: Limit concurrent access to prevent resource exhaustion
* **Rate limiting**: Protect APIs from abuse and overload
* **Lightweight**: Minimal overhead in the happy path

## Considered Options

* **Resilience4j** - Lightweight, modular fault tolerance library
* **Hystrix** - Netflix circuit breaker (deprecated)
* **Sentinel** - Alibaba flow control component
* **Custom Implementation** - Hand-rolled retry and circuit breaker logic

## Decision Outcome

Chosen option: **Resilience4j**, because it's lightweight, modular, well-integrated with Spring Boot, and actively maintained as the successor to Hystrix.

### Patterns Implemented

#### 1. Circuit Breaker

Prevents repeated calls to failing services:

```java
@CircuitBreaker(name = "keycloak", fallbackMethod = "createUserFallback")
public String createUser(String email, String password) {
    return keycloakClient.createUser(email, password);
}

public String createUserFallback(String email, String password, Exception ex) {
    log.warn("Keycloak unavailable, user creation deferred: {}", email);
    return null;  // Graceful degradation
}
```

**Configuration:**
```yaml
resilience4j:
  circuitbreaker:
    instances:
      keycloak:
        sliding-window-size: 10
        failure-rate-threshold: 50
        wait-duration-in-open-state: 10s
        permitted-number-of-calls-in-half-open-state: 3
        record-exceptions:
          - java.io.IOException
          - java.net.SocketTimeoutException
```

#### 2. Retry

Automatically retries transient failures:

```java
@Retry(name = "externalApi")
@CircuitBreaker(name = "externalApi")  // Retry before circuit breaker
public Response callExternalApi(Request request) {
    return client.call(request);
}
```

**Configuration:**
```yaml
resilience4j:
  retry:
    instances:
      externalApi:
        max-attempts: 3
        wait-duration: 500ms
        exponential-backoff-multiplier: 2
        randomized-wait-factor: 0.5
        retry-exceptions:
          - java.io.IOException
        ignore-exceptions:
          - io.bitnomio.shared.domain.exception.ValidationException
```

#### 3. Rate Limiter

Limits request rate to protect services:

```java
@RateLimiter(name = "apiLimit")
public Response handleRequest(Request request) {
    return process(request);
}
```

**Configuration:**
```yaml
resilience4j:
  ratelimiter:
    instances:
      apiLimit:
        limit-for-period: 100
        limit-refresh-period: 1s
        timeout-duration: 0s
```

When limit exceeded, returns HTTP 429 (Too Many Requests).

#### 4. Bulkhead

Isolates resources to prevent exhaustion:

```java
@Bulkhead(name = "slowService", type = Bulkhead.Type.THREADPOOL)
public Response callSlowService(Request request) {
    return slowClient.call(request);
}
```

**Configuration:**
```yaml
resilience4j:
  bulkhead:
    instances:
      slowService:
        max-concurrent-calls: 10
        max-wait-duration: 500ms
  thread-pool-bulkhead:
    instances:
      slowService:
        max-thread-pool-size: 10
        core-thread-pool-size: 5
        queue-capacity: 100
```

### Consequences

**Good:**
* Lightweight with minimal overhead
* Modular - use only what you need
* Annotation-based for easy integration
* Metrics exposed via Actuator
* Well-documented with active community
* Functional programming support

**Bad:**
* Requires understanding of each pattern's use case
* Configuration can be verbose
* Fallback methods add code complexity
* Testing resilience scenarios requires setup

### Pattern Selection Guide

| Scenario | Pattern | Why |
|----------|---------|-----|
| External API calls | Circuit Breaker + Retry | Fail fast when service down, retry transient errors |
| Database calls | Circuit Breaker | Prevent connection pool exhaustion |
| Public API endpoints | Rate Limiter | Protect from abuse |
| Multiple external services | Bulkhead | Isolate each service's resources |
| Idempotent operations | Retry | Safe to retry without side effects |
| Non-idempotent operations | Circuit Breaker only | Don't retry, fail fast |

### Monitoring

Actuator endpoints expose resilience metrics:

```
/actuator/circuitbreakers      - Circuit breaker states
/actuator/retries              - Retry metrics
/actuator/ratelimiters         - Rate limiter metrics
/actuator/bulkheads            - Bulkhead metrics
```

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/resilience/` - Resilience configuration
* `documentation/PATTERNS.md` - Pattern decision guide
* Resilience4j documentation: https://resilience4j.readme.io/
