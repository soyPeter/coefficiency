# RabbitMQ for Asynchronous Messaging

## Status

Accepted

## Context and Problem Statement

The microservices architecture requires asynchronous communication for decoupling services and handling background tasks. We need to choose a message broker that provides reliability, ease of operations, and fits our team's expertise.

## Decision Drivers

* **Reliability**: Messages must not be lost
* **Operational simplicity**: Easy to deploy, monitor, and maintain
* **Team expertise**: Team has more experience with traditional message queues
* **Integration**: Good Spring Boot integration
* **Feature set**: Support for routing, dead-letter queues, retries

## Considered Options

* **RabbitMQ** - AMQP-based message broker with rich routing capabilities
* **Apache Kafka** - Distributed streaming platform with log-based storage
* **Amazon SQS** - Managed queue service with simpler semantics
* **Redis Streams** - Lightweight streaming with Redis

## Decision Outcome

Chosen option: **RabbitMQ**, because it provides reliable messaging with simpler operational overhead than Kafka and better routing flexibility than SQS.

### Implementation

**Exchange and Queue Naming Convention:**
```
Exchange: {domain}.events (e.g., customer.events)
Queue:    {consumer}.{event}.queue (e.g., notification.customer-created.queue)
Routing:  {domain}.{event} (e.g., customer.created)
```

**Publisher (via Outbox):**
```java
@Named
@Transactional
@PublishEvents(exchange = "customer.events", routingKey = "customer.created")
public class CreateCustomerUseCase {
    // Events recorded via DomainEventRecorder
    // Published by OutboxService to RabbitMQ
}
```

**Consumer:**
```java
@Component
public class CustomerCreatedListener {

    @RabbitListener(queues = "notification.customer-created.queue")
    public void onCustomerCreated(CustomerCreatedEvent event) {
        // Send welcome email
        emailService.sendWelcome(event.email());
    }
}
```

**Dead Letter Queue Configuration:**
```yaml
spring:
  rabbitmq:
    listener:
      simple:
        retry:
          enabled: true
          initial-interval: 1000
          max-interval: 10000
          multiplier: 2
          max-attempts: 3
        default-requeue-rejected: false

# Dead letter queue for failed messages
dlq:
  exchange: dlx.exchange
  routing-key: dlq
```

### Consequences

**Good:**
* Reliable message delivery with acknowledgments
* Rich routing capabilities (direct, topic, fanout, headers)
* Built-in dead-letter queue support
* Excellent Spring AMQP integration
* Web UI for monitoring queues
* Simpler operational model than Kafka

**Bad:**
* No built-in message replay (unlike Kafka's log)
* Scaling requires clustering setup
* No native stream processing capabilities
* Messages deleted after consumption

### Configuration

```yaml
spring:
  rabbitmq:
    host: ${RABBITMQ_HOST:localhost}
    port: ${RABBITMQ_PORT:5672}
    username: ${RABBITMQ_USER:guest}
    password: ${RABBITMQ_PASSWORD:guest}
    virtual-host: /bitnomio
    publisher-confirms: true
    publisher-returns: true

    listener:
      simple:
        acknowledge-mode: manual
        concurrency: 1
        max-concurrency: 5
        prefetch: 10
```

### Exchange/Queue Setup

```java
@Configuration
public class RabbitMQConfig {

    @Bean
    public TopicExchange customerExchange() {
        return new TopicExchange("customer.events");
    }

    @Bean
    public Queue customerCreatedQueue() {
        return QueueBuilder.durable("notification.customer-created.queue")
            .withArgument("x-dead-letter-exchange", "dlx.exchange")
            .withArgument("x-dead-letter-routing-key", "dlq")
            .build();
    }

    @Bean
    public Binding customerCreatedBinding(Queue queue, TopicExchange exchange) {
        return BindingBuilder.bind(queue)
            .to(exchange)
            .with("customer.created");
    }
}
```

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/messaging/` - RabbitMQ configuration
* `services/{service}/src/main/java/.../infra/io/events/` - Event listeners
* `application.yml` - RabbitMQ properties
* RabbitMQ documentation: https://www.rabbitmq.com/documentation.html
