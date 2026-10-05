# Planning: Core Platform

**PRD Reference:** `docs/project/prd/20260515-core-platform.md`
**Design Reference:** `docs/project/design/20260515-core-platform-design.md`

## Summary

New subproject `services/coeff` — a Jooby + SQLite desktop application serving a React 19 SPA. Follows the same patterns as `services/awitjacv` (Avaje Inject, JDBI, DDD layers) but with SQLite instead of PostgreSQL, an embedded React frontend, and fat JAR packaging.

## Dependency Graph

```
Dependency catalog update (SQLite, logstash-logback-encoder, OpenAPI)
    │
    ├── services/coeff/build.gradle.kts (Gradle config)
    │       │
    │       ├── logback.xml (JSON logging)
    │       ├── checkstyle + spotbugs config (inherit from root)
    │       │
    │       ├── SqliteConnection (schema init)
    │       │       │
    │       │       └── ExceptionMapper + domain exceptions
    │       │
    │       ├── App.java (Jooby, CORS, static files, OpenAPI, browser auto-open)
    │       │
    │       └── React SPA (Vite build → resources/static/)
    │               │
    │               ├── HashRouter layout + sidebar nav
    │               └── i18n EN/ES (react-intl)
    │
    └── settings.gradle.kts (add :services:coeff)
```

## Vertical Slices

### Slice 1: Backend Foundation
Build config, SQLite connection, schema init, exception handling, App.java entry point with Jooby modules. This is the backend skeleton — no business logic yet, just infrastructure.

### Slice 2: Frontend Shell
Vite + React 19 + Metronic setup, HashRouter with placeholder pages, sidebar navigation, i18n with EN/ES message bundles.

## Implementation Order

Bottom-up: dependencies → database → infrastructure → App.java → frontend shell → i18n.

1. Gradle build config + version catalog updates — enables compilation
2. SqliteConnection + schema — enables database operations
3. ExceptionMapper + domain exceptions — enables error handling
4. App.java with Jooby, CORS, static files, OpenAPI — enables server startup
5. React SPA shell with Vite, HashRouter, layout — enables UI rendering
6. i18n infrastructure with EN/ES bundles — enables language switching

Each step leaves the system in a working state (except step 5 depends on step 4 for the frontend to be served).

## Tasks

### Task 1: [S] build: configure coeff subproject with Gradle and dependencies

Update version catalog with SQLite, logstash-logback-encoder, and jooby-openapi dependencies. Create `services/coeff/build.gradle.kts` with application plugin, fat JAR packaging, and Jooby/SQLite dependencies. Add to `settings.gradle.kts`. Create `logback.xml` with JSON encoder. Create source directory tree.

**Files:**
- `gradle/libs.versions.toml`
- `settings.gradle.kts`
- `services/coeff/build.gradle.kts`
- `services/coeff/src/main/resources/logback.xml`

### Task 2: [XS] feat: create SqliteConnection and schema initialization

Create `SqliteConnection.java` wrapping JDBC connection to SQLite at `data/coeff.db`. Schema init creates `consultants`, `users`, `settings`, `cost_concepts` tables plus `v_client_financials` and `v_position_profitability` views. JDBI `@Factory` for repository wiring.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/config/SqliteConnection.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/config/JdbiFactory.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/config/AvajeModule.java`

### Task 3: [XS] feat: create ExceptionMapper and domain exceptions

Create `NotFoundException` and `BadRequestException` in domain layer. Create `ExceptionMapper` in infra that maps exceptions to HTTP status codes returning JSON `{ error: message }`.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/domain/exception/NotFoundException.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/domain/exception/BadRequestException.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/io/rest/ExceptionMapper.java`

### Task 4: [S] feat: create App.java with Jooby config, CORS, static files

Create `CoeffApplication.java` extending Jooby. Register AvajeInject, JdbiModule, OpenAPI plugin, Swagger/ReDoc. Add CORS before-filter. Serve static files from `/`. Configure Jackson with JavaTimeModule. Set port 62226 with virtual threads. Add browser auto-open on startup.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/CoeffApplication.java`

### Task 5: [S] feat: create React SPA shell with Vite, HashRouter, Metronic layout

Set up Vite + React 19 + TypeScript project in `services/coeff/frontend/`. HashRouter with routes: consultants, billing, clients, import, config, docs. Metronic sidebar layout with navigation. Gradle task to build frontend and copy to `resources/static/` before JAR assembly.

**Files:**
- `services/coeff/frontend/package.json`
- `services/coeff/frontend/vite.config.ts`
- `services/coeff/frontend/src/App.tsx`
- `services/coeff/frontend/src/routing/app-routing.tsx`
- `services/coeff/frontend/src/layout/SidebarLayout.tsx`
- `services/coeff/frontend/tsconfig.json`
- `services/coeff/frontend/index.html`

### Task 6: [S] feat: create i18n infrastructure with EN/ES bundles

Create react-intl IntlProvider wrapper in React. English and Spanish message bundles covering nav labels, page titles, table headers, button labels, and common UI strings. Language switcher component in sidebar. Locale persisted in localStorage, detected from browser on first visit.

**Files:**
- `services/coeff/frontend/src/i18n/IntlProvider.tsx`
- `services/coeff/frontend/src/i18n/en.ts`
- `services/coeff/frontend/src/i18n/es.ts`
- `services/coeff/frontend/src/i18n/messages.ts`
- `services/coeff/frontend/src/components/LanguageSwitcher.tsx`

## Skills Required

- `jooby/java-core` — domain layer (framework-free)
- `jooby/jooby-mvc` — infra layer (MVC controllers, Avaje Inject)
- `frontend/frontend-patterns` — React/TypeScript conventions

## Risks

1. **SQLite vs PostgreSQL**: The existing service uses PostgreSQL. SQLite has different SQL dialect (no ARRAY, different date functions). Need to verify schema compatibility.
2. **Frontend build integration**: Gradle must invoke npm during build. Need Node.js available on the build machine. The frontend build task should be optional (skip if Node not available).
3. **Fat JAR size**: Including a full React SPA + Node runtime dependencies in the JAR may increase size. The built frontend is just static HTML/JS/CSS (~1-5MB), so this should be acceptable.
