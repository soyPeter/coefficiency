# Service Creation Guide

*Guide for creating new microservices. See full examples at `docs/NEW/documentation/developer/CREATE_NEW_SERVICE.md`*

---

## Quick Start

### 1. Generate Service Structure

```bash
# Using backbone service generator
./scripts/init-project.sh <project-name> -f quarkus -s <service-name>

# Or manually create:
mkdir -p services/<service>/src/main/java/io/bitnomio/<service>/
mkdir -p services/<service>/src/main/resources
mkdir -p services/<service>/src/test/java/io/bitnomio/<service>
```

### 2. Directory Structure (Hexagonal Architecture)

```
services/<service>/
├── src/main/java/io/bitnomio/<service>/
│   ├── domain/
│   │   ├── model/entity/          # Domain entities
│   │   ├── model/vo/            # Value objects (immutable)
│   │   ├── event/                # Domain events
│   │   └── actions/              # Repository interfaces (ports)
│   ├── app/
│   │   └── <Entity>UseCase.java  # Use cases
│   └── infra/
│       ├── io/rest/            # REST controllers
│       ├── config/              # Configuration
│       └── data/
│           ├── dto/             # Request/Response DTOs
│           └── persistence/   # JDBI repositories
├── src/main/resources/
│   ├── application.yml          # Service config
│   └── db/migration/            # Flyway migrations
└── src/test/java/               # Unit & integration tests
```

---

## Domain Layer Rules

### Entities
- Use Java Records for simple data
- Include validation in compact constructor
- Business methods return new instances (immutable)

```java
public record Customer(
    String id,
    String email,
    CustomerStatus status
) {
    public Customer {
        requireNonNull(email, "Email required");
    }
    
    public Customer activate() {
        return new Customer(id, email, CustomerStatus.ACTIVE);
    }
}
```

### Value Objects
- Always immutable
- Validate in constructor
- No identity - equals by value

### Repository Interfaces (Ports)
```java
public interface CustomerRepository {
    void save(Customer customer);
    Optional<Customer> findById(String id);
}
```

---

## Application Layer Rules

### Use Cases (@Named)
- One class per use case (SRP)
- Use constructor injection
- Return domain entities or DTOs

```java
@Named
public class CreateCustomerUseCase {
    private final CustomerRepository repository;
    
    public CreateCustomerUseCase(CustomerRepository repository) {
        this.repository = repository;
    }
    
    public Customer execute(CreateCustomerReq req) {
        Customer customer = Customer.create(req.email());
        repository.save(customer);
        return customer;
    }
}
```

### DTO Naming
- Request: `Create<Entity>Req`
- Response: `<Entity>Res`
- Row (JDBI): `<Entity>Row`

---

## Infrastructure Layer Rules

### REST Controllers
```java
@Path("/api/customers")
@Produces(MediaType.APPLICATION_JSON)
public class CustomerController {
    
    @POST
    public Response createCustomer(CreateCustomerReq req) {
        // Use case invocation
        return Response.status(CREATED).entity(res).build();
    }
}
```

### JDBI Repositories
```java
public interface CustomerSqlRepo extends CustomerRepository {
    
    @SqlUpdate("INSERT INTO customers (id, email) VALUES (:id, :email)")
    void save(@BindBean Customer customer);
    
    @SqlQuery("SELECT * FROM customers WHERE id = :id")
    @RegisterConstructorMapper(CustomerRow.class)
    Optional<CustomerRow> findById(@Bind("id") String id);
}
```

---

## Testing Patterns

### Unit Test
```java
@ExtendWith(MockitoExtension.class)
class CreateCustomerUseCaseTest {
    
    @Mock CustomerRepository repository;
    
    @Test
    void shouldCreateCustomer() {
        when(repository.save(any())).thenReturn(customer);
        
        Customer result = useCase.execute(req);
        
        assertNotNull(result);
        verify(repository).save(any());
    }
}
```

### Integration Test
```java
@QuarkusTest
class CustomerResourceTest {
    
    @InjectMock CustomerRepository repository;
    
    @Test
    void shouldReturnCustomer() {
        // Test with RestAssured
    }
}
```

---

## Next Steps

1. **Add domain logic** - Entities, events, business rules
2. **Create use cases** - Application layer
3. **Build infrastructure** - REST controllers, repositories
4. **Add tests** - Unit and integration tests
5. **Configure deployment** - Docker, environment variables

---

## Related Documentation

- **Patterns**: `backbone/reference/patterns.md` - CQRS, Outbox, Idempotency
- **Java Conventions**: `backbone/reference/java-conventions.md` - Coding standards
- **Full Examples**: `docs/NEW/documentation/developer/CREATE_NEW_SERVICE.md`
- **Architecture**: `docs/NEW/documentation/architecture/`

---

*For project-specific implementations, see Bitnomio production docs at `docs/NEW/documentation/`*