# Jooby Framework Conventions

## Overview

Jooby is a modular, high-performance web framework for Java and Kotlin. This template uses Jooby 4.5.1 with the MVC API, Avaje Inject for DI, Netty server, and JDBI for persistence.

## Key Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| API style | MVC (`@Path`, `@GET`, `@POST`) | Annotation-based, familiar to JAX-RS/Spring MVC developers |
| DI | Avaje Inject (compile-time) | Same `jakarta.inject` annotations as CDI, zero runtime reflection |
| AOP | Avaje Inject AOP (`@Aspect` + `AspectProvider`) | Compile-time method interception (not CDI `@InterceptorBinding`) |
| Server | Netty | Default Jooby server, high-performance non-blocking |
| Persistence | JDBI via `jooby-jdbi` module | Consistent with existing backbone templates |
| Migrations | Flyway via `jooby-flyway` module | Standard database migration tool |
| Transactions | Manual (Jooby Transaction API or JDBC) | `jooby-jdbi` handles transactions via JDBI handles |

## MVC API Annotations

```java
import io.jooby.annotation.*;

@Path("/api/v1/resource")     // Class-level path prefix
public class MyController {

    @GET                        // HTTP GET
    @Path("/{id}")              // Method-level path (appended to class path)
    public MyRes getById(@PathParam String id) { ... }

    @POST                       // HTTP POST
    public MyRes create(@Body CreateReq req) { ... }

    @PUT
    @Path("/{id}")
    public MyRes update(@PathParam String id, @Body UpdateReq req) { ... }

    @DELETE
    @Path("/{id}")
    public void delete(@PathParam String id, @QueryParam String reason) { ... }

    @GET
    public List<MyRes> list(@QueryParam int page, @QueryParam int size) { ... }
}
```

**Parameter annotations:**
- `@PathParam` — Path variable from URI template
- `@QueryParam` — Query string parameter
- `@Body` — Request body (deserialized by Jooby)
- `@FormParam` — Form field
- `@Header` — HTTP header
- `@Cookie` — Cookie value

## Avaje Inject Patterns

### Annotations

| Annotation | Package | Usage |
|-----------|---------|-------|
| `@Singleton` | `jakarta.inject` | Singleton bean (default scope) |
| `@Inject` | `jakarta.inject` | Constructor injection |
| `@Named` | `jakarta.inject` | Qualifier for named beans |
| `@Factory` | `io.avaje.inject` | Factory class with `@Bean` methods (replaces CDI `@Produces`) |
| `@Bean` | `io.avaje.inject` | Producer method inside a `@Factory` |
| `@External` | `io.avaje.inject` | Marks a dependency provided at runtime (from Jooby modules) |
| `@InjectModule` | `io.avaje.inject` | Declares external dependencies via `requires` |

### Bean Wiring

```java
// Singleton bean with constructor injection
@Singleton
public class MyService {
    private final MyRepo repo;

    @Inject
    public MyService(MyRepo repo) {
        this.repo = repo;
    }
}

// Factory for producing beans (replaces @Produces)
@Factory
public class MyFactory {
    @Bean
    @Named("command")
    public MyCommandRepo commandRepo(Jdbi jdbi) {
        return jdbi.onDemand(MySqlCommandRepo.class);
    }
}

// External dependency declaration
@InjectModule(requires = Jdbi.class)
public class AppModule {}
```

### Annotation Processor Order

```kotlin
dependencies {
    // avaje-inject-generator must be before jooby-apt
    annotationProcessor("io.avaje:avaje-inject-generator:12.5")
    annotationProcessor("io.jooby:jooby-apt:4.5.1")
}
```

## Avaje AOP (Aspect-Oriented Programming)

For method interception (logging, idempotency, security), use Avaje's compile-time AOP:

```java
// 1. Define aspect annotation
@Aspect(ordering = 1)
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Logged {}

// 2. Implement aspect provider
@Singleton
public class LoggedAspect implements AspectProvider<Logged> {
    @Override
    public MethodInterceptor interceptor(Method method, Logged annotation) {
        return invocation -> {
            System.out.println("before: " + method.getName());
            try {
                invocation.invoke();
            } finally {
                System.out.println("after: " + method.getName());
            }
        };
    }
}

// 3. Use on methods
@Singleton
public class MyService {
    @Logged
    public void doSomething() { ... }
}
```

## Application Setup

```java
@Singleton
@InjectModule(requires = Jdbi.class)
public class App extends Jooby {

    public App() {
        // Install Jooby modules
        install(AvajeInjectModule.of());     // Avaje DI
        install(new JdbiModule());            // JDBI
        install(new FlywayModule());          // Flyway

        // Register MVC controllers (lifecycle managed by Avaje)
        mvc(MyController.class);
    }

    public static void main(String[] args) {
        Jooby.runApp(args, App::new);
    }
}
```

## Module Installation Order

1. `AvajeInjectModule.of()` — must be first (enables DI for subsequent modules)
2. Framework modules (`JdbiModule`, `FlywayModule`, etc.)
3. MVC controllers via `mvc()`

## Service Resolution

```java
// Inside a route handler:
MyService service = require(MyService.class);

// With name qualifier:
MyService service = require(MyService.class, "name");
```

## Build Configuration

```kotlin
plugins {
    id("java")
    id("application")
}

application {
    mainClass = "com.example.App"
}

dependencies {
    annotationProcessor("io.avaje:avaje-inject-generator:12.5")
    annotationProcessor("io.jooby:jooby-apt:4.5.1")

    implementation(platform("io.avaje:avaje-inject:12.5"))
    implementation("io.jooby:jooby:4.5.1")
    implementation("io.jooby:jooby-netty:4.5.1")
    implementation("io.jooby:jooby-avaje-inject:4.5.1")
    implementation("io.jooby:jooby-jackson:4.5.1")
    implementation("io.jooby:jooby-jdbi:4.5.1")
    implementation("io.jooby:jooby-flyway:4.5.1")
}
```

## Never Do

- Do NOT use `@ApplicationScoped` (Jakarta EE) — use `@Singleton` (Jakarta Inject)
- Do NOT use `@Produces` (CDI) — use `@Factory` + `@Bean` (Avaje)
- Do NOT use `@Transactional` (Jakarta) — handle transactions manually via JDBI handle
- Do NOT use `@InterceptorBinding` (CDI) — use `@Aspect` + `AspectProvider` (Avaje AOP)
- Do NOT use JAX-RS annotations (`jakarta.ws.rs.*`) — use Jooby annotations (`io.jooby.annotation.*`)
