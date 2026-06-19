# Entity Immutability and AuditFields Composition Pattern

## Status

Accepted and Implemented

## Context and Problem Statement

The project had mutable domain entities extending `AuditableEntity` base class for audit trail support (createdBy, updatedBy, deleted, deletedAt, deletedBy). This violated immutability principles from ADR-0003 (Java Records over Lombok) and created several issues:

- **Mutable base class anti-pattern**: Inheritance hierarchy violates composition-over-inheritance principle
- **State leakage**: Mutable entities could be accidentally modified after creation
- **Inconsistent immutability**: Records are immutable, but inherited audit behavior was mutable
- **Tight coupling**: All entities forced to inherit specific audit fields and behavior
- **Testing difficulty**: Mutable entities harder to reason about in tests (identity vs equality)
- **Database layer concerns in domain**: Soft delete logic mixed with business entities

## Decision Drivers

* **Immutability principle**: All domain entities should be immutable records
* **Composition over inheritance**: Reusable audit fields without inheritance hierarchy
* **Framework independence**: Domain layer should not depend on framework concerns
* **DDD compliance**: Entities and Value Objects must be self-contained
* **Backward compatibility**: Existing code should continue working during migration
* **Testing clarity**: Immutable entities enable simpler, clearer test assertions

## Considered Options

### Option 1: Keep Mutable `AuditableEntity` Base Class
- ❌ Violates immutability principles
- ❌ Maintains inheritance anti-pattern
- ❌ Contradicts ADR-0003 (Records over Lombok)

### Option 2: Use Immutable `AuditFields` Record + Composition ⭐ CHOSEN
- ✅ Entities are true records (immutable)
- ✅ Reusable composition without inheritance
- ✅ Framework-agnostic domain layer
- ✅ Supports soft delete via composition
- ⚠️ Requires updating all entities and use cases

### Option 3: Hybrid Approach (Both Base Class and Composition)
- ⚠️ Maintains technical debt
- ⚠️ Double maintenance burden
- ❌ Inconsistent architecture

## Decision Outcome

Chosen option: **Option 2 - Immutable `AuditFields` Record + Composition**

Replace the mutable `AuditableEntity` base class with a composed immutable `AuditFields` record.

### Implementation Pattern

#### 1. Create Immutable `AuditFields` Record

```java
package es.myinvestor.shared.domain.model;

import java.time.Instant;
import java.util.Objects;

/**
 * Immutable audit information composed into domain entities.
 *
 * <p>Replaces the mutable AuditableEntity base class.
 * Use composition in records instead of inheritance.
 */
public record AuditFields(
    String createdBy,
    Instant createdAt,
    String updatedBy,
    Instant updatedAt,
    boolean deleted,
    Instant deletedAt,
    String deletedBy
) {

  public AuditFields {
    Objects.requireNonNull(createdAt, "createdAt cannot be null");
  }

  // Factory for new entities (created now, not yet deleted)
  public static AuditFields fresh(String createdBy) {
    return new AuditFields(
        createdBy,
        Instant.now(),
        null,
        null,
        false,
        null,
        null
    );
  }

  // Mark as deleted (returns new instance)
  public AuditFields markDeleted(String deletedBy) {
    return new AuditFields(createdBy, createdAt, updatedBy, updatedAt, true, Instant.now(), deletedBy);
  }

  // Mark as updated (returns new instance)
  public AuditFields markUpdated(String updatedBy) {
    return new AuditFields(createdBy, createdAt, updatedBy, Instant.now(), deleted, deletedAt, deletedBy);
  }

  // Restore deleted entity (returns new instance)
  public AuditFields restore() {
    return new AuditFields(createdBy, createdAt, updatedBy, updatedAt, false, null, null);
  }

  public boolean isDeleted() {
    return deleted;
  }
}
```

#### 2. Entity Records with Composed AuditFields

**Before (Mutable base class):**
```java
@Getter
@Setter
public class Customer extends AuditableEntity {
    private String id;
    private String email;
    // ... fields
    
    public void setEmail(String email) {
        this.email = email;  // ❌ Mutation!
    }
}
```

**After (Immutable record with composition):**
```java
public record Customer(
    String id,
    String email,
    String firstName,
    String lastName,
    AuditFields audit
) {
    public Customer {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(email, "email must not be null");
        Objects.requireNonNull(audit, "audit must not be null");
    }

    // Functional update returns new instance (never mutates)
    public Customer withEmail(String newEmail) {
        return new Customer(id, newEmail, firstName, lastName, audit.markUpdated(null));
    }

    // Soft delete returns new instance
    public Customer markAsDeleted(String deletedBy) {
        return new Customer(id, email, firstName, lastName, audit.markDeleted(deletedBy));
    }

    // Restore deleted customer
    public Customer restore() {
        return new Customer(id, email, firstName, lastName, audit.restore());
    }

    // Backward-compatible getters for migration
    public String getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public boolean isDeleted() {
        return audit.isDeleted();
    }

    public String getCreatedBy() {
        return audit.createdBy();
    }

    public Instant getCreatedAt() {
        return audit.createdAt();
    }

    public String getUpdatedBy() {
        return audit.updatedBy();
    }

    public Instant getUpdatedAt() {
        return audit.updatedAt();
    }

    // ... other backward-compatible getters
}
```

#### 3. Use Case Pattern: Functional Updates

**Before (Mutable approach):**
```java
@Named
@Transactional
public class UpdateCustomerUseCase {
    public void execute(String id, String newEmail) {
        Customer customer = repo.findById(id).orElseThrow();
        customer.setEmail(newEmail);  // ❌ Mutates object
        customer.setUpdatedBy("user-123");  // ❌ Mutates object
        repo.save(customer);
    }
}
```

**After (Immutable approach):**
```java
@Named
@Transactional("commandTransactionManager")
@PublishEvents(exchange = "customer.events", routingKey = "customer.updated")
public class UpdateCustomerUseCase {

    private final CustomerCommandRepository repo;
    
    public UpdateCustomerUseCase(CustomerCommandRepository repo) {
        this.repo = repo;
    }

    public Customer execute(String id, String newEmail, String userId) {
        Customer customer = repo.findById(id)
            .orElseThrow(() -> new CustomerNotFound(id));

        // Always assign result of update method
        customer = customer.withEmail(newEmail);
        customer = customer.withUpdatedBy(userId);

        // Save immutable instance
        repo.save(customer);

        // Record domain event for Outbox Pattern
        DomainEventRecorder.record(new CustomerEmailUpdatedEvent(id, newEmail));

        return customer;
    }
}
```

#### 4. JDBI Row Mapping with Composition

**Row record for SQL mapping:**
```java
package es.myinvestor.customer.infra.data.persistence.sql;

import es.myinvestor.shared.domain.model.AuditFields;
import org.jdbi.v3.core.mapper.reflect.ColumnName;
import java.time.Instant;

public record CustomerRow(
    @ColumnName("id") String id,
    @ColumnName("email") String email,
    @ColumnName("first_name") String firstName,
    @ColumnName("last_name") String lastName,
    @ColumnName("created_by") String createdBy,
    @ColumnName("created_at") Instant createdAt,
    @ColumnName("updated_by") String updatedBy,
    @ColumnName("updated_at") Instant updatedAt,
    @ColumnName("deleted") boolean deleted,
    @ColumnName("deleted_at") Instant deletedAt,
    @ColumnName("deleted_by") String deletedBy
) {
    // Convert from DB row to domain entity
    public Customer toDomain() {
        AuditFields audit = new AuditFields(
            createdBy,
            createdAt,
            updatedBy,
            updatedAt,
            deleted,
            deletedAt,
            deletedBy
        );
        return new Customer(id, email, firstName, lastName, audit);
    }
}
```

**Repository using the row mapper:**
```java
@RegisterConstructorMapper(CustomerRow.class)
public interface CustomerSqlCommandRepo extends CustomerCommandRepo {

    @SqlUpdate("""
        INSERT INTO customers (id, email, first_name, last_name, 
                               created_by, created_at, deleted)
        VALUES (:id, :email, :firstName, :lastName, :createdBy, :createdAt, :deleted)
    """)
    void save(@BindBean Customer customer);

    @SqlQuery("SELECT * FROM customers WHERE id = :id AND deleted = false")
    Optional<CustomerRow> findByIdInternal(@Bind("id") String id);

    // Default method converts row to domain entity
    @Override
    default Optional<Customer> findById(String id) {
        return findByIdInternal(id).map(CustomerRow::toDomain);
    }
}
```

#### 5. Testing with Immutable Entities

**Cleaner test assertions:**
```java
@Test
void shouldUpdateCustomerEmail() {
    // Arrange
    Customer original = new Customer(
        "cust-123",
        "old@example.com",
        "John",
        "Doe",
        AuditFields.fresh("admin")
    );

    // Act
    Customer updated = original.withEmail("new@example.com");

    // Assert (no mutation - original unchanged)
    assertThat(updated.email()).isEqualTo("new@example.com");
    assertThat(original.email()).isEqualTo("old@example.com");  // Unchanged!
    
    assertThat(updated.audit().updatedBy()).isEqualTo("admin");
    assertThat(updated.isDeleted()).isFalse();
}

@Test
void shouldDeleteAndRestore() {
    // Arrange
    Customer customer = new Customer(
        "cust-123",
        "user@example.com",
        "John",
        "Doe",
        AuditFields.fresh("admin")
    );

    // Act
    Customer deleted = customer.markAsDeleted("admin");
    Customer restored = deleted.restore();

    // Assert
    assertThat(deleted.isDeleted()).isTrue();
    assertThat(deleted.audit().deletedAt()).isNotNull();
    assertThat(restored.isDeleted()).isFalse();
    assertThat(restored.audit().deletedAt()).isNull();
}
```

### Consequences

#### Good ✅
* **True immutability**: Entities are records, cannot be mutated after creation
* **Composition over inheritance**: No deep class hierarchies
* **Testability**: Immutable objects are easier to test and reason about
* **Thread safety**: Immutable objects are inherently thread-safe
* **Value semantics**: Records provide correct equals/hashCode based on values
* **Functional approach**: Methods return new instances, encouraging pure functions
* **Framework independence**: Domain layer has zero framework dependencies
* **Reusability**: `AuditFields` can be composed into any entity
* **Backward compatibility**: Getter methods support migration path

#### Bad ⚠️
* **Allocation overhead**: Functional updates create new objects (minor impact, worth trade-off)
* **Verbosity**: Update methods need explicit assignment patterns
* **All-or-nothing**: If you need one field updated, you reconstruct entire entity
* **Developer mindset shift**: Requires functional thinking, not imperative mutation
* **Testing migration burden**: Existing mutable tests need rewriting

### Migration Path

1. **Phase 1: Create `AuditFields` record** (Done)
   - Define immutable audit composition
   - Keep `AuditableEntity` deprecated

2. **Phase 2: Convert high-value entities** (Done)
   - Customer, User, Signup, Referral entities
   - Add backward-compatible getters
   - Update use cases to assign results

3. **Phase 3: Update tests** (Done)
   - Fix test assertions for immutable objects
   - Use `any(Entity.class)` for mock verification
   - Verify immutability in new tests

4. **Phase 4: Remove deprecated base class** (Done)
   - Delete `AuditableEntity` from codebase
   - Verify no remaining references

5. **Phase 5: Documentation & standards** (This ADR)
   - Document pattern in AGENTS.md
   - Create migration guide for future entities
   - Add code examples to guidelines

### Entity Conversion Checklist

When converting an entity from mutable to immutable:

- [ ] Make entity a `record` (not a class)
- [ ] Add `AuditFields audit` as last field
- [ ] Add validation in compact constructor
- [ ] Create functional update methods (`withField()`)
- [ ] Add `markAsDeleted()` and `restore()` methods
- [ ] Add backward-compatible getters (for migration)
- [ ] Update all use cases to **assign results**: `entity = entity.withField(value)`
- [ ] Create or update `*Row` record with `toDomain()` method
- [ ] Update repository to return domain entities, not rows
- [ ] Fix tests to handle immutability: `any(Entity.class)` in mocks
- [ ] Remove any remaining mutations from use cases

### Example: Complete Entity Conversion

See these files for working implementations:

**Immutable Records:**
- `services/customer/src/main/java/.../domain/model/vo/Customer.java`
- `services/customer/src/main/java/.../domain/model/vo/User.java`
- `services/signup/src/main/java/.../domain/model/vo/Signup.java`
- `services/referral/src/main/java/.../domain/model/vo/Referral.java`

**Row Records with `toDomain()`:**
- `services/customer/src/main/java/.../infra/data/persistence/sql/CustomerRowJdbi.java`
- `services/signup/src/main/java/.../infra/data/persistence/sql/SignupRow.java`

**Updated Use Cases:**
- `services/customer/src/main/java/.../app/CreateCustomerUseCase.java`
- `services/signup/src/main/java/.../app/VerifyEmailUseCase.java`

**Fixed Tests:**
- `services/customer/src/test/java/.../app/CreateCustomerUseCaseTest.java`
- `services/signup/src/test/java/.../app/CompleteSignupUseCaseTest.java`

## References

- **ADR-0003**: [Java Records over Lombok](./003-java-records.md) - Foundation for immutability
- **ADR-0001**: [Hexagonal Architecture](./001-hexagonal-architecture.md) - Domain layer independence
- **ADR-0008**: [JSR-330 Framework Independence](./008-jsr330.md) - Framework-agnostic design
- **Project Guidelines**: `documentation/developer/GUIDELINES.md` - DDD principles
- **Entity Pattern**: `documentation/developer/CREATE_NEW_SERVICE.md` Step 1.1 - Domain modeling

## Status Timeline

- **Proposed**: 2026-03-17
- **Accepted**: 2026-03-17
- **Implemented**: 2026-03-17 (All entities converted, tests updated, base class removed)
- **Supersedes**: AuditableEntity inheritance pattern

---

## Appendix: Common Questions

### Q: Won't object creation overhead hurt performance?

**A:** No, for three reasons:
1. Record creation is optimized by JVM (allocation is cheap)
2. Immutability enables more compiler/runtime optimizations
3. Garbage collection is more efficient with many short-lived objects
4. For most operations, the performance benefit from immutability outweighs allocation cost

Measure if you're concerned: Most business applications spend <5% CPU on object allocation.

### Q: How do I handle large entities with many fields?

**A:** Use builder patterns for construction, but the record itself stays immutable:

```java
public record LargeEntity(
    String id,
    String field1,
    String field2,
    // ... 20 more fields
    AuditFields audit
) {
    public static Builder builder() {
        return new Builder();
    }
    
    public static class Builder {
        private String id;
        private String field1;
        // ... builder methods
        
        public LargeEntity build() {
            return new LargeEntity(id, field1, /* ... */, audit);
        }
    }
}
```

### Q: Can I do lazy initialization with immutable entities?

**A:** Use helper methods instead of lazy fields:

```java
public record Customer(String id, String email, AuditFields audit) {
    // Lazy computation (not lazy field)
    public Optional<String> getDomain() {
        return Optional.of(email)
            .map(e -> e.split("@")[1]);
    }
}
```

### Q: What about entities with optional fields?

**A:** Use `Optional<T>` or nullable fields (null is valid for optional data):

```java
public record Customer(
    String id,
    String email,
    String firstName,
    Optional<String> middleName,  // Optional field
    String lastName,
    AuditFields audit
) {}
```
