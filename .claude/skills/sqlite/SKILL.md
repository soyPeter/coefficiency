---
name: sqlite
description: Write or review SQLite schema, Flyway migrations and SQLite-specific SQL in coefficiency - constant-default ALTER TABLE, idempotent migrations that work on fresh databases and restored dumps, baselineOnMigrate traps, encryption at rest. Use for db/migration files and Sqlite* classes.
applies-to: sqlite 3.49, flyway 11, coefficiency
last-verified: 2026-10-05
sources: coefficiency decisions D-012 (ADR-007) and lessons (6-MEMORY.md)
---

# SQLite and migrations in coefficiency

The accepted ADRs and `backbone/4-KNOWLEDGE.md` override this skill. Background: ADR-007 and the traps in `backbone/6-MEMORY.md`.

## Migration rules

1. Every schema change is a **new** Flyway migration `V<n>__<description>.sql` (English, snake_case) in `services/coeff/src/main/resources/db/migration/`. Never edit an applied migration.
2. Use `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS` and `CREATE VIEW IF NOT EXISTS`, so migrations stay idempotent.
3. `ALTER TABLE ADD COLUMN` accepts **only constant defaults** (`DEFAULT ''`, `DEFAULT 0`). For a function default such as `datetime('now')`, leave the column nullable and fill it in code, or define it in a `CREATE TABLE`.
4. `baselineOnMigrate(true)` marks V1 as applied on restored dumps **without running it**. Anything added to the schema must also exist for a baselined database: add it in V2 or later with `IF NOT EXISTS`.
5. A column that V1 may or may not contain must not be added by a Flyway `ALTER TABLE` (it fails as a duplicate on one of the two histories). Use the legacy `initSchema()` fallback for that case, and record why in the task's spec.
6. SQLite has limited `ALTER TABLE` (no drop or alter of constraints on older versions). Structural changes use the table-rebuild pattern inside one migration: create the new table, copy, drop the old one, rename, recreate indexes and views.

## Testing a migration

- Run it against a **fresh database** (all migrations from V1) and against a **restored dump** (V1 baselined).
- Assert the resulting schema (columns, indexes, views) in an integration test. Tests use a real SQLite database, not mocks.

## Data and SQL

- Tables and columns are English snake_case; booleans are `INTEGER` 0/1; dates are ISO-8601 `TEXT` in UTC.
- Money and rates are stored as typed value objects flattened by binding helpers (ADR-003); never format numbers in SQL.
- Add an index for every foreign key and every column used in `WHERE` or `ORDER BY` on large tables.
- Bind every value (`:name` parameters); never concatenate input into SQL.

## Encryption at rest

- The database file is encrypted with AES-256-GCM (`DbEncryption`). Never write decrypted copies, dumps or temporary files outside the app's managed paths, and never log query parameters that contain personal or salary data.
- Backups and dumps go through the admin module, which handles encryption and Flyway after restore.

## Linked skills
- `jdbi`: repositories, binding and row mapping on top of this schema.
- `security`: personal and salary data, encryption and logging rules.
- `module-testing`: migration and repository tests on a real database.
