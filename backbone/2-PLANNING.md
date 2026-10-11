# 2. Planning: coefficiency

## Architecture style
A single service (`services/coeff`) with hexagonal layering **per feature** (package by feature, then `domain/`, `app/`, `infra/`), a Jooby REST layer, and a React SPA bundled into the same fat jar. The stack and its rules are recorded in [ADR-002](adr/ADR-002-stack-and-architecture.md).

## Structure
```text
services/coeff/
├── src/main/java/io/bitnomio/coeff/<feature>/   # package by feature
│   ├── domain/        # framework-free types and rules
│   ├── app/           # use cases and ports; services own data access
│   └── infra/rest/    # Jooby controllers and DTOs (all framework code lives in infra/)
├── src/main/resources/       # application.conf, logback.xml, db/migration (Flyway)
├── src/test/java/...         # unit tests (JUnit 5, AssertJ, Mockito)
└── frontend/src/             # React 19 + TypeScript: pages, components, hooks, i18n, api.ts
gradle/libs.versions.toml     # version catalog
build-tools/                  # checkstyle, spotbugs, dependency-check suppressions
scripts/                      # secret-scan.sh, base64-scan.sh (CI), service generator, worktree setup
REVIEW.md                     # code-review findings behind the open M6 tasks
DESIGN.md                     # frontend design system (colours, typography, components)
```

Features: `admin`, `auth`, `billing`, `bonusbreakdown`, `client`, `consultant`, `doc`, `file`, `quarterlybonus`, `report`, `simulator`, `tenurebonus`, plus `shared`. The older features `auth`, `client`, `file` and `simulator` don't follow the layered layout yet (open M6 tasks).

## Main flows
- **Request:** the SPA calls `/api/*` → `AuthFilter` checks the HMAC token → a Jooby controller in `infra/rest` → an application service → repositories (JDBI) on the encrypted SQLite database.
- **Startup:** Avaje Inject wires the beans → the DB file is decrypted → Flyway migrates the schema (`baselineOnMigrate` for restored dumps) → Jooby serves the API and the static SPA.
- **Simulation:** the simulator page sends a 26-field input → `TaxEngine` (IRPF dual brackets, family deductions, SS categories) → COEF result, optionally persisted to the consultant.
- **Import and backup:** CSV import with validation and deduplication; backup, dump and restore through the admin module.

## External dependencies
None at runtime besides the local filesystem. Testcontainers is used for integration tests.
