---
id: CHNG-016
title: Introduce Flyway for schema maintenance
status: closed
grilled: true
type: backend
---

# Introduce Flyway for Schema Maintenance

## Problem Statement

The current schema management relies on inline JDBC calls in `SqliteConnection.initSchema()` with mixed DDL and ALTER TABLE migration statements. Schema changes are tracked programmatically rather than declaratively, making it hard to version, audit, or reproduce migrations across environments. The `AdminService.migrateSchema()` duplicates some of these migrations for dump restore compatibility. There is no single source of truth for the schema definition.

## Grilling

### Scope

- **Q:** What exactly should this feature do?
- **A:** Add Flyway for full schema management — all tables, indexes, views, and future migrations. Replace the DDL portion of `SqliteConnection.initSchema()`. Wire Flyway to run at startup after database decryption.
- **Q:** What should it NOT do?
- **A:** It should NOT manage the encryption layer (`.db-key`, `app.db.enc` lifecycle). It should NOT manage seed data — only schema. It should NOT remove the legacy ALTER TABLE fallbacks yet.
- **Q:** What's the smallest slice that would be valuable?
- **A:** V1 base migration capturing the current schema as-is + Flyway wired at startup, replacing `initSchema()` DDL. Legacy ALTER TABLEs kept as fallback.

### Boundaries

- **Q:** What are the integration points with existing code?
- **A:** `SqliteConnection.initSchema()` — replace its DDL section. `SqliteConnection.init()` — add Flyway migrate call after JDBI creation. `AuthController.setup()` — add Flyway migrate after `createKeyFile()`. `AdminService.restoreDump*()` — Flyway will handle the schema after dump restore (via `reinit()`).
- **Q:** Which modules will this touch?
- **A:** `shared/db/SqliteConnection.java` (DDL removed from initSchema). `shared/db/` (new Flyway wiring). `build.gradle.kts` (add flyway-core + jooby-flyway deps). New migration files in `resources/db/migration/`. Other modules unaffected.
- **Q:** Are there parts we should NOT modify?
- **A:** Do NOT touch DbEncryption, AuthService, domain layer, frontend. Do NOT change the schema content — V1 = exact current schema.

### Data & State

- **Q:** What new data structures are needed?
- **A:** No new tables. Flyway's own schema history table (`flyway_schema_history`) will be created automatically in the SQLite database.
- **Q:** Where does state live?
- **A:** Schema state lives in Flyway's `flyway_schema_history` table inside the decrypted `coeff.db`. The encryption layer (DbEncryption) handles the lifecycle — Flyway runs against the already-decrypted database.
- **Q:** What are the read/write patterns?
- **A:** Flyway reads the schema history table on every `migrate()` call to determine pending migrations. It writes the schema history table after each migration. Migrations are run at startup (post-decrypt) and after setup.

### API

- **Q:** What endpoints or interfaces are needed?
- **A:** No new API endpoints. Flyway is triggered programmatically via `Flyway.migrate()`. The `jooby-flyway` module provides the Flyway bean, but auto-run is disabled — we trigger manually post-decrypt.
- **Q:** How is Flyway triggered?
- **A:** Via `jooby-flyway` module for DI, with auto-run disabled. Manual `flyway.migrate()` call in `SqliteConnection.init()` after JDBI creation (post-decrypt). Also called in `AuthController.setup()` after `createKeyFile()` initializes the DB.
- **Q:** What happens if a migration fails?
- **A:** Flyway wraps each migration in a transaction. On failure, the migration is rolled back and the app fails to start. The error propagates up through Jooby's exception handling.

### Implementation Order

- **Q:** What's the first vertical slice?
- **A:** Add Flyway dependencies → Create V1 base migration SQL → Wire Flyway in SqliteConnection → Replace initSchema() DDL with Flyway call → Verify app starts and creates schema.
- **Q:** What are the dependencies between slices?
- **A:** V1 must exist before Flyway can run. Flyway must be wired before initSchema DDL can be removed. AdminService.migrateSchema() removal is a separate follow-up.
- **Q:** What are the highest-risk parts?
- **A:** Timing: Flyway must run after DB decryption, not before. Setup flow: Flyway must create `flyway_schema_history` in the fresh DB during setup, before encryption. Dump restore: restored DB must match V1 schema for Flyway to recognize it.

## Requirements

- **REQ-FLY-001**: `build.gradle.kts` must include `flyway-core` and `jooby-flyway`. The `coeff-core` bundle in `libs.versions.toml` must include both libraries.
- **REQ-FLY-002**: A `V1__initial_schema.sql` file must be created under `src/main/resources/db/migration/` containing all CREATE TABLE statements, indexes, and views from the current `initSchema()` DDL, in a single migration.
- **REQ-FLY-003**: `SqliteConnection.init()` must configure Flyway with `coeff.db` as the target and call `flyway.migrate()` after JDBI creation. The Flyway bean must be provided via `jooby-flyway` module with auto-run disabled.
- **REQ-FLY-004**: The DDL portion of `SqliteConnection.initSchema()` (CREATE TABLE, CREATE INDEX, CREATE VIEW) must be removed. The ALTER TABLE migration statements must remain as a fallback for pre-Flyway databases.
- **REQ-FLY-005**: `AuthController.setup()` must call `flyway.migrate()` after `createKeyFile()` and before `encrypt()`, so the fresh database has the full schema before being encrypted.
- **REQ-FLY-006**: `AdminService.restoreDumpBackup()` and `restoreDumpFromUpload()` must trigger Flyway migration after the dump SQL executes, ensuring `flyway_schema_history` is populated and the schema matches expectations.
- **REQ-FLY-007**: The `AdminService.migrateSchema()` method must be retained for dump restore compatibility with pre-Flyway databases. Its removal is deferred to a follow-up change.
- **REQ-FLY-008**: Flyway must NEVER be triggered when the database is in encrypted state (`app.db.enc`). It must only run against the decrypted `coeff.db`.
