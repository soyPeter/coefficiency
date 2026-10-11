# 3. Tasks: coefficiency

The task index. Each task has a spec in `backbone/specs/<id>.md` and goes through the pipeline in `8-WORKFLOW.md`. Only one task may be `[WIP]` at a time. Edit lines in place.

Migrated from the old `TASKS.md` on 2026-10-05. The completed history of M1 to M8 (about 150 tasks) is in git: `git show 08ac6d6:TASKS.md`. Sizes in brackets are the original estimates (XS to L).

## Milestones

| Milestone | Status | Description |
|---|---|---|
| M1 Project bootstrap | done | Scaffold, build, first commit |
| M2 Core platform | done | Jooby/SQLite backend, React SPA shell, i18n |
| M3 Security | done | Auth, HMAC tokens, AES-256-GCM DB encryption |
| M4 Consultant management | done | CRUD, billing, clients, CSV import |
| M5 COEF simulator | done | Tax engine (IRPF + SS), COEF calculation, fiscal config |
| M6 Code-review remediation | in progress (about 85%) | Findings in `REVIEW.md`: layering, oversized frontend files, simulation history |
| M7 Javalin feature parity | done | Typed value objects, MoM billing, bonus UI, forecast/YoY, hooks, i18n parity |
| M8 Flyway schema management | done | Inline DDL replaced by Flyway migrations |
| M9 Test coverage | planned | Integration tests for the main controllers, first frontend component tests |

## M6: Code-review remediation

Findings and context: `REVIEW.md`.

- [ ] **Task 6.1: Move Jdbi injection from controllers into the service layer (auth, billing, client)** [S] (spec: backbone/specs/6.1.md)
  Scan 2026-10-05: auth, billing and client controllers no longer import `Jdbi` (their services do; see 6.5 to 6.7). Still importing it: `ConsultantController`, `SimulatorController`, `ConceptsController`, `SettingsController`.
- [ ] **Task 6.2: Unify controller package locations** [S] (spec: backbone/specs/6.2.md)
  Open question for its spec: the old task said `infra/io/rest/`, while the architecture notes say `infra/rest/`.
- [ ] **Task 6.3: Split the oversized SimulatorPage (878 lines) into sub-components** [M] (spec: backbone/specs/6.3.md)
  Check first: on 2026-10-05 the file was 593 lines, so it may be partly done; ConsultantsPage (1000) and ConfigPage (973) are now larger.
- [ ] **Task 6.4: Split the oversized useIdleTimer hook (387 lines) into smaller hooks** [M] (spec: backbone/specs/6.4.md)
  On 2026-10-05 `frontend/src/hooks/useIdleTimer.ts` was 141 lines.
- [ ] **Task 6.5: Apply domain/app/infra layering to the auth feature** [M] (spec: backbone/specs/6.5.md)
- [ ] **Task 6.6: Apply domain/app/infra layering to the billing feature** [M] (spec: backbone/specs/6.6.md)
- [ ] **Task 6.7: Apply domain/app/infra layering to the client feature** [M] (spec: backbone/specs/6.7.md)
- [ ] **Task 6.8: Apply domain/app/infra layering to the simulator feature** [M] (spec: backbone/specs/6.8.md)
- [ ] **Task 6.9: Apply domain/app/infra layering to the doc and file-import features** [S] (spec: backbone/specs/6.9.md)
- [ ] **Task 6.10: Simulation history: simulations table and save, list and delete endpoints** [S] (spec: backbone/specs/6.10.md)

Found by the harness scan on 2026-10-05 (`python3 scripts/harness/lib/harness.py scan`):

- [ ] **Task 6.11: Move Jdbi out of the application services in admin, bonusbreakdown, quarterlybonus, report and tenurebonus** (ports in `app/`, JDBI adapters in `infra/`) (spec: backbone/specs/6.11.md)
- [ ] **Task 6.12: Review the empty catch blocks** in CoeffConfig, AdminService, AdminController, AuthController, Consultant, DbEncryption and one more (`scan` lists them); handle, translate or document each (spec: backbone/specs/6.12.md)
- [ ] **Task 6.13: Replace hard-coded UI text with i18n keys** in BillingSummaryPage, ConfigPage and ConsultantsPage (spec: backbone/specs/6.13.md)

## M9: Test coverage

The old list had "integration tests for AuthController and SimulatorController" as a separate item; it is covered by 9.1 and 9.3.

- [ ] **Task 9.1: Integration tests for the AuthController endpoints** [S] (spec: backbone/specs/9.1.md)
- [ ] **Task 9.2: Integration tests for ConsultantController CRUD** [S] (spec: backbone/specs/9.2.md)
- [ ] **Task 9.3: Integration tests for the SimulatorController endpoints** [S] (spec: backbone/specs/9.3.md)
- [ ] **Task 9.4: Frontend component tests for LoginPage and SimulatorPage** [S] (spec: backbone/specs/9.4.md)
  Needs an ADR first: the frontend has no test runner yet (no Vitest or Jest in `package.json`).

<!-- One line per task; the status marker sits on the task line:
- [ ] **Task 1.1: <title>** (spec: backbone/specs/1.1.md)
Start = change it to "- [WIP]" (needs a valid, grilled, user-approved spec).
Finish = change it to "- [x]" (needs a judge pass on the current code). -->

## Status markers

| Marker | Meaning |
|---|---|
| `[ ]` | Defined or being defined (spec, ADRs, grilling, approval) |
| `[WIP]` | Being built and judged; at most one task |
| `[x]` | Done: judge passed, Definition of Done met |
