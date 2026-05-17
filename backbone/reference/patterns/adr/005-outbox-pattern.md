# Outbox Pattern for Reliable Event Publishing

## Status

Accepted

## Context and Problem Statement

In a distributed system, we need to ensure domain events are reliably published after database transactions commit. The challenge is that database writes and message broker publishing are separate operations that cannot be combined in a single transaction (dual-write problem).

## Decision Drivers

* **Reliability**: Events must not be lost even if message broker is temporarily unavailable
* **Consistency**: Events should only be published if the business transaction succeeds
* **Ordering**: Events should be published in the order they were created
* **Audit trail**: Need a record of all events for debugging and replay

## Considered Options

* **Transactional Outbox Pattern** - Store events in database, publish asynchronously
* **Change Data Capture (CDC)** - Use database logs to detect changes
* **Direct Publishing with Retry** - Publish directly to broker with retry logic
* **Saga Pattern with Compensation** - Compensating transactions on failure

## Decision Outcome

Chosen option: **Transactional Outbox Pattern**, because it guarantees reliable publishing while being simpler to implement than CDC and more reliable than direct publishing.

### How It Works

1. Business operation and event are saved in the **same database transaction**
2. Background service polls the outbox table for unpublished events
3. Events are published to RabbitMQ and marked as published
4. Failed events are retried with exponential backoff

### Implementation

**Use Case with Event Recording:**
```java
@Named
@Transactional
@PublishEvents(exchange = "customer.events", routingKey = "customer.created")
public class CreateCustomerUseCase {

    public Customer execute(CreateCustomerReq request) {
        Customer customer = Customer.create(request.email(), request.name());
        customerRepo.save(customer);

        // Event stored in same transaction as customer
        DomainEventRecorder.record(new CustomerCreatedEvent(
            customer.id(),
            customer.email(),
            Instant.now()
        ));

        return customer;
    }
}
```

**Outbox Table Schema:**
```sql
CREATE TABLE outbox (
    event_id UUID PRIMARY KEY,
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE,
    retry_count INTEGER DEFAULT 0
);

CREATE INDEX idx_outbox_unpublished ON outbox (created_at)
    WHERE published_at IS NULL;
```

**Outbox Service:**
```java
@Service
public class OutboxService {

    @Scheduled(fixedDelayString = "${outbox.polling.interval:1000}")
    @Transactional
    public void publishPendingEvents() {
        List<OutboxEntry> pending = outboxRepo.findUnpublished(batchSize);
        for (OutboxEntry entry : pending) {
            try {
                rabbitTemplate.convertAndSend(
                    entry.exchange(),
                    entry.routingKey(),
                    entry.payload()
                );
                outboxRepo.markPublished(entry.eventId());
            } catch (Exception e) {
                outboxRepo.incrementRetry(entry.eventId());
            }
        }
    }
}
```

### Consequences

**Good:**
* Events are never lost - stored in database alongside business data
* Guaranteed eventual delivery even if broker is down
* Events only published if transaction commits (no phantom events)
* Audit trail of all events in outbox table
* Simple to understand and debug

**Bad:**
* Slight delay between transaction commit and event delivery
* Requires background polling process
* Outbox table grows and needs cleanup
* Additional database writes for every event

### Configuration

```yaml
outbox:
  polling:
    interval: 1000           # Poll every second
    batch-size: 100          # Events per poll
    max-retries: 3           # Retry failed events 3 times
    retention-days: 7        # Keep published events for 7 days
```

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/events/OutboxService.java`
* `services/libs/shared-application/src/main/java/.../events/DomainEventRecorder.java`
* `infrastructure/db/migrations/shared-libs/V1__create_outbox_table.sql`
* `documentation/PATTERNS.md` - Pattern decision guide
