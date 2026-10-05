# Architecture & Conventions

## Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Jooby 4.5 (Netty), Avaje Inject, Jackson |
| Persistence | SQLite (AES-256-GCM encrypted at rest), JDBI 3, Flyway migrations (`services/coeff/src/main/resources/db/migration`) |
| Security | HMAC-signed tokens, BCrypt passwords (see `docs/project/design/20260515-security-design.md`) |
| Frontend | React 19, TypeScript, Vite 7, TanStack Query + Table, i18n (English keys) |
| Build | Gradle (Kotlin DSL, version catalog `gradle/libs.versions.toml`), Shadow jar bundles the frontend |
| Tests | JUnit 5, Mockito, AssertJ, Testcontainers; separate `intTest` source set |

## Layout

```
services/coeff/
├── src/main/java/io/bitnomio/coeff/<feature>/   # package by feature
│   ├── domain/        # framework-free types and rules
│   ├── app/           # use cases, ports
│   └── infra/rest/    # Jooby controllers and DTOs (all framework code lives in infra/)
├── src/main/resources/       # application.conf, logback.xml, db/migration
├── src/test/java/...         # unit tests
└── frontend/src/             # pages, components, hooks, i18n, api.ts
```

Features: `admin`, `auth`, `billing`, `bonusbreakdown`, `client`, `consultant`, `doc`, `file`, `quarterlybonus`, `report`, `simulator`, `tenurebonus`, plus `shared`. Some older features (`auth`, `client`, `file`, `simulator`) don't follow the layered layout yet; see the M6 tasks in `TASKS.md`.

## Layer rules

- `domain/`: no Jooby, Jakarta, JDBI or Jackson imports.
- `app/`: use cases and ports; no framework annotations. Services own data access (controllers don't receive `Jdbi`).
- `infra/`: all framework code. REST controllers live in `<feature>/infra/rest/`.

## Naming: English only

All identifiers are English: classes, methods, variables, constants, packages, files, DB tables and columns, API endpoints, environment variables, i18n keys. Comments may be bilingual; code may not.

| What | Rule | Good | Bad |
|---|---|---|---|
| Classes | PascalCase | `ConsultantService` | `ServicioConsultor` |
| Methods / variables | camelCase | `calculateCoef()` | `calcularCoef()` |
| Constants / env vars | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` | `MAX_INTENTOS` |
| Packages | lowercase | `io.bitnomio.coeff.billing` | `io.bitnomio.coeff.facturacion` |
| DB tables / columns | snake_case | `created_at` | `fecha_creacion` |
| API endpoints | kebab-case | `/api/file-import` | `/api/importar-archivo` |
