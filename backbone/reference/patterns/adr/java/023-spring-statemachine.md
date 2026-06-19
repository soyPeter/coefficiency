# Spring Statemachine for Onboarding Flow

## Status

Accepted and Implemented

## Context and Problem Statement

The onboarding service needed a state machine to manage user progression through a three-level flow: `PROSPECT → MEMBER → HOLDER`. The implementation required:

- **Hierarchical states** with parent/child relationships (e.g., `MEMBER_COMPLIANCE_PENDING` containing KYC, AML, and RISK substates)
- **Parallel/orthogonal regions** running concurrently within a parent state — specifically KYC, AML, and RISK checks must run simultaneously and independently within `MEMBER_COMPLIANCE_PENDING`
- **Per-user isolation** — each user's onboarding must have an independent machine instance; concurrent users must not share state
- **State persistence and restoration** — state must survive JVM restarts; a user mid-compliance-check must resume from their exact region states, not restart from scratch
- **Event-driven transitions with guards and actions** — pre-transition validation (compliance checks, admin permissions, level progression) and post-transition auditing

## Decision Drivers

- **Parallel/orthogonal regions** — the most discriminating requirement; KYC, AML, and RISK must run concurrently with independent state management
- **Per-user factory pattern** — each user needs an isolated machine instance to prevent state contamination between concurrent onboarding sessions
- **Persistence API** — must serialize and restore complete machine state including parallel region substates
- **Spring ecosystem fit** — the project uses Spring Boot 4.0.2; native Spring integration reduces configuration overhead
- **Guard and action model** — pre/post-transition hooks for compliance validation and audit trail recording

## Considered Options

### Option 1: Custom State Pattern (Hand-Rolled FSM)

Implement a finite state machine using the GoF State pattern directly.

- ✅ Zero external dependencies, full control over implementation
- ✅ Simpler mental model for basic linear flows
- ❌ Implementing parallel/orthogonal regions from scratch is complex and error-prone — requires coordinating concurrent sub-state tracking across multiple regions
- ❌ No persistence API — serialization and restoration logic must be designed from scratch
- ❌ No guard/action lifecycle — transition dispatch mechanism must be built and maintained
- ❌ Higher long-term maintenance burden for the state machine framework itself

### Option 2: Stateless4j

A lightweight Java state machine library with a clean, fluent API.

- ✅ Simple, clean API for basic state machine flows
- ✅ Very lightweight, minimal transitive dependencies
- ✅ Easy to understand and onboard new developers
- ❌ No native support for parallel/orthogonal regions — KYC, AML, and RISK would require workarounds (e.g., separate machines or manual coordination)
- ❌ No built-in persistence API — serialization must be handled entirely by the application
- ❌ Less active maintenance compared to Spring Statemachine (fewer recent releases)

### Option 3: Akka FSM / Akka Typed Behaviors

Use Akka's actor-based state machine via `FSM` trait or `Behaviors` in Akka Typed.

- ✅ Mature actor model with built-in distribution support
- ✅ Excellent persistence via Akka Persistence (event sourcing, snapshots)
- ✅ Strong support for concurrent state management across many users
- ❌ Requires adopting the full Akka runtime — significant overhead for a single service feature
- ❌ Actor model is conceptually different from Spring's imperative programming model; steep learning curve for Spring-native teams
- ❌ Adds substantial dependency footprint: Akka Core, Akka Persistence, serialization libraries (e.g., Jackson or Protobuf codecs)
- ❌ Not idiomatic for Spring Boot services; interoperability between Spring DI and Akka actors requires bridging

### Option 4: Spring Statemachine ⭐ CHOSEN

Spring Statemachine is the official Spring project for state machine support.

- ✅ Native parallel/orthogonal regions: `region("KYC")`, `region("AML")`, `region("RISK")` in the `StateMachineStateConfigurer` DSL
- ✅ `@EnableStateMachineFactory` provides the per-user factory pattern — `factory.getStateMachine(userId)` creates isolated machine instances
- ✅ `StateMachinePersister<S, E, T>` interface allows custom persistence (JDBI in our case)
- ✅ Hierarchical state configuration with parent/child relationships via `.parent(...)` in the DSL
- ✅ `Guard<S, E>` and `Action<S, E>` interfaces for pre/post-transition logic
- ✅ Integrates naturally with Spring Boot's dependency injection and configuration
- ⚠️ More complex configuration API than simple alternatives — the `StateMachineConfigurerAdapter` DSL has a learning curve
- ⚠️ Heavier dependency footprint than Stateless4j
- ⚠️ Spring Statemachine is not among the most actively maintained Spring projects; API stability should be monitored across major versions

## Decision Outcome

**Chosen: Option 4 — Spring Statemachine**

Spring Statemachine is the only option among those evaluated that provides native, first-class support for parallel/orthogonal regions — the most critical requirement. The factory pattern for per-user isolation and the `StateMachinePersister` interface for custom persistence align directly with the project's JDBI-first persistence strategy (see ADR-0002).

### Consequences

**Good:**

- Parallel compliance regions (KYC/AML/RISK) are first-class citizens configured cleanly in the DSL — no ad-hoc coordination code required
- Per-user factory pattern via `@EnableStateMachineFactory` provides proper isolation for concurrent onboarding sessions without application-level coordination
- `StateMachinePersister` interface integrates cleanly with our JDBI persistence strategy (see `JdbiStateMachinePersister`)
- Guards (`LevelProgressionGuard`, `CompliancePassedGuard`, `AdminPermissionGuard`) and actions (`RecordAuditAction`) fit naturally into the Spring component model

**Bad:**

- Spring Statemachine adds configuration complexity — the `StateMachineConfigurerAdapter` DSL requires developers to understand hierarchical state machine concepts before contributing
- `@EnableStateMachineFactory` instances are not trivial Spring beans — each user's machine is a graph of Spring-managed objects; under high concurrent load, memory and GC pressure should be monitored
- Region state serialization is not provided out-of-the-box — `JdbiStateMachinePersister` requires custom logic to walk `StateMachineAccess` regions and serialize each region's current state to JSONB
- The synchronous `sendEvent(Message<E>)` API must be used instead of the reactive `sendEvent(Mono<Message<E>>)` — the reactive version returns an empty `Flux` in blocking execution contexts, causing all transitions to appear rejected

## References

- **[ADR-0002](../../adr/002-jdbi-persistence.md)** — JDBI over JPA: persistence strategy context
- **[ADR-0001](../../adr/001-hexagonal-architecture.md)** — Hexagonal Architecture: framework isolation principles
