<!-- FRAMEWORK: JAVA -->
---
framework: java
name: infinitic-patterns
description: Orchestration-based event-driven architecture with Infinitic framework. Use when building complex business workflows, need guaranteed event delivery, or want to replace choreography with centralized orchestration.
origin: agentic-backbone
version: "1.0"
---

# Infinitic Patterns

Orchestration-based event-driven architecture using Infinitic framework.

## When to Use

- Complex multi-service business processes (order fulfillment, onboarding, etc.)
- Need centralized workflow definition with observability
- Building idempotent services that react to commands and produce events
- Need sagas with compensating transactions
- Want built-in retries, DLQ, and error propagation
- Project type: `event-driven`, `workflow-orchestration`, `saga`

## When NOT to Use

- Simple request/response microservices
- Event-driven but simple fan-out (publish subscribe is enough)
- Already invested in choreography and it works well
- Team unfamiliar with orchestration model

## Core Concepts

### Commands vs Events

| Message Type | Direction | Semantic |
|-------------|-----------|----------|
| **Command** | Orchestrator → Service | "DO this action" |
| **Event** | Service → Orchestrator | "I DID this action" |

**Rule:** Services never call other services directly. They only emit events and receive commands.

### Workflow Service

Dedicated service that:
1. Owns the business process definition
2. Sends commands to services
3. Consumes events from services
4. Maintains workflow state in its own database
5. Can trigger other workflows

### Service Worker

Wrapper around your business logic that:
1. Receives commands from orchestrator
2. Executes business logic
3. Emits events back to orchestrator
4. Handles serialization/deserialization automatically

## Infinitic Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Application                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    Commands    ┌─────────────────────┐     │
│  │  Workflow   │ ←───────────── │    Service Worker    │     │
│  │  Service   │                │    (OrderService)    │     │
│  │(orchestrator)              └──────────┬──────────┘     │
│  └──────┬─────┘                           │                │
│         │ Events                          │ Events          │
│         └────────────────────┬────────────┘                │
│                              ↓                              │
│                    ┌─────────────────┐                     │
│                    │ Apache Pulsar   │                     │
│                    │ (event broker)  │                     │
│                    └────────┬────────┘                     │
│                             │                              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### 1. Define Commands and Events

```java
// Commands sent TO service
@Name("order.create")
@Version(1)
public class CreateOrder {
    @Tag private String orderId;
    @Tag private String customerId;
    private List<OrderItem> items;
}

@Name("order.cancel")
@Version(1)
public class CancelOrder {
    @Tag private String orderId;
    private String reason;
}

// Events emitted BY service
@Name("order.created")
@Version(1)
public class OrderCreated {
    @Tag private String orderId;
    private Instant createdAt;
}

@Name("order.cancelled")
@Version(1)
public class OrderCancelled {
    @Tag private String orderId;
    private Instant cancelledAt;
}
```

### 2. Implement Service Worker

```java
public class OrderServiceImpl implements OrderService {
    private final OrderRepository repository;

    @Override
    public OrderCreated createOrder(CreateOrder command) {
        Order order = Order.create(
            command.getOrderId(),
            command.getCustomerId(),
            command.getItems()
        );
        repository.save(order);

        return new OrderCreated(order.getId(), Instant.now());
    }

    @Override
    public OrderCancelled cancelOrder(CancelOrder command) {
        Order order = repository.findById(command.getOrderId());
        order.cancel(command.getReason());
        repository.save(order);

        return new OrderCancelled(order.getId(), Instant.now());
    }
}
```

### 3. Implement Workflow

```java
public class OrderWorkflowImpl implements OrderWorkflow {
    private final DispatchService dispatchService;
    private final PaymentService paymentService;
    private final NotificationService notificationService;

    @Override
    public void createOrder(CreateOrder order) {
        // 1. Create order
        OrderCreated created = dispatchService.createOrder(order);

        // 2. Process payment
        try {
            PaymentCaptured captured = paymentService.capturePayment(
                PaymentRequest.forOrder(created.getOrderId())
            );

            // 3. Notify success
            notificationService.notifyOrderCreated(created.getOrderId());

        } catch (PaymentFailed e) {
            // 4. Compensate: cancel order
            dispatchService.cancelOrder(
                CancelOrder.withReason(created.getOrderId(), "Payment failed")
            );
            notificationService.notifyOrderFailed(created.getOrderId(), e.getMessage());
        }
    }
}
```

### 4. Workflow State

Infinitic stores workflow state automatically:

```java
// Access workflow state
WorkflowState state = context.getState();

// Persist custom state
state.put("retryCount", retryCount);
state.put("customerEmail", email);
```

### 5. Timers and Delays

```java
@Override
public void handleOrderTimeout(OrderTimeout timeout) {
    // Check if order still pending
    if (orderRepository.isPending(timeout.getOrderId())) {
        // Cancel and notify
        dispatchService.cancelOrder(
            CancelOrder.withReason(timeout.getOrderId(), "Order timeout")
        );
        notificationService.notifyOrderTimeout(timeout.getOrderId());
    }
}

// In workflow, set a timer
context.createTimer(
    Instant.now().plus(Duration.ofMinutes(30)),
    new OrderTimeout(orderId)
);
```

### 6. Error Handling

```java
// Retry configuration
@Retry(maxAttempts = 3, delay = Duration.ofSeconds(10))
public PaymentCaptured capturePayment(PaymentRequest request) {
    return paymentGateway.charge(request);
}

// Dead letter handling
@OnFailure(maxAttempts = 3)
public void onPaymentFailure(PaymentFailed failure) {
    // Alert ops team, manual intervention
    opsChannel.alert("Payment failed after retries", failure);
}
```

## SAGA Pattern with Compensations

Infinitic supports saga pattern with compensating transactions:

```java
public class OrderSaga implements OrderSagaWorkflow {

    @Override
    public void processOrder(CreateOrder command) {
        // Step 1: Reserve inventory
        InventoryReserved reserved = inventoryService.reserve(
            new ReserveInventory(command.getOrderId(), command.getItems())
        );

        // Step 2: Capture payment
        PaymentCaptured captured = paymentService.capture(
            new CapturePayment(command.getOrderId(), command.getAmount())
        );

        // Step 3: Create shipment
        ShipmentCreated shipment = shippingService.create(
            new CreateShipment(command.getOrderId(), command.getAddress())
        );

        // If anything fails after this point, compensations run automatically
    }

    // Compensation methods (called automatically on failure)
    @Compensation
    public void cancelShipment(ShipmentCreated shipment) {
        shippingService.cancel(shipment.getShipmentId());
    }

    @Compensation
    public void refundPayment(PaymentCaptured payment) {
        paymentService.refund(payment.getTransactionId());
    }

    @Compensation
    public void releaseInventory(InventoryReserved reserved) {
        inventoryService.release(reserved.getReservationId());
    }
}
```

## Workflow Versioning

Infinitic supports updating workflows without breaking running instances:

```java
@Name("order.process")
@Version(2)  // Version 2 of the workflow
public class OrderWorkflowV2 implements OrderWorkflow {
    // New logic with additional steps
}
```

**Rules:**
- Running workflows continue with their original version
- New workflows use the latest version
- Event schema changes should be backward compatible

## Deployment

### Docker Compose (Development)

```yaml
services:
  pulsar:
    image: apachepulsar/pulsar:latest
    command: bin/pulsar standalone
    ports:
      - "6650:6650"
      - "8080:8080"

  order-service:
    build: ./order-service
    depends_on:
      - pulsar
    environment:
      PULSAR_SERVICE_URL: pulsar://pulsar:6650

  workflow-service:
    build: ./workflow-service
    depends_on:
      - pulsar
    environment:
      PULSAR_SERVICE_URL: pulsar://pulsar:6650
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-workflow
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-workflow
  template:
    metadata:
      labels:
        app: order-workflow
    spec:
      containers:
        - name: workflow
          image: myapp/order-workflow:latest
          env:
            - name: PULSAR_SERVICE_URL
              value: "pulsar://pulsar:6650"
```

## Monitoring

### Infinitic Dashboard

Infinitic provides built-in workflow state visibility:

```bash
# View running workflows
infinitic workflow ls --status=RUNNING

# View workflow history
infinitic workflow history --id=order-12345

# View current state
infinitic workflow state --id=order-12345
```

### Metrics

```java
// Custom metrics
@Metric(name = "order_created", tags = {"service=order"})
public OrderCreated createOrder(CreateOrder cmd) { }

// Metrics exposed at /metrics endpoint
// - infinitic_workflow_running
// - infinitic_workflow_completed
// - infinitic_workflow_failed
// - infinitic_workflow_duration_seconds
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Workflow knows too much | Workflow doing too much logic | Keep services dumb, workflow orchestrates |
| Synchronous calls in workflow | Defeats async benefits | Use commands/events only |
| Large workflow state | State bloat | Persist only workflow ID, fetch data from services |
| No compensating actions | Failed sagas leave inconsistent state | Always implement compensation for non-idempotent operations |

## Related Skills

- Skill: `cqrs-event-sourcing` — CQRS and event sourcing fundamentals
- Skill: `outbox-pattern` — Reliable event publishing from services
- Skill: `nats-patterns` — NATS messaging for CDC pipelines
- Skill: `software-architectures` — Architecture decision matrix