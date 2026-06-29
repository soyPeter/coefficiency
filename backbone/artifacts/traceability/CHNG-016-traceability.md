# Traceability Matrix — CHNG-016: Introduce Flyway for Schema Maintenance

| REQ ID | Requirement | Code | Test | Status |
|--------|-------------|------|------|--------|
| REQ-FLY-001 | Add Flyway dependencies | `build.gradle.kts` (jooby-flyway, flyway-core) | Build compiles | ✓ |
| REQ-FLY-002 | Create V1 base migration | `V1__initial_schema.sql` | N/A (SQL file) | ✓ |
| REQ-FLY-003 | Wire Flyway at startup | `SqliteConnection.init()` (Flyway.migrate()) | 84 tests pass | ✓ |
| REQ-FLY-004 | Replace initSchema() DDL | `SqliteConnection.java` (DDL removed, ALTER kept) | 84 tests pass | ✓ |
| REQ-FLY-005 | Wire Flyway in setup flow | Handled by `authRepository.exists()` → `SqliteConnection.init()` | 84 tests pass | ✓ |
| REQ-FLY-006 | Wire Flyway after dump restore | Handled by `sqliteConnection.reinit()` → `init()` | Dump restore verified | ✓ |
| REQ-FLY-007 | Keep migrateSchema() fallback | `AdminService.migrateSchema()` retained | N/A | ✓ |
| REQ-FLY-008 | Flyway only after decryption | `Flyway.migrate()` in `init()` (post-reinit) | 84 tests pass | ✓ |

## NCR/CAPA Closure

| NCR | CAPA | Root Cause | Fix | Status |
|-----|------|------------|-----|--------|
| NCR-004 | CAPA-004 | Javalin dump missing created_at/updated_at | migrateSchema() fallback + @Nullable ConsultantRow | ✓ closed |
| NCR-005 | CAPA-005 | Flyway fails on non-empty schema without history | baselineOnMigrate(true) | ✓ closed |
| NCR-006 | CAPA-006 | ALTER TABLE NOT NULL silently fails on populated tables | NOT NULL removed; @Nullable in ConsultantRow | ✓ closed |
| NCR-007 | CAPA-007 | V1 baseline skips views; NOT NULL ALTER fails | V2__add_views.sql; DEFAULT-only ALTER | ✓ closed |
| NCR-008 | CAPA-008 | Unicode escape inconsistencies in frontend | Standardized \u20AC/\u2014/\u00D7 to literal characters | ✓ closed |
| NCR-009 | CAPA-009 | Reports tab NPE on null sortBy | Null guards + HashMap instead of Map.of() | ✓ closed |
