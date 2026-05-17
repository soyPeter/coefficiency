# [Date] — Tech Stack

*Date: [YYYY-MM-DD]*

## Current Tech Stack

- **Core:** [Framework and version, e.g. Quarkus 3.x / Spring Boot 3.x / Laravel 11]
- **Build:** [Build tool and version, e.g. Gradle 9.x / Maven 3.x / Composer]
- **DI:** [Dependency injection approach]
- **Persistence:** [Database + query library + migration tool]
- **Messaging:** [Message broker if applicable]

## Never Do List

*(Add project-specific hard constraints here — things that caused production incidents,
violated architectural principles, or created debt. Be specific.)*

- **NEVER** [constraint 1]
- **NEVER** [constraint 2]

## Layer Constraints

| Layer | Allowed | Forbidden |
|-------|---------|-----------|
| `domain/` | [pure domain types] | [framework imports] |
| `app/` | [use-case orchestration] | [infrastructure code] |
| `infra/` | [adapters, I/O, DB] | — |
