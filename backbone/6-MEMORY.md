# 6. Memory: coefficiency

Hard-won knowledge: traps, root causes and non-obvious lessons. Add a dated bullet under the right heading.

## Traps and pitfalls

- (migrated) **Flyway + SQLite `ALTER TABLE`:** `ALTER TABLE ADD COLUMN` rejects non-constant defaults such as `DEFAULT (datetime('now'))`. Only constant defaults (`DEFAULT ''`, `DEFAULT 0`, other literals) are allowed. A column that needs a function default must be defined in the initial `CREATE TABLE` (V1), not added later.
- (migrated) **`baselineOnMigrate(true)` skips V1:** when Flyway baselines a non-empty database (a restored dump), it marks V1 as applied without running it. Anything defined only in V1 (views, columns) is then missing. Add such elements in V2 or later, written to tolerate elements that already exist.
- (migrated) **Migrations must work across both histories:** a migration that adds a column with `ALTER TABLE` fails if a newer V1 `CREATE TABLE` already has that column. Test every migration on a fresh database (V1 runs) and on a restored dump (V1 baselined).
- (migrated) **Column additions that V1 may or may not have created** belong in the legacy `initSchema()` `ALTER TABLE` fallbacks (which skip duplicates), not in Flyway. Flyway migrations are best for additive `CREATE ... IF NOT EXISTS` changes (tables, views, indexes).
- (migrated, ADR-003) **`@BindBean` cannot bind typed value objects** (`Coef`, `Tariff`, ...) to SQL `double` columns. Flatten them in a binding helper (`ConsultantBindings`) instead of registering global argument factories.

## Lessons learned

- 2026-10-05: The project moved from the old Agentic Backbone framework to the agentic harness. Its tasks, PRDs, design and planning docs, decisions (now ADR-003 to ADR-007) and these lessons were carried over; the framework's hooks and scripts were removed.

- 2026-10-05: The first harness scan found 33 existing rule violations (23 blocking): `Jdbi` in four controllers and five application services, 13 test files with JUnit assertions, seven empty catch blocks and hard-coded UI text in three pages. Each has a task (6.1, 6.11 to 6.13) or is migrated when touched. The old task list did not show the spread: 6.1 named the wrong features. Rerun `harness.py scan` after each refactor.

## Open questions and contradictions

- 2026-10-05: The decision log started at D-008; D-001 to D-007 were not in the repository when it was migrated. If they matter, recover them from the old framework's history and add them as ADRs.
- 2026-10-05: Task 6.2 said controllers go under `infra/io/rest/`, while the architecture notes (now `2-PLANNING.md`) say `infra/rest/`. Settle it in the task's spec.
- 2026-10-05: 13 existing test files use JUnit assertions, although new tests use AssertJ (ADR-002). They are migrated when touched; `harness.py scan` lists them.
