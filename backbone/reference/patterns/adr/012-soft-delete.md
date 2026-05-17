# Soft Delete Strategy with Audit Fields

## Status

Accepted

## Context and Problem Statement

The Bitnomio platform needs to support entity deletion while preserving audit trails and enabling data recovery. Hard deletion (physical removal) loses historical context, breaks referential integrity with events/logs, and makes recovery impossible. We need a strategy that enables safe deletion while maintaining data integrity and auditability.

## Decision Drivers

* **Audit trail**: Maintain complete history of all entities including deletions
* **Data recovery**: Enable restoration of deleted records without backup restoration
* **Referential integrity**: Preserve links to deleted entities in events and logs
* **Compliance**: Support retention policies and GDPR right-to-be-forgotten (soft delete + anonymization)
* **Query simplicity**: Queries should automatically exclude deleted records without special handling
* **Performance**: Minimal query overhead for soft deletes

## Considered Options

* **Hard delete** - Physical removal from database (no recovery, loses history)
* **Soft delete with deleted flag** - Boolean flag without timestamp (minimal audit info)
* **Soft delete with audit fields** - Boolean flag + timestamp + user tracking (full audit trail)
* **Temporal tables** - Database-level history tracking with system-time versioning (complex)
* **Event sourcing** - Store all state changes as immutable events (major architecture change)

## Decision Outcome

Chosen option: "Soft delete with audit fields", because it provides complete audit trails with minimal schema overhead, enables easy recovery, works with existing SQL queries, and requires no database-specific features (temporal tables work on PostgreSQL 14+).

### Implementation

**Audit Fields Pattern:**

All entities extend `AuditableEntity` base class with:
```
- deleted: boolean          (Default: false)
- deletedAt: Instant        (Nullable, set when deleted)
- deletedBy: String         (Nullable, user ID who deleted)
- createdBy: String         (User ID who created)
- updatedBy: String         (User ID who last updated)
- createdAt: Instant        (Auto-set on creation)
- updatedAt: Instant        (Auto-set on updates)
```

**Entity Example:**
See: `services/customer/src/main/java/io/bitnomio/customer/domain/model/entity/Customer.java`

```java
public record Customer(
    String id,
    String email,
    String firstName,
    String lastName,
    boolean deleted,
    Instant deletedAt,
    String deletedBy,
    Instant createdAt,
    String createdBy,
    Instant updatedAt,
    String updatedBy
) {
    public Customer markAsDeleted(String userId) {
        return new Customer(
            id, email, firstName, lastName,
            true, Instant.now(), userId,
            createdAt, createdBy, Instant.now(), userId
        );
    }
    
    public Customer restore(String userId) {
        return new Customer(
            id, email, firstName, lastName,
            false, null, null,
            createdAt, createdBy, Instant.now(), userId
        );
    }
}
```

**Use Cases:**

Delete operation via dedicated use case:
- See: `services/customer/src/main/java/io/bitnomio/customer/app/DeleteCustomerUseCase.java`
- Sets `deleted = true`, `deletedAt = now()`, `deletedBy = userId`
- Publishes `CustomerDeletedEvent` via Outbox Pattern

Restore operation via dedicated use case:
- See: `services/customer/src/main/java/io/bitnomio/customer/app/RestoreCustomerUseCase.java`
- Sets `deleted = false`, `deletedAt = null`, `deletedBy = null`
- Publishes `CustomerRestoredEvent` for audit

**Query Filtering:**

All queries automatically filter out deleted records:
```sql
SELECT * FROM customers 
WHERE deleted = false
```

Query repositories explicitly include deletion status:
```java
// Query repo - includes soft-deleted filtering automatically
public interface CustomerSqlQueryRepo extends CustomerQueryRepo {
    @SqlQuery("""
        SELECT * FROM customers 
        WHERE id = :id AND deleted = false
    """)
    Optional<CustomerRow> findById(@Bind("id") String id);
    
    @SqlQuery("""
        SELECT * FROM customers 
        WHERE deleted = true
        ORDER BY deleted_at DESC
    """)
    List<CustomerRow> findDeleted();  // Explicit method for deleted records
}
```

**Database Schema:**

See: `infrastructure/db/migrations/shared-libs/V4__add_audit_fields.sql`

```sql
ALTER TABLE customers ADD COLUMN deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE customers ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE customers ADD COLUMN deleted_by VARCHAR(255);
ALTER TABLE customers ADD COLUMN created_by VARCHAR(255);
ALTER TABLE customers ADD COLUMN updated_by VARCHAR(255);
ALTER TABLE customers ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE customers ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Index for soft-delete queries
CREATE INDEX idx_customers_deleted ON customers(deleted) WHERE deleted = false;
```

### Consequences

* Good, because enables data recovery without backup restoration
* Good, because maintains complete audit trail with user tracking
* Good, because minimal schema overhead (just audit fields)
* Good, because minimal query overhead (single WHERE clause)
* Good, because no database-specific features required (works on PostgreSQL 11+)
* Good, because straightforward to understand and implement
* Bad, because deleted data still occupies storage space
* Bad, because requires discipline to filter deleted records in all queries
* Bad, because doesn't satisfy "right-to-be-forgotten" without anonymization
* Bad, because can be confused with GDPR deletion (requires additional anonymization)

## GDPR Compliance

**For "right-to-be-forgotten":**
1. Soft delete user data (deletes records)
2. Anonymize personally identifiable information:
   - Email → `redacted-{hash}`
   - Name → `Deleted User {hash}`
   - Contact info → `[REDACTED]`
3. Keep aggregated/anonymized data indefinitely
4. Permanently delete personal data after retention period

## Related Patterns

- **Outbox Pattern**: Events published when entities are deleted/restored
- **Domain Events**: `CustomerDeletedEvent` and `CustomerRestoredEvent` for auditing
- **Use Cases**: Dedicated `DeleteCustomerUseCase` and `RestoreCustomerUseCase`
- **Query Repositories**: Filter out deleted records automatically

## References

* `documentation/ARCHITECTURE.md` - System design including soft delete pattern
* `infrastructure/db/migrations/shared-libs/V4__add_audit_fields.sql` - Schema migration
* GDPR Compliance: https://gdpr-info.eu/ (right-to-erasure Section 17)
* Database archival patterns: https://use-the-index-luke.com/sql/where-clause/null-safe-comparison/is-null

## Historical Decisions

This ADR supercedes any previous approaches to entity deletion. All services must use soft delete with audit fields exclusively.
