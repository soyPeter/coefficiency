# Changelog

## [0.1.0] - 2026-06-29

### Added
- Flyway schema management with V1+V2 migrations (CHNG-016)
- V2 migration for v_client_financials and v_position_profitability views
- `baselineOnMigrate(true)` for non-empty schema compatibility
- `migrateSchema()` fallback for Javalin dump restore ALTER TABLEs
- `@Nullable` annotations on ConsultantRow for null-safe JDBI mapping
- NCR/CAPA quality management (9 NCRs, 9 CAPAs closed)

### Fixed
- ConsultantPage crash: missing created_at/updated_at columns after dump import
- Clients tab crash: missing v_client_financials view
- Reports tab NPE: null sortBy in getPerConsultant()
- Reports tab TypeError: null values passed to fmt()/pct()
- Consultant update error: Jackson unrecognized field coefPercentage
- Consultant update SQL: missing updated_at column
- Flyway V3 migration: non-constant default (datetime('now')) in ALTER TABLE
- Unicode escape inconsistency: standardized \u20AC/\u2014/\u00D7 to literal chars

### Changed
- SqliteConnection.initSchema() DDL replaced by Flyway migrations
- ALTER TABLE NOT NULL DEFAULT changed to DEFAULT-only for SQLite compat
- ReportService.getPerConsultant() null-safe filter and sort

### Archived
- CHNG-001 through CHNG-016 — all completed changes archived
