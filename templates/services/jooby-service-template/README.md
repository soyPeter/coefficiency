# __SERVICE_PASCAL__ Service

Jooby 4.x microservice with hexagonal architecture and Avaje Inject DI.

## Tech Stack

- **Framework:** Jooby 4.5.1 (MVC API, Netty)
- **DI:** Avaje Inject 12.5 (compile-time)
- **Persistence:** JDBI 3 + PostgreSQL
- **Migrations:** Flyway
- **Build:** Gradle (Kotlin DSL)
- **Java:** 21+

## Architecture

Hexagonal (domain/app/infra):
- `domain/` — Pure Java, no framework imports
- `app/` — Use cases (business logic orchestration)
- `infra/` — Framework code, persistence, REST controllers

## Development

```bash
# Start database
docker compose up -d __SERVICE__-db

# Run the service
./gradlew run

# Tests
./gradlew test
./gradlew intTest
```
