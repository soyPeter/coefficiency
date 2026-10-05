<!-- VERSION: 2026.05.13#5-commandpipeline,16commandstotal -->
# 6. Long-Term Memory

*This file contains critical context, lessons learned, patterns that worked, and traps to avoid.*

## Patterns That Worked (Keep Using These)

<!-- Add patterns that worked well for this project -->

## Lessons Learned & Traps to Avoid (Do Not Repeat)

- **Flyway + SQLite ALTER TABLE:** `ALTER TABLE ADD COLUMN` rejects non-constant defaults like `DEFAULT (datetime('now'))`. Only constant defaults (strings, numbers, `DEFAULT ''`, `DEFAULT 0`) are allowed. If a function default is needed, the column must be defined in the initial `CREATE TABLE` (Flyway V1), not added later via ALTER TABLE.
- **baselineOnMigrate(true) skips V1 execution:** When Flyway baselines a non-empty database, it marks V1 as applied without running it. Any schema elements defined only in V1 (views, columns added via CREATE TABLE) will be missing. Use separate V2+ migrations to add elements that V1 would have created, or ensure the migration handles already-existing elements gracefully.
- **Flyway migrations must be idempotent across migration history:** A migration that adds a column via ALTER TABLE will fail if a later version of V1's CREATE TABLE already includes that column. Test migrations against both fresh (V1 runs) and restored (V1 baselined, columns may be missing) databases.
- **Don't put ALTER TABLE in Flyway migrations for columns that V1 may or may not have created:** Use the `initSchema()` ALTER TABLE fallbacks (which silently skip duplicates) for column additions that might conflict with V1. Flyway migrations are best for additive-only changes (new tables, views, indexes) that can use `CREATE IF NOT EXISTS`.

## Contextual Anchors

<!-- Add contextual anchors for this project -->

## Project Context

<!-- Add project-specific context that future agents need to know -->

---

### How to Add Entries

```markdown
## [CATEGORY: Patterns / Lessons / Anchors]
- **Item:** [Brief description]
```

Valid categories:
- Patterns That Worked
- Lessons Learned & Traps to Avoid
- Contextual Anchors
- Project Context
