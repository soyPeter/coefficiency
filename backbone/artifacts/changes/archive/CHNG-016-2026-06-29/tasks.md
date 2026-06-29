# Tasks — CHNG-016: Introduce Flyway for Schema Maintenance

## Metadata

- **Change:** CHNG-016
- **Type:** backend
- **Size:** M (4 sub-tasks)

## Task List

### T-001: [S] Add Flyway dependencies to build configuration
- Add `flyway-core` and `jooby-flyway` to `coeff-core` bundle in `libs.versions.toml`
- Add `jooby-flyway` and `flyway-core` to `coeff/build.gradle.kts` `dependencies` block
- REQ-FLY-001

### T-002: [M] Create V1 base migration SQL file
- Create `services/coeff/src/main/resources/db/migration/V1__initial_schema.sql`
- Include all CREATE TABLE statements from `SqliteConnection.initSchema()` DDL
- Include all CREATE INDEX and CREATE VIEW statements
- Verify the SQL file matches the exact current schema
- REQ-FLY-002

### T-003: [M] Wire Flyway in SqliteConnection and remove initSchema() DDL
- Configure Flyway `DataSource` pointing to `coeff.db` path
- Call `flyway.migrate()` after JDBI creation in `SqliteConnection.init()`, before `initSchema()`
- Remove CREATE TABLE, CREATE INDEX, CREATE VIEW DDL from `initSchema()`
- Keep ALTER TABLE migration statements as fallback
- REQ-FLY-003, REQ-FLY-004, REQ-FLY-008

### T-004: [S] Wire Flyway in AuthController.setup()
- Add `Flyway` bean injection to `AuthController`
- Call `flyway.migrate()` after `dbEncryption.createKeyFile()` and before `dbEncryption.encrypt()`
- REQ-FLY-005

### T-005: [S] Wire Flyway after dump restore
- Add `Flyway` bean injection to `AdminService`
- Trigger `flyway.migrate()` after `sqliteConnection.reinit()` at end of restore methods
- REQ-FLY-006, REQ-FLY-007

## Verification

1. Fresh `rm -rf services/coeff/data/` → start app → setup wizard → verify all tables created via Flyway (check `flyway_schema_history` table)
2. Login → logout → re-login → verify Flyway doesn't re-run migrations (checksums match)
3. Create a new dump → restore it → verify data survives and schema is intact
4. Import a Javalin-format dump → verify schema is baselined by Flyway after reinit
