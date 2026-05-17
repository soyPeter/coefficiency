<!-- VERSION: 2026.05.13#5-commandpipeline,16commandstotal -->
# 3. Active Task Logbook & Milestones

*This file is the active task logbook for the project. Every task, no matter how small, must be tracked here.*
*Before starting any task, mark it `[WIP]`. Never start a task already marked `[WIP]` — ask the user first.*

---

## Project Progression Summary

| Milestone | Status | Progress | Description |
|-----------|--------|----------|-------------|
| **M1: Project Bootstrap** | [x] | 100% | Completed by generator during `init-project.sh` |
| **M2: Core Platform** | [x] | 100% | Jooby/SQLite backend, React SPA shell, i18n |
| **M3: Security** | [x] | 100% | Auth, HMAC tokens, AES-256-GCM DB encryption |
| **M4: Consultant Management** | [x] | 100% | CRUD, billing, clients, CSV import |
| **M5: COEF Simulator** | [x] | 100% | Tax engine (IRPF+SS), COEF calc, fiscal config |

---

## Active Milestones

### M5: COEF Simulator
*Tax engine (IRPF+SS), COEF calculator, fiscal configuration.*

- [x] [M] feat: create TaxEngine and SimulatorService
- [x] [M] feat: create SimulatorController, SettingsController, ConceptsController
- [x] [S] feat: create frontend SimulatorPage and ConfigPage

### M4: Consultant Management
*Consultant CRUD, billing analytics, client grouping, CSV import.*

- [x] [S] feat: create Consultant domain entity, action, and use cases
- [x] [S] feat: create Consultant JDBI repos, DTOs, and controller
- [x] [S] feat: create Billing service and controller
- [x] [S] feat: create Client grouping and financial analytics endpoints
- [x] [S] feat: create CSV import endpoint
- [x] [M] feat: create frontend ConsultantsPage, BillingPage, ClientsPage, ImportPage

### M2: Core Platform (Backend + Frontend Foundation)

*Foundational platform: Jooby/SQLite backend, React SPA shell, i18n. Dependency for all feature PRDs.*

- [x] [S] build: configure coeff subproject with Gradle, SQLite, and quality gates
- [x] [XS] feat: create SqliteConnection and schema initialization
- [x] [XS] feat: create ExceptionMapper and domain exceptions
- [x] [S] feat: create CoeffApplication with Jooby, CORS, static files, OpenAPI
- [x] [S] feat: create React SPA shell with Vite, HashRouter, and Metronic layout
- [x] [S] feat: create i18n infrastructure with EN/ES bundles

### M3: Security (Auth, Token Validation & DB Encryption)

*Three security layers: password-based auth, HMAC token validation, AES-256-GCM database encryption.*

- [x] [S] feat: create AuthService with HMAC token and password hashing
- [x] [XS] feat: create AuthRepository and SqliteAuthRepository
- [x] [S] feat: create AuthController with setup/login/logout endpoints
- [x] [S] feat: create AuthFilter for token validation on /api/* routes
- [x] [M] feat: create DbEncryption for AES-256-GCM file encryption
- [x] [S] feat: create frontend api.ts with auth headers and 401/503 handling
- [x] [S] feat: create LoginPage with login/setup forms

---

## Completed Tasks

### M1: Project Bootstrap
*Completed during project generation. Scaffold, build tool, and first build were set up automatically.*

- [x] Project scaffold created (src/, tests/, config/)
- [x] Framework and build tool configured
- [x] First working build verified
- [x] Initial commit created

---

## Task Format Convention

For non-trivial tasks (new features, architectural changes), include the PRD reference:
```markdown
- [ ] feat: Add OAuth login (PRD: backbone/prd/20260424-oauth.md)
```

---

## Legend

- `[ ]` = Pending
- `[WIP]` = In progress — do NOT start another agent on this task
- `[x]` = Completed
