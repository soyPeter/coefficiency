<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: testing-guide
description: Testing patterns and best practices - unit tests, integration tests, Testcontainers, mocking, coverage targets. Use when writing tests for new features or improving test coverage.
---

# Testing Guide

Comprehensive testing patterns for maintainable, effective tests.

## When to Use

- Writing tests for new features
- Improving test coverage
- Setting up integration tests
- Debugging test failures
- Fixing bugs (Prove-It Pattern)

## The TDD Cycle

```
    RED                GREEN              REFACTOR
 Write a test    Write minimal code    Clean up the
 that fails  ──→  to make it pass  ──→  implementation  ──→  (repeat)
      │                  │                    │
      ▼                  ▼                    ▼
   Test FAILS        Test PASSES         Tests still PASS
```

### Step 1: RED — Write a Failing Test

Write the test first. It must fail. A test that passes immediately proves nothing.

```java
// RED: This test fails because createOrder doesn't exist yet
@Test
void shouldCreateOrderWithValidRequest() {
    CreateOrderReq req = new CreateOrderReq("customer-1", List.of("item-1"));
    Order result = orderService.create(req);
    assertThat(result.getCustomerId()).isEqualTo("customer-1");
    assertThat(result.getStatus()).isEqualTo(OrderStatus.PENDING);
}
```

### Step 2: GREEN — Make It Pass

Write the minimum code to make the test pass. Don't over-engineer.

### Step 3: REFACTOR — Clean Up

With tests green, improve code without changing behavior. Run tests after each step.

## The Prove-It Pattern (Bug Fixes)

When a bug is reported, **do not start by trying to fix it.** Start by writing a test that reproduces it.

```
Bug report arrives
       │
       ▼
  Write a test that demonstrates the bug
       │
       ▼
  Test FAILS (confirming the bug exists)
       │
       ▼
  Implement the fix
       │
       ▼
  Test PASSES (proving the fix works)
       │
       ▼
  Run full test suite (no regressions)
```

## The Test Pyramid

```
         ╱╲
        ╱  ╲      E2E (~5%)
       ╱────╲
      ╱      ╲    Integration (~15%)
     ╱────────╲
    ╱          ╲  Unit (~80%)
   ╱────────────╲
```

**The Beyonce Rule:** If you liked it, you should have put a test on it. Infrastructure changes, refactoring, and migrations are not responsible for catching your bugs — your tests are.

## Test Sizes

| Size | Constraints | Speed | Example |
|------|------------|-------|---------|
| Small | Single process, no I/O | Milliseconds | Pure function tests |
| Medium | Multi-process, localhost only | Seconds | API tests with test DB |
| Large | Multi-machine, external services | Minutes | E2E, performance |

## Excellence Checklist

- [ ] Unit tests > 80% coverage
- [ ] Integration tests for all use cases
- [ ] Named test methods describe behavior
- [ ] Tests are independent (no order dependency)
- [ ] Mock external dependencies
- [ ] Use Testcontainers for database tests

## Test Types

| Type | Purpose | Speed | Tool |
|------|---------|-------|------|
| Unit | Single class logic | Fast | Mock |
| Integration | Multiple components | Slow | Testcontainers |
| Contract | API compatibility | Medium | Pact/RestAssured |
| E2E | Full system | Slowest | Real services |
| Quarkus IT | Native/HTTP layer testing | Medium | `@QuarkusIntegrationTest` |

**When to use each:**
- `@QuarkusTest`: unit-level bean testing, mock injection, in-memory CDI
- `@QuarkusIntegrationTest`: full HTTP stack, native image validation, JAR packaging
- Testcontainers: real database integration without mocks
- E2E: full system validation with real services

## Quarkus Test Patterns

| Annotation | Purpose | Speed | Port Required |
|------------|---------|-------|--------------|
| `@QuarkusTest` | In-memory CDI, bean testing | Fast | No |
| `@QuarkusIntegrationTest` | Real JAR, packaging validation | Medium | Yes |

**Dev Services**: Quarkus automatically provisions containers (Postgres, Ollama, etc.) for tests. No explicit container management needed.

**REST Assured integration:**
```java
@QuarkusTest
class OrderResourceTest {

    @Test
    void shouldCreateOrder(TestTransaction) {
        given()
            .contentType(ContentType.JSON)
            .body("{\"customerId\":\"c-1\"}")
        .when()
            .post("/orders")
        .then()
            .statusCode(201);
    }
}
```

## Unit Test Pattern

```java
class CreateOrderUseCaseTest {

    @Mock
    private OrderRepository orderRepo;
    
    @InjectMock
    private CreateOrderUseCase useCase;

    @Test
    void shouldCreateOrderWithValidRequest() {
        // Given
        CreateOrderReq req = new CreateOrderReq("customer-1", List.of("item-1"));
        when(orderRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        
        // When
        Order result = useCase.execute(req);
        
        // Then
        assertThat(result.getCustomerId()).isEqualTo("customer-1");
        assertThat(result.getStatus()).isEqualTo(OrderStatus.PENDING);
        verify(orderRepo).save(any(Order.class));
    }
    
    @Test
    void shouldFailWithInvalidCustomer() {
        // Given
        CreateOrderReq req = new CreateOrderReq(null, List.of("item-1"));
        
        // When/Then
        assertThatThrownBy(() -> useCase.execute(req))
            .isInstanceOf(InvalidCustomerException.class);
    }
}
```

## Integration Test Pattern (Testcontainers)

```java
@Testcontainers
class OrderRepositoryIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");
    
    @Test
    void shouldSaveAndRetrieveOrder() {
        // Given
        Order order = Order.create("customer-1", List.of("item-1"));
        
        // When
        orderRepository.save(order);
        Optional<Order> found = orderRepository.findById(order.getId());
        
        // Then
        assertThat(found).isPresent();
        assertThat(found.get().getCustomerId()).isEqualTo("customer-1");
    }
}
```

## Writing Good Tests

### Test State, Not Interactions

Assert on the *outcome*, not on which methods were called internally.

```java
// Good: Tests what the function does (state-based)
@Test
void returnsTasksSortedByCreationDateNewestFirst() {
    List<Task> tasks = taskService.listTasks("createdAt", "desc");
    assertThat(tasks.get(0).getCreatedAt())
        .isAfter(tasks.get(1).getCreatedAt());
}

// Bad: Tests how the function works internally (interaction-based)
@Test
void callsDbQueryWithOrderByCreatedAtDesc() {
    taskService.listTasks("createdAt", "desc");
    verify(db).query("ORDER BY created_at DESC");
}
```

### DAMP Over DRY in Tests

In production code, DRY is usually right. In tests, **DAMP (Descriptive And Meaningful Phrases)** is better. Each test should tell a complete story.

```java
// DAMP: Each test is self-contained and readable
@Test
void rejectsTasksWithEmptyTitles() {
    assertThatThrownBy(() -> createTask(""))
        .isInstanceOf(ValidationException.class);
}

@Test
void trimsWhitespaceFromTitles() {
    Task task = createTask("  Buy groceries  ");
    assertThat(task.getTitle()).isEqualTo("Buy groceries");
}
```

### Prefer Real Implementations Over Mocks

```
Preference order:
1. Real implementation  → Highest confidence
2. Fake                 → In-memory version
3. Stub                 → Returns canned data
4. Mock (interaction)   → Use sparingly
```

### Name Tests Descriptively

```java
// Good: Reads like a specification
describe('TaskService.completeTask', () => {
    it('sets status to completed and records timestamp');
    it('throws NotFoundError for non-existent task');
    it('is idempotent — completing already-completed task is no-op');
});

// Bad: Vague names
@Test
void testCompleteTask() { ... }
@Test
void test2() { ... }
```

## Test Naming Convention

| Pattern | Use When |
|---------|----------|
| `shouldDoXWhenY` | Behavior-driven |
| `testDoX` | Simple cases |
| `givenX_whenY_thenZ` | Given-When-Then style |

## Coverage Targets

| Layer | Target | Tool |
|-------|--------|-------|
| Domain | 90%+ | JaCoCo |
| Application | 80%+ | JaCoCo |
| Infrastructure | 60%+ | JaCoCo |

## Common Mistakes

### Bad: Brittle Tests
```java
// ❌ BAD - Order-dependent tests
@Test
void testOrderCreation() {
    orderService.create();
    orderService.update(); // Depends on create!
}
```

### Good: Independent Tests
```java
// ✅ GOOD - Each test stands alone
@Test
void shouldCreateOrder() { /* ... */ }

@Test
void shouldUpdateOrder() { /* ... */ }
```

## Running Tests

```bash
# All tests
./gradlew test

# Single test class
./gradlew test --tests "CreateOrderUseCaseTest"

# Integration tests only
./gradlew test --tests "*IntegrationTest"

# With coverage
./gradlew jacocoTestReport
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll write tests after the code works" | You won't. And tests written after test implementation, not behavior. |
| "This is too simple to test" | Simple code gets complicated. The test documents expected behavior. |
| "Tests slow me down" | Tests slow you down now. They speed you up every time you change the code later. |
| "I tested it manually" | Manual testing doesn't persist. Tomorrow's change might break it. |

## Red Flags

- Writing code without any corresponding tests
- Tests that pass immediately (may not test what you think)
- Bug fixes without reproduction tests
- Tests that test framework behavior instead of application behavior
- Vague test names
- Skipping tests to make the suite pass
