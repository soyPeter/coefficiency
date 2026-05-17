# Spring Boot Conventions

*Spring Boot-specific patterns. See `java-conventions.md` for base Java patterns.*

---

## Quick Reference

| Pattern | Spring Boot | Quarkus |
|---------|-------------|---------|
| REST Controller | `@RestController` | `@Path` |
| GET | `@GetMapping` | `@GET` |
| POST | `@PostMapping` | `@POST` |
| PUT | `@PutMapping` | `@PUT` |
| DELETE | `@DeleteMapping` | `@DELETE` |
| DI | `@Autowired`, `@Inject` | `@Inject` |
| Service | `@Service` | `@Named` |
| Component | `@Component` | `@Named` |
| Configuration | `@Configuration`, `@Bean` | `@Produces` |
| Config | `@Value`, `@ConfigurationProperties` | `@ConfigProperty` |
| Path Param | `@PathVariable` | `@PathParam` |
| Query Param | `@RequestParam` | `@QueryParam` |
| Body | `@RequestBody` | (automatic) |

---

## Spring Boot Patterns

### REST Controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable String id) {
        // ...
        return ResponseEntity.ok(user);
    }
    
    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody CreateUserReq req) {
        // ...
        return ResponseEntity.status(HttpStatus.CREATED).body(user);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(
            @PathVariable String id, 
            @RequestBody UpdateUserReq req) {
        // ...
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable String id) {
        // ...
    }
}
```

### Service Layer

```java
@Service
public class UserService {
    
    private final UserRepository repository;
    
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
    
    @Transactional
    public User createUser(CreateUserReq req) {
        // ...
    }
}
```

### Repository

```java
@Repository
public interface UserRepository extends JpaRepository<User, String> {
    
    Optional<User> findByEmail(String email);
    
    List<User> findByStatus(UserStatus status);
}
```

---

## Dependency Injection

### Constructor Injection (Preferred)

```java
@Service
public class UserService {
    private final UserRepository repository;
    
    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

### Using @Qualifier

```java
@Service
public class UserService {
    private final UserRepository repository;
    
    public UserService(@Qualifier("jpa") UserRepository repository) {
        this.repository = repository;
    }
}
```

---

## Configuration

```java
@Configuration
public class AppConfig {
    
    @Value("${app.retry.max:3}")
    private int maxRetries;
    
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

Or using record:

```java
@Configuration
@ConfigurationProperties(prefix = "app")
public record AppProperties(
    String databaseUrl,
    @DefaultValue("3") int retryMax
) {}
```

---

## Testing

```java
@SpringBootTest
class UserServiceTest {
    
    @Autowired
    UserService service;
    
    @MockBean
    UserRepository repository;
    
    @Test
    void shouldCreateUser() {
        when(repository.save(any())).thenReturn(user);
        
        User result = service.createUser(req);
        
        assertThat(result.getId()).isNotNull();
        verify(repository).save(any());
    }
}
```

### Controller Tests

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    
    @Autowired
    MockMvc mockMvc;
    
    @MockBean
    UserService userService;
    
    @Test
    void shouldReturnUser() throws Exception {
        when(userService.findById("1")).thenReturn(Optional.of(user));
        
        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value("1"));
    }
}
```

---

## Package Structure

```
com/example/<service>/
├── config/                    # Configuration
├── controller/               # REST controllers
├── service/                  # @Service classes
├── repository/               # @Repository interfaces
├── model/                    # Domain models
├── infra/
│   └── dto/                 # Data transfer objects
└── exception/              # Custom exceptions
```

---

## Related

- `conventions-general.md` - Core principles
- `java-conventions.md` - Java patterns and SOLID

*Last updated: 2026-04-12*