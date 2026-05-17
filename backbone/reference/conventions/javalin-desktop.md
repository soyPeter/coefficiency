<!-- VERSION: 2026.05.13 -->
# Javalin Desktop Conventions

*Javalin 7.2 + SQLite + React desktop dashboard patterns. See `java.md` for base Java patterns.*

---

## Quick Reference

| Pattern | Javalin 7 | Spring/Quarkus Equivalent |
|---------|-----------|---------------------------|
| REST Routes | `config.routes.get("/api/...", ctx -> ...)` | `@GetMapping` / `@GET` |
| Route Groups | `config.routes.apiBuilder(() -> { path("/api", () -> { get(...); }); })` | `@RequestMapping` / `@Path` |
| Path Param | `ctx.pathParam("id")` | `@PathVariable` / `@PathParam` |
| Query Param | `ctx.queryParam("page")` | `@RequestParam` / `@QueryParam` |
| Body (JSON) | `ctx.bodyAsClass(Dto.class)` | `@RequestBody` |
| Upload | `ctx.uploadedFile("file")` | `@MultipartForm` |
| Response | `ctx.json(obj)`, `ctx.status(201)` | `ResponseEntity` / `Response` |
| Static Files | `config.staticFiles.add(...)` | `resources/static/` |
| Server Start | `Javalin.create(...).start(port)` | Embedded auto-start |
| CORS | `config.bundledPlugins.enableCors(cors -> ...)` | `@CrossOrigin` / CORS filter |
| Lifecycle | `config.events.serverStarted(() -> ...)` | `@EventListener` / `@Observes` |

---

## Architecture: Tomato (Package by Feature)

Javalin has no DI container. We use **manual constructor injection** and **package by feature**.

```
src/main/java/io/bitnomio/<project>/
├── DashboardServer.java          # Javalin bootstrap, route wiring, lifecycle
├── metric/
│   ├── Metric.java               # Domain record (NO framework imports)
│   ├── MetricRepository.java     # JDBC/SQLite persistence
│   ├── MetricService.java        # Business logic (pure Java)
│   └── MetricController.java     # HTTP handlers (method references)
└── fileimport/
    └── FileImportController.java # CSV upload + parse
```

### Why Package by Feature?

- **Cohesion:** All code for a feature lives together
- **Navigation:** Find everything related to "metrics" in one directory
- **Refactoring:** Delete or extract a feature by moving one directory
- **No unnecessary interfaces:** Repository is a concrete class; inject it directly

### Layer Rules

| Package | Allowed | Forbidden |
|---------|---------|-----------|
| `metric/` | Records, repositories, services, controllers | Cross-feature imports (import `fileimport.*` in `metric/`)
| `fileimport/` | Upload parsing, CSV logic | Business rules that belong in `metric/` |
| Root | Bootstrap, config, cross-cutting wiring | Business logic |

**Domain Must Be Framework-Free.** No Javalin, no SQLite imports in records/enums.

---

## Dependency Injection (Manual)

Javalin has NO built-in DI container. Wire dependencies in `DashboardServer.main()`.

```java
public static void main(String[] args) {
    MetricRepository repository = new MetricRepository("data/app.db");
    repository.initSchema();

    MetricService service = new MetricService(repository);
    MetricController controller = new MetricController(service);

    Javalin.create(config -> {
        config.routes.apiBuilder(() -> {
            path("/api/metrics", () -> {
                get(controller::getAll);
                post(controller::create);
            });
        });
    }).start(7000);
}
```

**Rules:**
- Construct dependencies in `main()` (or a dedicated `AppConfig` class)
- Pass dependencies via constructors
- NEVER use static fields for stateful dependencies
- NEVER use field injection (Javalin doesn't support it anyway)

---

## REST Controllers

Controllers are plain Java classes with `public void method(Context ctx)` signatures.

```java
public class MetricController {
    private final MetricService service;

    public MetricController(MetricService service) {
        this.service = service;
    }

    public void getAll(Context ctx) {
        ctx.json(service.getAllMetrics());
    }

    public void getByName(Context ctx) {
        String name = ctx.pathParam("name");
        ctx.json(service.getMetricsByName(name));
    }

    public void create(Context ctx) {
        CreateMetricRequest req = ctx.bodyAsClass(CreateMetricRequest.class);
        Metric metric = service.addMetric(req.name(), req.value());
        ctx.status(201).json(metric);
    }

    public record CreateMetricRequest(String name, double value) {}
}
```

**Rules:**
- One controller per feature
- Methods return `void` — write to `ctx` directly
- Use Java records for request/response DTOs (co-located in controller)
- Validation: use `ctx.bodyValidator(Dto.class).required().get()` in Javalin 7

---

## Javalin 7 Route Registration

All routes MUST be registered inside `Javalin.create(config -> { ... })`.

```java
Javalin.create(config -> {
    // Static files
    config.staticFiles.add(staticFiles -> {
        staticFiles.directory = "/static";
        staticFiles.location = Location.CLASSPATH;
    });

    // CORS
    config.bundledPlugins.enableCors(cors -> cors.addRule(it -> it.anyHost()));

    // Routes
    config.routes.apiBuilder(() -> {
        get("/api/health", ctx -> ctx.json(Map.of("status", "ok")));

        path("/api/metrics", () -> {
            get(metricController::getAll);
            post(metricController::create);
            path("/{name}", () -> {
                get(metricController::getByName);
            });
        });
    });

    // Lifecycle
    config.events.serverStarted(() -> {
        System.out.println("Server started on port 7000");
    });
}).start(7000);
```

**Javalin 7 vs 6 Differences:**
- Routes inside `config.routes` (not `app.get()` after creation)
- `config.events.serverStarted(...)` (not `app.events(event -> ...)`)
- `config.jetty.port = 7000` (not `config.jetty.defaultPort`)
- `ctx.endpoint().path()` (not `ctx.matchedPath()`)
- Validation requires `.required()` before `.get()`

---

## SQLite Persistence

```java
public class MetricRepository {
    private final Connection connection;

    public MetricRepository(String dbPath) {
        try {
            java.io.File dbFile = new java.io.File(dbPath);
            if (dbFile.getParentFile() != null) {
                dbFile.getParentFile().mkdirs();
            }
            this.connection = DriverManager.getConnection("jdbc:sqlite:" + dbPath);
        } catch (SQLException e) {
            throw new RuntimeException("Failed to connect to SQLite: " + e.getMessage(), e);
        }
    }

    public void initSchema() {
        // CREATE TABLE IF NOT EXISTS ...
    }
}
```

**Rules:**
- Handle `:memory:` databases (parent file is null)
- Wrap checked SQLExceptions in RuntimeExceptions
- Use try-with-resources for Statements/ResultSets
- Batch inserts with `PreparedStatement.addBatch()` / `executeBatch()`

---

## Frontend (React)

### Build Integration

Maven `frontend-maven-plugin` handles the entire frontend build:

```xml
<plugin>
    <groupId>com.github.eirslett</groupId>
    <artifactId>frontend-maven-plugin</artifactId>
    <!-- installs Node, runs npm install + npm run build -->
</plugin>
```

Vite builds `frontend/src/` → `frontend/dist/`, then Maven copies `dist/` → `target/classes/static/`.

### Vite Dev Proxy

```js
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': 'http://localhost:7000'
    }
  }
}
```

Run `npm run dev` in `frontend/` for HMR; Javalin backend on `:7000` handles API.

### Static File Serving

```java
Javalin.create(config -> {
    config.staticFiles.add(staticFiles -> {
        staticFiles.directory = "/static";
        staticFiles.location = Location.CLASSPATH;
    });
});
```

Built frontend served from `src/main/resources/static/` at runtime.

---

## Configuration

No external config server. Use simple Java constants or `application.properties` if needed.

```java
public class Config {
    public static final int PORT = 7000;
    public static final String DB_PATH = "data/app.db";
}
```

---

## Testing

### Unit Tests (JUnit 5)

```java
class MetricRepositoryTest {
    private MetricRepository repository;

    @BeforeEach
    void setUp() {
        repository = new MetricRepository(":memory:");
        repository.initSchema();
    }

    @AfterEach
    void tearDown() {
        repository.close();
    }

    @Test
    void saveAndFind() {
        Metric m = new Metric(0, "cpu", 75.5, Instant.now());
        int id = repository.save(m);
        assertTrue(id > 0);
        assertEquals(1, repository.findAll().size());
    }
}
```

### Integration Tests (Javalin TestTools)

```java
class DashboardServerTest {
    private Javalin createApp() {
        MetricRepository repo = new MetricRepository(":memory:");
        repo.initSchema();
        MetricController controller = new MetricController(new MetricService(repo));

        return Javalin.create(config -> {
            config.routes.apiBuilder(() -> {
                get("/api/health", ctx -> ctx.json(Map.of("status", "ok")));
                path("/api/metrics", () -> {
                    get(controller::getAll);
                    post(controller::create);
                });
            });
        });
    }

    @Test
    void healthCheck() {
        JavalinTest.test(createApp(), (server, client) -> {
            var response = client.get("/api/health");
            assertEquals(200, response.code());
        });
    }
}
```

**Requires:** `javalin-bundle` (includes `javalin-testtools` and JUnit Jupiter).

---

## Build Commands

```bash
# Full build (backend + frontend)
mvn clean package

# Run
java -jar target/<project>-1.0.0.jar

# Dev mode (backend only, frontend via Vite)
mvn compile exec:java -Dexec.mainClass="io.bitnomio.<project>.DashboardServer"

# Frontend only
cd frontend && npm install && npm run dev

# Native installer
mvn package jpackage:jpackage
```

---

## Related

- `conventions-general.md` - Core principles
- `java.md` - Java patterns and SOLID
- `backbone/4-KNOWLEDGE.md` - Tech stack, NEVER DO list

*Last updated: 2026-05-13*
