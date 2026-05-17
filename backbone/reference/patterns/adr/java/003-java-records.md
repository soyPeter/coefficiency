# Java Records over Lombok

## Status

Accepted

## Context and Problem Statement

The project needs a consistent approach for data modeling across entities, DTOs, and value objects. We need to choose between using Lombok annotations or Java Records for reducing boilerplate while maintaining:
- Immutability guarantees
- Clear, readable code
- Type safety
- Framework compatibility

## Decision Drivers

* **Immutability**: All data carriers should be immutable by default
* **Reduced boilerplate**: Avoid manual equals/hashCode/toString
* **Language-native**: Prefer standard Java features over external libraries
* **Validation**: Need constructor-level validation for data integrity
* **JDBI compatibility**: Must work seamlessly with JDBI mapping

## Considered Options

* **Java Records** - Built-in language feature since Java 16, immutable by design
* **Lombok** - Annotation processor generating boilerplate at compile time
* **Manual implementation** - Hand-written getters, equals, hashCode, toString

## Decision Outcome

Chosen option: **Java Records**, because they provide immutability by default, are a standard language feature, and offer compact constructor validation.

### Implementation Pattern

```java
// Domain Entity as Record
public record Customer(
    String id,
    String email,
    String firstName,
    String lastName,
    CustomerStatus status
) {
    // Compact constructor for validation
    public Customer {
        requireNonNull(id, "ID cannot be null");
        requireNonNull(email, "Email cannot be null");
    }

    // Factory method for creation
    public static Customer create(String email, String firstName, String lastName) {
        return new Customer(
            TSID.Factory.getTsid().toString(),
            email,
            firstName,
            lastName,
            CustomerStatus.ACTIVE
        );
    }

    // Business method returns new instance (functional approach)
    public Customer deactivate() {
        return new Customer(id, email, firstName, lastName, CustomerStatus.INACTIVE);
    }
}
```

### Usage Patterns

**DTOs:**
```java
public record CreateCustomerReq(
    @NotBlank String email,
    @NotBlank String firstName,
    @NotBlank String lastName
) {}

public record CustomerRes(
    String id,
    String email,
    String firstName,
    String lastName,
    String status
) {
    public static CustomerRes from(Customer customer) {
        return new CustomerRes(
            customer.id(),
            customer.email(),
            customer.firstName(),
            customer.lastName(),
            customer.status().name()
        );
    }
}
```

**Value Objects:**
```java
public record Email(String value) {
    public Email {
        requireNonNull(value, "Email cannot be null");
        if (!value.matches("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$")) {
            throw new IllegalArgumentException("Invalid email format");
        }
    }
}
```

### Consequences

**Good:**
* Immutability enforced by language - no accidental mutation
* Automatically provides equals(), hashCode(), toString()
* Compact constructors enable validation at instantiation
* Standard Java feature - no external dependencies
* Works well with serialization (Jackson) and persistence (JDBI)
* Thread-safe by design

**Bad:**
* Records cannot extend other classes (only implement interfaces)
* No inheritance hierarchy for entities
* If mutable state is needed, must use traditional classes
* Slightly verbose for entities with many optional fields

### Framework Compatibility

**Jackson serialization:**
```java
// Works automatically - no configuration needed
ObjectMapper mapper = new ObjectMapper();
String json = mapper.writeValueAsString(customer);
Customer customer = mapper.readValue(json, Customer.class);
```

**JDBI mapping:**
```java
// Use @RegisterConstructorMapper with Row records
@RegisterConstructorMapper(CustomerRow.class)
public interface CustomerSqlQueryRepo { ... }
```

**Bean validation:**
```java
// Works with Jakarta Validation annotations
public record CreateCustomerReq(
    @NotBlank @Email String email
) {}
```

## References

* `services/{service}/src/main/java/.../domain/model/` - Domain entities and VOs
* `services/{service}/src/main/java/.../infra/data/dto/` - DTOs
* `services/{service}/src/main/java/.../infra/io/rest/req/` and `res/` - API DTOs
