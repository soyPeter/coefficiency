# coefficiency

Consultant management and COEF simulator: consultants, clients and billing, a tax engine (IRPF + Social Security), COEF and bonus calculations, reports. One service, `services/coeff`: a Jooby backend that serves a React SPA, backed by an encrypted SQLite database.

## Where things are

- **Work to do:** `TASKS.md`. Open items are the unchecked tasks under *Active Milestones* (M6 code-review remediation); `REVIEW.md` has the findings behind them.
- **Architecture, stack and conventions:** `docs/project/architecture.md` (read before changing code).
- **Product and design context:** `docs/project/prd/`, `docs/project/design/`, `docs/project/planning/`.
- **Decisions and lessons:** `docs/project/decisions.md`, `docs/project/lessons.md`.
- **Framework notes:** `docs/project/conventions/` (Java, Jooby, testing patterns, security checklist).

## Commands

```bash
./gradlew build                          # compile + unit tests
./gradlew :services:coeff:test           # unit tests
./gradlew :services:coeff:intTest        # integration tests (Testcontainers)
./gradlew :services:coeff:shadowJar      # fat jar, builds the frontend first
cd services/coeff/frontend && npm run dev     # frontend dev server (Vite)
cd services/coeff/frontend && npm run lint    # ESLint
bash scripts/secret-scan.sh --staged     # what CI runs (also base64-scan.sh)
```

## Working rules

- Mark a task `[WIP]` in `TASKS.md` when you start it and `[x]` when done; add new work there.
- Record architectural decisions in `docs/project/decisions.md` and non-obvious lessons in `docs/project/lessons.md`.
- Schema changes go through a new Flyway migration (`V<n>__description.sql`), never by editing an applied one.
- Conventional Commits: `type(scope): subject` with types `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`.
