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

## Multi-Pass Adversarial Review

For deep/full-audit depths, use multi-pass adversarial review with parallel specialized reviewers.

### Preflight Gating

Run automated checks before spawning AI reviewers. If preflight fails, stop and report — don't waste tokens on code that doesn't compile:

```bash
# Preflight gate — all must pass before AI review
npm run build  || { echo "BUILD FAILED"; exit 1; }
npm run lint   || { echo "LINT FAILED"; exit 1; }
npm run test   || { echo "TESTS FAILED"; exit 1; }
```

### Signal Detection

Detect review scope from changed files to select the right specialists:

```javascript
const signals = {
  hasDb:      files.some(f => /(db|migrations?|schema|prisma|sql)/i.test(f)),
  hasApi:     files.some(f => /(api|routes?|controllers?|endpoints?)/i.test(f)),
  hasDomain:  files.some(f => /(domain|model|entity|value-object)/i.test(f)),
  hasFrontend: files.some(f => /\.(tsx|jsx|vue|svelte)$/.test(f)),
  hasBackend: files.some(f => /(service|repository|adapter|port)/i.test(f)),
  hasDevops:  files.some(f => /(Dockerfile|k8s|terraform|\.github\/workflows)/i.test(f)),
  needsArchitecture: files.length > 20
};
```

### Specialist Selection

Spawn parallel reviewers, one per matching signal:

| Specialist | Signal | Focus Areas |
|------------|--------|-------------|
| Code Quality | always | Style, best practices, bugs, error handling, maintainability, duplication |
| Security | always | Auth/Authz flaws, injection risks, secrets, insecure defaults |
| Performance | always | N+1 queries, blocking ops, hot paths, memory leaks |
| Test Coverage | always | Missing tests, edge cases, test quality, mock appropriateness |
| Database | hasDb | Query performance, indexes, migration safety, data integrity |
| Architecture | needsArchitecture | Module boundaries, dependency direction, layer coupling |
| API | hasApi | REST conventions, status codes, pagination, versioning |
| Domain | hasDomain | Domain purity, ubiquitous language, aggregate consistency |
| Frontend | hasFrontend | Component boundaries, state management, accessibility |
| Backend | hasBackend | Service boundaries, domain logic, concurrency, idempotency |
| DevOps | hasDevops | CI/CD safety, secrets handling, build/test pipelines |

### Adversarial Roles

For critical/delicate reviews, review the same changes from 3 adversarial perspectives:

1. **Blind Hunter** — Reviews with no knowledge of context or assumptions. Catches confusing interfaces, missing documentation, surprising behavior.
2. **Edge Case Hunter** — Focuses on boundary conditions: nulls, empty collections, concurrent access, overflow, error paths, retry storms.
3. **Acceptance Auditor** — Verifies code against requirements/proposal/design. Finds untested requirements, incomplete implementations, logic that doesn't match the spec.

### Aggregation & Deduplication

After parallel reviews complete, aggregate findings:

```javascript
function aggregateFindings(results) {
  // Deduplicate by file:line:description
  const items = [];
  for (const {pass, findings = []} of results) {
    for (const f of findings) {
      items.push({
        id: `${pass}:${f.file}:${f.line}:${f.description}`,
        pass, ...f,
        status: f.falsePositive ? 'false-positive' : 'open'
      });
    }
  }
  const deduped = [...new Map(items.map(i => [i.id, i])).values()];
  const bySeverity = {critical: [], high: [], medium: [], low: []};
  deduped.forEach(i => !i.falsePositive && bySeverity[i.severity || 'low'].push(i));
  return { items: deduped, bySeverity, totals: Object.fromEntries(
    Object.entries(bySeverity).map(([k, v]) => [k, v.length])
  )};
}
```

Each finding should include: `file`, `line`, `severity` (critical|high|medium|low), `description`, `suggestion`, `confidence` (high|medium|low), `falsePositive` (boolean). Report all with confidence >= medium.

### Iteration Loop (Optional)

For automated review-fix cycles, iterate up to 5 times with stall detection:

```javascript
const MAX_ITERATIONS = 5, MAX_STALLS = 1;
let iteration = 1, stallCount = 0, lastHash = null;

while (iteration <= MAX_ITERATIONS) {
  const results = await spawnParallelReviewers(passes);
  const findings = aggregateFindings(results);
  if (findings.openCount === 0) break;

  // Fix in severity order: critical → high → medium → low
  for (const issue of [...findings.bySeverity.critical, ...findings.bySeverity.high]) {
    applyFix(issue); // Read file, validate suggestion, apply edit
  }
  gitCommit(`fix: review feedback (iteration ${iteration})`);

  // Stall detection — hash comparison of open findings
  const hash = sha256(JSON.stringify(findings.items.filter(i => !i.falsePositive)));
  if (hash === lastHash) stallCount++;
  lastHash = hash;
  if (stallCount >= MAX_STALLS || iteration >= MAX_ITERATIONS) break;
  iteration++;
}
```

### Structured JSON Output

Passes return findings as structured JSON:

```json
{
  "pass": "security",
  "findings": [
    {
      "file": "src/auth/login.ts",
      "line": 89,
      "severity": "high",
      "description": "Password comparison uses timing-vulnerable string equality",
      "suggestion": "Use crypto.timingSafeEqual() instead of ===",
      "confidence": "high",
      "falsePositive": false
    },
    {
      "file": "src/config.ts",
      "line": 12,
      "severity": "low",
      "description": "Magic number 3600 should be named constant",
      "suggestion": "const CACHE_TTL_SECONDS = 3600;",
      "confidence": "medium",
      "falsePositive": false
    }
  ]
}
```

## QMS Integration

Every review finding with severity >= high MUST be registered as a Quality Management System (QMS) record. This creates an auditable chain from finding → NCR → CAPA → closure.

### NCR Registration

For each finding (severity >= high), register a nonconformance report:

```bash
./scripts/qms-register-issue.sh \
  --title "Short description of issue" \
  --description "Detailed finding from review" \
  --severity critical|major|minor \
  --category code|security|performance|configuration|process|documentation \
  --source review
```

Severity mapping: critical=P0 → `critical`, high=P1 → `major`, medium=P2 → `minor`, low=P3 → `observation`

### CAPA (Corrective Action)

For each registered NCR, create a linked corrective action:

```bash
./scripts/qms-capa-create.sh \
  --ncr NCR-XXX \
  --owner "dev" \
  --due 2026-06-23 \
  --root-cause "Root cause analysis: what made the bug possible at the process/design level" \
  --action-plan "Concrete steps to fix and prevent recurrence"
```

### QMS Report

After registering, generate a QMS status report:

```bash
./scripts/qms-report.sh
./scripts/qms-report.sh --full
./scripts/qms-report.sh --aging
```

### NCR → CAPA → Remediation Plan Flow

```
Finding (P0/P1)
  └── NCR (backbone/artifacts/qms/ncr/NCR-XXX.yml)
       └── CAPA (backbone/artifacts/qms/capa/CAPA-XXX.yml)
            └── Remediation plan step (backbone/artifacts/reports/remediation-*.md)
                 └── Task in 3-TASKS.md
                      └── Commit fixing the issue → CAPA verification → CAPA closure
```

## Remediation Planning

After aggregate findings, generate a remediation plan at `backbone/artifacts/reports/remediation-$(date +%Y-%m-%d).md`. The plan translates findings into actionable, ordered work units.

### Structure

```
# Remediation Plan: [report-name]

## Objective

Solve all findings from [report-path]. [N] phases, ~[N] tasks.

## Dependency Graph

```
Phase 1 (Security & Critical) ───────────────────────────────┐
  └── Phase 2 (Backend Foundation) ──────────────────────┐    │
        └── Phase 3 (Architecture) ──────────────────────┤    │
              └── Phase 4 (SOLID) ───────────────────────┤    │
                    └── Phase 5 (API/Frontend/Test) ──────┘    │
                          └── Phase 6 (Polish & Verify) ────────┘
```

## Phases

### Phase N: [Category Name]

**Dependencies:** [list]
**Parallel steps within phase:** [yes/no]

#### Step N.M — [Action Description] (REQ-XXX-NN)
**File:** `path/to/file.java:line`
**NCR:** NCR-XXX
**CAPA:** CAPA-XXX
**Action:**
- Bullet list of concrete changes
**Verify:** How to confirm fix works
**Effort:** [XS/S/M/L]

## Rollback Strategy

| Phase | Rollback |
|-------|----------|
| 1 | Revert commit |
| 2 | Revert commit |

## Model Tier Assignment

| Phase | Tier | Reason |
|-------|------|--------|
| 1 | Strongest | Security changes affect all users |
| 3 | Strongest | Design decisions affect all later code |

## Success Criteria

- [ ] All NCRs closed
- [ ] All CAPAs verified
- [ ] Build + tests pass
- [ ] [Add report-specific criteria]
```

### Phase Organization

Group findings into phases by category and dependency:

| Phase | Typical Contents | Priority |
|-------|------------------|----------|
| 1. Security & Critical | Secrets, auth, injection, data loss | Must fix first |
| 2. Foundation | Shared utilities, config, build | Unblocks later phases |
| 3. Architecture | DDD, dependency injection, layer boundaries | Structural changes |
| 4. SOLID | God classes, SRP violations, switch statements | Large refactors |
| 5. API/Frontend/Test | API contracts, UI components, test gaps | Can parallelize |
| 6. Polish & Verify | Logging, naming, final verification | Always last |

### Effort Tags

| Tag | Meaning | Example |
|-----|---------|---------|
| [XS] | < 30 min, 1 file, mechanical | Rename, extract constant, fix import |
| [S] | 1–2 hours, 2–5 files, simple logic | Extract method, add validation |
| [M] | 2–4 hours, 5–15 files, moderate logic | Split class, add feature, add tests |
| [L] | 4+ hours, 15+ files, complex refactor | Split god class, add pagination, full test suite |

## Providing Feedback

### Constructive Comments

| Instead of | Write |
|-----------|-------|
| "This is wrong" | "Consider extracting this into a helper method for reusability" |
| "Why did you do this?" | "Could you explain the reasoning for this approach?" |
| "This is bad code" | "This pattern may lead to maintenance issues because..." |

### Prioritization
- **P0 (Critical):** Security vulnerabilities, data loss, data integrity bugs
- **P1 (High):** Logic errors, performance regressions, missing edge cases
- **P2 (Medium):** Code smells, DRY violations, test gaps
- **P3 (Low):** Style, naming, minor improvements, documentation

### Output Format

```
## Code Review Report

### Summary
- Scope: <N> files across <M> modules
- Verdict: ✅ PASS | ⚠️ PASS WITH ISSUES | ❌ FAIL

### 🔴 CRITICAL (P0)
- [ ] Severity issue in `file:line`: description

### 🟡 HIGH (P1)
- [ ] ...

### 🔵 MEDIUM (P2)
- [ ] ...

### ⚪ LOW (P3)
- [ ] ...

### Non-Issues (examined and dismissed)
- `file:line` — intentional because <reason>

### Statistics
- Files reviewed: <N>
- P0: <N> | P1: <N> | P2: <N> | P3: <N>
- False positives dismissed: <N>
```
