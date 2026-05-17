<!-- VERSION: 2026.05.04 -->
# Quarkus Conventions

*Quarkus-specific patterns. See `java-conventions.md` for base Java patterns.*

---

## Quick Reference

| Pattern | Spring | Quarkus |
|---------|--------|---------|
| REST Controller | `@RestController` | `@Path` |
| GET | `@GetMapping` | `@GET` |
| POST | `@PostMapping` | `@POST` |
| PUT | `@PutMapping` | `@PUT` |
| DELETE | `@DeleteMapping` | `@DELETE` |
| DI | `@Autowired` | `@Inject` |
| Component | `@Service`, `@Component` | `@Named` |
| Config | `@Value`, `@ConfigurationProperties` | `@ConfigProperty` |
| Path Param | `@PathVariable` | `@PathParam` |
| Query Param | `@RequestParam` | `@QueryParam` |
| Body | `@RequestBody` | (automatic) |

---

## Forbidden Patterns

### NO Spring
```java
// WRONG
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;

// CORRECT
import jakarta.ws.rs.*;
import jakarta.inject.*;
```

### NO Lombok
```java
// WRONG (@Data)
@Data
public class User { private String id; }

// CORRECT (Java Record)
public record User(String id, String name) {}
```

### NO JPA/Hibernate in Domain
```java
// domain/model/vo/User.java
// WRONG
@Entity
public class User { @Id private String id; }

// CORRECT - Pure Java record
public record User(String id, String name) {}
```

---

## Layer Rules

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| `domain/` | Records, enums, local interfaces | ANY framework imports (`org.jboss`, `io.quarkus`) |
| `app/` | `@Named`, use cases | CDI scopes (`@ApplicationScoped`) |
| `infra/` | All Quarkus/CDI/DB code | - |

### Domain Must Be Framework-Free
Domain layer cannot import:
- `org.jboss.*`
- `io.quarkus.*`
- `jakartaenterprise.*`

This is enforced by `validate-quarkus.sh` hook.

---

## Dependency Injection

### Constructor Injection (Mandatory)
```java
@ApplicationScoped
public class UserService {
    private final UserRepository repository;
    
    @Inject
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

### Using @Named
```java
@Named
@ApplicationScoped
public class UserService {
    // Same as Spring @Service
}
```

### No Annotation Needed (Single Constructor)
```java
@ApplicationScoped
public class UserService {
    private final UserRepository repository;
    
    // @Inject optional with single constructor
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

---

## REST Controllers

```java
@Path("/api/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {
    
    @GET
    @Path("/{id}")
    public User getUser(@PathParam("id") String id) {
        // ...
    }
    
    @POST
    public Response createUser(CreateUserReq req) {
        // ...
        return Response.status(Response.Status.CREATED)
            .entity(user)
            .build();
    }
    
    @PUT
    @Path("/{id}")
    public User updateUser(@PathParam("id") String id, UpdateUserReq req) {
        // ...
    }
    
    @DELETE
    @Path("/{id}")
    public void deleteUser(@PathParam("id") String id) {
        // ...
    }
}
```

---

## Configuration

```java
@ConfigProperty(name = "app.database.url")
String databaseUrl;

@ConfigProperty(name = "app.retry.max", defaultValue = "3")
int maxRetries;
```

### OpenAPI / Swagger UI
```properties
quarkus.smallrye-openapi.info-title=My Service API
quarkus.smallrye-openapi.info-version=1.0.0
quarkus.swagger-ui.always-include=true
quarkus.swagger-ui.path=/swagger-ui
```

### Health & Metrics
```properties
quarkus.smallrye-health.root-path=/health
quarkus.smallrye-health.liveness-path=/live
quarkus.smallrye-health.readiness-path=/ready
quarkus.micrometer.export.prometheus.path=/metrics
quarkus.micrometer.registry-enabled-default=true
```

### Kubernetes (Optional)
```properties
quarkus.kubernetes.labels.app-type=microservice
quarkus.kubernetes.env.secrets=my-secret
quarkus.kubernetes.env.configmaps=my-config
quarkus.container-image.group=my-org
quarkus.container-image.name=my-service
quarkus.container-image.registry=ghcr.io
```

---

## Testing

### Unit Tests (Mockito + AssertJ)
```java
@ExtendWith(MockitoExtension.class)
class CreateUserUseCaseTest {

    @Mock
    private UserCommandAction mockAction;

    @Test
    void shouldCreateUserWithValidData() {
        CreateUserReq request = new CreateUserReq("John", "john@example.com");
        User result = useCase.execute(request);
        assertThat(result.name()).isEqualTo("John");
        verify(mockAction).save(any(User.class));
    }
}
```

### Integration Tests (@QuarkusTest + REST Assured)
```java
@QuarkusTest
class UserResourceIT {

    @Test
    void shouldCreateUser() {
        CreateUserReq request = Instancio.of(CreateUserReq.class).create();

        given()
            .contentType(ContentType.JSON)
            .body(request)
        .when()
            .post("/api/v1/users")
        .then()
            .statusCode(201)
            .body("data.id", notNullValue());
    }

    @Test
    void shouldListUsers() {
        given()
            .queryParam("page", 0)
            .queryParam("size", 10)
        .when()
            .get("/api/v1/users")
        .then()
            .statusCode(200)
            .body("meta.pagination.page", equalTo(0));
    }
}
```

### Test Data Generation (Instancio)
```java
// Generate random test data without manual fixture boilerplate
Person person = Instancio.of(Person.class)
    .ignore(Select.field("id"))      // Skip auto-generated fields
    .supply(Select.field("email"), () -> "test@example.com")
    .create();
```

---

## Package Structure

```
io/bitnomio/<service>/
├── domain/
│   ├── model/vo/<Entity>.java      # Records
│   ├── actions/                   # Domain actions
│   └── events/                   # Domain events
├── app/
│   └── <Entity>UseCase.java       # Use cases
└── infra/
    ├── config/                    # Config classes
    ├── data/
    │   ├── dto/                 # Request/Response DTOs
    │   └── persistence/        # JDBI repositories
    └── io/
        └── rest/               # REST controllers
```

---

## Alternative Persistence Patterns

This project uses **JDBI** for persistence (see `4-KNOWLEDGE.md`). The following patterns are documented for reference but are NOT used in this template.

### Hibernate ORM with Panache (Reference Only)
```java
// Simple CRUD with Panache — NOT used in this project
@Entity
public class Employee extends PanacheEntity {
    public String firstName;
    public String lastName;
    public int salary;
}

@ApplicationScoped
public class EmployeeRepository implements PanacheRepository<Employee> {
    public List<Employee> findBySalaryGreaterThan(int salary) {
        return list("salary > ?1", salary);
    }
}
```

### Why JDBI Over Panache
- Domain purity: No `@Entity` annotations in domain layer
- SQL control: Explicit queries for performance tuning
- Hexagonal alignment: Repository interfaces in domain, JDBI implementations in infra

## Related

- `conventions-general.md` - Core principles
- `java-conventions.md` - Java patterns and SOLID
- `scripts/validate-quarkus.sh` - Validation hook

*Last updated: 2026-04-23*