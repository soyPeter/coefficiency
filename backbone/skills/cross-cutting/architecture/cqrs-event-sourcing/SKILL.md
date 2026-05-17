<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: cqrs-event-sourcing
description: CQRS and event sourcing patterns with Java records and sealed types in Quarkus. Use when user asks about event sourcing, CQRS architecture, aggregate rebuild from events, or event store implementation.
---

# CQRS and Event Sourcing Skill

CQRS (Command Query Responsibility Segregation) and Event Sourcing patterns for Quarkus services using Java records and sealed types.

## When to Use
- Designing command vs query model separation
- Implementing event sourcing for audit trails and temporal queries
- Rebuilding aggregate state from event history
- Handling eventual consistency between command and query models
- Choosing between CRUD and event-sourced aggregates

---

## 1. CQRS in Quarkus

CQRS separates the model used for writing (commands) from the model used for reading (queries).

### Command Model vs Query Model

| Aspect | Command Side | Query Side |
|--------|-------------|------------|
| **Purpose** | State transitions, business invariants | Data retrieval, projections |
| **Model** | Aggregate with behavior | DTOs with Panache repository |
| **Reads** | Single aggregate by ID | Multiple query models |
| **Consistency** | Strong (transactional) | Eventual (async projection) |

### `domain/actions/` Command Action Pattern

Command actions define the write-side contract:

```java
// domain/actions/OrderCommandAction.java
public interface OrderCommandAction {
    void save(Order aggregate);
    Optional<Order> findById(OrderId id);
    void delete(OrderId id);
}

// Query side uses a separate repository
// infra/data/persistence/sql/OrderQueryRepo.java
@Repository
public class OrderQueryRepo implements OrderQueryAction {
    public Optional<OrderSummaryDto> findSummaryById(OrderId id) {
        return find("id", id.value())
            .project(OrderSummaryDto.class)
            .firstResultOptional();
    }
}
```

### Query Side: Panache Repository + DTO Projection

```java
// Query DTO (immutable projection)
public record OrderSummaryDto(
    UUID orderId,
    String customerEmail,
    Money total,
    OrderStatus status,
    Instant placedAt
) {}

// Query repository with Panache
@Repository
public class OrderQueryRepo extends PanacheRepository<OrderEntity> {
    public Optional<OrderSummaryDto> findSummaryById(UUID orderId) {
        return find("id", orderId)
            .project(OrderSummaryDto.class)
            .firstResultOptional();
    }

    public List<OrderSummaryDto> findByCustomerEmail(String email) {
        return find("customerEmail", email)
            .project(OrderSummaryDto.class)
            .list();
    }
}
```

### Synchronization Strategies

| Strategy | When to Use | Trade-off |
|----------|-------------|-----------|
| **Outbox Pattern** | Reliability required | Added complexity |
| **Dual Write** | Simple cases | Inconsistency risk |
| **Eventual Consistency** | Read replicas | Stale reads possible |

---

## 2. Event Sourcing with Java Records

Event sourcing stores state changes as a sequence of immutable event records.

### Event Record Pattern

```java
// domain/event/OrderPlacedEvent.java
public record OrderPlacedEvent(
    UUID orderId,
    String customerEmail,
    Instant timestamp
) implements OrderEvent {

    public OrderPlacedEvent {
        if (customerEmail == null || customerEmail.isBlank()) {
            throw new IllegalArgumentException("customerEmail is required");
        }
    }
}

// Companion static factory for common construction
public record OrderPlacedEvent(
    UUID orderId,
    String customerEmail,
    Instant timestamp
) implements OrderEvent {
    public static OrderPlacedEvent create(UUID orderId, String customerEmail) {
        return new OrderPlacedEvent(orderId, customerEmail, Instant.now());
    }
}
```

### Sealed Types for Event Families

```java
// domain/event/OrderEvent.java (sealed interface)
public sealed interface OrderEvent permits OrderPlacedEvent, OrderShippedEvent, OrderCancelledEvent {
    UUID orderId();
    Instant occurredOn();
}

// domain/event/OrderShippedEvent.java
public record OrderShippedEvent(
    UUID orderId,
    String trackingNumber,
    Instant shippedAt
) implements OrderEvent {}

// domain/event/OrderCancelledEvent.java
public record OrderCancelledEvent(
    UUID orderId,
    String reason,
    Instant cancelledAt
) implements OrderEvent {}
```

### Event Store Implementation with Panache

```java
// infra/data/persistence/entity/StoredEvent.java
@Entity
@Table(name = "stored_events")
public class StoredEvent extends PanacheEntity {
    @Column(name = "aggregate_id")
    public UUID aggregateId;

    @Column(name = "aggregate_type")
    public String aggregateType;

    @Column(name = "event_type")
    public String eventType;

    @Column(name = "event_data", columnDefinition = "TEXT")
    public String eventData;  // JSON serialized

    @Column(name = "sequence_number")
    public Long sequenceNumber;

    @Column(name = "occurred_on")
    public Instant occurredOn;

    public static List<StoredEvent> findByAggregateIdOrderBySequence(UUID aggregateId) {
        return find("aggregateId = ?1 ORDER BY sequenceNumber ASC", aggregateId).list();
    }
}
```

### Snapshot Strategy for Long Event Streams

```java
// Aggregate with snapshot support
public class Order {
    private final OrderId id;
    private OrderStatus status;
    private List<OrderLine> lines;
    private int version;  // Incremented each event

    // Snapshot every 100 events
    private static final int SNAPSHOT_THRESHOLD = 100;

    public void applySnapshot(OrderSnapshot snapshot) {
        this.status = snapshot.status();
        this.lines = new ArrayList<>(snapshot.lines());
        this.version = snapshot.version();
    }

    public Optional<OrderSnapshot> takeSnapshot() {
        if (version % SNAPSHOT_THRESHOLD == 0) {
            return Optional.of(new OrderSnapshot(id, status, List.copyOf(lines), version));
        }
        return Optional.empty();
    }
}

// Snapshot entity
@Entity
@Table(name = "order_snapshots")
public class OrderSnapshot extends PanacheEntity {
    public UUID aggregateId;
    public String status;
    public String linesJson;
    public int version;
    public Instant createdAt;
}
```

### Rebuild Aggregate from Event Log

```java
// Pure fold function: apply events to build current state
public class OrderFactory {

    public Order rebuildFromEvents(UUID orderId, List<StoredEvent> events) {
        OrderState state = new OrderState(orderId);
        for (StoredEvent event : events) {
            state = applyEvent(state, event);
        }
        return new Order(state);
    }

    private OrderState applyEvent(OrderState state, StoredEvent event) {
        return switch (event.eventType()) {
            case "OrderPlacedEvent" -> {
                OrderPlacedEvent e = deserialize(event.eventData(), OrderPlacedEvent.class);
                yield state.withCustomer(e.customerEmail())
                           .withStatus(OrderStatus.PLACED);
            }
            case "OrderShippedEvent" -> {
                OrderShippedEvent e = deserialize(event.eventData(), OrderShippedEvent.class);
                yield state.withTracking(e.trackingNumber())
                           .withStatus(OrderStatus.SHIPPED);
            }
            case "OrderCancelledEvent" -> {
                OrderCancelledEvent e = deserialize(event.eventData(), OrderCancelledEvent.class);
                yield state.withStatus(OrderStatus.CANCELLED)
                           .withCancelReason(e.reason());
            }
            default -> state;  // Unknown event type, skip
        };
    }
}

// Internal state record (immutable transitions)
private record OrderState(
    UUID id,
    String customerEmail,
    OrderStatus status,
    String trackingNumber,
    String cancelReason,
    List<OrderLine> lines,
    int version
) {
    OrderState withStatus(OrderStatus status) {
        return new OrderState(id, customerEmail, status, trackingNumber, cancelReason, lines, version + 1);
    }
    // ... other transitions
}
```

---

## 3. Integration with Backbone Template

The backbone template already provides the `domain/event/` directory and supports event sourcing patterns.

### Template Structure

```
src/main/java/__PACKAGE__/
├── domain/
│   ├── model/           # Entities, VOs
│   ├── event/           # Domain events (pre-created)
│   │   └── DomainEvent.java
│   ├── actions/         # Repository ports
│   └── services/        # Domain services
├── app/                 # Application services (use cases)
├── infra/
│   └── data/
│       └── persistence/
│           ├── entity/  # Panache entities
│           └── repo/    # Repository implementations
```

### `@PublishEvents` Outbox Pattern

```java
// app/OrderService.java
@ApplicationScoped
public class OrderService {
    private final OrderCommandAction commandRepo;
    private final EventOutbox outbox;

    public OrderId placeOrder(PlaceOrderRequest request) {
        Order order = Order.create(CustomerId.generate(), request.items());
        commandRepo.save(order);

        // Outbox ensures reliable event publication
        order.pullDomainEvents().forEach(outbox::schedule);

        return order.id();
    }
}

// Outbox entity
@Entity
@Table(name = "event_outbox")
public class EventOutbox extends PanacheEntity {
    public UUID eventId;
    public String eventType;
    public String payload;  // JSON
    public OutboxStatus status;  // PENDING, PUBLISHED, FAILED
    public Instant createdAt;
    public int retryCount;
}
```

### `StoredEvent` Entity for Event Sourcing

The backbone template includes a `StoredEvent` entity in `infra/data/persistence/entity/`:

```java
@Entity
@Table(name = "stored_events")
public class StoredEvent extends PanacheEntityBase {
    @Column(name = "aggregate_id")
    public UUID aggregateId;

    @Column(name = "aggregate_type")
    public String aggregateType;

    @Column(name = "event_type")
    public String eventType;

    @Column(name = "event_data")
    public String eventData;

    @Column(name = "sequence_number")
    public Long sequenceNumber;

    @Column(name = "occurred_on")
    public Instant occurredOn;
}
```

### Migration Path from CRUD to Event-Sourced Aggregate

**Phase 1: Add Events Without Changing Storage**
1. Add domain events to entity state transitions
2. Publish events via outbox alongside existing CRUD
3. Read models still use direct queries

**Phase 2: Dual-Write Phase**
1. Write events to event store on each state change
2. Maintain read models via event projection
3. Both write paths active during migration

**Phase 3: Event-Sourced Only**
1. Remove direct aggregate writes
2. Read models powered purely by event projections
3. Event store is source of truth

---

## 4. Materialized Views + Streaming Database

Query-optimized views for read-heavy microservices, powered by CDC + streaming.

### The Problem: Cross-Service Queries

```
Without Materialized Views:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Product Svc │    │  Order Svc  │    │ Inventory Svc│
└──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    API Composition
                    (N round-trips)
                           │
                    ┌──────▼──────┐
                    │   Client    │
                    └─────────────┘
```

**Issues with API Composition:**
- N round-trips per query
- Tight coupling between services
- Complex aggregation logic
- May not provide real-time data

### The Solution: CQRS + Materialized Views

```
Commands: PostgreSQL → Debezium → NATS → RisingWave → Materialized View
                                ↓
Queries: UI → Query Handler → Materialized View (real-time)
```

**Pattern:**
1. **Separate Commands from Queries (CQRS)**
2. **Identify query patterns** needing real-time data
3. **Create materialized views** in streaming database
4. **Subscribe to CDC events** to keep views updated

### Streaming Database: RisingWave

Open-source streaming database with built-in CDC connectors.

**CDC Source from PostgreSQL:**

```sql
CREATE TABLE orders (
    order_id int,
    order_date bigint,
    customer_name varchar,
    price decimal,
    product_id int,
    order_status smallint,
    PRIMARY KEY (order_id)
) WITH (
    connector = 'mysql-cdc',
    hostname = 'mysql',
    port = '3306',
    username = 'root',
    password = '123456',
    database.name = 'mydb',
    table.name = 'orders',
    server.id = '1'
);
```

**Create Materialized View:**

```sql
CREATE MATERIALIZED VIEW order_details AS
SELECT
    order_id,
    SUM(item_price) AS total_price,
    AVG(item_price) AS avg_price
FROM
    order_events
GROUP BY
    order_id;
```

### CDC Pipeline: PostgreSQL → Debezium → NATS → RisingWave

```
PostgreSQL (WAL) → Debezium → NATS (JetStream) → RisingWave → Materialized View
```

### Benefits

| Benefit | Description |
|---------|-------------|
| Simple queries | Pre-aggregated views, no complex joins |
| Improved performance | Read-optimized storage |
| Real-time data | CDC keeps views updated |
| Scalability | Query side scales independently |
| Fault tolerance | Streaming DB as fallback |

### Decision Framework

| When to Use | When NOT to Use |
|-------------|----------------|
| Read-heavy workloads | Write-heavy workloads |
| Cross-service aggregation | Simple single-service reads |
| Real-time dashboards | Tolerate stale data |
| Complex joins | Simple CRUD |

### Related Patterns

| Pattern | Role |
|---------|------|
| Transactional Outbox | Reliable event publishing |
| CDC (Change Data Capture) | Event extraction |
| NATS JetStream | Durable event transport |
| Streaming Database | View materialization |

---

## 5. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Event Sourcing Overkill** | Simple CRUD with 5 entities gets event-sourced | Use event sourcing when audit trail, temporal queries, or replay matters |
| **CQRS Without Eventual Consistency Handling** | Read model stale after writes | Acknowledge lag, use optimistic UI, retry patterns |
| **Projection Lag Causing Read Inconsistencies** | User sees stale data after write | Design projections for latency requirements, use read-your-writes patterns |
| **Large Event Payloads** | Serializing entire aggregate state per event | Store only delta, use snapshots |
| **No Snapshot Strategy** | Rebuild from genesis for long-running aggregates | Add snapshots every N events |
| **Event Schema Evolution** | Adding fields breaks existing event deserialization | Version events, use upcasting pattern |
| **Leaking Infrastructure to Domain** | Aggregate depends on event store | Repository encapsulates storage details |

---

## Linked Skills

- **Domain-Driven Design** → `domain-driven-design` for aggregate, entity, and domain event fundamentals
- **Event-Driven Architecture** → `software-architectures` for messaging patterns between services
- **Java Records** → `java-core` for immutable record patterns
- **Panache Persistence** → `java-quarkus` for repository and entity patterns
- **Outbox Pattern** → `outbox-pattern` for reliable event publication
- **NATS Patterns** → `nats-patterns` for NATS JetStream messaging
- **PostgreSQL Patterns** → `postgres-patterns` for CDC configuration

---

## References

- *CQRS* — Greg Young
- *Event Sourcing* — Martin Fowler
- *Designing Event-Driven Systems* — Ben Stopford (Confluent)
- *Data Synchronization in Microservices* — Bobur (Mercadona Tech)
