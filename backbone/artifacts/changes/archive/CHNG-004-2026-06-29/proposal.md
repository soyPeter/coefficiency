---
grilled: true
---

# Core Platform

## Summary

Desktop application backend (Jooby + SQLite) and frontend foundation (React 19 + Metronic). Provides the HTTP server, routing, database layer, build system, i18n infrastructure, and documentation page for the Consultant COEF Calculator.

## Background

A consulting manager needs a local desktop tool to replace Excel spreadsheets for tracking consultant profitability. The application runs as a local HTTP server serving a React SPA, storing all data in a local SQLite database.

## Grilling

### Scope
- **Q:** What does this PRD cover?
- **A:** The foundational platform: Java/Jooby backend server, SQLite database, gradle build with fat JAR packaging, feature-based architecture, React 19 SPA with HashRouter and Metronic UI, i18n EN/ES, auto-generated API documentation page, error mapping, CORS, and health endpoint.
- **Q:** What is out of scope?
- **A:** Business logic for consultants, billing, clients, simulator, config — those have separate PRDs. Multi-user, cloud deployment, mobile apps.

### Boundaries
- **Q:** What are the integration points?
- **A:** App.java wires all controllers via constructor injection. SqliteConnection provides the JDBC connection to all repositories. Frontend api.ts communicates via HTTP to all controllers.
- **Q:** Which parts should NOT change?
- **A:** The Archiecture rules (domain must be framework-free, app has port interfaces, infra has all framework code) are non-negotiable. Build system (gradle shade plugin) and deployment model (fat JAR) should stay stable.

### Data & State
- **Q:** What data structures are needed?
- **A:** SqliteConnection wraps a JDBC Connection. Settings stored as key-value pairs in single table. User records in users table. Schema migrations run on initSchema().
- **Q:** Where does state live?
- **A:** All state in SQLite file (data/app.db, encrypted to app.db.enc). No server-side cache. Token stored in frontend localStorage.

### API
- **Q:** What are the core platform endpoints?
- **A:** GET /api/health (status check), OpenAPI/Swagger/ReDoc at standard paths. CORS handled via before-filter. Errors mapped by ExceptionMapper (404, 400, 503, 500).
- **Q:** How is the API documented?
- **A:** Jooby OpenAPI plugin scans @OpenApi annotations on all controller methods. Swagger UI at /swagger, ReDoc at /redoc, spec at /openapi.json.

### Implementation Order
- **Q:** What's the foundation layer?
- **A:** Build system → Database layer → Feature modules (one by one) → API doc → Frontend shell → i18n.
- **Q:** What are the highest-risk parts?
- **A:** Database schema migrations (compatibility with existing DBs). Frontend build integration with gradle. Jooby version compatibility.

## Requirements

### REQ-PLAT-001: Backend Server
WHEN the user starts the application, the system SHALL launch a Jooby HTTP server on port 62226 with virtual threads enabled.

### REQ-PLAT-002: Static File Serving
WHEN the browser requests the root URL, the system SHALL serve the built React SPA from classpath:/static/.

### REQ-PLAT-003: JAR Distribution
WHEN the user runs `java -jar target/Jooby-coef-calc-1.0.0.jar`, the system SHALL start the full application with embedded frontend.

### REQ-PLAT-004: OpenAPI Documentation
WHEN the user navigates to /swagger or /redoc, the system SHALL display auto-generated API documentation from @OpenApi annotations.

### REQ-PLAT-005: Frontend Routing
WHEN the user navigates in the SPA, the system SHALL use HashRouter with routes for consultants, billing, clients, import, config, and docs.

### REQ-PLAT-006: i18n
WHEN the user switches language, the system SHALL toggle UI text between English and Spanish via react-intl, persisted in localStorage.

### REQ-PLAT-007: CORS
WHEN the browser sends a cross-origin request, the system SHALL respond with permissive CORS headers.

### REQ-PLAT-008: Error Handling
WHEN a controller throws an exception, the system SHALL map NotFoundException → 404, BadRequestException → 400, IllegalStateException → 503, Exception → 500.

### REQ-PLAT-009: Architecture Rules
WHEN organizing code, the system SHALL use feature-based packages: domain/ (framework-free records), app/ (services + interfaces), infra/ (controllers + persistence + DTOs).

### REQ-PLAT-010: Browser Auto-Open
WHEN the server starts, the system SHALL attempt to open http://localhost:62226 in the default browser.

### REQ-PLAT-011: Code Quality Tools
WHEN building, the system SHALL run Checkstyle, SpotBugs, and JaCoCo coverage checks.

### REQ-PLAT-012: Logging
WHEN the system runs, the system SHALL log structured JSON via Logback with logstash-logback-encoder.

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
