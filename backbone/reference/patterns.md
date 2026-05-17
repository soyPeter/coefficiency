# Architectural Patterns

*Reference guide for architectural patterns and design decisions. See ADRs for detailed context.*

---

## Universal Patterns

Applicable to any tech stack. These are copied to every new project.

| Pattern | ADR | When to Use |
|---------|-----|-------------|
| [Hexagonal Architecture](patterns/adr/001-hexagonal-architecture.md) | 001 | Foundational — always |
| [CQRS Lite](patterns/adr/004-cqrs-lite.md) | 004 | Read/write separation |
| [Outbox Pattern](patterns/adr/005-outbox-pattern.md) | 005 | Reliable events |
| [Idempotency](patterns/adr/006-idempotency.md) | 006 | Duplicate prevention |
| [RabbitMQ](patterns/adr/007-rabbitmq.md) | 007 | Async messaging |
| [HMAC Auth](patterns/adr/010-hmac-auth.md) | 010 | Service-to-service auth |
| [Keycloak](patterns/adr/011-keycloak.md) | 011 | OAuth2/OIDC |
| [Soft Delete](patterns/adr/012-soft-delete.md) | 012 | Logical deletion |

## Java/JVM Patterns

Only applicable to Quarkus, Spring Boot, and Kotlin projects. Copied by `init-backbone.sh` for Java-based frameworks only. Located in `patterns/adr/java/`.

| Pattern | ADR | When to Use |
|---------|-----|-------------|
| [JDBI Persistence](patterns/adr/java/002-jdbi-persistence.md) | 002 | SQL-first control |
| [Java Records](patterns/adr/java/003-java-records.md) | 003 | Value objects, DTOs |
| [JSR-330](patterns/adr/java/008-jsr330.md) | 008 | Framework independence |
| [Resilience4j](patterns/adr/java/009-resilience4j.md) | 009 | Fault tolerance |

---

## Pattern Selection Guide

### Architecture Foundation

Use these first for any new service:

1. **Hexagonal (001)** — Clean separation domain/app/infra
2. **Idempotency (006)** — Protect against duplicates from day one

### Data & Persistence

- **CQRS Lite (004)** — High read traffic, separate replicas
- **Soft Delete (012)** — Audit trail required
- **JDBI (002)** _(Java only)_ — When you need SQL-first control

### Reliability & Events

- **Outbox (005)** — Reliable event publishing
- **RabbitMQ (007)** — Async messaging backbone
- **Resilience4j (009)** _(Java only)_ — Circuit breaker, retry, bulkhead

### Security

- **HMAC (010)** — Service-to-service calls
- **Keycloak (011)** — User identity, OAuth2

### Java/JVM Specific

- **Java Records (003)** — Immutable DTOs and value objects
- **JSR-330 (008)** — Use `@Named`, not `@Service`/`@Component`

---

## Development Guides

- **Service Creation**: `backbone/reference/create-service.md`
- **Development Guidelines**: `backbone/reference/development-guidelines.md`
- **Your Framework Conventions**: `backbone/reference/conventions/<framework>.md`

---

*For full ADR context, see the ADR files in `patterns/adr/`.*
