# Architecture Decision Records (ADRs)

*Core architectural decisions for the backbone. See production docs for full context.*

## ADRs in This Set (1-12)

| # | Title | Status |
|---|-------|--------|
| [001](001-hexagonal-architecture.md) | **Hexagonal Architecture with DDD** | Accepted |
| [002](002-jdbi-persistence.md) | **JDBI for SQL-First Persistence** | Accepted |
| [003](003-java-records.md) | **Java Records over Lombok** | Accepted |
| [004](004-cqrs-lite.md) | **CQRS Lite Pattern** | Accepted |
| [005](005-outbox-pattern.md) | **Outbox Pattern** | Accepted |
| [006](006-idempotency.md) | **Idempotency Pattern** | Accepted |
| [007](007-rabbitmq.md) | **RabbitMQ for Messaging** | Accepted |
| [008](008-jsr330.md) | **JSR-330 for Framework Independence** | Accepted |
| [009](009-resilience4j.md) | **Resilience4j for Fault Tolerance** | Accepted |
| [010](010-hmac-auth.md) | **HMAC-SHA256 for Service Auth** | Accepted |
| [011](011-keycloak.md) | **Keycloak for User Management** | Accepted |
| [012](012-soft-delete.md) | **Soft Delete Strategy** | Accepted |

## Quick Navigation

### Architecture Foundation
- **[001: Hexagonal](001-hexagonal-architecture.md)** - Start here. 3-layer structure.

### Persistence & Data
- **[002: JDBI](002-jdbi-persistence.md)** - Why SQL-first
- **[003: Java Records](003-java-records.md)** - Immutable values
- **[012: Soft Delete](012-soft-delete.md)** - Logical deletion

### Patterns
- **[004: CQRS Lite](004-cqrs-lite.md)** - Read/write separation
- **[005: Outbox](005-outbox-pattern.md)** - Reliable events
- **[006: Idempotency](006-idempotency.md)** - Duplicate prevention
- **[009: Resilience4j](009-resilience4j.md)** - Circuit breaker, retry

### Security
- **[010: HMAC Auth](010-hmac-auth.md)** - Service authentication
- **[011: Keycloak](011-keycloak.md)** - OAuth2/OIDC

## For More Context

**Full production ADRs:** See `docs/NEW/architecture/adr/` (22+ ADRs)

This includes B2F-Proxy gateway decisions and more detailed consequences.

## Format

These follow [MADR 4.0.0](https://adr.github.io/madr/) format.

---

*Backbone purpose: Bootstrap a new service with production-proven patterns.*