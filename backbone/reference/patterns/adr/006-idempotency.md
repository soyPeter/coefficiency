# Idempotency Pattern for Safe Operations

## Status

Accepted

## Context and Problem Statement

In distributed systems with unreliable networks, clients may retry requests that already succeeded. We need to ensure that duplicate requests don't cause duplicate side effects (e.g., charging a customer twice, creating duplicate records).

## Decision Drivers

* **Safe retries**: Operations must be safely retryable without side effects
* **Client experience**: Clients should be able to retry without worrying about duplicates
* **Payment safety**: Financial operations absolutely cannot be duplicated
* **API reliability**: APIs should handle network failures gracefully

## Considered Options

* **Idempotency Keys** - Client-provided keys to identify unique requests
* **Natural Idempotency** - Design operations to be naturally idempotent (e.g., upserts)
* **Optimistic Locking** - Version-based conflict detection
* **Request Deduplication** - Server-side request fingerprinting

## Decision Outcome

Chosen option: **Idempotency Keys**, because they provide explicit control over what constitutes a duplicate request and allow clients to safely retry any operation.

### How It Works

1. Client sends request with `Idempotency-Key` header
2. Server checks if key exists in idempotency store
3. If exists, return cached response (no execution)
4. If not, execute operation, cache response, return result
5. Key expires after TTL

### Implementation

**Annotation-Based:**
```java
@Named
@Transactional
@Idempotent(ttl = 3600, keyFrom = KeySource.HEADER)
public class CreateCustomerUseCase {

    public Customer execute(CreateCustomerReq request) {
        // This will only execute once per idempotency key
        Customer customer = Customer.create(request.email());
        customerRepo.save(customer);
        return customer;
    }
}
```

**Client Usage:**
```bash
# First request - executes operation
curl -X POST /api/v1/customers \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -d '{"email": "user@example.com"}'

# Retry with same key - returns cached response
curl -X POST /api/v1/customers \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
  -d '{"email": "user@example.com"}'
```

**Idempotency Table:**
```sql
CREATE TABLE idempotency_store (
    idempotency_key VARCHAR(255) PRIMARY KEY,
    response JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_idempotency_expires ON idempotency_store (expires_at);
```

### Consequences

**Good:**
* Clients can safely retry any request
* Prevents duplicate payments, records, and side effects
* Response consistency - same key always returns same response
* Simple integration via annotation

**Bad:**
* Requires client cooperation (sending idempotency key)
* Storage overhead for caching responses
* TTL management needed to prevent unbounded growth
* Not suitable for read operations (naturally idempotent)

### When to Use

**Use for:**
- POST requests that create resources
- Payment processing operations
- External API calls
- Any operation with side effects

**Do NOT use for:**
- GET requests (naturally idempotent)
- DELETE by ID (naturally idempotent)
- PUT with deterministic ID (naturally idempotent)
- Read-only operations

### Configuration

```yaml
idempotency:
  enabled: true
  default-ttl: 3600              # 1 hour
  header-name: Idempotency-Key
  cleanup:
    enabled: true
    interval: 3600000            # Hourly cleanup
```

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/idempotency/IdempotencyAspect.java`
* `services/libs/shared-application/src/main/java/.../annotations/Idempotent.java`
* `infrastructure/db/migrations/shared-libs/V2__create_idempotency_table.sql`
* `documentation/PATTERNS.md` - Pattern decision guide
