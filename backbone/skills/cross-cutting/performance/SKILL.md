<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: performance-optimization
description: Measure-first performance optimization. Use when performance requirements exist, when you suspect regressions, or when Core Web Vitals need improvement.
---

# Performance Optimization

Measure before optimizing. Performance work without measurement is guessing — and guessing leads to premature optimization that adds complexity without improving what matters.

## When to Use

- Performance requirements exist (load time budgets, response time SLAs)
- Users or monitoring report slow behavior
- Core Web Vitals scores below thresholds
- Suspect a change introduced regression
- Building features handling large datasets or high traffic

**Not for:** Don't optimize before you have evidence of a problem.

## Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP | <= 2.5s | <= 4.0s | > 4.0s |
| INP | <= 200ms | <= 500ms | > 500ms |
| CLS | <= 0.1 | <= 0.25 | > 0.25 |

## The Optimization Workflow

```
1. MEASURE  → Establish baseline
2. IDENTIFY → Find actual bottleneck
3. FIX      → Address specific bottleneck
4. VERIFY   → Measure again, confirm improvement
5. GUARD    → Add monitoring/tests to prevent regression
```

## Common Anti-Patterns

### N+1 Queries (Backend)

```java
// BAD: N+1 — one query per item
List<Task> tasks = Task.listAll();
for (Task task : tasks) {
    task.owner = User.findById(task.ownerId); // N queries!
}

// GOOD: Single query with join
List<Task> tasks = Task.find("SELECT t FROM Task t JOIN FETCH t.owner").list();
```

### Unbounded Data Fetching

```java
// BAD: Fetching all records
List<Task> allTasks = Task.listAll();

// GOOD: Paginated
List<Task> tasks = Task.find("ORDER BY createdAt DESC")
    .page(0, 20)
    .list();
```

### Missing Caching (Backend)

```java
// Cache frequently-read, rarely-changed data
@CacheResult(cacheName = "app-config")
public AppConfig getAppConfig() {
    return AppConfig.findFirst();
}

// HTTP caching headers
@CacheControl(maxAge = 300)
@GET
public Response getTasks() { ... }
```

## Performance Budget

```
JS bundle: < 200KB gzipped (initial load)
CSS: < 50KB gzipped
Images: < 200KB per image (above fold)
Fonts: < 100KB total
API response: < 200ms (p95)
Time to Interactive: < 3.5s on 4G
Lighthouse Performance: >= 90
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "We'll optimize later" | Performance debt compounds. Fix obvious anti-patterns now. |
| "It's fast on my machine" | Your machine isn't the user's. Profile on representative hardware. |
| "This optimization is obvious" | If you didn't measure, you don't know. |
| "Users won't notice 100ms" | Research shows 100ms delays impact conversion. |

## Red Flags

- Optimization without profiling data
- N+1 patterns in data fetching
- List endpoints without pagination
- Images without optimization
- Bundle size growing without review
- No performance monitoring

## Verification

- [ ] Before/after measurements exist (specific numbers)
- [ ] Specific bottleneck identified and addressed
- [ ] Core Web Vitals within "Good" thresholds
- [ ] Bundle size hasn't increased significantly
- [ ] No N+1 queries in new code
- [ ] Existing tests still pass
