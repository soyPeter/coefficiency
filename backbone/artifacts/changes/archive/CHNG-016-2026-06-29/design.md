---
id: CHNG-016
title: Introduce Flyway for schema maintenance
parent: none
---

# Design: Introduce Flyway for Schema Maintenance

## C4 Model

### Context (Level 1)

```
┌──────────────────────────────────────────────────────┐
│                    coeff Application                   │
│                                                        │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐            │
│  │ Jooby   │  │ Flyway   │  │ DbEncrypt │            │
│  │ Router  │  │ (migrate)│  │ (encrypt) │            │
│  └────┬────┘  └────┬─────┘  └─────┬─────┘            │
│       │            │              │                    │
│       ▼            ▼              ▼                    │
│  ┌──────────────────────────────────────┐             │
│  │          SQLite (coeff.db)           │             │
│  │  ┌──────────────────────────────┐   │             │
│  │  │ flyway_schema_history        │   │             │
│  │  │ users, consultants, settings │   │             │
│  │  │ cost_concepts, bonuses, ...  │   │             │
│  │  └──────────────────────────────┘   │             │
│  └──────────────────────────────────────┘             │
└──────────────────────────────────────────────────────┘
```

### Container (Level 2) — Startup Sequence

```
App Start
   │
   ▼
SqliteConnection.init()
   │
   ├── Create SQLiteDataSource (jdbc:sqlite:coeff.db)
   ├── Create Jdbi instance
   ├── Install SqlObjectPlugin
   │
   ├── [NEW] Flyway.migrate() ──────────────► runs V1__initial_schema.sql
   │                                              │
   │                                              ├── CREATE TABLE IF NOT EXISTS
   │                                              ├── CREATE INDEX
   │                                              └── CREATE VIEW
   │
   └── [REMOVED] initSchema() DDL section
       [KEPT] ALTER TABLE migration fallbacks
```

### Container — Setup Flow

```
POST /api/auth/setup
   │
   ├── dbEncryption.createKeyFile(password)
   ├── authRepository.save(username, hash)
   │
   ├── [NEW] Flyway.migrate()  ─────────────► schema created in coeff.db
   │
   ├── dbEncryption.encrypt()  ─────────────► coeff.db → app.db.enc
   └── dbEncryption.startPeriodicSync()
```

### Container — Dump Restore Flow

```
POST /api/admin/backups/dump/*/restore
   │
   ├── Execute dump SQL
   ├── Execute usersSql
   ├── migrateSchema(stmt)  [fallback]
   │
   ├── dbEncryption.encrypt()
   ├── dbEncryption.decryptDirect()
   │
   └── sqliteConnection.reinit()
          │
          └── [NEW] Flyway.migrate()  ←─ baselines if schema history missing
```

## Architecture Decisions

### ADR-001: Use Flyway over Liquibase

**Status:** Accepted

**Context:** The version catalog already has `flyway-core` and `jooby-flyway`. The Jooby ecosystem provides first-class Flyway integration via `jooby-flyway` module.

**Decision:** Use Flyway. Jooby's `flyway()` extension method configures the Flyway bean automatically.

**Consequences:** No additional dependency management. Flyway's SQL-based migrations are simpler for this project's scale than Liquibase XML/YAML.

### ADR-002: Programmatic trigger, not auto-run

**Status:** Accepted

**Context:** `jooby-flyway` auto-runs on `onStarted`, but the database is encrypted at that point (only `app.db.enc` exists). Flyway needs to run against the decrypted `coeff.db`.

**Decision:** Disable `jooby-flyway` auto-run. Obtain the Flyway bean via DI and call `flyway.migrate()` manually after the database is decrypted.

**Consequences:** Simpler control. Flyway runs at the right point in the decryption lifecycle.

### ADR-003: Keep ALTER TABLE fallbacks

**Status:** Accepted

**Context:** Existing installations may have databases created before Flyway. The ALTER TABLE statements in `initSchema()` handle these. Dump restore also relies on `AdminService.migrateSchema()`.

**Decision:** Keep both fallbacks. Mark for removal in a follow-up change after validating Flyway in production.

**Consequences:** No risk of breaking existing data. Some code duplication until follow-up.

## Data Model

No new tables or columns. Flyway creates its own `flyway_schema_history` table automatically:

```sql
CREATE TABLE flyway_schema_history (
    installed_rank INTEGER PRIMARY KEY,
    version VARCHAR(50),
    description VARCHAR(200),
    type VARCHAR(20),
    script VARCHAR(1000),
    checksum INTEGER,
    installed_by VARCHAR(100),
    installed_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_time INTEGER,
    success BOOLEAN
);
```

The V1 migration contains the full schema as currently defined in `SqliteConnection.initSchema()`:
- `users` (5 columns + indexes)
- `consultants` (24 columns + indexes)
- `settings` (3 columns)
- `cost_concepts` (5 columns)
- `tenure_bonuses` (5 columns)
- `quarterly_bonuses` (8 columns)
- `bonus_breakdown_cache` (11 columns)
- `simulations` (4 columns)
- Views: `v_client_financials`, `v_position_profitability`

## API Contracts

No new API endpoints. Configuration only:

```java
// Flyway bean (via jooby-flyway, auto-run disabled)
Flyway flyway = Flyway.configure()
    .dataSource("jdbc:sqlite:" + dbPath, "", "")
    .locations("classpath:db/migration")
    .load();
```

## Migration File

```sql
-- V1__initial_schema.sql
-- Captures the exact current schema from SqliteConnection.initSchema()
```

## Sequence Diagrams

### Startup after Login

```
User          Jooby         SqliteConn     Flyway        coeff.db
  │             │               │            │             │
  │ POST /login │               │            │             │
  │────────────>│               │            │             │
  │             │  decrypt()    │            │             │
  │             │──────────────>│            │             │
  │             │               │ app.db.enc │             │
  │             │               │──────decrypt────────────>│
  │             │               │←─────────coeff.db───────│
  │             │  reinit()     │            │             │
  │             │──────────────>│            │             │
  │             │               │ migrate()  │             │
  │             │               │────────────>             │
  │             │               │            │ V1_________│
  │             │               │            │────────────>│
  │             │               │            │ flyway_hist │
  │             │               │            │────────────>│
  │             │               │←──ok───────             │
  │             │               │ initSchema() [DDL removed│
  │             │               │ ALTER fallback kept]     │
  │             │ token         │            │             │
  │←────────────│               │            │             │
```

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Flyway runs against encrypted DB | Flyway only triggered after decrypt, in `SqliteConnection.init()` which is called after `reinit()` |
| Setup flow creates DB without Flyway | `flyway.migrate()` added after `createKeyFile()` in `AuthController.setup()` |
| Existing DB with partial schema | ALTER TABLE fallbacks kept in `initSchema()` and `AdminService.migrateSchema()` |
| Dump restore creates schema without Flyway history | `sqliteConnection.reinit()` at end of restore triggers Flyway, which detects the existing schema and baselines |
| Flyway checksum mismatch on restored dump | Flyway `baselineOnMigrate=true` or manual baseline command for restored databases |
