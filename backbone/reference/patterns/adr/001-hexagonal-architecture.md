# Hexagonal Architecture with Domain-Driven Design

## Status

Accepted

## Context and Problem Statement

The project requires a maintainable, scalable, and testable architecture that clearly separates business logic from infrastructure concerns. We need to choose an architectural style that:
- Enforces clean separation of concerns
- Allows framework-agnostic domain logic
- Facilitates testing at all levels
- Enables infrastructure changes without affecting business logic

## Decision Drivers

* **Testability**: Domain logic must be testable without infrastructure dependencies
* **Maintainability**: Clear boundaries make code easier to understand and modify
* **Flexibility**: Infrastructure should be swappable without domain changes
* **Framework independence**: Domain and application layers should not depend on Spring
* **Team familiarity**: Patterns should be well-documented and widely understood

## Considered Options

* **Hexagonal Architecture (Ports & Adapters)** - Three-layer separation with dependency inversion
* **Layered Architecture** - Traditional layers (Presentation → Business → Data)
* **Clean Architecture** - Onion-style with entities at the center

## Decision Outcome

Chosen option: **Hexagonal Architecture (Ports & Adapters)**, because it provides clear boundaries, enforces the dependency rule, and naturally supports our CQRS and event-driven patterns.

### Structure

Each microservice follows this structure:

```
services/{service}/src/main/java/io/bitnomio/{service}/
├── domain/                     # Core business logic (no framework dependencies)
│   ├── model/
│   │   ├── entity/             # Domain entities with behavior
│   │   └── vo/                 # Value Objects (immutable)
│   ├── actions/                # Repository interfaces (ports)
│   ├── service/                # Domain services (complex logic)
│   └── event/                  # Domain events
├── app/                        # Application layer (use cases)
│   └── *UseCase.java           # One use case per class
└── infra/                      # Infrastructure layer (adapters)
    ├── io/
    │   ├── rest/               # REST controllers (input adapters)
    │   └── events/             # Event listeners
    └── data/
        ├── dto/                # Data Transfer Objects
        └── persistence/
            └── sql/                # JDBI repositories (output adapters)
```

### Dependency Rule

Dependencies flow inward: **Infrastructure → Application → Domain**

- Domain layer has zero external dependencies
- Application layer depends only on Domain
- Infrastructure layer implements ports defined in Domain/Application

### Consequences

**Good:**
* Domain logic can be unit tested in isolation without mocking frameworks
* Infrastructure can be swapped (e.g., PostgreSQL to another SQL DB) without domain changes
* Clear separation of concerns improves code readability
* Natural fit for microservices with well-defined boundaries
* Supports both synchronous (REST) and asynchronous (events) communication

**Bad:**
* More boilerplate code for defining interfaces (ports) and implementations (adapters)
* Learning curve for developers unfamiliar with the pattern
* Requires discipline to maintain boundaries

### Implementation Notes

- Domain layer uses Java Records for entities and value objects
- Application layer uses `@Named` (JSR-330) instead of `@Service`
- Infrastructure layer uses Spring Boot, JDBI, and RabbitMQ
- Shared libraries follow the same layered structure

## References

* `services/{service}/src/main/java/io/bitnomio/{service}/` - Service structure
* `services/libs/shared-domain/` - Shared domain components
* `services/libs/shared-application/` - Shared application components
* `services/libs/shared-infrastructure/` - Shared infrastructure components
