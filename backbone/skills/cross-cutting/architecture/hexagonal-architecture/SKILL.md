<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: hexagonal-architecture
description: Comprehensive deep-dive into Hexagonal Architecture (Ports and Adapters) — from theory to production-ready implementation. Covers Dependency Inversion, Domain/Application/Infrastructure layers, Ports and Adapters, Spring Boot examples, testing strategies, migration patterns, and common pitfalls.
---

# Hexagonal Architecture (Ports and Adapters)

Comprehensive deep-dive into building maintainable, testable, and resilient software systems using Hexagonal Architecture.

## When to Use

- Building services with complex business logic that must survive infrastructure changes
- Systems with multiple external integrations (databases, APIs, message queues)
- Long-lived applications where tech stack may evolve over years
- Projects requiring comprehensive, fast test suites
- Teams practicing Domain-Driven Design
- Reviewing whether code respects hexagonal layer boundaries
- Migrating legacy layered applications toward better testability

---

## Core Problem

In traditional layered architecture, business logic is tightly coupled to infrastructure:

```java
// Traditional — business logic mixed with infrastructure
@Service
public class PaymentService {
    @Autowired
    private PaymentRepository repository;  // JPA dependency
    @Autowired
    private RestTemplate restTemplate;     // HTTP client
    @Autowired
    private JavaMailSender mailSender;     // Email library

    public void processPayment(Payment payment) {
        if (payment.getAmount() > 10000) {
            ResponseEntity<ValidationResult> response =
                restTemplate.getForEntity("https://api.fraud-check.com/validate",
                                         ValidationResult.class);
        }
        repository.save(payment);
        mailSender.send(createEmail(payment));
    }
}
```

**Problems:** testing nightmare, fragile to schema changes, vendor lock-in, business rules buried in technical details.

Hexagonal Architecture (Alistair Cockburn, 2005) solves this: **"Allow an application to be developed and tested in isolation from its eventual run-time devices and databases."**

---

## Fundamental Principles

### 1. Dependency Inversion

Dependencies point inward, toward the domain:

```
External Systems → Adapters → Ports (Interfaces) → Domain
                                    ↑
                          Domain defines what it needs
```

```java
// Domain defines what it needs (port interface)
public interface OrderRepository {
    Order save(Order order);
}

// Infrastructure implements what domain needs (adapter)
public class JpaOrderRepository implements OrderRepository {
    // JPA specifics hidden here
}
```

### 2. Business Logic Isolation

Domain code must be:
- **Framework-agnostic** — no Spring/Quarkus/Jakarta annotations in domain
- **Technology-agnostic** — no database, HTTP, or UI concerns
- **Testable in isolation** — no containers, databases, or networks
- **Expressive** — written in business language, not technical jargon

### 3. Symmetry of External Dependencies

All external systems (UI, database, APIs, message queues, file system) are treated identically: through **ports** and **adapters**.

### 4. The Core Decision Rule

To decide if something belongs inside or outside the hexagon, ask:

> **"Does it do I/O or run out-of-process?"**

- **No** → Inside the hexagon (domain or application layer)
- **Yes** → Outside (adapter)

**Critical:** A component's dependencies disqualify it even if the component itself doesn't do I/O. If it depends on Spring, a database driver, or any framework — it's outside.

---

## Three Layers

Common misconception: **the hexagon contains BOTH domain AND application layers.** Adapters sit outside.

```
┌─────────────────────────────────────────┐
│           ADAPTERS (outside)            │
│  Web, CLI, Database, External APIs      │
│  ┌───────────────────────────────────┐  │
│  │     APPLICATION / USE CASES       │  │     ← Orchestration
│  │  ┌─────────────────────────────┐  │  │
│  │  │         DOMAIN              │  │  │     ← Pure business logic
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
        Dependencies flow INWARD only
```

### Domain (Core)

Pure business logic with zero infrastructure dependencies. Contains:
- **Entities** — objects with identity and lifecycle
- **Value Objects** — immutable, equality-by-value
- **Domain Events** — things that happened in the domain
- **Domain Services** — stateless logic not fitting a single entity
- **Port interfaces** — what the domain needs from the outside world

### Application (Use Cases)

Orchestrates domain objects and coordinates workflows. Contains:
- **Use Case / Application Services** — implement primary ports
- **Commands / Queries** — input for use cases

### Infrastructure (Adapters)

Technical implementations that connect to the real world. Contains:
- **Primary Adapters** — REST controllers, message consumers, CLI commands
- **Secondary Adapters** — JPA repositories, HTTP clients, email senders
- **Configuration** — DI wiring, framework setup

---

## Implementation Order

Build features in this order — each layer depends on the one below:

1. **Domain** — Entities, Value Objects, Repository Interfaces
2. **Application** — Use Cases, Services, DTOs
3. **Infrastructure** — Repositories, Controllers, Adapters

You can't build use cases without entities. You can't build controllers without use cases.

---

## Ports: The Contracts

### Primary Ports (Driving/Inbound)

Define what the application **can do** — the API of business logic:

```java
public interface ProcessPayment {
    PaymentResult processPayment(PaymentRequest request);
    PaymentStatus checkPaymentStatus(String paymentId);
    void cancelPayment(String paymentId);
}
```

Characteristics:
- Defined by business requirements, not technical constraints
- Express use cases in domain language
- Implemented by application services

### Secondary Ports (Driven/Outbound)

Define what the application **needs** from the outside world:

```java
public interface PaymentRepository {
    Payment save(Payment payment);
    Optional<Payment> findById(PaymentId id);
}

public interface FraudDetection {
    FraudCheckResult checkForFraud(Transaction transaction);
}

public interface NotificationService {
    void sendPaymentConfirmation(Payment payment);
}
```

Characteristics:
- Defined by domain needs, not infrastructure capabilities
- Implemented by adapters
- Easy to mock for testing

---

## Adapters: The Translators

### Primary Adapters (Driving/Inbound)

Drive the application by calling primary ports. Controllers are thin: validate input → call use case → return response. **Zero business logic.**

```java
@RestController
@RequestMapping("/api/payments")
public class PaymentController {
    private final ProcessPayment processPayment;

    @PostMapping
    public ResponseEntity<PaymentResponseDTO> createPayment(
            @RequestBody PaymentRequestDTO requestDTO) {
        PaymentRequest request = PaymentMapper.toDomain(requestDTO);
        PaymentResult result = processPayment.processPayment(request);
        return ResponseEntity.ok(PaymentMapper.toDTO(result));
    }
}
```

**Examples:** REST Controllers, GraphQL Resolvers, CLI Commands, Message Queue Consumers, WebSocket Handlers, Scheduled Jobs

### Secondary Adapters (Driven/Outbound)

Implement what the domain needs. They translate between domain types and infrastructure types:

```java
@Component
public class JpaPaymentRepositoryAdapter implements PaymentRepository {
    private final SpringDataPaymentRepository springRepo;
    private final PaymentEntityMapper mapper;

    @Override
    public Payment save(Payment payment) {
        PaymentEntity entity = mapper.toEntity(payment);
        PaymentEntity saved = springRepo.save(entity);
        return mapper.toDomain(saved);
    }
}
```

**Examples:** JPA/MongoDB Repositories, REST API Clients, Message Queue Publishers, Email Senders, File System Access, Cache Implementations

### Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| **Request DTO** | `*Request` | `CreatePaymentRequest` |
| **Response DTO** | `*Response` or `*View` | `PaymentResponse`, `OrderView` |
| **Persistence entity** | `*Dbo` or `*Entity` | `PaymentDbo`, `PaymentEntity` |
| **Domain → DTO** | `from(domain)` or `toDTO()` | `PaymentResponse.from(payment)` |
| **DTO → Domain** | `toDomain()` or `as*()` | `mapper.toDomain(request)`, `request.asPayment()` |
| **Controller** | `*Controller` | `PaymentController` |
| **Use case** | `*Service` | `CreatePaymentService` |

---

## Module Structure

```
service/
├── domain/
│   ├── model/
│   │   ├── Payment.java
│   │   ├── Money.java
│   │   └── Customer.java
│   ├── port/
│   │   ├── in/
│   │   │   ├── ProcessPaymentUseCase.java
│   │   │   └── QueryPaymentUseCase.java
│   │   └── out/
│   │       ├── PaymentRepository.java
│   │       ├── FraudDetection.java
│   │       └── NotificationService.java
│   └── exception/
│       └── PaymentException.java
│
├── application/
│   ├── service/
│   │   ├── PaymentService.java
│   │   └── PaymentQueryService.java
│   └── config/
│       └── UseCaseConfig.java
│
└── infrastructure/
    ├── adapter/
    │   ├── in/
    │   │   ├── rest/
    │   │   │   ├── PaymentController.java
    │   │   │   └── dto/
    │   │   └── messaging/
    │   │       └── PaymentEventConsumer.java
    │   └── out/
    │       ├── persistence/
    │       │   ├── JpaPaymentAdapter.java
    │       │   └── entity/
    │       ├── fraud/
    │       │   └── ExternalFraudServiceAdapter.java
    │       └── notification/
    │           └── EmailNotificationAdapter.java
    └── config/
        └── SpringConfiguration.java
```

### TypeScript/Node.js Module Structure

```
src/
├── domain/
│   ├── entities/
│   │   ├── payment.entity.ts
│   │   └── money.value-object.ts
│   ├── ports/
│   │   ├── in/
│   │   │   └── process-payment.use-case.ts     # interface
│   │   └── out/
│   │       ├── payment.repository.ts            # interface
│   │       └── fraud-detection.ts               # interface
│   └── events/
│       └── payment-processed.event.ts
├── application/
│   └── use-cases/
│       └── process-payment.service.ts           # implements port
└── infrastructure/
    ├── adapters/
    │   ├── in/
    │   │   └── rest/
    │   │       ├── payment.controller.ts
    │   │       └── payment.request.dto.ts
    │   └── out/
    │       ├── persistence/
    │       │   ├── prisma-payment.repository.ts
    │       │   └── payment-entity.ts
    │       └── fraud/
    │           └── http-fraud-detection.ts
    └── config/
        └── di.config.ts
```

---

## Domain Layer — Complete Examples

### Java — Entity with Behavior

```java
// domain/model/Payment.java
// NO framework imports — pure Java
public class Payment {
    private final PaymentId id;
    private final Money amount;
    private final CustomerId customerId;
    private PaymentStatus status;
    private final PaymentMethod method;
    private final Instant createdAt;
    private Instant completedAt;
    private final List<DomainEvent> domainEvents = new ArrayList<>();

    public Payment(PaymentId id, Money amount, CustomerId customerId,
                   PaymentMethod method) {
        this.id = Objects.requireNonNull(id);
        this.amount = Objects.requireNonNull(amount);
        this.customerId = Objects.requireNonNull(customerId);
        this.method = Objects.requireNonNull(method);
        this.status = PaymentStatus.PENDING;
        this.createdAt = Instant.now();
        validateAmount();
    }

    private void validateAmount() {
        if (amount.isNegativeOrZero()) {
            throw new InvalidPaymentException("Amount must be positive");
        }
        if (amount.isGreaterThan(Money.of(1_000_000))) {
            throw new InvalidPaymentException("Amount exceeds maximum limit");
        }
    }

    public void markAsProcessing() {
        if (status != PaymentStatus.PENDING) {
            throw new IllegalStateException(
                "Cannot process payment in status: " + status);
        }
        this.status = PaymentStatus.PROCESSING;
    }

    public void complete() {
        if (status != PaymentStatus.PROCESSING) {
            throw new IllegalStateException(
                "Cannot complete payment in status: " + status);
        }
        this.status = PaymentStatus.COMPLETED;
        this.completedAt = Instant.now();
        domainEvents.add(new PaymentCompletedEvent(this.id));
    }

    public void fail(String reason) {
        this.status = PaymentStatus.FAILED;
        domainEvents.add(new PaymentFailedEvent(this.id, reason));
    }

    public List<DomainEvent> pullDomainEvents() {
        var emitted = List.copyOf(domainEvents);
        domainEvents.clear();
        return emitted;
    }
}
```

### Java — Value Object

```java
// domain/model/Money.java
public class Money {
    private final BigDecimal amount;
    private final Currency currency;

    private Money(BigDecimal amount, Currency currency) {
        if (amount == null) throw new IllegalArgumentException("Amount cannot be null");
        this.amount = amount.setScale(2, RoundingMode.HALF_UP);
        this.currency = Objects.requireNonNull(currency);
    }

    public static Money of(BigDecimal amount, Currency currency) {
        return new Money(amount, currency);
    }

    public static Money of(double amount) {
        return new Money(BigDecimal.valueOf(amount), Currency.EUR);
    }

    public boolean isGreaterThan(Money other) {
        assertSameCurrency(other);
        return this.amount.compareTo(other.amount) > 0;
    }

    public boolean isNegativeOrZero() {
        return amount.compareTo(BigDecimal.ZERO) <= 0;
    }

    public Money add(Money other) {
        assertSameCurrency(other);
        return new Money(this.amount.add(other.amount), this.currency);
    }

    private void assertSameCurrency(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException(
                "Cannot operate on different currencies");
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Money money)) return false;
        return amount.compareTo(money.amount) == 0 && currency.equals(money.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount.stripTrailingZeros(), currency);
    }
}
```

### TypeScript — Rich Entity

```typescript
// domain/entities/cell.entity.ts
export class CellEntity {
  constructor(
    private readonly _id: number,
    private readonly _level: LevelValueObject,
    private _status: CellStatus,
    private _blockReasonId: number | null
  ) {}

  get id(): number { return this._id }
  get level(): LevelValueObject { return this._level }

  // BEHAVIOR — not just getters
  isPicking(): boolean {
    return this._level.isPicking()
  }

  isBlocked(): boolean {
    return this._blockReasonId !== null
  }

  isAvailable(): boolean {
    return this._status === 'available' && !this.isBlocked()
  }

  block(reasonId: number): void {
    if (this.isBlocked()) throw new Error('Already blocked')
    this._blockReasonId = reasonId
    this._status = 'blocked'
  }
}

// domain/value-objects/level.value-object.ts
export class LevelValueObject {
  private readonly _value: number

  constructor(value: number) {
    if (value < 0 || value > 90) {
      throw new Error(`Level must be 0-90, got ${value}`)
    }
    if (value % 10 !== 0) {
      throw new Error(`Level must be multiple of 10, got ${value}`)
    }
    this._value = value
  }

  get value(): number { return this._value }
  isPicking(): boolean { return this._value === 0 }
  isReserve(): boolean { return this._value > 0 }

  equals(other: LevelValueObject): boolean {
    return this._value === other._value
  }
}
```

---

## Application Layer — Use Cases

Use cases orchestrate domain objects. They receive ports via constructor injection, return DTOs or void — never domain entities to infrastructure callers.

```java
// application/service/PaymentService.java
// @Transactional belongs here — on the use case, not in domain
@Transactional
public class PaymentService implements ProcessPaymentUseCase {

    private final PaymentRepository paymentRepository;
    private final FraudDetection fraudDetection;
    private final NotificationService notificationService;

    public PaymentService(
            PaymentRepository paymentRepository,
            FraudDetection fraudDetection,
            NotificationService notificationService) {
        this.paymentRepository = paymentRepository;
        this.fraudDetection = fraudDetection;
        this.notificationService = notificationService;
    }

    @Override
    public PaymentResult processPayment(ProcessPaymentCommand command) {
        Payment payment = new Payment(
            PaymentId.generate(),
            command.getAmount(),
            command.getCustomerId(),
            command.getMethod()
        );

        FraudCheckResult fraudCheck = fraudDetection.checkForFraud(payment);
        if (fraudCheck.isFraudulent()) {
            payment.fail("Fraud detected");
            paymentRepository.save(payment);
            notificationService.notifyPaymentFailed(payment, "Fraud detected");
            return PaymentResult.failure(payment.getId(), "Fraud detected");
        }

        try {
            payment.markAsProcessing();
            processWithGateway(payment);
            payment.complete();
            Payment saved = paymentRepository.save(payment);
            dispatchEvents(saved);
            notificationService.notifyPaymentProcessed(saved);
            return PaymentResult.success(saved);
        } catch (Exception e) {
            payment.fail(e.getMessage());
            paymentRepository.save(payment);
            notificationService.notifyPaymentFailed(payment, e.getMessage());
            return PaymentResult.failure(payment.getId(), e.getMessage());
        }
    }

    private void dispatchEvents(Payment payment) {
        for (DomainEvent event : payment.pullDomainEvents()) {
            eventDispatcher.dispatch(event);
        }
    }
}
```

### Commands and Queries

```java
// Command — intent to change state
public class ProcessPaymentCommand {
    private final CustomerId customerId;
    private final Money amount;
    private final PaymentMethod method;
    private final Map<String, String> metadata;

    // Constructor, getters, validation
}

// Query — intent to read state
public class GetPaymentDetailsQuery {
    private final String paymentId;

    // Constructor, getters
}
```

---

## Infrastructure Layer — Adapters

### Java — Persistence Adapter

```java
// adapter/out/persistence/JpaPaymentRepositoryAdapter.java
@Repository
public class JpaPaymentRepositoryAdapter implements PaymentRepository {

    private final SpringDataPaymentRepository jpaRepo;
    private final PaymentMapper mapper;

    public JpaPaymentRepositoryAdapter(
            SpringDataPaymentRepository jpaRepo,
            PaymentMapper mapper) {
        this.jpaRepo = jpaRepo;
        this.mapper = mapper;
    }

    @Override
    public Payment save(Payment payment) {
        PaymentEntity entity = mapper.toEntity(payment);
        return mapper.toDomain(jpaRepo.save(entity));
    }

    @Override
    public Optional<Payment> findById(PaymentId id) {
        return jpaRepo.findById(id.getValue())
                .map(mapper::toDomain);
    }

    @Override
    public List<Payment> findByCustomerId(CustomerId customerId) {
        return jpaRepo.findByCustomerId(customerId.getValue())
                .stream().map(mapper::toDomain).toList();
    }
}

// adapter/out/persistence/entity/PaymentEntity.java  — JPA stays in adapter
@Entity
@Table(name = "payments")
class PaymentEntity {
    @Id private String id;
    @Column(nullable = false) private BigDecimal amount;
    @Column(nullable = false) private String currency;
    @Column(name = "customer_id", nullable = false) private String customerId;
    @Enumerated(EnumType.STRING) private PaymentStatus status;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "completed_at") private Instant completedAt;

    protected PaymentEntity() {}  // JPA requirement
    // getters and setters
}

// adapter/out/persistence/PaymentMapper.java
@Component
public class PaymentMapper {
    PaymentEntity toEntity(Payment domain) {
        PaymentEntity entity = new PaymentEntity();
        entity.setId(domain.getId().getValue());
        entity.setAmount(domain.getAmount().getAmount());
        entity.setCurrency(domain.getAmount().getCurrency().toString());
        entity.setCustomerId(domain.getCustomerId().getValue());
        entity.setStatus(domain.getStatus());
        entity.setCreatedAt(domain.getCreatedAt());
        return entity;
    }

    Payment toDomain(PaymentEntity entity) {
        return new Payment(
            PaymentId.from(entity.getId()),
            Money.of(entity.getAmount(), Currency.valueOf(entity.getCurrency())),
            CustomerId.from(entity.getCustomerId()),
            entity.getCreatedAt(),
            entity.getStatus(),
            entity.getCompletedAt()
        );
    }
}
```

### TypeScript — Persistence Adapter

```typescript
// infrastructure/adapters/out/persistence/prisma-cell.repository.ts
@Injectable()
export class PrismaCellRepository implements ICellRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: number): Promise<CellEntity | null> {
    const data = await this.prisma.cell.findUnique({ where: { id } })
    if (!data) return null
    return this.toEntity(data)
  }

  async create(entity: CellEntity): Promise<CellEntity> {
    const data = await this.prisma.cell.create({
      data: this.toModel(entity),
    })
    return this.toEntity(data)
  }

  private toEntity(data: CellRecord): CellEntity {
    return new CellEntity(
      data.id,
      new LevelValueObject(data.level),
      data.status as CellStatus,
      data.blockReasonId,
    )
  }

  private toModel(entity: CellEntity): CellInput {
    return {
      level: entity.level.value,
      status: entity['_status'],
      blockReasonId: entity['_blockReasonId'],
    }
  }
}
```

### External Service Adapter

```java
// infrastructure/adapter/out/fraud/ExternalFraudServiceAdapter.java
@Component
public class ExternalFraudServiceAdapter implements FraudDetection {

    private final RestTemplate restTemplate;
    private final FraudServiceProperties properties;

    public ExternalFraudServiceAdapter(
            RestTemplate restTemplate,
            FraudServiceProperties properties) {
        this.restTemplate = restTemplate;
        this.properties = properties;
    }

    @Override
    public FraudCheckResult checkForFraud(Payment payment) {
        try {
            FraudCheckRequest request = new FraudCheckRequest(
                payment.getCustomerId().getValue(),
                payment.getAmount().getAmount(),
                payment.getAmount().getCurrency().toString()
            );

            ResponseEntity<FraudCheckResponse> response = restTemplate.postForEntity(
                properties.getApiUrl() + "/check",
                request,
                FraudCheckResponse.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return new FraudCheckResult(
                    response.getBody().isFraudulent(),
                    response.getBody().getRiskScore(),
                    response.getBody().getReason());
            }
            return FraudCheckResult.safe();
        } catch (Exception e) {
            // Decide on fail-open vs fail-closed strategy
            return FraudCheckResult.safe();  // fail-open
        }
    }
}
```

### Dependency Injection Wiring

```java
// config/MarketConfig.java — bind interfaces to implementations
@Configuration
class MarketConfig {

    @Bean
    CreateMarketUseCase createMarketUseCase(
            MarketRepository marketRepository,
            NotificationPort notificationPort) {
        return new CreateMarketService(marketRepository, notificationPort);
    }

    @Bean
    PaymentRepository paymentRepository(
            SpringDataPaymentRepository jpaRepo,
            PaymentMapper mapper) {
        return new JpaPaymentRepositoryAdapter(jpaRepo, mapper);
    }
}
```

```php
// Service Provider — Laravel binding
$this->app->bind(LessonRepository::class, EloquentLessonRepository::class);
$this->app->bind(CourseGenerationService::class, HttpCourseGenerationService::class);
```

---

## Domain Events

Signal that something meaningful happened. Raised inside entities, collected via `pullDomainEvents()`, dispatched by the use case after save.

```java
// domain/event/PaymentCompletedEvent.java
public class PaymentCompletedEvent implements DomainEvent {
    private final PaymentId paymentId;
    private final Instant occurredAt;

    public PaymentCompletedEvent(PaymentId paymentId) {
        this.paymentId = paymentId;
        this.occurredAt = Instant.now();
    }

    public PaymentId getPaymentId() { return paymentId; }
    public Instant getOccurredAt() { return occurredAt; }
}
```

---

## Testing Strategies

### Testing Pyramid for Hexagonal

```
              /\
             /  \    E2E Tests (Few)          — full system with real infra
            /    \
           /------\
          /        \  Integration (Some)       — test adapters with real deps
         /          \
        /--------------\ Unit Tests (Many)     — domain + use cases in isolation
       /                \
      /                  \
```

| Layer | Test Type | Mock What | Speed |
|---|---|---|---|
| Domain | Unit | Nothing — pure logic | ⚡ ms |
| Application | Unit | Port interfaces (fakes/stubs) | ⚡ ms |
| Adapters (repos) | Integration | Real database | ⏱ s |
| Adapters (web) | Integration | Mock input port | ⏱ s |
| Full system | E2E | Minimal — just wiring | 🐢 min |

### 1. Domain Unit Tests — Pure Logic, No Doubles

Test behavior, not construction:

```java
class PaymentTest {
    @Test
    void shouldTransitionFromPendingToProcessing() {
        Payment payment = new Payment(
            PaymentId.generate(), Money.of(100.00),
            new CustomerId("customer-123"), PaymentMethod.CREDIT_CARD
        );
        payment.markAsProcessing();
        assertThat(payment.getStatus()).isEqualTo(PaymentStatus.PROCESSING);
    }

    @Test
    void shouldThrowExceptionWhenAmountIsNegative() {
        assertThatThrownBy(() -> new Payment(
            PaymentId.generate(), Money.of(-100.00),
            new CustomerId("customer-123"), PaymentMethod.CREDIT_CARD
        )).isInstanceOf(InvalidPaymentException.class);
    }

    @Test
    void shouldRecordEventOnCompletion() {
        Payment payment = createValidPayment();
        payment.markAsProcessing();
        payment.complete();
        assertThat(payment.pullDomainEvents()).hasSize(1);
    }
}
```

### 2. Use Case Tests — With Mocked Ports

Ports provide clean seams for test doubles:

```java
@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {

    @Mock PaymentRepository paymentRepository;
    @Mock FraudDetection fraudDetection;
    @Mock NotificationService notificationService;
    @InjectMocks PaymentService paymentService;

    @Test
    void shouldProcessPaymentSuccessfully() {
        when(fraudDetection.checkForFraud(any())).thenReturn(FraudCheckResult.safe());
        when(paymentRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        PaymentResult result = paymentService.processPayment(createValidCommand());

        assertThat(result.getStatus()).isEqualTo(PaymentStatus.COMPLETED);
        verify(paymentRepository).save(any(Payment.class));
        verify(notificationService).notifyPaymentProcessed(any());
    }

    @Test
    void shouldRejectPaymentWhenFraudDetected() {
        when(fraudDetection.checkForFraud(any()))
            .thenReturn(FraudCheckResult.fraudulent("High risk"));

        PaymentResult result = paymentService.processPayment(createValidCommand());

        assertThat(result.getStatus()).isEqualTo(PaymentStatus.FAILED);
        verify(paymentRepository).save(argThat(p ->
            p.getStatus() == PaymentStatus.FAILED));
        verify(notificationService, never()).notifyPaymentProcessed(any());
    }
}
```

### 3. Adapter Integration Tests

Test adapters against real infrastructure:

```java
@DataJpaTest
@Import(JpaPaymentRepositoryAdapter.class)
class JpaPaymentRepositoryAdapterTest {

    @Autowired private PaymentRepository paymentRepository;
    @Autowired private TestEntityManager entityManager;

    @Test
    void shouldSaveAndRetrievePayment() {
        Payment payment = new Payment(
            PaymentId.generate(), Money.of(100.00),
            new CustomerId("customer-123"), PaymentMethod.CREDIT_CARD
        );
        Payment saved = paymentRepository.save(payment);
        entityManager.flush();
        entityManager.clear();
        Optional<Payment> retrieved = paymentRepository.findById(saved.getId());

        assertThat(retrieved).isPresent();
        assertThat(retrieved.get().getAmount()).isEqualTo(Money.of(100.00));
    }
}
```

Test external API adapters with HTTP mocking:

```java
@SpringBootTest
@AutoConfigureMockRestServiceServer
class ExternalFraudServiceAdapterTest {

    @Autowired private FraudDetection fraudDetection;
    @Autowired private MockRestServiceServer mockServer;

    @Test
    void shouldDetectFraudulentPayment() {
        Payment payment = createPayment(10000.00);
        mockServer.expect(requestTo(containsString("/check")))
            .andExpect(method(HttpMethod.POST))
            .andRespond(withSuccess("""
                {"fraudulent":true,"riskScore":95,"reason":"Unusual pattern"}
                """, MediaType.APPLICATION_JSON));

        FraudCheckResult result = fraudDetection.checkForFraud(payment);

        assertThat(result.isFraudulent()).isTrue();
        assertThat(result.getRiskScore()).isEqualTo(95);
    }

    @Test
    void shouldHandleServiceTimeout() {
        Payment payment = createPayment(100.00);
        mockServer.expect(requestTo(containsString("/check")))
            .andExpect(method(HttpMethod.POST))
            .andRespond(request -> { throw new ResourceAccessException("Timeout"); });

        FraudCheckResult result = fraudDetection.checkForFraud(payment);

        assertThat(result.isFraudulent()).isFalse();  // fail-open
    }
}
```

### 4. Web Layer Tests — Mock Input Port

```java
@WebMvcTest(MarketController.class)
class MarketControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean CreateMarketUseCase createMarket;  // mock the PORT, not the impl

    @Test
    void create_returns201_withValidPayload() throws Exception {
        given(createMarket.create(any())).willReturn(
            Market.create("Test", "test-market"));

        mockMvc.perform(post("/api/markets")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""{"name":"Test","slug":"test-market"}"""))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Test"));
    }
}
```

### 5. Contract Tests for Adapters

Validate that each adapter correctly honors the expectations of the port it implements:

```java
// Shared contract test — all PaymentRepository impls must pass this
abstract class PaymentRepositoryContractTest {

    protected abstract PaymentRepository createRepository();

    @Test
    void shouldSaveAndFindById() {
        Payment payment = createTestPayment();
        Payment saved = createRepository().save(payment);
        assertThat(createRepository().findById(saved.getId())).isPresent();
    }

    @Test
    void shouldReturnEmptyForUnknownId() {
        assertThat(createRepository().findById(PaymentId.generate())).isEmpty();
    }
}

// Concrete test for JPA implementation
class JpaPaymentRepositoryContractTest extends PaymentRepositoryContractTest {
    @Override
    protected PaymentRepository createRepository() {
        return new JpaPaymentRepositoryAdapter(jpaRepo, mapper);
    }
}
```

---

## Architecture Violation Checklist

Use this when reviewing code for hexagonal compliance:

- Domain classes import `org.springframework.*` → **violation**
- Domain classes import `javax.persistence.*` / `jakarta.persistence.*` → **violation**
- Domain classes have `@Entity`, `@Table`, `@Column` annotations → **violation**
- Domain classes use `@Transactional` → **violation**
- Controller imports a use case implementation class (not interface) → **violation**
- Use case imports `*Entity`, `*Dbo`, or concrete repository → **violation**
- `adapter/in/` directly imports `adapter/out/` → **violation**
- Repository returns ORM entities (not domain objects) → **violation**
- Controller contains `if` branches with business logic → **violation**
- Use case uses `DB::` or ORM directly (bypassing repository port) → **violation**

---

## Common Pitfalls

### 1. Anemic Domain Model

**Problem:** Domain objects become data holders; logic lives in services.

```java
// Wrong — anemic
public class Order {
    private String id;
    private OrderStatus status;
    // only getters/setters
}
```

**Fix:** Put business logic in domain entities. The principle: "If you have a utility function that takes entity data and does something with it, that function belongs IN the entity."

```java
// Correct — rich domain
public class Order {
    private final OrderId id;
    private OrderStatus status;

    public void cancel() {
        if (status != OrderStatus.PENDING) {
            throw new IllegalStateException(
                "Cannot cancel order in status: " + status);
        }
        this.status = OrderStatus.CANCELLED;
    }
}
```

### 2. Leaking Infrastructure into Domain

**Problem:** JPA annotations or framework imports in domain entities.

```java
// Wrong — domain polluted
@Entity
@Table(name = "payments")
public class Payment {
    @Id @GeneratedValue private String id;
    // JPA + Spring in domain
}
```

**Fix:** Separate domain and persistence models. Domain entities have zero annotations. Persistence `*Entity`/`*Dbo` classes live in `infrastructure/` only.

### 3. Controller Injecting Implementation Instead of Port

```java
// Wrong — depends on concrete class
class MarketController {
    private final CreateMarketService createMarketService;
}

// Correct — depends on port interface
class MarketController {
    private final CreateMarketUseCase createMarket;
}
```

**Why:** Depending on the concrete service prevents mocking in `@WebMvcTest` and leaks application-layer details into the adapter.

### 4. @Transactional in Domain Model

```java
// Wrong — infrastructure concern in domain
public class Market {
    @Transactional
    public Market publish() { ... }
}

// Correct — transaction boundary on use case
@Transactional
public class PublishMarketService implements PublishMarketUseCase {
    public Market publish(MarketId id) { ... }
}
```

### 5. Skipping Mapping — Returning JPA Entity

```java
// Wrong — JPA entity escapes adapter
public List<MarketEntity> listActive() {
    return jpaRepository.findByStatus(ACTIVE);
}

// Correct — map to domain inside adapter
public List<Market> findAllActive(Pageable pageable) {
    return jpaRepo.findByStatus(ACTIVE, pageable)
        .stream().map(MarketMapper::toDomain).toList();
}
```

### 6. Too Many or Too Few Ports

**Problem:** A port per method (explosion) or one generic megaport.

**Fix:** Group related operations into cohesive interfaces, often organized around domain aggregates: `ManagePayments` (commands), `QueryPayments` (queries).

### 7. Testing Only Through REST

**Problem:** All tests go through `@SpringBootTest`, making them slow and brittle.

**Fix:** Test at the appropriate level — domain unit tests (many), use case tests with mocks (some), adapter integration tests (few), E2E smoke tests (minimal).

### 8. Over-Engineering Simple CRUD

**Problem:** Hexagonal for a basic CRUD app adds complexity without benefit.

**Fix:** Use traditional layered architecture for simple CRUD. Apply hexagonal when you have complex business rules, multiple external integrations, high testability requirements, or long-term evolution.

### 9. Brittle Interfaces

```java
// Wrong — breaks when email required
void register(String username, String password);

// Correct — wrapper object evolves without breaking callers
void register(RegistrationRequest request);
```

### 10. Domain Scope Pollution

**Problem:** Third-party types (`GoogleUser`, `StripePayment`) leaking into domain.

**Fix:** Keep external types in adapters; map to domain types at the boundary.

### 11. Use Case Interdependencies

**Problem:** Use cases calling other use cases creates coupling.

**Fix:** Each use case should be self-contained, orchestrating domain objects directly.

### 12. Leaky Abstractions

**Problem:** Port interface exposes transport-layer details (e.g., HTTP headers).

**Fix:** Port interfaces must use domain-centric types, not HTTP/framework types.

### 13. Premature Database Design

**Problem:** Designing database schema before domain model.

**Fix:** Domain model comes first; database adapter maps to it.

### 14. Over-Complicated Adapters

**Problem:** Adapters adding logic beyond translation.

**Fix:** Adapters should be thin — just implement the port interface and translate.

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| **Port/Interface Bloat** — too many fine-grained ports | Group related operations into cohesive ports, organized around domain aggregates |
| **Leaky Abstractions** — port exposes transport details | Use domain-centric DTOs, never HTTP/framework types |
| **Adapter Drift** — adapter out of sync with external tech | Schedule automated validation; contract tests catch drift |
| **Overhead** — too many files for simple features | Only apply hexagonal where benefits justify cost (see decision framework) |

---

## When to Use vs When to Skip

### Use Hexagonal When:
- Complex business logic with multiple rules and validations
- Multiple external integrations (databases, APIs, queues, files)
- Long-lived system (5+ years) where tech stack may change
- High testability requirements with fast feedback
- Domain-Driven Design practices in use
- Multiple inbound adapters expected (REST + CLI + message consumer)
- Team practices TDD and wants pure-Java unit tests

### Avoid Hexagonal When:
- Simple CRUD with no complex business logic
- Prototypes, proofs of concept, or short-lived projects
- Very small team (< 3) with limited architecture experience
- Script-like batch jobs or data migration utilities
- Small projects where port/adapter abstraction adds overhead without benefit

### Decision Framework

Ask yourself: **Complexity?** **Longevity?** **Change frequency?** **Testing importance?** If 3+ are "yes", consider Hexagonal.

---

## Relationship to DDD

Hexagonal architecture is the **structural container**; DDD provides the **modeling substance**:

| Hexagonal | DDD Equivalent |
|---|---|
| `domain/model/` | Entities, Value Objects, Aggregates |
| `domain/port/out/` | Repository interface (per Aggregate Root) |
| `domain/event/` | Domain Events (raised inside Aggregates) |
| `domain/service/` | Domain Services (stateless, no framework) |
| `application/usecase/` | Application Services (orchestrate, dispatch events) |
| `adapter/out/persistence/` | JPA entities + mappers (NOT domain entities) |

**Neither is complete without the other:** Hexagonal without DDD produces anemic models with behavior in use cases. DDD without hexagonal produces framework-coupled domain objects.

---

## Migration Strategy: Strangler Fig

Gradually extract features from a legacy layered application:

1. **Identify a bounded context** — one feature area
2. **Extract domain model** — pure business logic, no framework
3. **Create ports** — interfaces for what the domain needs
4. **Create adapters** — wrap legacy code behind port interfaces
5. **Route new requests** — feature toggle between legacy and new flow
6. **Gradually replace adapters** — swap implementations behind the same port

```java
// Phase 1: Route via feature toggle
@PostMapping
public ResponseEntity<?> createOrder(@RequestBody OrderRequestDTO dto) {
    if (featureToggle.isEnabled("new-order-flow")) {
        PlaceOrderCommand command = mapper.toCommand(dto);
        OrderResult result = newService.placeOrder(command);
        return ResponseEntity.ok(mapper.toDTO(result));
    }
    legacyService.createOrder(dto);
    return ResponseEntity.ok().build();
}
```

### Phase 2: Swap Adapter Behind Same Port

```java
// Swap from JDBC to JPA — use case unchanged
@Configuration
public class RepositoryConfig {
    @Bean
    @ConditionalOnProperty(name = "repository.type", havingValue = "jpa")
    public PaymentRepository jpaRepository() {
        return new JpaPaymentRepositoryAdapter(jpaRepo, mapper);
    }

    @Bean
    @ConditionalOnProperty(name = "repository.type", havingValue = "legacy",
                          matchIfMissing = true)
    public PaymentRepository legacyRepository() {
        return new LegacyJdbcPaymentRepository(jdbcTemplate);
    }
}
```

---

## Backbone Layer Mapping

| Hexagonal Concept | Backbone Directory | Contents |
|---|---|---|
| **Domain Entity** | `domain/model/vo/` | Pure business objects with behavior |
| **Domain Event** | `domain/event/` | Things that happened in the domain |
| **Domain Service** | `domain/service/` | Stateless business logic |
| **Port (Inbound)** | `domain/port/in/` (interface) | Use case interfaces |
| **Port (Outbound)** | `domain/port/out/` (interface) | Repository, service interfaces |
| **Application Service** | `application/usecase/` | Implements use cases, orchestrates |
| **Primary Adapter** | `adapter/in/web/`, `adapter/in/messaging/` | REST controllers, consumers |
| **Secondary Adapter** | `adapter/out/persistence/`, `adapter/out/client/` | JPA repos, API clients |
| **DI Wiring** | `config/` | Bean definitions, framework config |

---

## References

- **BuckPal** — Spring Boot hexagonal example — https://github.com/thombergs/buckpal
- **hex-arch** — Hexagonal architecture example — https://github.com/yassineaitmalek/hex-arch
- **Hexagonal Architecture Spring Boot** — https://github.com/arhohuttunen/hexagonal-architecture-spring-boot
- **DDD Design** — skill.fish hexagonal DDD — https://www.skill.fish/skill/hexagonal-architecture-ddd-design
- **DDD Guide** — skill.fish hexagonal DDD guide — https://www.skill.fish/skill/hexagonal-architecture-ddd-guide
- **Ports & Adapters** — skill.fish hexagonal ports adapters — https://www.skill.fish/skill/hexagonal-architecture-ports-adapters
- **Architecture Guide** — skill.fish hexagonal guide — https://www.skill.fish/skill/hexagonal-architecture-guide
- **Java Architecture** — skill.fish hexagonal Java — https://www.skill.fish/skill/hexagonal-java-architecture
- **Clean Architecture** — skill.fish clean architecture hexagonal patterns — https://www.skill.fish/skill/clean-architecture-hexagonal-patterns
- **ECC Hexagonal Architecture Skill** — https://lobehub.com/skills/affaan-m-everything-claude-code-hexagonal-architecture?activeTab=skill
- **"Get Your Hands Dirty on Clean Architecture"** — Tom Hombergs
- **"Hexagonal Architecture Explained"** — Alistair Cockburn & Juan Manuel Garrido de Paz (2024)
- **Original article** — Alistair Cockburn — https://alistair.cockburn.us/hexagonal-architecture/
