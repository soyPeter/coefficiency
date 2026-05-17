# Testing Patterns Reference

Quick-reference for test structure, naming, mocking, and anti-patterns.

## Test Structure

### Arrange-Act-Assert

```java
@Test
void marksOverdueTasksWhenDeadlinePassed() {
    // Arrange
    Task task = createTask("Test", LocalDate.of(2025, 1, 1));
    
    // Act
    boolean isOverdue = taskService.isOverdue(task, LocalDate.of(2025, 1, 2));
    
    // Assert
    assertThat(isOverdue).isTrue();
}
```

### Given-When-Then

```java
@Test
void givenOverdueTask_whenCheckingStatus_thenReturnsOverdue() {
    // Given
    Task task = createOverdueTask();
    
    // When
    TaskStatus status = taskService.getStatus(task);
    
    // Then
    assertThat(status).isEqualTo(TaskStatus.OVERDUE);
}
```

## Mocking Hierarchy

```
1. Real implementation  → Highest confidence
2. Fake                 → In-memory version
3. Stub                 → Returns canned data
4. Mock (interaction)   → Use sparingly
```

## Test Naming Patterns

| Pattern | Example |
|---------|---------|
| shouldXWhenY | `shouldCreateOrderWhenRequestValid` |
| givenXWhenYThenZ | `givenValidRequest_whenCreatingOrder_thenReturnsCreated` |
| testX | `testCreateOrder` |

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Testing implementation details | Tests break on refactoring | Test state, not interactions |
| Flaky tests | Erode trust | Use deterministic assertions |
| Testing framework code | Wastes time | Only test YOUR code |
| Snapshot abuse | Large, unreviewed | Use sparingly, review changes |
| No test isolation | Pass individually, fail together | Each test sets up/tears down state |
| Mocking everything | Pass but production breaks | Prefer real > fake > stub > mock |
