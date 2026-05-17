<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: clean-code
description: Clean Code principles (DRY, KISS, YAGNI), naming conventions, function design, and refactoring. Use when user says "clean this code", "refactor", "improve readability", or when reviewing code quality.
---

# Clean Code Skill

Write readable, maintainable code following Clean Code principles.

## When to Use
- User says "clean this code" / "refactor" / "improve readability"
- Code review focusing on maintainability
- Reducing complexity
- Improving naming

---

## Core Principles

| Principle | Meaning | Violation Sign |
|-----------|---------|----------------|
| **DRY** | Don't Repeat Yourself | Copy-pasted code blocks |
| **KISS** | Keep It Simple, Stupid | Over-engineered solutions |
| **YAGNI** | You Aren't Gonna Need It | Features "just in case" |

---

## DRY - Don't Repeat Yourself

> "Every piece of knowledge must have a single, unambiguous representation in the system."

### Violation

```java
// ❌ BAD: Same validation logic repeated
public class UserController {

    public void createUser(UserRequest request) {
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            throw new ValidationException("Email is required");
        }
        if (!request.getEmail().contains("@")) {
            throw new ValidationException("Invalid email format");
        }
        // ... create user
    }

    public void updateUser(UserRequest request) {
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            throw new ValidationException("Email is required");
        }
        if (!request.getEmail().contains("@")) {
            throw new ValidationException("Invalid email format");
        }
        // ... update user
    }
}
```

### Refactored

```java
// ✅ GOOD: Single source of truth
public class EmailValidator {

    public void validate(String email) {
        if (email == null || email.isBlank()) {
            throw new ValidationException("Email is required");
        }
        if (!email.contains("@")) {
            throw new ValidationException("Invalid email format");
        }
    }
}

public class UserController {
    private final EmailValidator emailValidator;

    public void createUser(UserRequest request) {
        emailValidator.validate(request.getEmail());
        // ... create user
    }

    public void updateUser(UserRequest request) {
        emailValidator.validate(request.getEmail());
        // ... update user
    }
}
```

### DRY Exceptions

Not all duplication is bad. Avoid premature abstraction:

```java
// These look similar but serve different purposes - OK to duplicate
public BigDecimal calculateShippingCost(Order order) {
    return order.getWeight().multiply(SHIPPING_RATE);
}

public BigDecimal calculateInsuranceCost(Order order) {
    return order.getValue().multiply(INSURANCE_RATE);
}
// Don't force these into one method - they'll evolve differently
```

---

## KISS - Keep It Simple

> "The simplest solution is usually the best."

### Violation

```java
// ❌ BAD: Over-engineered for simple task
public class StringUtils {

    public boolean isEmpty(String str) {
        return Optional.ofNullable(str)
            .map(String::trim)
            .map(String::isEmpty)
            .orElseGet(() -> Boolean.TRUE);
    }
}
```

### Refactored

```java
// ✅ GOOD: Simple and clear
public class StringUtils {

    public boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }

    // Or use existing library
    // return StringUtils.isBlank(str);  // Apache Commons
    // return str == null || str.isBlank();  // Java 11+
}
```

### KISS Checklist

- Can a junior developer understand this in 30 seconds?
- Is there a simpler way using standard libraries?
- Am I adding complexity for edge cases that may never happen?

---

## YAGNI - You Aren't Gonna Need It

> "Don't add functionality until it's necessary."

### Violation

```java
// ❌ BAD: Building for hypothetical future
public interface Repository<T, ID> {
    T findById(ID id);
    List<T> findAll();
    List<T> findAll(Pageable pageable);
    List<T> findAll(Sort sort);
    List<T> findAllById(Iterable<ID> ids);
    T save(T entity);
    List<T> saveAll(Iterable<T> entities);
    void delete(T entity);
    void deleteById(ID id);
    void deleteAll(Iterable<T> entities);
    void deleteAll();
    boolean existsById(ID id);
    long count();
    // ... 20 more methods "just in case"
}

// Current usage: only findById and save
```

### Refactored

```java
// ✅ GOOD: Only what's needed now
public interface UserRepository {
    Optional<User> findById(Long id);
    User save(User user);
}

// Add methods when actually needed, not before
```

### YAGNI Signs

- "We might need this later"
- "Let's make it configurable just in case"
- "What if we need to support X in the future?"
- Abstract classes with one implementation

---

## Naming Conventions

### Variables

```java
// ❌ BAD
int d;                  // What is d?
String s;               // Meaningless
List<User> list;        // What kind of list?
Map<String, Object> m;  // What does it map?

// ✅ GOOD
int elapsedTimeInDays;
String customerName;
List<User> activeUsers;
Map<String, Object> sessionAttributes;
```

### Booleans

```java
// ❌ BAD
boolean flag;
boolean status;
boolean check;

// ✅ GOOD - Use is/has/can/should prefix
boolean isActive;
boolean hasPermission;
boolean canEdit;
boolean shouldNotify;
```

### Methods

```java
// ❌ BAD
void process();           // Process what?
void handle();            // Handle what?
void doIt();              // Do what?
User get();               // Get from where?

// ✅ GOOD - Verb + noun, descriptive
void processPayment();
void handleLoginRequest();
void sendWelcomeEmail();
User findByEmail(String email);
List<Order> fetchPendingOrders();
```

### Classes

```java
// ❌ BAD
class Data { }           // Too vague
class Info { }           // Too vague
class Manager { }        // Often a god class
class Helper { }         // Often a dumping ground
class Utils { }          // Static method dumping ground

// ✅ GOOD - Noun, specific responsibility
class User { }
class OrderProcessor { }
class EmailValidator { }
class PaymentGateway { }
class ShippingCalculator { }
```

### Naming Best Practices

**Use intention-revealing names** — the name should explain itself before looking at the implementation:

```java
// ❌ BAD: Must read implementation to understand
int d;                  // elapsed time in days?
List<User> list;        // active users? deleted users?

// ✅ GOOD: Intention is clear from the name
int elapsedTimeInDays;
List<User> activeUsers;
```

**Pick one word per concept** — consistency across the codebase:

```java
// ❌ BAD: Multiple words for same concept
fetchUser();     // in one module
getUser();       // in another
retrieveUser();  // in a third

// ✅ GOOD: One word, used everywhere
getUser();       // Choose one, use it consistently
```

**Use computer science terms when appropriate** — programmers understand patterns:

```java
// ✅ GOOD: CS term signals intent
AccountAdapter        // Adapter pattern
UserFactory           // Factory pattern
OrderVisitor          // Visitor pattern
PaymentStrategy       // Strategy pattern
```

**Use pronounceable, searchable names** — easy to discuss and find:

```java
// ❌ BAD: Hard to search, hard to pronounce
String yyyymmdstr;    // What is this? How do you say it?

// ✅ GOOD: Clear and searchable
String formattedDate; // Easy to find, easy to say
```

### Naming Conventions Table

| Element | Convention | Example |
|---------|------------|---------|
| Class | PascalCase, noun | `OrderService` |
| Interface | PascalCase, adjective or noun | `Comparable`, `List` |
| Method | camelCase, verb | `calculateTotal()` |
| Variable | camelCase, noun | `customerEmail` |
| Constant | UPPER_SNAKE | `MAX_RETRY_COUNT` |
| Package | lowercase | `com.example.orders` |

---

## Functions / Methods

### Keep Functions Small

```java
// ❌ BAD: 50+ line method doing multiple things
public void processOrder(Order order) {
    // validate order (10 lines)
    // calculate totals (15 lines)
    // apply discounts (10 lines)
    // update inventory (10 lines)
    // send notifications (10 lines)
    // ... and more
}

// ✅ GOOD: Small, focused methods
public void processOrder(Order order) {
    validateOrder(order);
    calculateTotals(order);
    applyDiscounts(order);
    updateInventory(order);
    sendNotifications(order);
}
```

### Single Level of Abstraction

```java
// ❌ BAD: Mixed abstraction levels
public void processOrder(Order order) {
    validateOrder(order);  // High level

    // Low level mixed in
    BigDecimal total = BigDecimal.ZERO;
    for (OrderItem item : order.getItems()) {
        total = total.add(item.getPrice().multiply(
            BigDecimal.valueOf(item.getQuantity())));
    }

    sendEmail(order);  // High level again
}

// ✅ GOOD: Consistent abstraction level
public void processOrder(Order order) {
    validateOrder(order);
    calculateTotal(order);
    sendConfirmation(order);
}

private BigDecimal calculateTotal(Order order) {
    return order.getItems().stream()
        .map(item -> item.getPrice().multiply(
            BigDecimal.valueOf(item.getQuantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
}
```

### Do One Thing

A function should do one thing, and do it well. If you can extract another function from it, it does more than one thing.

```java
// ❌ BAD: Mixing validation, calculation, persistence, notification
public void processOrder(Order order) {
    if (order == null || !order.isValid()) {
        throw new IllegalArgumentException("Invalid order");
    }
    BigDecimal total = BigDecimal.ZERO;
    for (OrderItem item : order.getItems()) {
        total = total.add(item.getPrice().multiply(
            BigDecimal.valueOf(item.getQuantity())));
    }
    order.setTotal(total);
    orderRepository.save(order);
    emailService.sendConfirmation(order.getCustomerEmail(), order);
    auditLog.log("Order processed: " + order.getId());
}

// ✅ GOOD: Each function does one thing, orchestrated at top level
public void processOrder(Order order) {
    validateOrder(order);
    calculateTotal(order);
    persistOrder(order);
    notifyCustomer(order);
    auditOrderProcessed(order);
}
```

### Have No Side Effects

A function should not modify hidden state or produce unexpected effects:

```java
// ❌ BAD: Hidden side effect — changes global state unexpectedly
public boolean checkSession(String sessionId) {
    Session session = sessionStore.find(sessionId);
    if (session != null && session.isExpired()) {
        sessionStore.delete(sessionId);  // Side effect! Caller doesn't expect this
        return false;
    }
    return session != null;
}

// ✅ GOOD: No side effects, or name reveals the effect
public boolean isSessionValid(String sessionId) {
    Session session = sessionStore.find(sessionId);
    return session != null && !session.isExpired();
}

// If you must delete, make it explicit:
public boolean checkAndInvalidateSession(String sessionId) { ... }
```

### No Duplication

Centralize frequently used code in one place:

```java
// ❌ BAD: Same validation in multiple places
public void createUser(UserRequest req) {
    if (req.getEmail() == null || !req.getEmail().contains("@")) {
        throw new ValidationException("Invalid email");
    }
    // ...
}

public void updateUser(UserRequest req) {
    if (req.getEmail() == null || !req.getEmail().contains("@")) {
        throw new ValidationException("Invalid email");
    }
    // ...
}

// ✅ GOOD: Single source of truth
public class EmailValidator {
    public void validate(String email) {
        if (email == null || !email.contains("@")) {
            throw new ValidationException("Invalid email");
        }
    }
}
```

### Limit Parameters

```java
// ❌ BAD: Too many parameters
public User createUser(String firstName, String lastName,
                       String email, String phone,
                       String address, String city,
                       String country, String zipCode) {
    // ...
}

// ✅ GOOD: Use parameter object
public User createUser(CreateUserRequest request) {
    // ...
}

// Or builder
public User createUser(UserBuilder builder) {
    // ...
}
```

### Avoid Flag Arguments

```java
// ❌ BAD: Boolean flag changes behavior
public void sendMessage(String message, boolean isUrgent) {
    if (isUrgent) {
        // send immediately
    } else {
        // queue for later
    }
}

// ✅ GOOD: Separate methods
public void sendUrgentMessage(String message) {
    // send immediately
}

public void queueMessage(String message) {
    // queue for later
}
```

---

## Comments

### Avoid Obvious Comments

```java
// ❌ BAD: Noise comments
// Set the user's name
user.setName(name);

// Increment counter
counter++;

// Check if user is null
if (user != null) {
    // ...
}
```

### Good Comments vs Bad Comments

**Good Comments:**

```java
// ✅ Legal comments — copyright, licenses
// ✅ Informative comments — clarify intent
// TODO: Replace with Redis cache after infrastructure upgrade (Q2 2026)
// WARNING: Order matters! Discounts must be applied before tax calculation
applyDiscounts(order);
calculateTax(order);

// ✅ Explain WHY, not WHAT
// Retry with exponential backoff to avoid overwhelming the server
// during high load periods (see incident #1234)
for (int attempt = 0; attempt < MAX_RETRIES; attempt++) {
    Thread.sleep((long) Math.pow(2, attempt) * 1000);
    // ...
}
```

**Bad Comments:**

```java
// ❌ Mumbling — unclear what the author meant
// We need to do this because of the thing
processThing();

// ❌ Redundant — states the obvious
// Increment counter
counter++;

// ❌ Misleading — comment doesn't match code
// Always returns true
public boolean isValid() { return false; }

// ❌ Mandated comments — required by policy, adds noise
/**
 * The name.
 */
private String name;

// ❌ Journal comments — version history belongs in git
// 2024-01-15: Added validation
// 2024-03-22: Fixed null pointer
// 2024-06-01: Refactored by John
public void process() { ... }

// ❌ Noise comments — restates what code already says
// Check if user is not null
if (user != null) { ... }
```

**Rule:** Don't give too much info. Comments should be precise and short. Avoid obvious comments.

### Let Code Speak

```java
// ❌ BAD: Comment explaining bad code
// Check if the user is an admin or has special permission
// and the action is allowed for their role
if ((user.getRole() == 1 || user.getRole() == 2) &&
    (action == 3 || action == 4 || action == 7)) {
    // ...
}

// ✅ GOOD: Self-documenting code
if (user.hasAdminPrivileges() && action.isAllowedFor(user.getRole())) {
    // ...
}
```

---

## Unit Tests

Tests are as important as production code. Keep them clean.

### Laws of TDD

1. **You are not allowed to write production code until you have written a failing unit test.**
2. **You are not allowed to write more of a unit test than is sufficient to fail.**
3. **You are not allowed to write more production code than is sufficient to pass the currently failing test.**

### F.I.R.S.T. Principles

| Letter | Principle | Meaning |
|--------|-----------|---------|
| **F** | Fast | Tests should run quickly (milliseconds) |
| **I** | Independent | No test should depend on another |
| **R** | Repeatable | Same result every time, any environment |
| **S** | Self-Validating | Pass/fail with boolean output, no manual checking |
| **T** | Timely | Write tests before or with production code |

### Clean Test Guidelines

```java
// ❌ BAD: Multiple asserts, unclear what failed
@Test
public void testUser() {
    User user = service.createUser("John", "john@example.com");
    assertNotNull(user);
    assertEquals("John", user.getName());
    assertEquals("john@example.com", user.getEmail());
    assertTrue(user.getId() > 0);
    assertNotNull(user.getCreatedAt());
}

// ✅ GOOD: One concept per test, descriptive name
@Test
public void createUser_savesUserWithGeneratedId() {
    User user = service.createUser("John", "john@example.com");
    assertThat(user.getId()).isPositive();
}

@Test
public void createUser_setsCreatedAtTimestamp() {
    User user = service.createUser("John", "john@example.com");
    assertThat(user.getCreatedAt()).isNotNull();
}
```

---

## Error Handling

Use exceptions, not return codes or null. Provide context.

```java
// ❌ BAD: Return null, force caller to check
public User findUser(Long id) {
    // ...
    return null;  // Caller must check for null
}

// Caller must handle null
User user = findUser(id);
if (user != null) {
    user.activate();
}

// ❌ BAD: Return error flags
public int withdraw(int amount) {
    if (amount > balance) return -1;  // What does -1 mean?
    // ...
    return 0;
}

// ✅ GOOD: Throw exceptions with context
public User findUser(Long id) {
    return repository.findById(id)
        .orElseThrow(() -> new UserNotFoundException("User not found: " + id));
}

// ✅ GOOD: Custom exceptions with meaningful names
public void withdraw(Money amount) {
    if (amount.isGreaterThan(balance)) {
        throw new InsufficientFundsException(
            "Cannot withdraw " + amount + ", balance is " + balance);
    }
    // ...
}

// Don't return null, don't pass null
public List<Order> findOrdersByUser(UserId userId) {
    if (userId == null) {
        throw new IllegalArgumentException("userId must not be null");
    }
    // ...
}
```

---

## Common Code Smells

| Smell | Description | Refactoring |
|-------|-------------|-------------|
| **Long Method** | Method > 20 lines | Extract Method |
| **Long Parameter List** | > 3 parameters | Parameter Object |
| **Duplicate Code** | Same code in multiple places | Extract Method/Class |
| **Dead Code** | Unused code | Delete it |
| **Magic Numbers** | Unexplained literals | Named Constants |
| **God Class** | Class doing too much | Extract Class |
| **Feature Envy** | Method uses another class's data | Move Method |
| **Primitive Obsession** | Primitives instead of objects | Value Objects |

### Magic Numbers

```java
// ❌ BAD
if (user.getAge() >= 18) { }
if (order.getTotal() > 100) { }
Thread.sleep(86400000);

// ✅ GOOD
private static final int ADULT_AGE = 18;
private static final BigDecimal FREE_SHIPPING_THRESHOLD = new BigDecimal("100");
private static final long ONE_DAY_MS = TimeUnit.DAYS.toMillis(1);

if (user.getAge() >= ADULT_AGE) { }
if (order.getTotal().compareTo(FREE_SHIPPING_THRESHOLD) > 0) { }
Thread.sleep(ONE_DAY_MS);
```

### Primitive Obsession

```java
// ❌ BAD: Primitives everywhere
public void createUser(String email, String phone, String zipCode) {
    // No validation, easy to mix up parameters
}

createUser("12345", "john@email.com", "555-1234");  // Wrong order, compiles!

// ✅ GOOD: Value objects
public record Email(String value) {
    public Email {
        if (!value.contains("@")) {
            throw new IllegalArgumentException("Invalid email");
        }
    }
}

public record PhoneNumber(String value) {
    // validation
}

public void createUser(Email email, PhoneNumber phone, ZipCode zipCode) {
    // Type-safe, self-validating
}
```

---

## Refactoring Quick Reference

| From | To | Technique |
|------|-----|-----------|
| Long method | Short methods | Extract Method |
| Duplicate code | Single method | Extract Method |
| Complex conditional | Polymorphism | Replace Conditional with Polymorphism |
| Many parameters | Object | Introduce Parameter Object |
| Temp variables | Query method | Replace Temp with Query |
| Comments explaining code | Self-documenting code | Rename, Extract |
| Nested conditionals | Early return | Guard Clauses |

### Guard Clauses

```java
// ❌ BAD: Deeply nested
public void processOrder(Order order) {
    if (order != null) {
        if (order.isValid()) {
            if (order.hasItems()) {
                // actual logic buried here
            }
        }
    }
}

// ✅ GOOD: Guard clauses
public void processOrder(Order order) {
    if (order == null) return;
    if (!order.isValid()) return;
    if (!order.hasItems()) return;

    // actual logic at top level
}
```

---

## Clean Code Checklist

When reviewing code, check:

- [ ] Are names meaningful and pronounceable?
- [ ] Are functions small and focused?
- [ ] Is there any duplicated code?
- [ ] Are there magic numbers or strings?
- [ ] Are comments explaining "why" not "what"?
- [ ] Is the code at consistent abstraction level?
- [ ] Can any code be simplified?
- [ ] Is there dead/unused code?

---

## Related Skills

- `solid-principles` - Design principles for class structure
- `design-patterns` - Common solutions to recurring problems
- `java-code-review` - Comprehensive review checklist
