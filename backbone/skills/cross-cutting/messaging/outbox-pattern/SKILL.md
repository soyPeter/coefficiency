<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: outbox-pattern
description: Implement the Transactional Outbox Pattern to solve the dual-write problem in distributed systems. Use when building event-driven microservices, ensuring reliable event delivery, or designing exactly-once semantics across service boundaries.
---

# Transactional Outbox Pattern

Solve the dual-write problem by atomically persisting domain events in the same database transaction as business state changes, then asynchronously publishing them via a background dispatcher.

## When to Use

- Publishing events from a service that writes to a relational database
- Need guaranteed delivery of domain events to message brokers (Kafka, RabbitMQ, etc.)
- Building event-driven microservices with eventual consistency requirements
- Avoiding data inconsistency when DB commits succeed but message publication fails
- Implementing exactly-once processing semantics (paired with Inbox pattern)

## When NOT to Use

- Simple monolith with a single database and no external event consumers
- Loose consistency is acceptable and occasional message loss is tolerable
- Not using a relational database (the atomic transaction guarantee is lost)
- System is small and overhead of running outbox infrastructure isn't justified

## The Problem: Dual-Write Hell

```csharp
// DON'T DO THIS IN PRODUCTION
public async Task CreateOrderAsync(CreateOrderRequest request)
{
    var order = new Order(request.CustomerId, request.Items);
    _dbContext.Orders.Add(order);
    await _dbContext.SaveChangesAsync(); // ✅ Committed
    
    // ❌ What if this fails? Network error? Broker down? Process crash?
    await _eventBus.PublishAsync(new OrderCreatedEvent(order.Id, order.CustomerId));
}
```

Failure modes:
- **DB commits, message never sends** → Ghost orders, missing downstream actions
- **Message sends, DB rolls back** → Phantom events, inconsistent state
- **Partial failures** → Data corruption, debugging nightmares

Root cause: You cannot have atomic transactions across a database and a message broker.

## The Solution

```
[Client Request]
       |
       v
[Service Layer] ----(Single DB Transaction)----> [Database]
       |                                             |-- orders
       |                                             |-- outbox (event payload stored here)
       |
       | (Later, Async)
       v
[Outbox Dispatcher] ----(Reads outbox)----> [Message Broker]
                                                  |
                                                  v
                                          [Consumer Service]
```

**How it works:**
1. **Atomic Write:** Save business data AND outbox message in the same database transaction
2. **Background Processing:** A separate worker polls the outbox and publishes messages
3. **At-Least-Once Delivery:** Messages are retried until confirmed published
4. **Idempotent Consumers:** Downstream services handle duplicate messages gracefully

## Core Schema

```sql
CREATE TABLE outbox_messages (
    id              UUID PRIMARY KEY,
    aggregate_id    VARCHAR(255) NOT NULL,
    aggregate_type  VARCHAR(100) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSONB NOT NULL,
    correlation_id  VARCHAR(100),
    status          VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    retry_count     INT NOT NULL DEFAULT 0,
    error           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMPTZ,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Critical indexes
CREATE INDEX idx_outbox_status_created ON outbox_messages(status, next_attempt_at);
CREATE INDEX idx_outbox_unprocessed ON outbox_messages(processed_at, created_at) WHERE processed_at IS NULL;
CREATE INDEX idx_outbox_aggregate ON outbox_messages(aggregate_type, aggregate_id);
```

## Implementation by Stack

### .NET / EF Core

**Outbox Entity:**
```csharp
public class OutboxMessage
{
    public Guid Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime OccurredOnUtc { get; set; }
    public DateTime? ProcessedOnUtc { get; set; }
    public string? Error { get; set; }
    public int RetryCount { get; set; }
}
```

**EF Core Interceptor (Recommended):**
```csharp
public class ConvertDomainEventsToOutboxMessagesInterceptor : SaveChangesInterceptor
{
    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        var dbContext = eventData.Context;
        if (dbContext is null)
            return base.SavingChangesAsync(eventData, result, cancellationToken);

        var outboxMessages = dbContext.ChangeTracker
            .Entries<Entity>()
            .Select(x => x.Entity)
            .SelectMany(entity =>
            {
                var domainEvents = entity.DomainEvents.ToList();
                entity.ClearDomainEvents();
                return domainEvents;
            })
            .Select(domainEvent => new OutboxMessage
            {
                Id = Guid.NewGuid(),
                Type = domainEvent.GetType().AssemblyQualifiedName!,
                Content = JsonConvert.SerializeObject(domainEvent, new JsonSerializerSettings
                {
                    TypeNameHandling = TypeNameHandling.All
                }),
                OccurredOnUtc = domainEvent.OccurredOn
            })
            .ToList();

        dbContext.Set<OutboxMessage>().AddRange(outboxMessages);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }
}
```

**Background Worker:**
```csharp
public class ProcessOutboxMessagesJob : BackgroundService
{
    private readonly IServiceScopeFactory _serviceScopeFactory;
    private readonly ILogger<ProcessOutboxMessagesJob> _logger;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try { await ProcessOutboxMessages(stoppingToken); }
            catch (Exception ex) { _logger.LogError(ex, "Error processing outbox"); }
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }

    private async Task ProcessOutboxMessages(CancellationToken cancellationToken)
    {
        using var scope = _serviceScopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();

        var messages = await dbContext.OutboxMessages
            .Where(m => m.ProcessedOnUtc == null)
            .Where(m => m.RetryCount < 5)
            .OrderBy(m => m.OccurredOnUtc)
            .Take(20)
            .ToListAsync(cancellationToken);

        foreach (var message in messages)
        {
            try
            {
                var domainEvent = JsonConvert.DeserializeObject(
                    message.Content,
                    new JsonSerializerSettings { TypeNameHandling = TypeNameHandling.All });

                if (domainEvent is not null)
                {
                    await mediator.Publish(domainEvent, cancellationToken);
                    message.ProcessedOnUtc = DateTime.UtcNow;
                }
            }
            catch (Exception ex)
            {
                message.RetryCount++;
                message.Error = ex.ToString();
                message.NextRetryAfter = DateTime.UtcNow.AddSeconds(Math.Pow(2, message.RetryCount));
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
```

### Java / Spring Boot / JPA

**Entity:**
```java
@Entity
@Table(name = "outbox_event")
public class OutboxEvent {
    @Id
    private UUID id;
    
    @Column(name = "aggregate_id", nullable = false)
    private UUID aggregateId;
    
    @Column(name = "aggregate_type", nullable = false)
    private String aggregateType;
    
    @Column(name = "type", nullable = false)
    private String type;
    
    @Column(columnDefinition = "jsonb", nullable = false)
    private String payload;
    
    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;
    
    @PrePersist
    public void prePersist() {
        this.createdAt = OffsetDateTime.now();
    }
}
```

**Service:**
```java
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final OutboxEventRepository outboxRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public UUID createOrder(CreateOrderCommand cmd) {
        Order order = new Order();
        order.setCustomerId(cmd.customerId());
        order.setStatus("PENDING");
        order = orderRepository.save(order);

        OrderCreatedPayload payload = new OrderCreatedPayload(
            order.getId(), order.getCustomerId(), cmd.items());

        OutboxEvent event = new OutboxEvent();
        event.setId(UUID.randomUUID());
        event.setAggregateId(order.getId());
        event.setAggregateType("Order");
        event.setType("OrderCreated");
        event.setPayload(objectMapper.writeValueAsString(payload));
        
        outboxRepository.save(event);
        return order.getId();
    }
}
```

**Dispatcher:**
```java
@Component
public class OutboxPublisher {
    private final OutboxRepository outboxRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Scheduled(fixedDelay = 5000)
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEvent> pending = outboxRepository
            .findTop50ByStatusOrderByCreatedAtAsc("PENDING");

        for (OutboxEvent event : pending) {
            try {
                var future = kafkaTemplate.send(
                    "order-events", event.getAggregateId(), event.getPayload());
                future.get(10, TimeUnit.SECONDS);
                event.setStatus("PROCESSED");
            } catch (Exception e) {
                // Keep PENDING, will retry
            }
        }
    }
}
```

### Python / SQLAlchemy

```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime, JSON
from sqlalchemy.orm import sessionmaker, declarative_base
from datetime import datetime
from kafka import KafkaProducer
import json, time, uuid

Base = declarative_base()

class OutboxEvent(Base):
    __tablename__ = 'outbox_events'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_type = Column(String, nullable=False)
    aggregate_id = Column(String, nullable=False)
    aggregate_type = Column(String, nullable=False)
    payload = Column(JSON, nullable=False)
    status = Column(String, default='PENDING')
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)

def add_order(session, order_data):
    order = create_order(order_data)
    event = OutboxEvent(
        event_type='ORDER_CREATED',
        aggregate_id=order.id,
        aggregate_type='Order',
        payload=order_data
    )
    session.add(order)
    session.add(event)
    session.commit()

def dispatch_events():
    producer = KafkaProducer(
        bootstrap_servers='kafka:9092',
        value_serializer=lambda v: json.dumps(v).encode('utf-8'))
    
    while True:
        session = Session()
        events = session.query(OutboxEvent).filter_by(status='PENDING').all()
        for event in events:
            try:
                producer.send('orders_topic', {
                    'type': event.event_type,
                    'data': event.payload
                })
                event.status = 'PROCESSED'
                event.processed_at = datetime.utcnow()
            except Exception:
                pass
        session.commit()
        time.sleep(5)
```

## The Inbox Pattern (Consumer-Side Idempotency)

Pair Outbox with Inbox for exactly-once processing semantics:

```sql
CREATE TABLE inbox_events (
    idempotency_key VARCHAR(255) PRIMARY KEY,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSONB NOT NULL,
    processed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Consumer pattern:**
```java
@KafkaListener(topics = "order-events", groupId = "shipping-service")
public void onOrderEvent(ConsumerRecord<String, String> record) {
    String idempotencyKey = record.headers().lastHeader("X-Idempotency-Key").value();
    
    // Skip if already processed
    if (inboxRepository.existsById(idempotencyKey)) return;
    
    // Process event
    processEvent(record.value());
    
    // Record processing
    inboxRepository.save(new InboxEvent(idempotencyKey, ...));
}
```

## Alternative: Debezium (CDC)

Instead of polling, use Debezium to tail the database transaction log:

**Pros:**
- Near real-time latency
- No polling load on the database
- Natural ordering (commit order preserved)
- No custom polling code

**Cons:**
- Extra infrastructure (Kafka Connect + Debezium)
- Database configuration for logical decoding
- Operational complexity

**Debezium Connector Config:**
```json
{
  "name": "outbox-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "debezium",
    "database.dbname": "orders_db",
    "table.include.list": "public.outbox_event",
    "transforms": "outbox",
    "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
    "transforms.outbox.route.by.field": "aggregate_type",
    "transforms.outbox.route.topic.replacement": "outbox.event.${routedByValue}"
  }
}
```

## Production Checklist

### Retry Strategy
- Implement exponential backoff (2^retry_count seconds)
- Cap max retries (typically 3-5)
- Move permanently failed messages to a Dead Letter Queue (DLQ)

### Monitoring
```csharp
// Key metrics to track
var unpublishedCount = await dbContext.OutboxMessages
    .CountAsync(m => m.ProcessedOnUtc == null);

var oldestMessage = await dbContext.OutboxMessages
    .Where(m => m.ProcessedOnUtc == null)
    .OrderBy(m => m.OccurredOnUtc)
    .FirstOrDefaultAsync();

var lagSeconds = oldestMessage != null
    ? (DateTime.UtcNow - oldestMessage.OccurredOnUtc).TotalSeconds
    : 0;
```

Alert if:
- Pending messages > 1000
- Oldest pending message > 60 seconds
- Failed messages > 0

### Cleanup Strategy
- Delete or archive processed messages after retention window (7+ days)
- Use table partitioning for high-volume systems
- Never delete before confirming the event was consumed

### Performance
- Batch processing (20-100 messages per poll)
- Index on `(status, next_attempt_at)` and `(processed_at, occurred_on)`
- Use separate connection pool for dispatcher if needed

## Common Mistakes

1. **Processing events outside a transaction**
   - ❌ Save after EACH event
   - ✅ Process batch, save once at end

2. **Not making handlers idempotent**
   - ❌ No deduplication on consumer side
   - ✅ Use idempotency keys or inbox pattern

3. **Synchronous processing in background worker**
   - ❌ `.Wait()` or blocking calls
   - ✅ Always use `await` in async methods

4. **Storing large payloads in outbox**
   - ❌ 10MB images in payload
   - ✅ Store references (URLs), not binary data

5. **Deleting events immediately after sending**
   - ❌ No audit trail, no replay capability
   - ✅ Mark as processed, clean up later

6. **Missing retry backoff**
   - ❌ Hammer failing broker every poll cycle
   - ✅ Exponential backoff with jitter

## Key Takeaways

- **Atomicity:** Data and events are always consistent within the service
- **Reliability:** Messages survive crashes and restarts
- **Scalability:** Background processing decouples publishing from request handling
- **Observability:** Full visibility into message flow and failures
- **Exactly-once effects:** Outbox (guaranteed delivery) + Inbox (idempotent consumption)

The Transactional Outbox Pattern isn't optional for distributed systems — it's the difference between "it usually works" and "it always works."
