<!-- VERSION: 2026.05.08 -->
# Quarkus Qute Desktop Conventions

*Quarkus + Qute + SQLite desktop dashboard patterns. See `java.md` for base Java patterns and `quarkus.md` for full Quarkus patterns.*

---

## Quick Reference

| Pattern | Quarkus Qute | Full Quarkus Microservice |
|---------|--------------|---------------------------|
| HTML Template | `@Inject Template dashboard` + `dashboard.data(...)` | Not used (JSON APIs only) |
| REST API | Same: `@Path`, `@GET`, `@POST` | Same |
| DI | `@Inject` + constructor | Same |
| Static Assets | `META-INF/resources/static/` | Same |
| Frontend Build | **None** — vanilla JS + CDN | React/Vite build pipeline |
| Charts | Chart.js via CDN | Recharts (React) |
| Interactivity | HTMX + vanilla JS | React state/hooks |

---

## Architecture

### 3-Layer Structure (Domain / App / Infra)

```
src/main/java/io/bitnomio/<project>/
├── DashboardResource.java        # Qute HTML page + HTMX endpoints
├── MetricsResource.java          # JSON REST API
├── FileResource.java             # Multipart upload
├── BrowserLauncher.java          # Auto-open browser on startup
├── domain/
│   ├── Metric.java               # Java records (NO framework imports)
│   └── ImportResult.java
├── app/
│   ├── MetricsService.java       # @ApplicationScoped business logic
│   └── FileImportService.java    # CSV parsing
└── infra/
    └── SqliteRepository.java     # @ApplicationScoped JDBC repository
```

### Layer Rules

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| `domain/` | Records, enums, exceptions | ANY framework imports (`io.quarkus`, `jakarta`) |
| `app/` | `@ApplicationScoped`, services | HTTP/JDBC directly |
| `infra/` | `@ApplicationScoped`, JDBC, Qute, REST | Business rules |

**Domain Must Be Framework-Free.** No Quarkus, no Jakarta imports in `domain/`.

---

## Dependency Injection (CDI)

```java
@ApplicationScoped
public class MetricsService {
    private final SqliteRepository repository;

    @Inject
    public MetricsService(SqliteRepository repository) {
        this.repository = repository;
    }
}
```

### Constructor Injection (Mandatory)

Single constructor: `@Inject` optional.
Multiple constructors: `@Inject` required on the one to use.

**NEVER field injection:**
```java
// WRONG
@Inject
private MetricsService service;  // FORBIDDEN

// CORRECT
private final MetricsService service;
@Inject
public MyClass(MetricsService service) {
    this.service = service;
}
```

---

## Qute Templating

### Main Page Resource

```java
@Path("/")
public class DashboardResource {
    @Inject Template dashboard;
    @Inject MetricsService service;

    @GET
    @Produces(MediaType.TEXT_HTML)
    public TemplateInstance index() {
        List<Metric> metrics = service.getAllMetrics();
        return dashboard.data("metrics", metrics);
    }
}
```

### Template (`templates/dashboard.html`)

```html
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://unpkg.com/htmx.org@1.9"></script>
    <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
    <!-- Server-rendered with initial data -->
    <div id="metricsTable"
         hx-get="/api/metrics"
         hx-trigger="load, every 5s"
         hx-swap="innerHTML">
        {#include metrics-table.html metrics=metrics /}
    </div>

    <canvas id="chart"></canvas>
    <script src="/static/js/app.js"></script>
</body>
</html>
```

### Partial Template (`templates/metrics-table.html`)

```html
<table>
    <tbody>
        {#if metrics.isEmpty()}
        <tr><td colspan="4">No metrics yet.</td></tr>
        {#else}
        {#for metric in metrics}
        <tr>
            <td>{metric.id}</td>
            <td>{metric.name}</td>
            <td>{metric.value}</td>
        </tr>
        {/for}
        {#endif}
    </tbody>
</table>
```

---

## REST Controllers (JSON API)

```java
@Path("/api/metrics")
@Produces(MediaType.APPLICATION_JSON)
public class MetricsResource {

    @Inject
    MetricsService service;

    @GET
    public List<Metric> getAll() {
        return service.getAllMetrics();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(CreateMetricRequest request) {
        Metric metric = service.addMetric(request.name(), request.value());
        return Response.status(201).entity(metric).build();
    }
}
```

---

## Multipart File Upload

```java
@Path("/api/files")
public class FileResource {
    @Inject FileImportService importService;

    @POST
    @Path("/upload")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response upload(@MultipartForm FileUploadForm form) {
        if (form.file == null) {
            return Response.status(400)
                .entity(new ImportResult(false, 0, "No file"))
                .build();
        }
        ImportResult result = importService.process(form.file, "");
        return Response.ok(result).build();
    }

    public static class FileUploadForm {
        @FormParam("file")
        @PartType(MediaType.APPLICATION_OCTET_STREAM)
        public InputStream file;
    }
}
```

---

## SQLite Persistence

```java
@ApplicationScoped
public class SqliteRepository {
    private Connection connection;

    @PostConstruct
    void init() {
        File dbFile = new File("data/app.db");
        dbFile.getParentFile().mkdirs();
        this.connection = DriverManager.getConnection(
            "jdbc:sqlite:" + dbFile.getPath()
        );
        initSchema();
    }
}
```

**Why `@PostConstruct`?** Quarkus manages the lifecycle. Schema init runs after CDI constructs the bean.

---

## Frontend (Zero Build)

### No Node.js. No npm. No Vite.

Static JS/CSS served directly from `META-INF/resources/static/`:

```
src/main/resources/
├── templates/
│   ├── dashboard.html
│   └── metrics-table.html
└── META-INF/resources/
    └── static/
        ├── css/style.css
        └── js/app.js
```

### Chart.js (CDN)

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
```

### HTMX (CDN)

```html
<script src="https://unpkg.com/htmx.org@1.9.12"></script>
```

```html
<!-- Auto-refresh table every 5 seconds -->
<div hx-get="/api/metrics" hx-trigger="load, every 5s" hx-swap="innerHTML">
</div>
```

---

## Browser Launch

```java
@ApplicationScoped
public class BrowserLauncher {
    void onStart(@Observes StartupEvent ev) {
        if (Desktop.isDesktopSupported()
                && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
            Desktop.getDesktop().browse(new URI("http://localhost:8080"));
        }
    }
}
```

Auto-opens browser when Quarkus starts (dev and prod modes).

---

## Configuration (`application.properties`)

```properties
quarkus.http.port=8080
quarkus.http.host=0.0.0.0
quarkus.live-reload.instrumentation=true
```

---

## Build Commands

```bash
# Dev mode (live reload)
mvn quarkus:dev

# Production build
mvn package
java -jar target/quarkus-app/quarkus-run.jar

# Native image (requires GraalVM)
mvn package -Pnative
```

---

## Testing

### Unit Tests (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class MetricsServiceTest {
    @Mock SqliteRepository repository;
    @InjectMocks MetricsService service;

    @Test
    void shouldAddMetric() {
        Metric result = service.addMetric("temp", 23.5);
        assertEquals("temp", result.name());
    }
}
```

### Integration Tests (@QuarkusTest)

```java
@QuarkusTest
class MetricsResourceTest {
    @Test
    void shouldListMetrics() {
        given()
            .when().get("/api/metrics")
            .then()
            .statusCode(200)
            .body("$.size()", greaterThanOrEqualTo(0));
    }
}
```

---

## Related

- `conventions-general.md` - Core principles
- `java.md` - Java patterns and SOLID
- `quarkus.md` - Full Quarkus microservice patterns (JDBI, Panache, etc.)
- `backbone/4-KNOWLEDGE.md` - Tech stack, NEVER DO list

*Last updated: 2026-05-08*
