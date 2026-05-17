<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: domain-driven-design
description: Domain-Driven Design patterns for Java — Value Objects, Entities, Domain Services, Application Services, Domain Events, Aggregates, Bounded Contexts, and Modules. Use when modeling complex business domains, designing entity behavior, or structuring DDD-aligned hexagonal services.
---

# Domain-Driven Design (DDD) Skill

Practical DDD patterns for Java developers, mapped to the backbone's hexagonal architecture and Quarkus ecosystem.

## When to Use
- Modeling complex business domains (insurance claims, loan management, healthcare)
- Designing entity behavior vs anemic data models
- Deciding between Value Object and Entity
- Structuring services (Domain vs Application vs Infrastructure)
- Implementing Domain Events for loose coupling
- Defining Bounded Contexts and module boundaries
- Reviewing whether code follows DDD principles

---

## Core Concepts Quick Reference

| Concept | Definition | Identity | Mutability | Example |
|---------|-----------|----------|------------|---------|
| **Value Object** | Describes a characteristic, no conceptual identity | Value-based equality | Immutable | `Email`, `Money`, `DateRange` |
| **Entity** | Has a unique identity, lifecycle, continuity | ID-based equality | Mutable state | `User`, `Order`, `Article` |
| **Aggregate** | Cluster of entities and VOs treated as one unit | Root entity has ID | Enforced invariants | `Order` + `OrderLine`s |
| **Domain Service** | Stateless business logic that doesn't fit an entity | N/A | Stateless | `PricingEngine`, `TransferService` |
| **Application Service** | Orchestrates use cases, no business logic | N/A | Stateless | `CreateOrderUseCase` |
| **Domain Event** | Something that happened in the domain | N/A | Immutable | `OrderPlacedEvent` |
| **Bounded Context** | Boundary where a domain model applies | N/A | N/A | `Billing`, `Inventory`, `Shipping` |

---

## 1. Value Objects

> "A small object such as Money or a date range. Their key property is that they follow value semantics rather than reference semantics." — Martin Fowler

### Characteristics

- **Equality by value** — Two VOs are equal if all their fields are equal
- **Immutable** — Never modify; create a new instance instead
- **Self-validating** — Constructor ensures the value is valid
- **Replaceable** — Swap one VO for another without side effects
- **No identity** — They are not stored in their own database table

### Value Object vs Entity

```
Value Object: Seat on Southwest Airlines (all seats are the same)
Entity:       Seat on most airlines (each seat is uniquely identified)

Value Object: Phone number in a contact app
Entity:       Phone line in a telecom system (has status, contract, history)
```

### Java Example

```java
// ✅ Value Object: Immutable, self-validating, equality by value
public record Email(String value) {

    public Email {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Email must not be empty");
        }
        if (!value.contains("@")) {
            throw new IllegalArgumentException("Invalid email format: " + value);
        }
    }

    public String domain() {
        return value.substring(value.indexOf("@") + 1);
    }
}

// ✅ Money value object
public record Money(BigDecimal amount, Currency currency) {

    public Money {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount must be non-negative");
        }
        if (currency == null) {
            throw new IllegalArgumentException("Currency is required");
        }
    }

    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("Cannot add different currencies");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }

    public Money multiply(int factor) {
        return new Money(this.amount.multiply(BigDecimal.valueOf(factor)), this.currency);
    }
}

// ✅ Usage in Entity constructor — true semantic meaning
public class User {
    private final UserId id;
    private final Email email;  // Not String!
    private final Name name;    // Not String!

    public User(UserId id, Email email, Name name) {
        this.id = id;
        this.email = email;
        this.name = name;
    }
}
```

### Entity ID as Value Object

```java
// ✅ Entity ID is a Value Object
public record UserId(UUID value) {

    public UserId {
        if (value == null) {
            throw new IllegalArgumentException("UserId must not be null");
        }
    }

    public static UserId generate() {
        return new UserId(UUID.randomUUID());
    }

    public static UserId fromString(String value) {
        return new UserId(UUID.fromString(value));
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
```

**Benefits of Value Objects:**
- Type safety — `Email` vs `String` prevents mixing up parameters
- Self-validation — Invalid values cannot be created
- Immutability — No side effects, thread-safe
- Rich behavior — `money.add(other)` reads like domain language

---

## 2. Entities

> "An object that has a distinct identity that runs through time and different states." — Eric Evans

### Characteristics

- **Identity** — Uniquely identified (UUID, ISBN, DNI, etc.)
- **Mutability** — State changes over time
- **Encapsulated behavior** — Methods modify state with business rules
- **Domain events** — Record what happened

### Identity Generation Strategies

| Strategy | When to Use | Trade-off |
|----------|-------------|-----------|
| **Application-generated UUID** | Most cases | No DB dependency, entity is complete at construction |
| **Client-provided** | Natural identifiers (ISBN, DNI) | Must ensure uniqueness |
| **Database-generated** | Legacy, simple CRUD | Entity is incomplete until persisted (DDD anti-pattern) |

**Recommendation:** Generate IDs in the application. Don't let the database own entity identity.

```java
// ✅ Application-generated UUID
public class Person {
    private final PersonId id;
    private Name name;
    private Email email;

    private Person(PersonId id, Name name, Email email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    public static Person create(Name name, Email email) {
        return new Person(PersonId.generate(), name, email);
    }

    // Entity behavior encapsulates state changes
    public void changeEmail(Email newEmail) {
        this.email = newEmail;
        recordEvent(new PersonEmailChangedEvent(this.id, newEmail));
    }

    // ... getters, events
}
```

### Entity Behavior (Rich Domain Model)

```java
// ✅ Entity encapsulates its own behavior and invariants
public class Article {
    private final ArticleId id;
    private String title;
    private String content;
    private ArticleStatus status;
    private Instant updatedAt;
    private final List<DomainEvent> domainEvents = new ArrayList<>();

    private Article(ArticleId id, String title, String content) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.status = ArticleStatus.DRAFT;
        this.updatedAt = Instant.now();
    }

    public static Article create(ArticleId id, String title, String content) {
        return new Article(id, title, content);
    }

    public void publish() {
        if (this.status == ArticleStatus.PUBLISHED) {
            throw new IllegalStateException("Article is already published");
        }
        this.status = ArticleStatus.PUBLISHED;
        this.updatedAt = Instant.now();
        recordEvent(new ArticlePublishedEvent(this.id));
    }

    public void updateContent(String newContent) {
        if (this.status == ArticleStatus.PUBLISHED) {
            throw new IllegalStateException("Cannot edit published article");
        }
        this.content = newContent;
        this.updatedAt = Instant.now();
    }

    public void changeTitle(String newTitle) {
        this.title = newTitle;
        this.updatedAt = Instant.now();
    }

    // Don't expose setters — expose intent-revealing methods
    // ❌ BAD: article.setStatus(PUBLISHED) — bypasses business rules!
    // ✅ GOOD: article.publish() — enforces invariants

    private void recordEvent(DomainEvent event) {
        this.domainEvents.add(event);
    }

    public List<DomainEvent> pullDomainEvents() {
        List<DomainEvent> events = new ArrayList<>(this.domainEvents);
        this.domainEvents.clear();
        return events;
    }
}
```

### Validation in Entities

```java
// ✅ Value-level validation belongs in Value Objects
public record Name(String value) {
    public Name {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Name must not be empty");
        }
        if (value.length() > 100) {
            throw new IllegalArgumentException("Name too long");
        }
    }
}

// ✅ Integrity validation (cross-field) belongs in Entity constructor or factory
public class Order {
    private final OrderId id;
    private final List<OrderLine> lines;
    private final Money total;

    private Order(OrderId id, List<OrderLine> lines) {
        this.id = id;
        this.lines = List.copyOf(lines);  // Defensive copy

        // Cross-field validation
        if (lines.isEmpty()) {
            throw new IllegalArgumentException("Order must have at least one line");
        }

        this.total = lines.stream()
            .map(OrderLine::subtotal)
            .reduce(Money.zero(Currency.USD), Money::add);
    }
}
```

---

## 3. Services

When behavior doesn't naturally belong to an entity or value object, use a service.

### Types of Services

| Type | Contains | Example |
|------|----------|---------|
| **Domain Service** | Business logic that spans multiple aggregates or doesn't fit an entity | `PricingEngine`, `FraudDetector` |
| **Application Service** | Orchestrates use cases, transforms DTOs to domain, dispatches events | `CreateOrderUseCase` |
| **Infrastructure Service** | Technical concerns (email, logging, persistence) | `SmtpEmailSender`, `JpaOrderRepository` |

### Domain Service

Stateless business logic that doesn't belong to a single entity.

```java
// ✅ Domain Service: Encapsulates cross-aggregate business logic
public class TransferService {

    public void transfer(Account from, Account to, Money amount) {
        if (!from.canWithdraw(amount)) {
            throw new InsufficientFundsException("Cannot transfer " + amount);
        }

        from.debit(amount);
        to.credit(amount);
        // Both accounts record their own domain events
    }
}

// ✅ Domain Service: Needs external dependency (encryption)
public class UserRegistrationService {
    private final PasswordEncoder passwordEncoder;

    public UserRegistrationService(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    public User register(Email email, String plainPassword) {
        Password hashedPassword = passwordEncoder.encode(plainPassword);
        return User.create(UserId.generate(), email, hashedPassword);
    }
}
```

**Domain Service receives dependencies via interfaces** (Dependency Inversion):

```java
// Domain defines the contract
public interface PasswordEncoder {
    Password encode(String plainPassword);
}

// Infrastructure provides the implementation
public class BCryptPasswordEncoder implements PasswordEncoder {
    @Override
    public Password encode(String plainPassword) {
        return new Password(BCrypt.hashpw(plainPassword, BCrypt.gensalt()));
    }
}
```

### Application Service

The "glue" between the outside world and the domain. No business logic.

```java
// ✅ Application Service: Orchestrates, no business rules
public class CreateOrderUseCase {
    private final OrderRepository orderRepository;
    private final EventPublisher eventPublisher;

    public CreateOrderUseCase(OrderRepository orderRepository,
                               EventPublisher eventPublisher) {
        this.orderRepository = orderRepository;
        this.eventPublisher = eventPublisher;
    }

    public OrderResult execute(CreateOrderRequest request) {
        // 1. Transform primitive request into domain objects
        CustomerId customerId = CustomerId.fromString(request.customerId());
        List<OrderLine> lines = request.items().stream()
            .map(item -> new OrderLine(
                ProductId.fromString(item.productId()),
                new Money(item.price(), Currency.USD),
                item.quantity()
            ))
            .toList();

        // 2. Create aggregate (business rules enforced in constructor)
        Order order = Order.create(customerId, lines);

        // 3. Persist
        orderRepository.save(order);

        // 4. Publish domain events
        order.pullDomainEvents().forEach(eventPublisher::publish);

        // 5. Return DTO (never return raw entities!)
        return new OrderResult(order.id().toString(), order.total().amount());
    }
}
```

### Anti-Pattern: Anemic Domain Model

```java
// ❌ ANTI-PATTERN: Entity is just data, all logic in services
public class Article {
    private Long id;          // Just fields
    private String title;
    private String status;    // String, not enum!
    // ... getters and setters only
}

public class ArticleService {
    public void publish(Article article) {
        article.setStatus("PUBLISHED");  // No validation, no invariants!
        article.setUpdatedAt(Instant.now());
        repository.save(article);
    }
}

// Problem: Any code can do article.setStatus("PUBLISHED") anywhere.
// The entity is not protecting its own invariants.
```

**Fix:** Move behavior to the entity. Entities should encapsulate their own state transitions.

---

## 4. Domain Events

> "A domain event is an event that captures something that happened in the domain. It is immutable, named in past tense, and contains the IDs of affected entities." — Eric Evans

### Characteristics

- **Named in past tense** — `OrderPlaced`, `UserEmailChanged`, `ArticlePublished`
- **Immutable** — Never modify after creation
- **Contains IDs, not entities** — Serializable, no ORM references
- **Timestamped** — When did it occur?
- **Recorded by entities** — The entity that changed records what happened
- **Dispatched by application services** — Infrastructure concern

### Implementation

```java
// ✅ Domain Event: Immutable, past tense, contains IDs
public record ArticlePublishedEvent(
    ArticleId articleId,
    Instant occurredOn
) implements DomainEvent {

    public ArticlePublishedEvent {
        if (articleId == null) {
            throw new IllegalArgumentException("articleId is required");
        }
        if (occurredOn == null) {
            throw new IllegalArgumentException("occurredOn is required");
        }
    }

    public ArticlePublishedEvent(ArticleId articleId) {
        this(articleId, Instant.now());
    }
}

// Domain Event marker interface
public interface DomainEvent {
    Instant occurredOn();
}
```

### Recording Events in Entities

```java
public class User {
    private final UserId id;
    private Email email;
    private final List<DomainEvent> domainEvents = new ArrayList<>();

    // Factory method records event
    public static User create(UserId id, Email email) {
        User user = new User(id, email);
        user.recordEvent(new UserCreatedEvent(id));
        return user;
    }

    public void changeEmail(Email newEmail) {
        Email oldEmail = this.email;
        this.email = newEmail;
        recordEvent(new UserEmailChangedEvent(this.id, oldEmail, newEmail));
    }

    private void recordEvent(DomainEvent event) {
        this.domainEvents.add(event);
    }

    public List<DomainEvent> pullDomainEvents() {
        List<DomainEvent> events = new ArrayList<>(this.domainEvents);
        this.domainEvents.clear();
        return events;
    }
}
```

### Dispatching Events

```java
// ✅ Application Service dispatches events after persistence
public class ChangeEmailUseCase {
    private final UserRepository repository;
    private final EventPublisher publisher;

    public void execute(UserId userId, Email newEmail) {
        User user = repository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));

        user.changeEmail(newEmail);
        repository.save(user);

        // Dispatch events so listeners can react
        user.pullDomainEvents().forEach(publisher::publish);
    }
}

// ✅ Listener reacts to event (loosely coupled)
public class WelcomeEmailListener {
    @EventListener
    public void onUserCreated(UserCreatedEvent event) {
        // Send welcome email
    }
}

public class AuditLogListener {
    @EventListener
    public void onEmailChanged(UserEmailChangedEvent event) {
        // Log audit trail
    }
}
```

### Benefits of Domain Events

- **Open/Closed** — Add new behavior without modifying existing use cases
- **Decoupled** — Side effects (email, audit, indexing) happen asynchronously
- **Audit trail** — Record of everything that happened
- **Smaller use cases** — Each does one thing, events handle the rest

---

## 5. Aggregates

An aggregate is a cluster of entities and value objects treated as a single unit for data changes.

### Rules

- **One aggregate root** — The entity that external code references
- **Root controls access** — Entities inside the aggregate cannot be modified directly
- **Transaction boundary** — One aggregate per transaction
- **Invariants enforced** — The aggregate ensures its internal consistency

```java
// ✅ Aggregate: Order (root) + OrderLine (child)
public class Order {
    private final OrderId id;
    private final CustomerId customerId;
    private final List<OrderLine> lines;  // Child entities
    private OrderStatus status;

    private Order(OrderId id, CustomerId customerId, List<OrderLine> lines) {
        this.id = id;
        this.customerId = customerId;
        this.lines = new ArrayList<>(lines);
        this.status = OrderStatus.PENDING;

        // Aggregate invariant
        if (lines.isEmpty()) {
            throw new IllegalArgumentException("Order must have at least one item");
        }
    }

    public static Order create(CustomerId customerId, List<OrderLine> lines) {
        return new Order(OrderId.generate(), customerId, lines);
    }

    public void addLine(ProductId product, Money price, int quantity) {
        if (status != OrderStatus.PENDING) {
            throw new IllegalStateException("Cannot modify submitted order");
        }
        lines.add(new OrderLine(product, price, quantity));
    }

    public void removeLine(ProductId product) {
        if (status != OrderStatus.PENDING) {
            throw new IllegalStateException("Cannot modify submitted order");
        }
        lines.removeIf(line -> line.productId().equals(product));

        // Enforce invariant after mutation
        if (lines.isEmpty()) {
            throw new IllegalStateException("Order must have at least one item");
        }
    }

    public Money total() {
        return lines.stream()
            .map(OrderLine::subtotal)
            .reduce(Money.zero(Currency.USD), Money::add);
    }

    public void submit() {
        if (status != OrderStatus.PENDING) {
            throw new IllegalStateException("Order already submitted");
        }
        this.status = OrderStatus.SUBMITTED;
        recordEvent(new OrderSubmittedEvent(this.id, total()));
    }

    // External code can read lines, but not modify directly
    public List<OrderLine> lines() {
        return List.copyOf(lines);  // Defensive copy
    }
}
```

---

## 6. Bounded Contexts

> "A bounded context is a boundary within which a particular domain model applies." — Eric Evans

### Key Idea

The same word can mean different things in different parts of a business:

| Term | In Sales Context | In Support Context |
|------|-----------------|-------------------|
| **Customer** | Someone who bought something | Someone who opened a ticket |
| **Product** | Something with a price | Something with known issues |
| **Account** | Billing entity | Login credentials |

Each context has its own model, its own language, its own database.

### Structure

```
ShopManager/                    # Product
├── sales/                      # Bounded Context: Sales
│   ├── src/
│   │   └── ShopManager/
│   │       ├── Customer/       # Module
│   │       │   ├── Domain/
│   │       │   ├── Application/
│   │       │   └── Infrastructure/
│   │       └── Order/          # Module
│   │           ├── Domain/
│   │           ├── Application/
│   │           └── Infrastructure/
│   └── tests/
├── support/                    # Bounded Context: Support
│   ├── src/
│   │   └── ShopManager/
│   │       ├── Ticket/         # Module
│   │       └── Customer/       # Different Customer model!
│   └── tests/
└── inventory/                  # Bounded Context: Inventory
    └── src/
```

### Communication Between Contexts

| Method | When | How |
|--------|------|-----|
| **REST API** | Synchronous, real-time | Each context exposes endpoints |
| **Domain Events** | Asynchronous, eventual consistency | Kafka/RabbitMQ between contexts |
| **Shared Kernel** | Small, stable subset both need | Extract to shared library (use sparingly) |

**Rule:** Don't share database tables between bounded contexts. Each context owns its data.

---

## 7. Modules

Within a bounded context, group code by domain concept, not by technical layer.

### Hexagonal Structure Within a Module

```
src/
└── ShopManager/
    └── Product/                    # Module: Product
        ├── Domain/                 # Core business logic
        │   ├── Model/
        │   │   ├── Product.java        # Entity
        │   │   ├── ProductId.java      # Value Object
        │   │   └── Price.java          # Value Object
        │   ├── Event/
        │   │   └── ProductCreatedEvent.java
        │   ├── Repository/
        │   │   └── ProductRepository.java  # Interface (port)
        │   └── Service/
        │       └── PricingService.java     # Domain Service
        ├── Application/            # Use cases
        │   ├── CreateProductUseCase.java
        │   └── GetProductByIdUseCase.java
        └── Infrastructure/        # Technical details
            ├── Persistence/
            │   ├── ProductEntity.java
            │   └── JpaProductRepository.java
            └── Web/
                └── ProductController.java
```

### Naming Rules

- Name modules using **ubiquitous language** (the language of the business)
- Don't create folders like `valueobjects/`, `repositories/`, `events/` inside Domain
- Group by concept: `Product/`, `Order/`, `Customer/`
- Within concept, split by layer: `Domain/`, `Application/`, `Infrastructure/`

---

## 8. DDD + Backbone Hexagonal Mapping

The backbone's hexagonal structure IS a DDD implementation:

| Backbone Layer | DDD Concept |
|---------------|-------------|
| `domain/model/vo/` | Value Objects, Entity IDs |
| `domain/model/` | Entities |
| `domain/event/` | Domain Events |
| `domain/actions/` | Repository Ports (interfaces) |
| `app/` | Application Services (Use Cases) |
| `infra/data/persistence/` | Repository Adapters |
| `infra/io/rest/` | Input Adapters |
| `infra/config/` | Dependency Injection wiring |

### Example: Complete DDD Service in Backbone

```java
// domain/model/vo/Email.java — Value Object
public record Email(String value) {
    public Email {
        if (value == null || !value.contains("@")) {
            throw new IllegalArgumentException("Invalid email");
        }
    }
}

// domain/model/vo/UserId.java — Entity ID as Value Object
public record UserId(UUID value) {
    public static UserId generate() { return new UserId(UUID.randomUUID()); }
}

// domain/model/User.java — Entity with behavior
public class User {
    private final UserId id;
    private Email email;
    private final List<DomainEvent> events = new ArrayList<>();

    public static User create(Email email) {
        User user = new User(UserId.generate(), email);
        user.recordEvent(new UserCreatedEvent(user.id));
        return user;
    }

    public void changeEmail(Email newEmail) {
        this.email = newEmail;
        recordEvent(new UserEmailChangedEvent(this.id, newEmail));
    }

    public List<DomainEvent> pullDomainEvents() { ... }
}

// domain/event/UserCreatedEvent.java — Domain Event
public record UserCreatedEvent(UserId userId, Instant occurredOn) implements DomainEvent {}

// domain/actions/UserCommandAction.java — Repository Port
public interface UserCommandAction {
    void save(User user);
    Optional<User> findById(UserId id);
}

// app/CreateUserUseCase.java — Application Service
@RequestScoped
public class CreateUserUseCase {
    private final UserCommandAction repository;
    private final EventPublisher publisher;

    public UserId execute(CreateUserRequest request) {
        User user = User.create(new Email(request.email()));
        repository.save(user);
        user.pullDomainEvents().forEach(publisher::publish);
        return user.id();
    }
}

// infra/data/persistence/sql/UserSqlCommandRepo.java — Repository Adapter
@ApplicationScoped
public class UserSqlCommandRepo implements UserCommandAction {
    private final Jdbi jdbi;
    // ... JDBI implementation
}
```

---

## DDD Review Checklist

When reviewing code for DDD alignment:

- [ ] **Value Objects** are immutable and self-validating
- [ ] **Entities** have identity, encapsulate behavior, no public setters
- [ ] **Domain logic** lives in entities, not application services
- [ ] **Domain Services** are stateless and named after domain operations
- [ ] **Application Services** orchestrate but don't contain business rules
- [ ] **Domain Events** are immutable, past-tense, contain IDs not entities
- [ ] **Aggregates** enforce invariants internally, root controls access
- [ ] **Repositories** return aggregates, not raw database rows
- [ ] **Modules** are named after domain concepts, not technical layers
- [ ] **No anemic domain model** — entities are not just data bags

---

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Anemic Domain Model** | Entities have only getters/setters | Move behavior to entities |
| **Database-Generated IDs** | Entity incomplete until persisted | Generate UUIDs in application |
| **Primitive Obsession** | Using `String`, `int` instead of VOs | Create `Email`, `Money`, `Name` |
| **Leaky Abstractions** | Domain imports `javax.persistence` | Pure domain, framework in infra |
| **God Aggregate** | Aggregate with 10+ entities | Split into smaller aggregates |
| **Domain Events with Entities** | Events contain ORM references | Events contain IDs only |
| **Shared Database** | Multiple contexts read same tables | Each context owns its data |

---

## Linked Skills

- **Hexagonal architecture** → Use `architecture-review` to verify layer boundaries
- **Value Objects in Java** → Use `java-core` for records and immutability patterns
- **Events between services** → Use `software-architectures` (Event-Driven section)
- **Testing entities** → Use `test-quality` for domain object testing
- **API design** → Use `api-design` for DTOs at application boundaries

---

## References

- *Domain-Driven Design* — Eric Evans
- *Implementing Domain-Driven Design* — Vaughn Vernon
- *Patterns, Principles, and Practices of Domain-Driven Design* — Scott Millett
