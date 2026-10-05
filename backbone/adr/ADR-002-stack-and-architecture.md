# ADR-002: Stack and architecture: Java 21, Jooby, Avaje Inject, JDBI on encrypted SQLite, React 19

## Status
Accepted

## Date
2026-10-05

## Context
coefficiency is a single-user desktop tool that runs a local HTTP server and keeps sensitive consultant and salary data on the user's machine (see `1-PRD.md`). The stack below was chosen when the project was generated and has been in use through milestones M1 to M8. This ADR records it so specs can reference it and the harness can adopt the matching catalog packs. It documents the decisions in place; it does not change them.

## Decision
- **Language and build:** Java 21, built with Gradle (Kotlin DSL, version catalog) into a Shadow fat jar that bundles the frontend.
- **Web and DI:** Jooby 4.5 on Netty with MVC annotations; Avaje Inject for compile-time DI and AOP. No CDI, no Jakarta EE, no JAX-RS, no Spring.
- **Persistence:** SQLite, encrypted at rest (AES-256-GCM); JDBI 3, SQL-first, with no ORM; schema changes only through Flyway migrations (ADR-007).
- **Architecture:** package by feature, each feature layered `domain/` (framework-free), `app/` (use cases and ports, no framework code) and `infra/` (all framework code, REST controllers in `infra/rest/`).
- **Tests:** JUnit 5 with AssertJ for new tests, Mockito at ports, Testcontainers for integration tests.
- **Boilerplate:** records and explicit constructors; no Lombok.
- **Frontend:** React 19, TypeScript, Vite, TanStack Query and Table, EN/ES i18n with English keys.

Harness catalog packs implied by this decision:
- `java` with options `gradle`, `junit5-assertj` and `no-lombok`.
- `jdbi` with options `no-orm`, `hexagonal-layers` and `flyway`.
- No pack exists for Jooby, Avaje Inject, SQLite or React; they are covered by project skills (`jooby`, `sqlite`, `frontend`). The `quarkus` and `container` packs do not apply (no Quarkus, no container images).

## Alternatives considered
- Spring Boot with JPA: heavier runtime and startup for a desktop tool, and an ORM conflicts with the SQL-first, explicit-persistence approach (ADR-003).
- Quarkus: strong for services, but CDI and its build model add little to a single local process; Jooby with Avaje gives compile-time wiring with a smaller footprint.
- PostgreSQL or another server database: needs a separate process and administration, which a single-user desktop tool should not require.

## Consequences
- Agents load the `java`, `java-test` and `jdbi` skills (adopted packs) and the `jooby`, `sqlite` and `frontend` project skills for the matching paths.
- Guardrails block CDI, JAX-RS, Lombok, ORM imports, JUnit assertions in new tests, framework imports in `domain/` and `app/`, and `Jdbi` in controllers.
- Existing code that predates these rules (13 test files with JUnit assertions, features not yet layered) is migrated through the open M6 tasks, not all at once.
- A Java 21 JDK is required on every machine that builds or tests the project.
