<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: software-architectures
description: Catalog of 20 essential software architectures for Java developers. Use when selecting an architecture for a new project, reviewing architecture choices, or migrating between architectural styles. Covers monolith, microservices, hexagonal, event-driven, CQRS, saga, and more.
---

# Software Architectures Catalog

Reference guide for the 20 architectures every Java developer should know, mapped to the backbone's hexagonal defaults and Java/Quarkus ecosystem.

## When to Use
- Starting a new project and need to choose an architecture
- Reviewing whether the current architecture fits the problem
- Planning migration from one architecture to another
- Evaluating if a service should be monolith, microservice, or serverless

---

## Architecture Decision Matrix

| Architecture | Best For | Team Size | Scale | Complexity |
|-------------|----------|-----------|-------|------------|
| **Monolithic** | MVPs, startups v1.0 | 1-5 | Low | Low |
| **Layered (N-Tier)** | Enterprise CRUD apps | 5-20 | Medium | Low |
| **Hexagonal** | Services with multiple adapters | 3-15 | Medium | Medium |
| **Clean** | Large enterprise, long-lived code | 10-50 | High | Medium |
| **DDD** | Complex business domains | 10-40 | High | High |
| **Microservices** | Independent scaling, polyglot | 20+ | Very High | High |
| **API Gateway** | 10+ microservices, public APIs | 15+ | High | Medium |
| **Event-Driven** | Async workflows, loose coupling | 10+ | Very High | High |
| **CQRS** | Read-heavy, audit-required systems | 10+ | High | High |
| **Event Sourcing** | 100% audit trail required | 10+ | High | Very High |
| **Saga** | Distributed transactions | 15+ | High | High |
| **Reactive** | 10K+ req/sec, streaming | 10+ | Very High | Medium |
| **Serverless** | Sporadic workloads, webhooks | 3-10 | Elastic | Low |
| **Strangler Fig** | Monolith → microservices migration | 10+ | Medium | Medium |
| **Cloud-Native** | K8s-first, auto-healing | 15+ | Very High | Medium |
| **SOA** | Legacy enterprise integration | 20+ | High | High |
| **Distributed** | Multi-region, fault-tolerant | 20+ | Very High | Very High |
| **Micro-Frontend** | Large SPA teams | 10+ | Medium | Medium |
| **API-First** | Multi-channel consumers | 5-20 | Medium | Low |
| **AI-Assisted** | ML-integrated products | 10+ | High | High |

---

## The 20 Architectures

### 1. Monolithic Architecture

**What it is:** One codebase, one deployment, all modules inside.

**When to use:**
- Small e-commerce MVP
- Startups building version 1.0
- Offline billing systems
- Team size < 5

**Backbone default:** The service generator creates modular monoliths (single service) by default. This IS a monolith, but organized hexagonally.

**Migration path:** Start here. When a module needs independent scaling, extract via Strangler Fig.

**Java/Quarkus fit:** Perfect fit. Quarkus fast startup makes monoliths viable even at scale.

---

### 2. Layered Architecture (N-Tier)

**What it is:** Controller → Service → Repository → DB. Classic Spring Boot style.

**When to use:**
- Banking internal apps
- Enterprise ERPs, HRMS, CRM
- Team familiar with Spring Boot conventions

**Backbone relation:** The backbone's `infra/`, `app/`, `domain/` is NOT layered — it's hexagonal. However, within `infra/io/rest/` you may see Controller→Service→Repository patterns.

**Warning:** Easy to become "transaction script" anti-pattern. Consider hexagonal if business logic grows.

---

### 3. Hexagonal Architecture (Ports & Adapters)

**What it is:** Domain at center. Inputs/outputs (DB, API, messaging) are adapters around it.

**When to use:**
- Payment gateways (Razorpay, Stripe)
- Systems with multiple adapters (REST + Kafka + DB)
- Strong domain isolation required

**Backbone default:** YES — this is the backbone's default architecture. See `backbone/4-KNOWLEDGE.md`.

**Key rule:** Dependencies point inward. Adapters → Application → Domain.

**Java/Quarkus mapping:**
- `domain/` — Pure Java, no framework imports
- `app/` — CDI use cases (`@RequestScoped`)
- `infra/` — JDBI repos, REST controllers, Kafka listeners

---

### 4. Event-Driven Architecture

**What it is:** Services communicate via events (Kafka, RabbitMQ, NATS). No direct REST calls.

**When to use:**
- Order workflows (OrderPlaced → PaymentProcessed → InventoryUpdated)
- Fraud detection
- Real-time tracking

**Backbone integration:** The template generates `domain/event/<Entity>CreatedEvent.java` and supports `@PublishEvents` outbox pattern.

**Quarkus stack:** Kafka/RabbitMQ extension + SmallRye Reactive Messaging.

---

### 5. Microservices Architecture

**What it is:** System broken into small independent services, each deploys separately.

**When to use:**
- Netflix, Uber, Amazon scale
- Teams need technology freedom
- Independent scaling requirements

**Backbone stance:** The backbone generates individual services. You compose them into a microservices ecosystem. Each service is hexagonal internally.

**Anti-pattern warning:** Don't start with microservices. Start monolithic-hexagonal, extract when needed.

---

### 6. Microservices with API Gateway

**What it is:** All microservices hidden behind a single entry point (Spring Cloud Gateway, Kong, AWS API Gateway, NGINX).

**When to use:**
- 10+ microservices
- Public API surface
- Need rate limiting, auth at edge

**Backbone integration:** Generate each service with the backbone, place a gateway in front.

#### API Gateway Core Functions

| Function | Description |
|----------|-------------|
| **Centralized Entry Point** | Single route for all clients. Clients communicate with one endpoint regardless of microservice complexity. |
| **Request Routing** | Routes requests to appropriate microservices based on URL, HTTP method, headers, or parameters. |
| **Protocol Translation** | Translates between client protocol (REST) and microservice protocol (gRPC, WebSocket, etc.). |
| **Authentication/Authorization** | Validates API keys, OAuth, JWT tokens at the edge. Implements RBAC. |
| **Request Aggregation** | Collects data from multiple microservices into a single response. Reduces client round-trips. |
| **Monitoring & Analytics** | Logs requests/responses, provides insights into system performance and usage patterns. |
| **Caching** | Caches microservice responses to reduce latency and improve scalability. |

#### API Gateway Disadvantages

| Disadvantage | Mitigation |
|--------------|------------|
| **Single Point of Failure** | Deploy gateway in HA configuration, use circuit breakers |
| **Increased Complexity** | Invest in gateway expertise, use declarative configuration |
| **Performance Bottleneck** | Optimize routing logic, use async processing, scale horizontally |
| **Service Discovery Burden** | Use dynamic configuration (Consul, Eureka, Kubernetes Ingress) |
| **Latency for Aggregated Requests** | Implement efficient caching, async aggregation |
| **Vendor Lock-In** | Use open-source gateway (Kong, NGINX, Spring Cloud Gateway) over cloud-managed |

#### API Gateway Implementation

**Kong Gateway (Docker Compose):**
```yaml
services:
  kong:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: postgres
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    ports:
      - "8000:8000"    # Proxy
      - "8443:8443"    # HTTPS
      - "8001:8001"   # Admin API
```

**Spring Cloud Gateway:**
```java
@Configuration
public class GatewayConfig {
    @Bean
    public RouteLocator routes(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("user-service", r -> r
                .path("/api/users/**")
                .filters(f -> f
                    .addRequestHeader("X-Gateway", "true")
                    .addResponseHeader("X-Gateway-Version", "1.0"))
                .uri("lb://user-service"))
            .route("order-service", r -> r
                .path("/api/orders/**")
                .filters(f -> f
                    .hystrix(c -> c.setName("order-fallback")
                        .setFallbackUri("forward:/fallback/order")))
                .uri("lb://order-service"))
            .build();
    }
}
```

**NGINX Configuration:**
```nginx
upstream user_service {
    server user-service:8080;
}

upstream order_service {
    server order-service:8080;
}

server {
    listen 80;

    location /api/users {
        proxy_pass http://user_service;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/orders {
        proxy_pass http://order_service;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

#### Routing Rules

| Pattern | Use Case |
|---------|----------|
| `/api/{service}/**` | Path-based routing (standard) |
| `header[ X-Service: user ]` | Header-based routing |
| `Method=POST, Path=/orders` | Method + path routing |
| `Queryparam[version]=v2` | Query parameter routing |

---

### 6b. Event-Driven: Choreography vs Orchestration

Event-driven microservices can use two patterns for coordinating business processes:

#### Choreography Pattern (Problematic)

```
Service A → [event] → Service B → [event] → Service C
     ↑                                          │
     └────────────────── [event] ───────────────┘
```

**What it is:** Services react to events from other services and produce their own events. No central coordinator.

**Issues:**
| Problem | Impact |
|---------|--------|
| Process scattered | No central view of business process implementation |
| Event schema coupling | Changes to event structure break downstream consumers |
| Fan-in complexity | Reacting to multiple events requires state storage |
| No transactions | Coordinating multi-service success/failure is hard |
| Hard to update | Changing process without breaking running instances is difficult |
| No observability | Customer support cannot trace process execution |

#### Orchestrator Pattern (Preferred)

```
Orchestrator → [command] → Service A
     ↑                        │
     │ [event]                ↓
     └ ←────────── Service B
```

**What it is:** A dedicated workflow service manages business process execution by sending commands and consuming events.

**Benefits:**
| Benefit | Description |
|---------|-------------|
| Centralized process | Business flow defined in one place, visible and versioned |
| Decoupling | Services don't need to know about other services' events |
| Fan-in easy | Orchestrator manages state, not consumers |
| Transactions | Compensating actions can reverse failed steps |
| Safe updates | Workflows can be versioned without breaking running instances |
| Observability | Built-in state tracking for support/debugging |

#### Framework: Infinitic

Open-source Java framework for orchestration-based event-driven apps. Built on Apache Pulsar.

**Components provided by Infinitic:**

| Component | Purpose |
|-----------|---------|
| Topic topology | Message schemas managed for you |
| Client | Start and interact with workflows |
| Service workers | Wrap your Java services (consumers/producers handled) |
| Workflow workers | Implement business logic in plain Java |
| Scheduler | Built-in, not your concern |

**Infinitic Benefits:**
- Horizontally scalable event-driven services
- Built-in error management (retries, dead letter queues, error propagation)
- Complex workflows with timers and signals
- Git-versioned workflow definitions
- Update workflows without breaking running instances
- Built-in workflow state observability

**Infinitic Architecture:**
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Service A │     │  Service B  │     │  Service C  │
│  (worker)  │     │  (worker)   │     │  (worker)   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │ events            │ events            │ events
       └──────────────────┬┴──────────────────┘
                          ↓
              ┌───────────────────────┐
              │   Apache Pulsar       │
              │  (event broker)       │
              └──────────┬───────────┘
                         ↓
              ┌───────────────────────┐
              │   Workflow Service    │
              │   (orchestrator)       │
              └───────────────────────┘
```

---

### 7. Service-Oriented Architecture (SOA)

**What it is:** Microservices predecessor. Big enterprise SOAP services.

**When to use:**
- Government systems
- Banking legacy integrations
- Telecom provisioning

**Backbone stance:** Generally avoid for new projects. Use REST/JSON microservices instead. Keep this skill for maintaining legacy.

---

### 8. Serverless Architecture

**What it is:** No application servers. Logic runs as functions (AWS Lambda, Azure Functions).

**When to use:**
- Image processing pipelines
- Scheduled jobs
- Payment webhooks
- Sporadic traffic (cost efficiency)

**Java/Quarkus fit:** Quarkus has excellent Lambda support via `quarkus-amazon-lambda` extension. Fast cold start with GraalVM native images.

---

### 9. Reactive Architecture

**What it is:** Non-blocking, asynchronous systems using WebFlux, Reactor, RxJava, or Mutiny.

**When to use:**
- High traffic APIs (10,000+ req/sec)
- Real-time chat
- Stock-market live feeds

**Quarkus stack:** Mutiny (built-in), SmallRye Reactive Messaging, Vert.x. Quarkus IS reactive by default.

---

### 10. CQRS (Command Query Responsibility Segregation)

**What it is:** Separate models for Commands (write) and Queries (read). Often paired with Event Sourcing.

**When to use:**
- Banking transactions
- Wallet systems (Paytm, PhonePe)
- Read-heavy with complex writes

**Backbone integration:** The template generates `domain/actions/<Entity>CommandAction.java` (command side) and search/list queries separately. Extend with read-model projections.

---

### 11. Event Sourcing Architecture

**What it is:** Store all events, not just final state. Rebuild state by replaying events.

**When to use:**
- Blockchain-like ledgers
- Wallet systems requiring full audit
- Inventory movement tracking

**Java ecosystem:** Axon Framework, EventStoreDB, or custom with Kafka + PostgreSQL.

---

### 12. Saga Architecture

**What it is:** Distributed transaction management without 2PC. Orchestration or choreography of compensating transactions.

**When to use:**
- Order processing (reserve → pay → ship, with rollback on failure)
- Multi-service workflows

**Patterns:**
- **Choreography:** Services react to each other's events
- **Orchestration:** Central saga coordinator manages flow

**Quarkus stack:** MicroProfile LRA (Long Running Actions), Camunda, or custom with Kafka.

---

### 13. Strangler Fig Architecture

**What it is:** Gradually migrate monolith → microservices. New features go to new services; old features get redirected.

**When to use:**
- Legacy banking migration
- Telecom billing modernization
- Any monolith that can't be rewritten in one go

**Backbone workflow:** Use the service generator for new services. Use API Gateway or proxy to route traffic incrementally.

---

### 14. Distributed Architecture

**What it is:** Services across distributed nodes: distributed caching, workflows, databases.

**When to use:**
- Redis Cluster, Kafka Cluster, Cassandra
- Kubernetes multi-zone deployments
- Multi-region active-active

**Quarkus stack:** Infinispan (caching), Kafka (messaging), Kubernetes (orchestration).

---

### 15. Clean Architecture

**What it is:** Robert C. Martin's structured version of hexagonal. More prescriptive about layers.

**When to use:**
- High-quality enterprise apps
- Fintech
- Startups building for scale

**Backbone relation:** The backbone's hexagonal is essentially Clean Architecture. The terms differ slightly:
- Hexagonal `domain/` ≈ Clean `entities/` + `use cases/`
- Hexagonal `infra/` ≈ Clean `frameworks & drivers/`

---

### 16. Domain-Driven Design (DDD)

**What it is:** Model software around the business domain. Entities, Value Objects, Aggregates, Repositories, Bounded Contexts.

**When to use:**
- Complex business systems (insurance claims, loan management)
- Healthcare
- Any domain where business rules are complex and changing

**Backbone integration:** The backbone's `domain/` layer is designed for DDD:
- Records = Value Objects
- `domain/model/vo/` = Entities and Value Objects
- `domain/actions/` = Repository ports ( Repositories)
- Each service = potential Bounded Context

---

### 17. Micro-Frontend Architecture

**What it is:** Split large UI into independent deployable frontend pieces.

**When to use:**
- Amazon product pages
- Netflix dashboard
- Large frontend teams

**Backbone scope:** Out of scope for backend generator, but relevant for full-stack projects using the `--frontend` flag.

---

### 18. API-First Architecture

**What it is:** Design the API contract first (OpenAPI), then generate code from spec.

**When to use:**
- Multi-consumer APIs (mobile + web + partners)
- Need predictable contracts
- Consumer-driven development

**Backbone integration:** Generate OpenAPI spec first, then use `openapi-generator` to create DTOs/controllers, or design spec alongside service generator.

---

### 19. Cloud-Native Architecture

**What it is:** Built for cloud/Kubernetes. Containerized, auto-healing, observable.

**When to use:**
- Netflix, Uber, Spotify scale
- K8s-first deployment
- Need horizontal pod autoscaling

**Quarkus is cloud-native by design:** Fast startup, low memory, native image, health checks, metrics (Micrometer), distributed tracing (OpenTelemetry).

---

### 20. AI-Assisted Architecture

**What it is:** Systems integrating ML models, recommendation engines, anomaly detection.

**When to use:**
- Fraud detection (UPI apps)
- Recommendation systems (Netflix, YouTube)
- Demand forecasting

**Java/Quarkus stack:**
- DJL (Deep Java Library) for inference
- REST/gRPC calls to Python ML services
- Quarkus LangChain4j for LLM integration

---

## Microservices Patterns (Bonus)

Beyond the 20 architectures, these patterns solve specific microservices challenges:

| Pattern | Problem Solved | Quarkus/Java Implementation |
|---------|---------------|----------------------------|
| **Service Decomposition** | How to split monolith | By feature/bounded context |
| **API Gateway** | Single entry point | Quarkus Gateway, Kong, NGINX |
| **Service Discovery** | Find services dynamically | Consul, Kubernetes DNS, Eureka |
| **Circuit Breaker** | Prevent cascading failures | MicroProfile Fault Tolerance (`@CircuitBreaker`) |
| **Bulkhead** | Isolate failures | Thread pool isolation, `@Bulkhead` |
| **Retry** | Handle transient failures | `@Retry`, exponential backoff |
| **Throttling** | Rate limiting | Bucket4j, API Gateway policies |
| **Externalized Config** | Config outside code | MicroProfile Config, Kubernetes ConfigMaps |
| **Sticky Session** | Session affinity | Avoid — use JWT/stateless instead |

---

## Architecture Migration Paths

### Start Simple, Evolve Complex

```
Monolith (Hexagonal)
    ↓ [Module needs independent scaling]
Strangler Fig Migration
    ↓ [Extract services one by one]
Microservices + API Gateway
    ↓ [Need async workflows]
Event-Driven + CQRS
    ↓ [Need audit trail]
Event Sourcing
```

### Decision Tree

```
Starting new project?
├── Team < 5, MVP phase?
│   └── Monolithic Hexagonal (backbone default)
├── Complex domain, changing rules?
│   └── DDD + Hexagonal
├── Need 10K+ req/sec?
│   └── Reactive + Hexagonal
├── Multiple teams, independent deploy?
│   └── Microservices (each hexagonal internally)
├── Legacy monolith, can't rewrite?
│   └── Strangler Fig
├── Sporadic traffic, cost-sensitive?
│   └── Serverless (Quarkus Lambda)
└── Need full audit trail?
    └── Event Sourcing + CQRS
```

---

## Anti-Pattern: Premature Architecture

> "I designed a system for a billion users while the application barely had fifty thousand."

**The rule:** Start with the simplest architecture that solves today's problem. Add complexity only when measurements prove it's needed.

**Example:** A username uniqueness check needs only:
```
User → Backend API → Database (unique index)
```
Not: User → API Gateway → Cache → Bloom Filter → Database Cluster

---

## Linked Skills

- **Architecture review** → Use `architecture-review` to evaluate if current structure matches chosen architecture
- **DDD implementation** → Use `domain-driven-design` for Value Objects, Entities, Services, Domain Events, and Bounded Contexts
- **Design patterns** → Use `design-patterns` for tactical implementations within architectural layers
- **New service** → Use `new-service` to generate services following hexagonal architecture
- **API design** → Use `api-design` when implementing API-First architecture
- **SOLID principles** → Use `solid-principles` to ensure architecture follows clean code principles

---

## Token Optimization

When discussing architecture with users:
1. Ask team size, scale, and domain complexity first
2. Recommend from the decision matrix (don't explain all 20)
3. Deep-dive only on the 2-3 relevant architectures
4. Reference this skill, don't copy all content into responses
