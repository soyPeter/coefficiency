<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: getting-started
description: Quick start guide for new developers - local setup, project structure, first API request, and common commands. Use when onboarding to a new project or setting up local development environment.
---

# Getting Started Skill

Quick start guide for setting up local development and understanding project structure.

## When to Use

- Onboarding to a new project
- Setting up local development environment
- Making first API request
- Understanding project structure

## Quick Setup

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21+ | Runtime |
| Docker | Latest | Local infrastructure |
| Gradle | 8.x | Build tool |

### Start Infrastructure

```bash
# Start all infrastructure services
./docker-start.sh

# Verify containers are running
docker ps
```

Expected: `postgres`, `rabbitmq`, `keycloak` containers.

### Build and Run

```bash
# Full build with tests
./gradlew build

# Run a specific service
./gradlew :services:customer:bootRun
```

Service ready when:
```
Netty started on port(s): 8080
Started CustomerApplication in X.XXX seconds
```

## Project Structure

### Three-Layer Architecture

```
┌─────────────────────────────────────────┐
│    Infrastructure (Framework, DB)        │
│  REST Controllers, Repos, Events        │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│       Application (Use Cases, DTOs)      │
│     Business rules with annotations      │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│   Domain (Pure business logic)          │
│   Entities, Events, Repository ports     │
└─────────────────────────────────────────┘
```

**Key principle:** Dependencies always flow inward. Domain has zero framework imports.

### Service Structure

```
services/{service}/
├── domain/
│   ├── model/vo/      # Entities, Value Objects
│   ├── event/         # Domain events
│   └── repository/     # Repository interfaces (ports)
├── app/
│   └── *UseCase.java  # One class per use case
└── infra/
    ├── io/rest/       # REST controllers
    └── data/
        ├── dto/           # Request/Response DTOs
        └── persistence/  # Repository implementations
```

### Shared Libraries

```
services/libs/
├── shared-domain/            # Base entities, events
├── shared-application/       # Annotations (@Idempotent, @PublishEvents)
├── shared-infrastructure/    # CQRS, Outbox, Idempotency, Resilience4j
└── shared-security/         # JWT validation
```

## Common Commands

### Build and Test
```bash
./gradlew build                    # Full build
./gradlew :services:service:test  # Single service tests
./gradlew test --tests "*Integration*"  # Integration tests
```

### Code Quality
```bash
./gradlew checkstyleMain    # Style checks
./gradlew spotbugsMain      # Static analysis
./gradlew jacocoTestReport  # Coverage report
```

### Docker
```bash
./docker-start.sh    # Start infrastructure
./docker-stop.sh     # Stop infrastructure
./docker-logs.sh     # View logs
```

## First API Request

### Create Entity
```bash
curl -X POST http://localhost:8080/api/v1/customers \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### Get Entity
```bash
curl http://localhost:8080/api/v1/customers/{id}
```

## Development Workflow

1. **Domain first** - Define entities, events, repository interfaces
2. **Use cases second** - Implement business logic in `app/`
3. **Infrastructure last** - REST controllers and repositories
4. **Write tests** - Unit, integration, and contract tests
5. **Run quality checks** - Before committing

## Next Steps

| Goal | Guide |
|------|-------|
| Create new service | [[reference/create-service.md]] |
| Understand patterns | [[skills/general/patterns-guide/SKILL.md]] |
| Write tests | [[skills/general/testing-guide/SKILL.md]] |
| REST API reference | [[reference/patterns/adr/004-cqrs-lite.md]] |
