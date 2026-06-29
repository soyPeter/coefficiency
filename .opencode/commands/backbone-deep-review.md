---
description: Deep full-spectrum codebase audit — DDD, SOLID, API, Security, Clean Code, Tests
agent: general
required-skills:
  - general/coding-standards
  - cross-cutting/code-quality
  - cross-cutting/testing/test-quality
  - cross-cutting/security
  - cross-cutting/architecture
  - cross-cutting/code-review
---

> **skill loading:** Read required-skills frontmatter. For each entry, check `backbone/skills/<path>/SKILL.md` first, then fallback to skill tool.

# Deep Full-Spectrum Code Analysis

Perform a comprehensive codebase audit covering DDD, SOLID, API contracts, security, clean code, test quality, and architecture depth. Spawns 4 parallel subagents for maximum coverage.

## Process

### Phase 1: Load Context
1. Read [`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md) — tech stack, constraints, NEVER DO list
2. Read [`backbone/8-WORKFLOW.md`](backbone/8-WORKFLOW.md) — conventions
3. Read [`backbone/9-AGENT-SKILLS.md`](backbone/9-AGENT-SKILLS.md) — available agents
4. Glob `src/main/java/**/*.java` and `frontend/src/**/*.{ts,tsx}` to understand scope

### Phase 2: Spawn 4 Parallel Subagents

Use `gsd-codebase-mapper` subagent type. Spawn ALL 4 simultaneously.

**Subagent 1 — DDD + SOLID + Architecture:**
```
Analyze src/main/java for:
1. DDD: Are domain records pure? Self-validating? Anemic? Value objects used?
2. SOLID: SRP violations (god classes >200 lines). OCP violations (switch/if-else).
   DIP violations (controllers creating services, app layer using framework types).
   ISP violations (fat interfaces).
3. Architecture: Module thickness (domain% vs app% vs infra% per module).
   Layer boundary violations. Circular deps. Shallow vs thick modules.
Read deeply: all *Controller.java, *Service.java, *Repository.java, domain/*.java
Write to: .planning/codebase/ANALYSIS.md
```

**Subagent 2 — API Contracts + Security:**
```
Analyze ALL controllers + frontend/api.ts for:
1. API: Route inventory (method, path, actual status, expected status).
   Response envelope consistency (ok vs success vs status vs direct object).
   HTTP method appropriateness (POST vs PUT for updates).
   Status code correctness (200 on error, 201 on create, 204 on delete).
   Pagination gaps on collection endpoints.
   Frontend-backend type mismatches (field names, return types).
2. Security: Hardcoded secrets. SQL injection (string concat in queries).
   Path traversal (user input in file paths). File upload validation (type/size).
   Exception leakage (getMessage() returned to client). Password hashing quality.
   Auth bypass possibilities. CORS. Rate limiting.
Write to: .planning/codebase/API_ANALYSIS.md
```

**Subagent 3 — Code Quality + Clean Code:**
```
Analyze ALL Java + TypeScript files for:
1. Clean Code: Method length >30 lines, class length >200 lines, nesting >3 levels.
   Complex conditionals (>3 operators). Magic numbers/strings.
   Duplicate code patterns (identical logic blocks).
2. Naming: Spanish identifiers. Inconsistent naming. Short variable names.
   Comment quality (stale, obvious, missing).
3. Error handling: Broad catches (catch Exception). Empty catch blocks.
   System.out.println vs logger. try-with-resources coverage.
4. Frontend: Component size >300 lines. useState sprawl vs useReducer.
   any types. i18n gaps. Hardcoded strings.
Write to: .planning/codebase/CONCERNS.md
```

**Subagent 4 — Test Quality + Coverage:**
```
Analyze ALL test files in src/test/java for:
1. Coverage matrix: domain ↔ test file mapping. Untested classes.
2. Test quality: Assertion density. Test isolation (BeforeAll vs BeforeEach).
   Mocking quality. Naming conventions. Edge case coverage.
3. Testing approach: TDD evidence in commit history.
   Unit vs integration vs E2E distribution.
   JaCoCo threshold compliance.
4. Frontend tests: Any test framework configured? Any test files found?
Write to: .planning/codebase/TESTING.md + .planning/codebase/CONVENTIONS.md
```

### Phase 3: Compile Report
Wait for all 4 subagents to complete, then:
1. Read all 4 outputs from `.planning/codebase/`
2. Compile into a single Markdown report at `backbone/artifacts/reports/deep-review-$(date +%Y-%m-%d).md`
3. Structure the report:
   - What's Clean (things done right)
   - CRITICAL Security Findings
   - SOLID Violations
   - DDD Health Assessment
   - Architecture Depth Map
   - API Contract Issues
   - Clean Code / Maintainability
   - Test Coverage & Quality
   - Non-Issues (intentional)
   - Consolidated Priority Recommendations (P0→P3 with REQ-IDs)
   - Summary Statistics

### Phase 4: QMS Registration
For each P0/P1 finding in the compiled report:
1. Register NCR: `./scripts/qms-register-issue.sh --title "<finding>" --severity critical|major --category <code|security|...> --source review`
2. Create CAPA: `./scripts/qms-capa-create.sh --ncr NCR-XXX --owner "dev" --due <date+30d> --root-cause "<analysis>" --action-plan "<steps>"`

### Phase 5: Generate Remediation Plan
Write `backbone/artifacts/reports/remediation-$(date +%Y-%m-%d).md`:
- Objective referencing the deep-review report
- Dependency graph (ASCII art showing phase ordering)
- Phases with steps: each step has file, action, verify criteria, effort tag [XS/S/M/L], NCR ref, CAPA ref
- Rollback strategy per phase
- Model tier assignment (which phases need strongest model)
- Success criteria (all NCRs closed, build + tests pass, report-specific gates)

### Phase 6: Cleanup
Remove `.planning/codebase/` directory.

## Output
- Deep review: `backbone/artifacts/reports/deep-review-YYYY-MM-DD.md`
- Remediation plan: `backbone/artifacts/reports/remediation-YYYY-MM-DD.md`
- NCRs: `backbone/artifacts/qms/ncr/NCR-XXX.yml`
- CAPAs: `backbone/artifacts/qms/capa/CAPA-XXX.yml`
Returns summary of top findings, NCRs registered, and CAPAs created.
