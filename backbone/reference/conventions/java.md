# Java Conventions

*Java-specific patterns and best practices. For base principles, see `conventions-general.md`.*

---

## Architecture: Hexagonal (Ports & Adapters)

```
src/main/java/io/bitnomio/<service>/
├── domain/          # Pure business logic, ZERO framework imports
│   ├── model/      # Domain models (records, enums)
│   ├── actions/    # Domain actions/commands
│   └── events/     # Domain events
├── app/            # Application layer (use cases)
│   └── <Entity>UseCase.java
└── infra/          # Infrastructure adapters
    ├── config/     # Configuration classes
    ├── data/       # Data access (DTOs, persistence)
    └── io/         # Input/output (REST, events)
```

### Layer Dependencies (单向)
```
domain → app → infra
domain → infra (via ports)
```
Domain must be framework-free. See `quarkus-conventions.md` or `springboot-conventions.md`.

---

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Packages | lowercase | `io.bitnomio.users` |
| Classes | PascalCase | `UserService`, `OrderRepository` |
| Interfaces | PascalCase + Optional suffix | `UserRepository`, `OrderService` |
| Methods | camelCase | `findById()`, `calculateTotal()` |
| Variables | camelCase | `userName`, `orderTotal` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Records | PascalCase | `User`, `OrderItem` |
| Enums | PascalCase | `OrderStatus`, `UserRole` |

---

## SOLID Principles

### S - Single Responsibility
A class should have only one reason to change.

```java
// BAD - Two responsibilities
class UserManager {
    saveUser(User user) { /* ... */ }
    generateReport(User user) { /* ... */ }
}

// GOOD - Separated
class UserRepository {
    save(User user) { /* ... */ }
}
class UserReport {
    generate(User user) { /* ... */ }
}
```

### O - Open/Closed
Open for extension, closed for modification.

```java
// BAD - Need to modify to add new shapes
class AreaCalculator {
    calculateArea(Shape shape) {
        if (shape instanceof Circle) { /* ... */ }
        else if (shape instanceof Square) { /* ... */ }
    }
}

// GOOD - Extend without modification
interface Shape {
    double calculateArea();
}
class Circle implements Shape {
    double calculateArea() { return Math.PI * r * r; }
}
```

### L - Liskov Substitution
Subclasses should be replaceable for their base classes.

```java
// BAD - Penguin breaks the contract
class Bird {
    void fly() { /* ... */ }
}
class Penguin extends Bird {
    @Override
    void fly() { 
        throw new UnsupportedOperationException(); // Breaks LSP!
    }
}

// GOOD - Proper hierarchy
interface Flyable {
    void fly();
}
class Bird implements Flyable {
    void fly() { /* ... */ }
}
// Penguin doesn't implement Flyable
```

### I - Interface Segregation
Prefer small, specific interfaces over large ones.

```java
// BAD - Fat interface
interface Worker {
    void work();
    void eat();
    void sleep();
}

// GOOD - Segregated
interface Workable { void work(); }
interface Eatable { void eat(); }
interface Sleepable { void sleep(); }
```

### D - Dependency Inversion
Depend on abstractions, not concretions.

```java
// BAD - Direct dependency
class OrderService {
    private DatabaseConnection db = new DatabaseConnection();
}

// GOOD - Depend on interface
class OrderService {
    private final OrderRepository repository;
    
    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }
}
```

---

## Clean Code Practices

### Naming

```java
// BAD - Non-descriptive
int d;
List<String> l;
Map<String, Object> m;

// GOOD - Descriptive
int daysUntilExpiry;
List<String> activeUserNames;
Map<String, User> usersById;
```

### Functions

```java
// BAD - Multiple responsibilities, complex logic
public double calc(double a, double b) {
    return a * b * 0.15 + a * b;
}

// GOOD - Clear intent, broken down
public double calculatePriceWithTax(double price, double quantity) {
    final double TAX_RATE = 0.15;
    double subtotal = price * quantity;
    double taxAmount = subtotal * TAX_RATE;
    return subtotal + taxAmount;
}
```

### Comments

**Don't pollute code with comments.** If necessary, comments should explain WHY, never WHAT or HOW.

```java
// BAD - What the code does (redundant)
public User findById(int id) {
    // Loop through users
    for (User u : users) {  // Find user with matching id
        if (u.getId() == id) {
            return u;
        }
    }
    return null;
}

// GOOD - None needed, code is self-documenting
public User findUserById(int userId) {
    return users.stream()
        .filter(u -> u.getId().equals(userId))
        .findFirst()
        .orElse(null);
}
```

---

## Advanced Practices

### Immutability

Prefer immutable objects. They're thread-safe and predictable.

```java
// BAD - Mutable
public class User {
    private String name;
    private List<String> roles;
    
    public void setName(String name) { this.name = name; }
    public List<String> getRoles() { return roles; }  // Returns mutable!
}

// GOOD - Immutable
public final class User {
    private final String name;
    private final List<String> roles;
    
    public User(String name, List<String> roles) {
        this.name = name;
        this.roles = List.copyOf(roles);  // Immutable copy
    }
    
    public String getName() { return name; }
    public List<String> getRoles() { return roles; }  // Already immutable!
    
    // Methods that return new instances
    public User withName(String newName) {
        return new User(newName, roles);
    }
    public User withAddedRole(String role) {
        return new User(name, List.concat(roles, role));
    }
}
```

### Testability

Design for testability from day one. Use dependency injection.

```java
// BAD - Hard to test (direct instantiation)
public class OrderProcessor {
    private DatabaseConnection db = new DatabaseConnection();
    private EmailService email = new EmailService();
    
    public void processOrder(Order order) { /* ... */ }
}

// GOOD - Testable with DI
public class OrderProcessor {
    private final OrderRepository repository;
    private final NotificationService notification;
    
    public OrderProcessor(OrderRepository repository, 
                        NotificationService notification) {
        this.repository = repository;
        this.notification = notification;
    }
    
    public void processOrder(Order order) { /* ... */ }
}

// Test
@Test
void shouldSendConfirmationOnOrder() {
    OrderRepository mockRepo = mock(OrderRepository.class);
    NotificationService mockNotify = mock(NotificationService.class);
    OrderProcessor processor = new OrderProcessor(mockRepo, mockNotify);
    
    processor.processOrder(testOrder);
    
    verify(mockRepo).save(testOrder);
    verify(mockNotify).sendConfirmation(testOrder);
}
```

---

## Streams - When to Avoid

Streams are great but not for every situation.

### 1. Modifying Collection In-Place

```java
// BAD - ConcurrentModificationException risk
numbers.stream()
    .forEach(n -> { if (n % 2 == 0) numbers.remove(n); });

// GOOD - Use removeIf
numbers.removeIf(n -> n % 2 == 0);
```

### 2. Breaking Early

```java
// BAD - No early termination in streams
words.stream()
    .filter(w -> w.equals("banana"))
    .findFirst()
    .ifPresent(System.out::println);

// GOOD - Simple loop for early exit
for (String word : words) {
    if (word.equals("banana")) {
        System.out.println(word);
        break;
    }
}
```

### 3. Checked Exceptions

```java
// BAD - Wrapped exceptions
files.stream()
    .map(f -> {
        try { return readFile(f); }
        catch (IOException e) { 
            throw new RuntimeException(e); 
        }
    });

// GOOD - Simple loop
for (String file : files) {
    try {
        processFile(file);
    } catch (IOException e) {
        log.error("Error: {}", file, e);
    }
}
```

### 4. Nested Loops

```java
// BAD - Unreadable
Arrays.stream(matrix)
    .flatMapToInt(Arrays::stream)
    .forEach(System.out::println);

// GOOD - Clear nested loops
for (int[] row : matrix) {
    for (int num : row) {
        System.out.println(num);
    }
}
```

### 5. Stateful Operations

```java
// BAD - External mutable state
AtomicInteger sum = new AtomicInteger(0);
list.stream().map(n -> sum.addAndGet(n));

// GOOD - Simple loop
int sum = 0;
for (int n : list) {
    sum += n;
}
```

---

## Advanced Coding Practices

### Composition Over Inheritance

```java
// BAD - Rigid inheritance
class Vehicle {
    protected int wheels;
    public void accelerate() { speed += 10; }
}
class Car extends Vehicle {
    public Car() { this.wheels = 4; }
}

// GOOD - Flexible composition
interface Movable {
    void accelerate();
    void brake();
}

class Car implements Movable {
    private final Engine engine;
    private double speed;
    
    public void accelerate() { speed += engine.getPower(); }
    public void brake() { speed = Math.max(0, speed - 10); }
}
```

### Design for Testability

See `java-testing` skill for full testing patterns.

---

## Package Structure

```
com/org.<company>.<project>/
├── <module>/
│   ├── config/           # Configuration
│   ├── domain/          # Domain models (pure Java)
│   ├── application/     # Use cases
│   ├── infrastructure/  # Adapters
│   └── api/            # REST controllers
```

---

## Related

- `conventions-general.md` - Base principles
- `quarkus-conventions.md` - Quarkus annotation mappings
- `springboot-conventions.md` - Spring Boot annotation mappings

*Last updated: 2026-04-12*