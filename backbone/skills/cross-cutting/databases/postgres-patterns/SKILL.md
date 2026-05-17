<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: postgres-patterns
description: PostgreSQL database patterns for query optimization, schema design, indexing, and security. Based on Supabase best practices.
origin: ECC
---

# PostgreSQL Patterns

Quick reference for PostgreSQL best practices. For detailed guidance, use the `database-reviewer` agent.

## When to Activate

- Writing SQL queries or migrations
- Designing database schemas
- Troubleshooting slow queries
- Implementing Row Level Security
- Setting up connection pooling

## Quick Reference

### Index Cheat Sheet

| Query Pattern | Index Type | Example |
|--------------|------------|---------|
| `WHERE col = value` | B-tree (default) | `CREATE INDEX idx ON t (col)` |
| `WHERE col > value` | B-tree | `CREATE INDEX idx ON t (col)` |
| `WHERE a = x AND b > y` | Composite | `CREATE INDEX idx ON t (a, b)` |
| `WHERE jsonb @> '{}'` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| `WHERE tsv @@ query` | GIN | `CREATE INDEX idx ON t USING gin (col)` |
| Time-series ranges | BRIN | `CREATE INDEX idx ON t USING brin (col)` |

### Data Type Quick Reference

| Use Case | Correct Type | Avoid |
|----------|-------------|-------|
| IDs | `bigint` | `int`, random UUID |
| Strings | `text` | `varchar(255)` |
| Timestamps | `timestamptz` | `timestamp` |
| Money | `numeric(10,2)` | `float` |
| Flags | `boolean` | `varchar`, `int` |

### Common Patterns

**Composite Index Order:**
```sql
-- Equality columns first, then range columns
CREATE INDEX idx ON orders (status, created_at);
-- Works for: WHERE status = 'pending' AND created_at > '2024-01-01'
```

**Covering Index:**
```sql
CREATE INDEX idx ON users (email) INCLUDE (name, created_at);
-- Avoids table lookup for SELECT email, name, created_at
```

**Partial Index:**
```sql
CREATE INDEX idx ON users (email) WHERE deleted_at IS NULL;
-- Smaller index, only includes active users
```

**RLS Policy (Optimized):**
```sql
CREATE POLICY policy ON orders
  USING ((SELECT auth.uid()) = user_id);  -- Wrap in SELECT!
```

**UPSERT:**
```sql
INSERT INTO settings (user_id, key, value)
VALUES (123, 'theme', 'dark')
ON CONFLICT (user_id, key)
DO UPDATE SET value = EXCLUDED.value;
```

**Cursor Pagination:**
```sql
SELECT * FROM products WHERE id > $last_id ORDER BY id LIMIT 20;
-- O(1) vs OFFSET which is O(n)
```

**Queue Processing:**
```sql
UPDATE jobs SET status = 'processing'
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending'
  ORDER BY created_at LIMIT 1
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

### Anti-Pattern Detection

```sql
-- Find unindexed foreign keys
SELECT conrelid::regclass, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey)
  );

-- Find slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC;

-- Check table bloat
SELECT relname, n_dead_tup, last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

### Configuration Template

```sql
-- Connection limits (adjust for RAM)
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET work_mem = '8MB';

-- Timeouts
ALTER SYSTEM SET idle_in_transaction_session_timeout = '30s';
ALTER SYSTEM SET statement_timeout = '30s';

-- Monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Security defaults
REVOKE ALL ON SCHEMA public FROM public;

SELECT pg_reload_conf();
```

## CDC: Change Data Capture with PostgreSQL

### Key Concepts

**WAL (Write-Ahead Log):** Ensures data integrity by logging changes before they're applied to database files. Every change is recorded, maintaining atomicity and durability.

**Replication Slots:** Ensure the master retains WAL entries for replicas even if they're temporarily disconnected. Two types: physical and logical.

**wal_level Options:**
- `minimal` — Basic crash recovery (default)
- `replica` — Supports read replicas
- `logical` — Required for CDC with Debezium

### Docker Compose: PostgreSQL with CDC

```yaml
services:
  postgres:
    image: postgres:latest
    command: >-
      -c wal_level=logical
      -c max_wal_senders=5
      -c max_replication_slots=5
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    ports:
      - "5432:5432"
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
```

### Create Table Example

```sql
CREATE TABLE accounts (
    user_id serial PRIMARY KEY,
    username VARCHAR (50) UNIQUE NOT NULL,
    password VARCHAR (50) NOT NULL,
    email VARCHAR (255) UNIQUE NOT NULL,
    created_on TIMESTAMP NOT NULL,
    last_login TIMESTAMP
);
```

### CDC Event Format (Debezium)

```json
{
  "before": null,
  "after": {
    "user_id": 4,
    "username": "user2",
    "email": "user2@email.com"
  },
  "source": {
    "version": "2.2.0.Alpha3",
    "connector": "postgresql",
    "db": "mydb",
    "schema": "public",
    "table": "accounts",
    "ts_ms": 1700505308860
  },
  "op": "c",
  "ts_ms": 1700505309220
}
```

**Operations:** `c` = create/insert, `u` = update, `d` = delete, `r` = read (snapshot)

### Related

- Agent: `database-reviewer` - Full database review workflow
- Skill: `clickhouse-io` - ClickHouse analytics patterns
- Skill: `backend-patterns` - API and backend patterns
- Skill: `outbox-pattern` - Transactional Outbox for reliable event delivery
- Skill: `nats-patterns` - NATS messaging for CDC events

---

*Based on Supabase Agent Skills (credit: Supabase team) (MIT License)*
