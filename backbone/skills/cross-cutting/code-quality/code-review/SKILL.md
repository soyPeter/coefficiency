<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: code-review
description: Cross-language code review patterns for identifying quality issues, security vulnerabilities, and best practices. Use when reviewing pull requests, conducting code quality assessments, or establishing review standards.
---

# Code Review Skill

Comprehensive code review patterns for identifying quality issues, security vulnerabilities, and best practices across any programming language.

## When to Use

- Reviewing pull requests
- Conducting code quality assessments
- Setting up code review standards
- Performing security-focused reviews
- Evaluating test coverage

## Excellence Checklist

- [ ] Zero critical security issues
- [ ] Code coverage > 80%
- [ ] Cyclomatic complexity < 10
- [ ] No high-priority vulnerabilities
- [ ] Documentation complete
- [ ] No significant code smells
- [ ] Performance impact validated
- [ ] Best practices followed

## Review Categories

### 1. Code Quality

**Logic Correctness:**
- Does the code do what the PR description claims?
- Are edge cases handled?
- Are there off-by-one errors?
- Does the logic handle null/empty inputs?

**Error Handling:**
```java
// ❌ BAD: Swallowing exceptions
try {
  doSomething();
} catch (Exception e) {
  // Empty catch block
}

// ✅ GOOD: Proper error handling
try {
  doSomething();
} catch (SpecificException e) {
  log.error("Failed to do something", e);
  throw new BusinessException("Failed because...", e);
}
```

**Resource Management:**
```java
// ❌ BAD: Resource leak
public void process() {
  FileInputStream fis = new FileInputStream("file.txt");
  // No close, no try-with-resources
}

// ✅ GOOD: Proper resource management
public void process() {
  try (FileInputStream fis = new FileInputStream("file.txt")) {
    // Process
  }
}
```

### 2. Security Review

**Input Validation:**
```java
// ❌ BAD: No input validation
public void deleteUser(Long userId) {
  userRepo.delete(userId); // Direct deletion without auth check
}

// ✅ GOOD: Proper authorization
public void deleteUser(Long userId, Long requesterId) {
  if (!requesterId.equals(userId) && !isAdmin(requesterId)) {
    throw new UnauthorizedException();
  }
  userRepo.delete(userId);
}
```

**SQL Injection Prevention:**
```java
// ❌ BAD: SQL injection
String query = "SELECT * FROM users WHERE email = '" + email + "'";

// ✅ GOOD: Parameterized query
String query = "SELECT * FROM users WHERE email = ?";
PreparedStatement ps = connection.prepareStatement(query);
ps.setString(1, email);
```

**Secrets Management:**
```java
// ❌ BAD: Hardcoded secret
String apiKey = "sk-live-abc123";

// ✅ GOOD: Environment variable
String apiKey = System.getenv("API_KEY");
```

### 3. Performance Analysis

**Database Queries:**
```java
// ❌ BAD: N+1 query problem
List<User> users = userRepo.findAll();
users.forEach(u -> {
  List<Order> orders = orderRepo.findByUserId(u.getId()); // Query per user!
});

// ✅ GOOD: JOIN FETCH
@Query("SELECT u FROM User u JOIN FETCH u.orders")
List<User> findAllWithOrders();
```

**Memory Leaks:**
```java
// ❌ BAD: Static collection accumulating
static List<String> cache = new ArrayList<>();

public void addToCache(String item) {
  cache.add(item); // Never cleared!
}

// ✅ GOOD: Bounded cache with eviction
LoadingCache<String, String> cache = Caffeine.newBuilder()
  .maximumSize(1000)
  .expireAfterWrite(Duration.ofMinutes(10))
  .build(key -> fetchFromDb(key));
```

### 4. Design Patterns

**SOLID Principles:**
- Single Responsibility: Does the class/module have one reason to change?
- Open/Closed: Is it open for extension but closed for modification?
- Liskov Substitution: Can subclasses be used interchangeably?
- Interface Segregation: Are interfaces focused and minimal?
- Dependency Inversion: Does it depend on abstractions, not concretions?

**DRY Compliance:**
```java
// ❌ BAD: Duplicated logic
public void sendEmailNotification(User user) {
  String message = "Dear " + user.getName() + ", your order is ready.";
  emailService.send(user.getEmail(), message);
}

public void sendSmsNotification(User user) {
  String message = "Dear " + user.getName() + ", your order is ready.";
  smsService.send(user.getPhone(), message);
}

// ✅ GOOD: Shared abstraction
public void sendNotification(User user, String message) {
  notifier.send(user, message);
}
```

### 5. Test Review

**Test Quality:**
```java
// ❌ BAD: Brittle test with no given-when-then
@Test
void testOrder() {
  Order order = new Order();
  order.addItem(new Item("widget", 10.0));
  assertEquals(10.0, order.getTotal()); // What about tax, shipping?
}

// ✅ GOOD: Clear given-when-then with realistic assertions
@Test
void testOrderWithTax() {
  // Given
  Order order = new Order();
  order.addItem(new Item("widget", 10.0));
  
  // When
  BigDecimal total = order.calculateTotal(taxRate);
  
  // Then
  assertEquals(new BigDecimal("10.75"), total);
}
```

**Edge Cases:**
- Null and empty inputs
- Boundary conditions
- Concurrent access
- Large inputs (scalability)
- Error conditions

## Review Checklist by Language

### Java/Kotlin
- [ ] Null safety (Kotlin: let, run, also vs null checks)
- [ ] Stream API usage (java)
- [ ] Coroutine usage (Kotlin)
- [ ] Immutability (data classes, val vs var)
- [ ] Exception handling
- [ ] Transaction boundaries
- [ ] JPA/Hibernate patterns

### Python
- [ ] Type hints usage
- [ ] Context managers (with statement)
- [ ] List comprehensions vs loops
- [ ] Dataclasses vs dicts
- [ ] Async/await patterns
- [ ] Exception handling
- [ ] Dependency injection

### Go
- [ ] Error handling (no exceptions)
- [ ] Goroutine management
- [ ] Interface usage
- [ ] Context propagation
- [ ] nil checks
- [ ] Struct embedding
- [ ] Error wrapping

### TypeScript/JavaScript
- [ ] Type safety (TypeScript: strict mode)
- [ ] Async/await over callbacks
- [ ] Null/undefined handling
- [ ] Destructuring
- [ ] Immutability (const, spread, Object.freeze)
- [ ] Module imports
- [ ] Promise handling

## Providing Feedback

### Constructive Comments

| Instead of | Write |
|-----------|-------|
| "This is wrong" | "Consider extracting this into a helper method for reusability" |
| "Why did you do this?" | "Could you explain the reasoning for this approach?" |
| "This is bad code" | "This pattern may lead to maintenance issues because..." |

### Prioritization
- **Blocking:** Security vulnerabilities, data loss bugs
- **Important:** Logic errors, performance issues
- **Minor:** Style preferences, minor improvements

### Review Template
```markdown
## Code Review: PR-123 Add user authentication

### Summary
Reviewed 47 files. Found 2 critical issues, 5 suggestions.

### Blocking Issues
- [ ] SQL injection in `UserService.java:45`
- [ ] Missing authorization check in `OrderController.java:78`

### Important Suggestions
- [ ] N+1 query in `OrderRepository.java:23`
- [ ] Consider using connection pooling in `DatabaseConfig.java`

### Minor Suggestions
- [ ] Unused import in `UserDto.java:3`
- [ ] Consider extracting magic number into constant

### Approval
Requires fixes for blocking issues before merge.
```
