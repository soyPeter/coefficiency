<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: patterns-guide
description: Decision tree for choosing architectural patterns - CQRS, Outbox, Idempotency, Soft Delete, Resilience4j. Use when designing new features or choosing patterns for implementation.
---

# Patterns Guide Skill

Decision tree for choosing and implementing architectural patterns.

## When to Use

- Designing a new feature
- Choosing which pattern to apply
- Understanding pattern trade-offs
- Deciding between patterns

## Quick Decision Tree

```
START: Building a new feature?

├─ Read-heavy operation (>1000 req/sec)?
│  ├─ YES → Use CQRS Lite
│  └─ NO → Continue
│
├─ Changes application state?
│  ├─ YES → Apply Idempotency pattern
│  └─ NO → Continue
│
├─ Must domain events be reliably published?
│  ├─ YES → Use Outbox pattern
│  └─ NO → Continue
│
├─ Calling external services?
│  ├─ YES → Use Resilience4j
│  └─ NO → Continue
│
└─ Need data recovery capability?
   ├─ YES → Use Soft Delete pattern
   └─ NO → Hard delete is acceptable
```

---

## Pattern 1: CQRS Lite

**Separate datasources for read and write operations.**

### When to Use
- High read volume (>1000 reads/sec)
- Complex reporting/aggregations
- Need independent scaling

### When NOT to Use
- Simple CRUD with balanced read/write
- Real-time consistency required
- Single database adequate

### Implementation

```java
// Separate datasources
@Bean(name = "commandDataSource")
public DataSource commandDataSource() {
    return DataSourceBuilder.create()
        .url("jdbc:postgresql://primary:5432/db")
        .build();
}

@Bean(name = "queryDataSource")  
public DataSource queryDataSource() {
    return DataSourceBuilder.create()
        .url("jdbc:postgresql://replica:5432/db")
        .build();
}
```

### See Also
[[reference/patterns/adr/004-cqrs-lite.md]]

---

## Pattern 2: Idempotency

**Prevent duplicate processing on retries.**

### When to Use
- API operations that can be retried
- Payment/transaction processing
- Any state-changing operation

### Implementation

```java
@Idempotent(ttl = 3600, keyFrom = KeySource.HEADER)
public Order execute(CreateOrderReq req) {
    // Safe to retry - duplicate requests return cached response
}
```

### See Also
[[reference/patterns/adr/006-idempotency.md]]

---

## Pattern 3: Outbox Pattern

**Reliable event publishing with database writes.**

### When to Use
- Domain events must be published
- Can't have event loss on crash
- Need exactly-once delivery

### Implementation

```java
@Transactional
@PublishEvents(exchange = "orders", routingKey = "order.created")
public Order createOrder(CreateOrderReq req) {
    Order order = Order.create(req);
    orderRepo.save(order);
    DomainEventRecorder.record(new OrderCreatedEvent(order));
    return order;
}
```

### See Also
[[reference/patterns/adr/005-outbox-pattern.md]]

---

## Pattern 4: Resilience4j

**Fault tolerance for external service calls.**

### When to Use
- Calling external APIs
- Database connections
- Any unreliable dependency

### Patterns Available
| Pattern | Purpose |
|---------|---------|
| Circuit Breaker | Prevent cascading failures |
| Retry | Handle transient failures |
| Rate Limiter | Prevent overload |
| Bulkhead | Isolate resources |

### Implementation

```java
@CircuitBreaker(name = "externalService")
@Retry(name = "externalService")
public ExternalData fetchData(String id) {
    return externalClient.get(id);
}
```

### See Also
[[reference/patterns/adr/009-resilience4j.md]]

---

## Pattern 5: Soft Delete

**Logical deletion preserving audit trail.**

### When to Use
- Need data recovery
- Compliance requirements
- Refer integrity needed

### Implementation

```java
// Entity has deleted field
public record Order(
    Long id,
    String status,
    boolean deleted,
    Instant deletedAt,
    String deletedBy
) {
    public void markDeleted(String userId) {
        // Set deleted=true, deletedAt=now, deletedBy=userId
    }
}

// Repository filters automatically
@SqlQuery("SELECT * FROM orders WHERE deleted = false")
List<Order> findAllActive();
```

### See Also
[[reference/patterns/adr/012-soft-delete.md]]

---

## Pattern Selection Checklist

Use this checklist when implementing new features:

- [ ] Is this read-heavy? → Consider CQRS
- [ ] Can this be retried? → Apply Idempotency
- [ ] Need reliable events? → Use Outbox
- [ ] Calling external services? → Add Resilience4j
- [ ] Need data recovery? → Use Soft Delete
- [ ] Multiple services updating same data? → Consider distributed transactions
