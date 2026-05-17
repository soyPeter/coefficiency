<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: architecture-review
description: Analyze Java project architecture at macro level - package structure, module boundaries, dependency direction, and layering. Use when user asks "review architecture", "check structure", "package organization", or when evaluating if a codebase follows clean architecture principles.
---

# Architecture Review Skill

Analyze project structure at the macro level - packages, modules, layers, and boundaries.

## When to Use
- User asks "review the architecture" / "check project structure"
- Evaluating package organization
- Checking dependency direction between layers
- Identifying architectural violations
- Assessing clean/hexagonal architecture compliance

---

## Quick Reference: Architecture Smells

| Smell | Symptom | Impact |
|-------|---------|--------|
| Package-by-layer bloat | `service/` with 50+ classes | Hard to find related code |
| Domain → Infra dependency | Entity imports `@Repository` | Core logic tied to framework |
| Circular dependencies | A → B → C → A | Untestable, fragile |
| God package | `util/` or `common/` growing | Dump for misplaced code |
| Leaky abstractions | Controller knows SQL | Layer boundaries violated |

---

## Package Organization Strategies

### Package-by-Layer (Traditional)

```
com.example.app/
├── controller/
│   ├── UserController.java
│   ├── OrderController.java
│   └── ProductController.java
├── service/
│   ├── UserService.java
│   ├── OrderService.java
│   └── ProductService.java
├── repository/
│   ├── UserRepository.java
│   ├── OrderRepository.java
│   └── ProductRepository.java
└── model/
    ├── User.java
    ├── Order.java
    └── Product.java
```

**Pros**: Familiar, simple for small projects
**Cons**: Scatters related code, doesn't scale, hard to extract modules

### Package-by-Feature (Recommended)

```
com.example.app/
├── user/
│   ├── UserController.java
│   ├── UserService.java
│   ├── UserRepository.java
│   └── User.java
├── order/
│   ├── OrderController.java
│   ├── OrderService.java
│   ├── OrderRepository.java
│   └── Order.java
└── product/
    ├── ProductController.java
    ├── ProductService.java
    ├── ProductRepository.java
    └── Product.java
```

**Pros**: Related code together, easy to extract, clear boundaries
**Cons**: May need shared kernel for cross-cutting concerns

### Hexagonal/Clean Architecture

```
com.example.app/
├── domain/                    # Pure business logic (no framework imports)
│   ├── model/
│   │   └── User.java
│   ├── port/
│   │   ├── in/               # Use cases (driven)
│   │   │   └── CreateUserUseCase.java
│   │   └── out/              # Repositories (driving)
│   │       └── UserRepository.java
│   └── service/
│       └── UserDomainService.java
├── application/               # Use case implementations
│   └── CreateUserService.java
├── adapter/
│   ├── in/
│   │   └── web/
│   │       └── UserController.java
│   └── out/
│       └── persistence/
│           ├── UserJpaRepository.java
│           └── UserEntity.java
└── config/
    └── BeanConfiguration.java
```

**Key rule**: Dependencies point inward (adapters → application → domain)

---

## Dependency Direction Rules

### The Golden Rule

```
┌─────────────────────────────────────────┐
│              Frameworks                 │  ← Outer (volatile)
├─────────────────────────────────────────┤
│           Adapters (Web, DB)            │
├─────────────────────────────────────────┤
│         Application Services            │
├─────────────────────────────────────────┤
│          Domain (Core Logic)            │  ← Inner (stable)
└─────────────────────────────────────────┘

Dependencies MUST point inward only.
Inner layers MUST NOT know about outer layers.
```

### Violations to Flag

```java
// ❌ Domain depends on infrastructure
package com.example.domain.model;

import org.springframework.data.jpa.repository.JpaRepository;  // Framework leak!
import javax.persistence.Entity;  // JPA in domain!

@Entity
public class User {
    // Domain polluted with persistence concerns
}

// ❌ Domain depends on adapter
package com.example.domain.service;

import com.example.adapter.out.persistence.UserJpaRepository;  // Wrong direction!

// ✅ Domain defines port, adapter implements
package com.example.domain.port.out;

public interface UserRepository {  // Pure interface, no JPA
    User findById(UserId id);
    void save(User user);
}
```

---

## Architecture Review Checklist

### 1. Package Structure
- [ ] Clear organization strategy (by-layer, by-feature, or hexagonal)
- [ ] Consistent naming across modules
- [ ] No `util/` or `common/` packages growing unbounded
- [ ] Feature packages are cohesive (related code together)

### 2. Dependency Direction
- [ ] Domain has ZERO framework imports (Spring, JPA, Jackson)
- [ ] Adapters depend on domain, not vice versa
- [ ] No circular dependencies between packages
- [ ] Clear dependency hierarchy

### 3. Layer Boundaries
- [ ] Controllers don't contain business logic
- [ ] Services don't know about HTTP (no HttpServletRequest)
- [ ] Repositories don't leak into controllers
- [ ] DTOs at boundaries, domain objects inside

### 4. Module Boundaries
- [ ] Each module has clear public API
- [ ] Internal classes are package-private
- [ ] Cross-module communication through interfaces
- [ ] No "reaching across" modules for internals

### 5. Scalability Indicators
- [ ] Could extract a feature to separate service? (microservice-ready)
- [ ] Are boundaries enforced or just conventional?
- [ ] Does adding a feature require touching many packages?

### 6. CQRS + Event Sourcing
- [ ] CQRS: Command model clearly separated from query model
- [ ] Event Sourcing: Event store present, aggregate rebuilds from events
- [ ] Projection lag: Query side handles eventual consistency

---

## Common Anti-Patterns

### 1. The Big Ball of Mud

```
src/main/java/com/example/
└── app/
    ├── User.java
    ├── UserController.java
    ├── UserService.java
    ├── UserRepository.java
    ├── Order.java
    ├── OrderController.java
    ├── ... (100+ files in one package)
```

**Fix**: Introduce package structure (start with by-feature)

### 2. The Util Dumping Ground

```
util/
├── StringUtils.java
├── DateUtils.java
├── ValidationUtils.java
├── SecurityUtils.java
├── EmailUtils.java      # Should be in notification module
├── OrderCalculator.java # Should be in order domain
└── UserHelper.java      # Should be in user domain
```

**Fix**: Move domain logic to appropriate modules, keep only truly generic utils

### 3. Anemic Domain Model

```java
// Domain object is just data
public class Order {
    private Long id;
    private List<OrderLine> lines;
    private BigDecimal total;
    // Only getters/setters, no behavior
}

// All logic in "service"
public class OrderService {
    public void addLine(Order order, Product product, int qty) { ... }
    public void calculateTotal(Order order) { ... }
    public void applyDiscount(Order order, Discount discount) { ... }
}
```

**Fix**: Move behavior to domain objects (rich domain model)

### 4. Framework Coupling in Domain

```java
package com.example.domain;

@Entity  // JPA
@Data    // Lombok
@JsonIgnoreProperties(ignoreUnknown = true)  // Jackson
public class User {
    @Id @GeneratedValue
    private Long id;

    @NotBlank  // Validation
    private String email;
}
```

**Fix**: Separate domain model from persistence/API models

### 5. Lazy Event Sourcing

```java
// Events are written but not used for read model rebuild
// Projections fall behind, query side becomes inconsistent
public class OrderService {
    public void placeOrder(Order order) {
        eventStore.save(new OrderPlacedEvent(order));
        // ✅ Event stored
        // ❌ But projections never rebuild from events
        // Query side stale, eventual consistency violated
    }
}
```

**Fix**: Ensure projections process events and rebuild read models

### 6. Silent Projection Failure

```java
// Event processing errors are swallowed
@ApplicationListener
public void handleOrderPlaced(OrderPlacedEvent event) {
    try {
        updateReadModel(event);
    } catch (Exception e) {
        // 💀 Silently ignored! Projection falls out of sync
        log.debug("Failed to update projection");
    }
}
```

**Fix**: Use dead-letter queue, alerting, and retry policies for event processing

---

## Analysis Commands

When reviewing architecture, examine:

```bash
# Package structure overview
find src/main/java -type d | head -30

# Largest packages (potential god packages)
find src/main/java -name "*.java" | xargs dirname | sort | uniq -c | sort -rn | head -10

# Check for framework imports in domain
grep -r "import org.springframework" src/main/java/*/domain/ 2>/dev/null
grep -r "import javax.persistence" src/main/java/*/domain/ 2>/dev/null

# Find circular dependencies (look for bidirectional imports)
# Check if package A imports from B and B imports from A
```

---

## Recommendations Format

When reporting findings:

```markdown
## Architecture Review: [Project Name]

### Structure Assessment
- **Organization**: Package-by-layer / Package-by-feature / Hexagonal
- **Clarity**: Clear / Mixed / Unclear

### Findings

| Severity | Issue | Location | Recommendation |
|----------|-------|----------|----------------|
| High | Domain imports Spring | `domain/model/User.java` | Extract pure domain model |
| Medium | God package | `util/` (23 classes) | Distribute to feature modules |
| Low | Inconsistent naming | `service/` vs `services/` | Standardize to `service/` |

### Dependency Analysis
[Describe dependency flow, violations found]

### Recommendations
1. [Highest priority fix]
2. [Second priority]
3. [Nice to have]
```

---

## Token Optimization

For large codebases:
1. Start with `find` to understand structure
2. Check only domain package for framework imports
3. Sample 2-3 features for pattern analysis
4. Don't read every file - look for patterns

## Architecture Selection Guide

When reviewing a project, verify the chosen architecture matches the problem:

| Indicator | Suggested Architecture | Verify |
|-----------|----------------------|--------|
| Team < 5, single deployable | Monolithic Hexagonal | All code in one repo, but layers respected |
| 10+ services, public API | Microservices + API Gateway | Gateway exists, services independently deployable |
| Heavy async workflows | Event-Driven | No direct service-to-service REST, events via Kafka/RabbitMQ |
| Read-heavy, audit required | CQRS + Event Sourcing | Separate read/write models, event store present. Implement with: `cqrs-event-sourcing` skill. Quarkus stack: Kafka + Panache StoredEvent, Axon Framework |
| Distributed transactions | Saga | Compensating transactions defined, no 2PC |
| Legacy monolith being modernized | Strangler Fig | Proxy/gateway routing traffic to new services |
| High traffic (10K+ req/sec) | Reactive | Non-blocking I/O, reactive streams (Mutiny/WebFlux) |
| Sporadic traffic, cost-sensitive | Serverless | Functions (Lambda) with fast cold start (GraalVM) |

For full architecture catalog and decision matrix, see `software-architectures` skill.

---

## ArchUnit: Executable Architecture Rules

**Weak architecture review:** Prose findings that fade. "This coupling might be risky."
**Strong architecture review:** Executable rules that fail the build. "This ArchUnit test fails on 3 classes."

Turn stable architectural decisions into ArchUnit tests that leave a scar in the build.

### When to Use

- Boundary violations found during architecture review
- Stable rules that should never be broken
- Preventing architectural drift over time
- CI-enforceable architecture documentation

### Common ArchUnit Rules

```java
package com.acme.architecture;

import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.*;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.*;

@AnalyzeClasses(packages = "com.acme")
class ArchitectureTest {

    // Layer rule: Controllers must not access repositories directly
    @ArchTest
    static final ArchRule controllers_do_not_access_repositories =
            noClasses()
                    .that().resideInAPackage("..controller..")
                    .should().accessClassesThat().resideInAPackage("..repository..");

    // Package cycle rule: No cycles between packages
    @ArchTest
    static final ArchRule application_slices_are_cycle_free =
            slices()
                    .matching("com.acme.(*)..")
                    .should().beFreeOfCycles();

    // Dependency direction: Infrastructure depends on domain, not vice versa
    @ArchTest
    static final ArchRule domain_should_not_depend_on_infrastructure =
            noClasses()
                    .that().resideInAPackage("..domain..")
                    .should().accessClassesThat().resideInAPackage("..infrastructure..");

    // Annotation rule: @Entity classes must not be in domain package
    @ArchTest
    static final ArchRule domain_no_persistence_annotations =
            noClasses()
                    .that().resideInAPackage("..domain.model..")
                    .should().beAnnotatedWith("jakarta.persistence.Entity");

    // Hexagonal: Ports are in domain, adapters in infra
    @ArchTest
    static final ArchRule ports_defined_in_domain =
            classes()
                    .that().resideInAPackage("..domain.port..")
                    .should().beInterfaces();
}
```

### Workflow: Review → Rule → Test

1. **Identify confirmed boundary violations** during architecture review
2. **Separate intentional exceptions** (documented, pre-existing) from new violations
3. **Propose ArchUnit rules** only for confirmed, stable boundaries
4. **Write tests in `src/test/java`** following existing test conventions
5. **Run the test** to confirm it captures the violation
6. **Commit the rule** — it now prevents future violations

### Stop Conditions

- **Intentional exceptions already documented** — Don't propose a rule for known exceptions; document them separately
- **Unstable boundaries** — If the architecture is still evolving, defer the rule
- **Framework-specific rules** — Consider Quarkus/Spring-specific ArchUnit extensions if available

### When NOT to Propose Rules

- Boundary violations that are one-off legacy code
- Architectural problems that will be resolved by a planned refactor
- Findings that require architectural redesign (not a simple rule)

## Linked Skills

Use these skills in combination with architecture-review:

- **To select or compare architectures** → Use `software-architectures` for the full 20-architecture catalog and decision matrix
- **To verify design principles** → Use `solid-principles` checklist after identifying issues
- **To review code quality** → Use `java-code-review` on files within identified problem packages
- **To check package dependencies** → Use `design-patterns` for proper decomposition strategies
