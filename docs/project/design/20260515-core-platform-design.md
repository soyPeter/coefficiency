# Design Document: Core Platform

**PRD Reference:** [20260515-core-platform.md](../prd/20260515-core-platform.md)
**Date:** 2026-05-15
**Status:** Draft

---

## 1. System Context (C4 Level 1)

A single-user desktop application for consulting managers to track consultant profitability. Runs as a local HTTP server on the user's machine serving a browser-based SPA.

### Actors
- **Consulting Manager**: End user who manages consultants, views billing analytics, and simulates profitability.

### External Systems
- **Browser**: Accesses the SPA frontend via localhost. No external network dependencies.

---

## 2. Container Diagram (C4 Level 2)

```
┌──────────────────────────────────────────────────────────┐
│                    User's Machine                         │
│                                                          │
│  ┌─────────────────┐     HTTP/62226     ┌──────────────┐ │
│  │                  │───────────────────▶│              │ │
│  │  Browser (SPA)   │◀──────────────────│  Jooby Server│ │
│  │  React 19        │     JSON/OpenAPI  │  (Netty)     │ │
│  │  HashRouter      │                   │              │ │
│  └──────────────────┘                   │  ┌──────────┐ │ │
│                                         │  │  SQLite  │ │ │
│                                         │  │  (JDBI)  │ │ │
│                                         │  └──────────┘ │ │
│                                         └──────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Containers
| Container | Technology | Responsibility |
|-----------|------------|----------------|
| Browser SPA | React 19, Metronic, Recharts | UI rendering, user interaction, client-side routing |
| Jooby Server | Jooby 4.5.1, Netty, Avaje Inject | HTTP API, static file serving, business logic |
| SQLite Database | SQLite via JDBI | Persistent storage for consultants, billing, settings |

---

## 3. Component Design (C4 Level 3)

### Jooby Server Container

#### Backend Components (Java)

| Component | Responsibility |
|-----------|----------------|
| `App.java` | Application entry point, module registration, filter setup |
| `SqliteConnection` | JDBC connection wrapper, schema initialization, lifecycle |
| `ExceptionMapper` | Maps domain exceptions to HTTP status codes |
| `HealthController` | `GET /api/health` endpoint |
| `AuthController` | Login/setup/logout endpoints (see Security PRD) |
| `AuthService` | Token validation, password hashing (see Security PRD) |
| `DbEncryption` | AES-256-GCM encrypt/decrypt (see Security PRD) |
| `ConsultantController` | CRUD for consultants |
| `ConsultantService` | Consultant business logic |
| `ConsultantRepository` | JDBI-based consultant persistence |
| `BillingService` | Billing summary computation via SQL aggregation |
| `BillingController` | Billing endpoints |
| `ClientService` | Client grouping and financial analytics |
| `ClientController` | Client endpoints |
| `SimulatorController` | COEF calculation endpoints |
| `SimulatorService` | COEF formula with tax engine |
| `TaxEngine` | IRPF bracket + SS contribution computation |
| `FiscalController` | Fiscal configuration CRUD |
| `SettingsController` | App settings CRUD |
| `SettingsRepository` | Key-value settings persistence |
| `FileImportController` | CSV upload and parsing |

#### Frontend Components (React/TypeScript)

| Component | Responsibility |
|-----------|----------------|
| `App.tsx` | Root component, auth routing, layout shell |
| `LoginPage` | Login/setup form |
| `ConsultantsPage` | Consultant list with sort, search, pagination |
| `ConsultantDetailModal` | Slide-out detail panel |
| `BillingSummaryPage` | Billing KPIs and charts |
| `ClientsPage` | Client list and financial analytics |
| `FileImportPage` | CSV upload interface |
| `SimulatorPage` | Interactive COEF calculator |
| `ConfigPage` | Fiscal parameters and settings management |
| `DocsPage` | Auto-generated documentation viewer |
| `api.ts` | HTTP client with auth header injection |
| `i18n/` | react-intl message files (EN/ES) |

#### Interactions

```
Browser ──HTTP──▶ Jooby ──JDBI──▶ SQLite
                    │
                    ├── mvc(HealthController)
                    ├── mvc(AuthController)
                    ├── mvc(ConsultantController)
                    ├── mvc(BillingController)
                    ├── mvc(ClientController)
                    ├── mvc(SimulatorController)
                    ├── mvc(FiscalController)
                    ├── mvc(SettingsController)
                    ├── mvc(FileImportController)
                    └── assets (static/ for React SPA)
```

---

## 4. Architecture Decisions

### ADR-001: Jooby MVC API with Avaje Inject

**Status:** Accepted
**Context:** Need a lightweight Java web framework with compile-time dependency injection for a desktop application.
**Decision:** Use Jooby 4.5.1 MVC API (`@Path`, `@GET`, `@POST`) with Avaje Inject (`@Singleton`, `@Inject`). Avaje Inject provides compile-time DI with `jakarta.inject` annotations — zero runtime reflection, fast startup.
**Consequences:** 
- Controllers use Jooby annotations (`io.jooby.annotation.*`) not JAX-RS
- DI uses `jakarta.inject` annotations, not Spring/CDI
- Avaje `@Factory` + `@Bean` replaces CDI `@Produces`
- Avaje `@Aspect` + `AspectProvider` replaces CDI `@InterceptorBinding`
**Alternatives Considered:**
- Spring Boot: Heavier runtime, slower startup, not ideal for local desktop app
- Raw Netty/Helidon: More boilerplate for same feature set

### ADR-002: DDD/Hexagonal Architecture

**Status:** Accepted
**Context:** Need to keep business logic framework-independent for testability and longevity.
**Decision:** Three-layer architecture: `domain/` (framework-free records), `app/` (service interfaces and use cases), `infra/` (all framework code — controllers, persistence, config).
**Consequences:**
- `domain/` has zero imports from Jooby, Avaje, or any framework
- `app/` uses only `jakarta.inject` annotations for DI
- `infra/` contains all Jooby MVC controllers, JDBI repositories, DTOs
- Layer violations are blocked by pre-commit hooks

### ADR-003: SQLite with JDBI

**Status:** Accepted
**Context:** Desktop application requires zero-install, file-based persistence.
**Decision:** Use SQLite via the Jooby JDBI module. Schema managed by Flyway migrations. No connection pooling needed (single user).
**Consequences:**
- Database is a single file (`data/app.db`)
- No separate database server to install
- JDBI provides type-safe SQL with `@SqlQuery`/`@SqlUpdate` annotations
- Flyway handles schema versioning

### ADR-004: Fat JAR Distribution

**Status:** Accepted
**Context:** Users need a single runnable artifact — no build tool or Node.js on their machine.
**Decision:** Use Gradle Shadow plugin to produce a fat JAR containing the Jooby server, compiled React SPA, and all dependencies. Run with `java -jar target/Jooby-coef-calc-1.0.0.jar`.
**Consequences:**
- Frontend build (npm) must run before JAR assembly as a Gradle task dependency
- JAR size ~50-80MB (JRE not included — users must have Java 21+)
- No classpath issues — everything bundled

### ADR-005: React 19 SPA with HashRouter

**Status:** Accepted
**Context:** SPA needs client-side routing that works without a backend URL rewrite rule (files served from classpath).
**Decision:** Use React 19 with HashRouter (`#/consultants`, `#/billing`, etc.) served as static files from `classpath:/static/`.
**Consequences:**
- URLs use hash fragment: `http://localhost:62226/#/consultants`
- No server-side routing configuration needed
- React build output copied to `src/main/resources/static/` during Gradle build

### ADR-006: i18n via react-intl

**Status:** Accepted
**Context:** Users need English and Spanish UI with client-side language switching.
**Decision:** Use `react-intl` for i18n. Messages stored in JSON files per locale. User preference persisted in `localStorage`.
**Consequences:**
- All user-facing strings externalized to message files
- Adding a new locale = new JSON file
- No server-side i18n needed (API responses use English)

### ADR-007: Self-Signed Auth with HMAC Tokens

**Status:** Accepted
**Context:** Desktop app has no external identity provider. Need simple, sufficient auth without OAuth complexity.
**Decision:** Password-based auth with SHA-256(salt+password) verification, HMAC-SHA256 signed tokens, and a before-filter on all `/api/*` routes.
**Consequences:**
- No external auth dependency
- Tokens are valid until logout or server restart
- See Security PRD for full details

### ADR-008: Logback with Structured JSON

**Status:** Accepted
**Context:** Need structured, parseable logs for debugging the desktop application.
**Decision:** Use Logback with `logstash-logback-encoder` for JSON-formatted logs. Console appender for development, file appender for production.
**Consequences:**
- Logs are machine-parseable JSON
- No Elastic stack required — plain JSON files on disk
- Configurable via `logback.xml`

---

## 5. API Contracts

### GET /api/health

**Response (Success):**
```json
{
  "status": "UP",
  "dbConnected": true,
  "uptime": 12345
}
```

**Response (Error):**
| Status | Condition |
|--------|-----------|
| 503 | Database not connected |

### GET /api/consultants

**Query Parameters:**
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | Page number |
| size | int | 20 | Rows per page |
| sort | string | "name" | Sort field |
| order | string | "asc" | Sort direction |
| search | string | "" | Text search across name/client/position |

**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "name": "John Doe",
      "client": "Acme Corp",
      "position": "Senior Engineer",
      "coef": 0.35,
      "tariff": 500.0,
      "fees": 120000.0,
      "coefPercentage": 0.22,
      "coefMargin": 26400.0,
      "managerBonus": 1320.0,
      "startDate": "2024-01-15",
      "endDate": null,
      "daysInRole": 851,
      "simulationInputs": null
    }
  ],
  "total": 42,
  "page": 1,
  "size": 20
}
```

### POST /api/consultants

**Request:**
```json
{
  "name": "Jane Smith",
  "client": "Beta Inc",
  "position": "Data Analyst",
  "tariff": 450.0,
  "coef": 0.28,
  "startDate": "2025-03-01",
  "endDate": null,
  "fees": 95000.0
}
```

**Response:** 201 Created with consultant object.

### PUT /api/consultants/{id}

**Request:** Same shape as POST. All fields required (full update).

**Response:** 200 OK with updated consultant object.

### DELETE /api/consultants/{id}

**Response:** 204 No Content.

### GET /api/billing/summary

**Response:**
```json
{
  "daily": 10500.0,
  "monthly": 220500.0,
  "annual": 2646000.0,
  "hires": 5,
  "terminations": 2,
  "netChange": 3,
  "annualDelta": 10,
  "expectedHires": 2,
  "expectedTerminations": 1
}
```

### GET /api/billing/monthly

**Response:**
```json
[
  {
    "month": "2025-01",
    "revenue": 220500.0,
    "hires": 1,
    "terminations": 0
  }
]
```

### GET /api/clients

**Response:**
```json
[
  {
    "client": "Acme Corp",
    "positionCount": 3,
    "consultants": ["John Doe", "Jane Smith"]
  }
]
```

### GET /api/clients/financial

**Response:**
```json
[
  {
    "client": "Acme Corp",
    "totalFees": 360000.0,
    "totalMargin": 72000.0,
    "totalBonus": 3600.0,
    "avgTenure": 420,
    "maxTenure": 851,
    "consultantCount": 3
  }
]
```

### POST /api/files/upload

**Request:** `multipart/form-data` with CSV file.

**CSV Format:** `name,client,position,coef,tariff,startDate,endDate,honorarios`

**Response:**
```json
{
  "imported": 15,
  "skipped": 2,
  "errors": 0
}
```

### GET /api/auth/status

**Response:**
```json
{
  "hasUser": true,
  "authenticated": false
}
```

### POST /api/auth/setup

**Request:**
```json
{
  "username": "admin",
  "password": "secret123"
}
```

**Response:** 200 OK with token.

### POST /api/auth/login

**Request:**
```json
{
  "username": "admin",
  "password": "secret123"
}
```

**Response:** 200 OK with token.

### POST /api/auth/logout

**Headers:** `Authorization: Bearer <token>`

**Response:** 204 No Content.

### Error Response Format

```json
{
  "error": "Not Found",
  "status": 404
}
```

| HTTP Status | Condition |
|-------------|-----------|
| 400 | BadRequestException (invalid input) |
| 401 | Missing/invalid auth token |
| 404 | Resource not found |
| 503 | Database not connected |
| 500 | Unexpected server error |

---

## 6. Data Model

### users

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INTEGER | PK AUTOINCREMENT | User ID |
| username | TEXT | UNIQUE NOT NULL | Login name |
| password_hash | TEXT | NOT NULL | SHA-256(salt + password) |
| salt | TEXT | NOT NULL | 16-byte random hex salt |
| created_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

### consultants

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INTEGER | PK AUTOINCREMENT | Consultant ID |
| name | TEXT | NOT NULL | Full name |
| client | TEXT | NOT NULL | Client company |
| position | TEXT | NOT NULL | Job title |
| coef | REAL | NOT NULL | Cost coefficient |
| tariff | REAL | NOT NULL | Daily tariff (EUR) |
| start_date | TEXT | NOT NULL | Start date (ISO 8601) |
| end_date | TEXT | NULLABLE | End date (ISO 8601) |
| fees | REAL | NULLABLE | Annual fees |
| coef_percentage | REAL | NULLABLE | Computed COEF % |
| coef_margin | REAL | NULLABLE | Computed margin |
| manager_bonus | REAL | NULLABLE | Computed bonus |
| simulation_inputs | TEXT | NULLABLE | JSON blob of simulator inputs |
| created_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| updated_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Update timestamp |

### settings

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| key | TEXT | PRIMARY KEY | Setting key |
| value | TEXT | NOT NULL | Setting value (JSON or scalar) |
| updated_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Update timestamp |

### cost_concepts

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INTEGER | PK AUTOINCREMENT | Concept ID |
| name | TEXT | NOT NULL | Concept name |
| type | TEXT | NOT NULL | monthly, yearly, onetime |
| default_value | REAL | NOT NULL | Suggested default |
| updated_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Update timestamp |

### SQL Views

#### v_client_financials
Aggregates per-client: total fees, total margin, total bonus, avg tenure, max tenure, consultant count.

#### v_position_profitability
Aggregates per-position: total fees, margin, count, avg COEF.

### Relationships

- consultants → users: N:1 (all consultants belong to the single user)
- consultants → settings (delta target): read via key lookup
- cost_concepts: standalone reference table
- settings: standalone key-value store

### Schema Migrations

Managed by Flyway. Migration files in `src/main/resources/db/migration/`:
- `V1__init.sql`: Create users, consultants, settings, cost_concepts tables + SQL views

---

## 7. Traceability

| Requirement ID | Summary | Design Section | Status |
|----------------|---------|----------------|--------|
| REQ-PLAT-001 | Backend Server (Jooby port 62226, virtual threads) | §3 (App.java), §4 ADR-001 | Draft |
| REQ-PLAT-002 | Static File Serving | §3 (App.java static/), §4 ADR-005 | Draft |
| REQ-PLAT-003 | JAR Distribution | §4 ADR-004 | Draft |
| REQ-PLAT-004 | OpenAPI Documentation | §3 (HealthController, @OpenApi), §4 ADR-001 | Draft |
| REQ-PLAT-005 | Frontend Routing (HashRouter) | §4 ADR-005 | Draft |
| REQ-PLAT-006 | i18n (EN/ES, react-intl) | §4 ADR-006 | Draft |
| REQ-PLAT-007 | CORS | §3 (App.java before-filter) | Draft |
| REQ-PLAT-008 | Error Handling (ExceptionMapper) | §3 (ExceptionMapper), §5 | Draft |
| REQ-PLAT-009 | Architecture Rules (DDD packages) | §4 ADR-002 | Draft |
| REQ-PLAT-010 | Browser Auto-Open | §3 (App.java main) | Draft |
| REQ-PLAT-011 | Code Quality Tools (Checkstyle, SpotBugs, JaCoCo) | §4 ADR-004 (Gradle config) | Draft |
| REQ-PLAT-012 | Logging (Logback + JSON) | §4 ADR-008 | Draft |

---

**Review History:**
| Date | Reviewer | Verdict | Notes |
|------|----------|---------|-------|
| | | | |
