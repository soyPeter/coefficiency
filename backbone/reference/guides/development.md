# Development Guidelines

*Core development practices for services built on this backbone.*

---

## Architecture Fundamentals

### Hexagonal Architecture (Ports & Adapters)

```
Domain (Core) ← Application ← Infrastructure
```

- **Domain layer**: Pure business logic, no framework dependencies
- **Application layer**: Use cases, DTOs, orchestration  
- **Infrastructure layer**: REST controllers, repositories, external services

### Key Principles

1. **Domain First**: Start with domain entities and business rules
2. **Dependency Inversion**: Domain defines ports, infrastructure implements adapters
3. **Immutability**: Records for value objects, factory methods for new instances
4. **Single Responsibility**: One class per use case

---

## Coding Standards

### Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Entity | Noun, singular | `Customer`, `Order` |
| Use Case | Verb + Entity + UseCase | `CreateCustomerUseCase` |
| Request DTO | `<Entity>Req` | `CreateCustomerReq` |
| Response DTO | `<Entity>Res` | `CustomerRes` |
| SQL Row | `<Entity>Row` | `CustomerRow` |
| Repository | `<Entity>Repo` | `CustomerRepo` |

### Record Usage

```java
// ✅ CORRECT - Immutable with validation
public record Email(String value) {
    public Email {
        requireNonNull(value);
        if (!value.contains("@")) throw new IllegalArgumentException();
    }
}

// ❌ WRONG - Mutable state
public class Email {
    private String value;  // Don't do this
}
```

### Use Case Pattern

```java
@Named
public class CreateCustomerUseCase {
    private final CustomerRepository repository;
    
    // Constructor injection (works with Spring + JSR-330)
    public CreateCustomerUseCase(CustomerRepository repository) {
        this.repository = repository;
    }
    
    public Customer execute(CreateCustomerReq req) {
        // 1. Validate input
        // 2. Create domain entity
        // 3. Persist
        // 4. Return result
    }
}
```

---

## Layer Rules

### Domain Layer
- ✅ Pure Java (records, enums, interfaces)
- ❌ NO framework imports (`org.jboss.*`, `io.quarkus.*`, `org.springframework.*`)
- ❌ NO annotations (except `@FunctionalInterface`)

### Application Layer  
- ✅ Use `@Named` (JSR-330) for framework independence
- ❌ NO CDI scopes (`@ApplicationScoped`)
- ❌ NO framework-specific annotations

### Infrastructure Layer
- ✅ All framework code goes here
- ✅ REST controllers, JDBI repositories, event listeners
- ✅ Adapters to external systems

---

## Repository Pattern

### Domain (Port Interface)
```java
public interface CustomerRepository {
    void save(Customer customer);
    Optional<Customer> findById(String id);
}
```

### Infrastructure (Adapter Implementation)
```java
public interface CustomerSqlRepository extends CustomerRepository {
    
    @SqlUpdate("INSERT INTO customers (id, email) VALUES (:id, :email)")
    @BindBean
    void save(Customer customer);
    
    @SqlQuery("SELECT * FROM customers WHERE id = :id")
    @RegisterConstructorMapper(CustomerRow.class)
    Optional<CustomerRow> findById(@Bind("id") String id);
}
```

---

## Testing Guidelines

### Test Strategy
1. **Unit tests** - Domain logic, use cases (mock dependencies)
2. **Integration tests** - Controllers, repositories (test containers)
3. **Contract tests** - API contracts between services

### Test Naming
```java
class CreateCustomerUseCaseTest {
    @Test
    void shouldCreateCustomer() { }
    
    @Test
    void shouldThrowWhenEmailInvalid() { }
}
```

---

## Related Documentation

- **Java Conventions**: `backbone/reference/java-conventions.md`
- **Patterns**: [`backbone/reference/patterns.md`](backbone/reference/patterns.md) - CQRS, Outbox, Idempotency
- **Full Guidelines**: `docs/NEW/documentation/developer/GUIDELINES.md`

---

*For detailed examples and patterns, see production documentation at `docs/NEW/documentation/`*