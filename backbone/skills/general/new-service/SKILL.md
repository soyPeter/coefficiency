<!-- FRAMEWORK: GENERAL -->
---
name: new-service
description: Generate a complete hexagonal-architecture microservice from the project's service template.
framework: general
---

# Skill: Generate New Microservice

Generate a complete hexagonal-architecture microservice from the project's service template.

## When to Use

- User asks to create a new service, module, or microservice
- User describes a new domain entity that needs CRUD operations
- A new bounded context needs scaffolding

## Command

```bash
bash scripts/service-generator/scripts/new-service.sh <service-name> [options]
```

## Options

| Flag | Default | Purpose |
|------|---------|---------|
| `--framework quarkus\|quarkus-kotlin-panache\|springboot` | `quarkus` | Template to use |
| `-p, --package <pkg>` | `io.bitnomio` | Base Java package |
| `-e, --entity <Name>` | Capitalized service name | Entity class name |
| `--table <name>` | `${name}s` | DB table name (override for irregular plurals) |
| `--table-url <seg>` | service name | REST URL path segment |

## Architecture Selection (Before Generating)

Before creating a service, confirm the architectural context:

| Question | If Yes | Action |
|----------|--------|--------|
| Is this the first service in a new system? | Start simple | Generate as monolithic-hexagonal (default) |
| Will this service communicate via events only? | Event-Driven | Ensure Kafka/RabbitMQ config in `application.properties` |
| Does this service need independent scaling? | Microservice | Confirm it has its own DB and deployment pipeline |
| Is this replacing part of a legacy monolith? | Strangler Fig | Plan routing rules before generating |
| Will reads and writes have very different models? | CQRS | Generate separate query/command repos |
| Is this a short-lived function (webhook, job)? | Serverless | Consider `quarkus-amazon-lambda` instead |

**Default:** The generator creates hexagonal architecture services. This is the right default for 80% of cases.

For full architecture guidance, see [`backbone/skills/cross-cutting/architecture/software-architectures/SKILL.md`](backbone/skills/cross-cutting/architecture/software-architectures/SKILL.md).

## Decision Checklist

Before running, confirm with the user:
1. **Service name** — lowercase alphanumeric, e.g. `order`, `payment`, `inventory`
2. **Entity name** — PascalCase, e.g. `Order`, `Payment` (defaults to capitalized service name)
3. **Framework** — `quarkus` (hexagonal, Java, JDBI), `quarkus-kotlin-panache` (Kotlin, Panache, Maven), or `springboot` (check [`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md))
4. **Package** — check existing services for the org's base package
5. **Table name** — check for irregular plurals: `category` → `categories`, not `categorys`
6. **Architecture fit** — does hexagonal (default) match the use case? (see Architecture Selection above)

## Example Invocations

```bash
# Standard: service name = entity name
bash scripts/service-generator/scripts/new-service.sh order

# Different entity name
bash scripts/service-generator/scripts/new-service.sh auth -e Credentials

# Custom package + irregular plural
bash scripts/service-generator/scripts/new-service.sh category \
  -p com.mycompany \
  --table categories \
  --table-url categories

# Spring Boot
bash scripts/service-generator/scripts/new-service.sh payment --framework springboot -p com.mycompany

# Quarkus + Kotlin + Panache (active record style)
bash scripts/service-generator/scripts/new-service.sh employee --framework quarkus-kotlin-panache -p com.mycompany
```

## What Gets Generated

### Quarkus (Default — Hexagonal, Java, Gradle, JDBI)

```
services/<name>/
├── build.gradle.kts
├── src/main/java/<package>/<name>/
│   ├── <Name>Application.java          — Entry point
│   ├── domain/
│   │   ├── model/vo/<Entity>.java      — Domain entity (Java Record, soft delete)
│   │   ├── actions/<Entity>CommandAction.java  — Repository port
│   │   └── event/<Entity>CreatedEvent.java     — Domain event
│   ├── app/
│   │   ├── Create<Entity>UseCase.java  — Create use case (@Idempotent, @PublishEvents)
│   │   └── Get<Entity>ByIdUseCase.java — GetById use case
│   └── infra/
│       ├── config/JdbiConfig.java      — JDBI repo wiring
│       ├── data/
│       │   ├── dto/Create<Entity>Req.java  — Request DTO
│       │   ├── dto/<Entity>Res.java        — Response DTO
│       │   └── persistence/sql/
│       │       ├── <Entity>Row.java        — SQL row mapper
│       │       └── <Entity>SqlCommandRepo.java — JDBI repo impl
│       └── io/rest/<Entity>CommandController.java — REST controller
├── src/main/resources/
│   ├── application.properties          — DB, RabbitMQ, logging config
│   └── db/migration/V1__create_<table>_table.sql — Flyway migration
└── src/test/java/<package>/<name>/
    ├── app/Create<Entity>UseCaseTest.java      — Unit test
    ├── app/Get<Entity>ByIdUseCaseTest.java     — Unit test
    └── infra/data/persistence/sql/<Entity>RepoIntegrationTest.java — Integration test
```

### Quarkus + Kotlin + Panache (Active Record, Maven)

```
services/<name>/
├── pom.xml
├── src/main/kotlin/<package>/<name>/
│   ├── <Name>Application.kt           — @QuarkusMain entry point
│   ├── domain/<Entity>.kt             — PanacheEntity (active record)
│   ├── repository/<Entity>Repository.kt — PanacheRepository
│   └── resource/<Entity>Resource.kt   — JAX-RS resource with @Timed
├── src/main/resources/
│   └── application.properties         — PostgreSQL/H2, OpenAPI, metrics, K8s
├── src/test/kotlin/<package>/<name>/
│   └── resource/<Entity>ResourceTest.kt — @QuarkusTest + REST Assured
└── k8s/
    ├── app-configmap.yaml
    └── postgresql-deployment.yaml
```

## After Generating

1. Customize entity fields in `domain/model/vo/<Entity>.java`
2. Update the Flyway migration to match
3. Configure database URL in `application.properties` / `application.yml`
4. Ensure shared module (`<package>.shared.*`) is available as a dependency
5. Run validation: `bash scripts/service-generator/scripts/validate-setup.sh <name>`
6. Build: `./gradlew :services:<name>:build`

## Shared Module

Generated services import from `<package>.shared.*`:
- `shared.app.config.annotations.Idempotent` — idempotency annotation
- `shared.app.config.annotations.PublishEvents` — outbox event publishing
- `shared.domain.event.DomainEventRecorder` — domain event recording
- `shared.infra.io.web.ControllerBase` — base controller
- `shared.infra.io.web.rest.StandardResponse` — response envelope

The shared module must exist in your project. If it doesn't, either create it or remove the
shared imports from the generated files and implement the patterns directly.
