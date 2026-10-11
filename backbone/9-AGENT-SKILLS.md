# 9. Agent Skills: coefficiency

Skills in `.claude/skills/`. Format and routing: `backbone/SKILLS.md`. Routes: `backbone/routing.conf`.

## Harness core skills

| Skill | Use for |
|---|---|
| `requirements-writing` | Specs: requirements and Given/When/Then acceptance criteria |
| `adr-writing` | Architecture Decision Records |
| `architecture` | Layers, boundaries, dependency direction, design reviews (`review.md`) |
| `api-design` | HTTP APIs: resources, status codes, errors, versioning, compatibility |
| `openapi` | OpenAPI contracts kept in sync with the code |
| `code-quality` | Readable, maintainable code; routed to all source files; judge checklist |
| `module-testing` | Test method, AC traceability, determinism; routed to tests; judge checklist |
| `security` | Input, injection, authN/authZ, secrets, data exposure; judge checklist |
| `changelog` | Release notes from Conventional Commits (on demand) |

Stack skills come from catalog packs adopted after the stack ADR (`harness.py catalog`, `harness.py adopt`). List them below with the ADR that chose them.

## Stack and project skills

| Skill | From (pack + ADR, or project) | Use for | Routed to |
|---|---|---|---|
| `java` | pack `java` (ADR-002) | Java language rules | every `.java` file, ADRs |
| `java-test` | pack `java`, option `junit5-assertj` (ADR-002) | JUnit 5 + AssertJ tests | `src/test`, `src/intTest` |
| `java-review` | pack `java` (ADR-002) | Java review checklist for the judge | on demand |
| `jdbi` | pack `jdbi` (ADR-002) | JDBI repositories, row mapping, migrations | persistence adapters, `db/migration` |
| `jooby` | project | Jooby MVC, Avaje Inject wiring, error mapping | `infra/`, application setup |
| `sqlite` | project | SQLite schema and Flyway constraints, encryption at rest | `db/migration`, `Sqlite*` classes |
| `frontend` | project | React SPA: api.ts, TanStack Query, i18n parity, forms, UI rules | `services/coeff/frontend/src` |
