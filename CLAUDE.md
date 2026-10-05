@AGENTS.md

# coefficiency: Claude Code notes

Consultant management and COEF simulator: one service, `services/coeff`, a Jooby backend that serves a React SPA, on an encrypted SQLite database.

- **Project knowledge:** `backbone/` (start with `backbone/0-START-HERE.md`). Stack and rules: `backbone/4-KNOWLEDGE.md` and ADR-002.
- **Work:** `backbone/3-TASKS.md`. The M6 findings behind the open tasks are in `REVIEW.md`.
- **Reference notes:** `docs/project/` (PRDs, design, planning, framework conventions); the frontend design system is `DESIGN.md`.
- **Build needs a Java 21 JDK** (`./gradlew build`). The frontend needs Node (`services/coeff/frontend`).
