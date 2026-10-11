# ADR-007: All schema changes go through Flyway

## Status
Accepted

## Date
Before 2026-10-05 (migrated from decision D-012; the original date was not recorded)

## Context
The schema used to be managed with inline JDBC DDL in `SqliteConnection.initSchema()` plus ad-hoc `ALTER TABLE` statements. That made versioning, auditing and reproducibility across environments difficult. Importing Javalin-format dumps crashed on schema mismatches (missing columns and views). Flyway was introduced through `jooby-flyway` with `baselineOnMigrate(true)`, to handle both fresh databases and restored dumps.

## Decision
- Every schema change (tables, columns, indexes, views, `ALTER TABLE`) is a Flyway migration, `V<n>__<description>.sql` in `src/main/resources/db/migration/`.
- The inline `initSchema()` fallbacks and `AdminService.migrateSchema()` are legacy compatibility only, never used for new changes.
- SQLite constraints apply:
  - `ALTER TABLE ADD COLUMN` takes only constant defaults;
  - use `CREATE ... IF NOT EXISTS`;
  - test against fresh databases and restored dumps (`6-MEMORY.md`).

## Alternatives considered
- Keeping inline DDL: no extra dependency, but no versioning, and failures stay silent (e.g. `NOT NULL DEFAULT` on populated tables).
- Liquibase: comparable, but heavier, and Jooby ships a Flyway module.

## Consequences
- Migration files are the single source of truth for the schema, versioned and reviewable.
- Every schema change is tested on a fresh database and on a restored dump.
- The legacy fallbacks remain until a later task removes them.
