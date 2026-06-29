---
name: backbone:deep-review
description: Deep full-spectrum codebase audit — DDD, SOLID, API, Security, Clean Code, Tests
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - Task
required-skills:
  - general/coding-standards
---

# Deep Full-Spectrum Code Analysis

Perform a comprehensive codebase audit covering DDD, SOLID, API contracts, security, clean code, test quality, and architecture depth. Spawns 4 parallel subagents for maximum coverage.

## Process

### Phase 1: Load Context
1. Load required skills from frontmatter
2. Read [`backbone/4-KNOWLEDGE.md`](backbone/4-KNOWLEDGE.md) — tech stack, constraints, NEVER DO list
3. Read [`backbone/8-WORKFLOW.md`](backbone/8-WORKFLOW.md) — conventions
4. Read [`backbone/9-AGENT-SKILLS.md`](backbone/9-AGENT-SKILLS.md) — available agents
5. Glob `src/main/java/**/*.java` and `frontend/src/**/*.{ts,tsx}` to understand scope

### Phase 2: Spawn 4 Parallel Subagents

Use `Task` tool with subagent_type `gsd-codebase-mapper` for each. Spawn ALL 4 simultaneously.

**Subagent 1 — DDD + SOLID + Architecture:**
Analyze src/main/java for DDD purity, SOLID violations, and architecture depth (module thickness, layer boundaries, circular deps). Read all *Controller.java, *Service.java, *Repository.java, domain/*.java. Write to .planning/codebase/ANALYSIS.md

**Subagent 2 — API Contracts + Security:**
Analyze ALL controllers + frontend/api.ts for API contract issues (status codes, methods, response envelopes, pagination, type mismatches) and security (hardcoded secrets, SQL injection, path traversal, file upload validation, exception leakage, password hashing). Write to .planning/codebase/API_ANALYSIS.md

**Subagent 3 — Code Quality + Clean Code:**
Analyze ALL Java + TS files for method/class size, nesting depth, magic numbers, duplicate code, Spanish identifiers, empty catch blocks, broad exception catches, System.out usage, i18n gaps, useState sprawl, any types. Write to .planning/codebase/CONCERNS.md

**Subagent 4 — Test Quality + Coverage:**
Analyze ALL test files for coverage matrix, assertion density, test isolation, mocking quality, TDD evidence, JaCoCo threshold. Check frontend for any test framework. Write to .planning/codebase/TESTING.md + .planning/codebase/CONVENTIONS.md

### Phase 3: Compile Report
1. Read all 4 outputs from `.planning/codebase/`
2. Compile report at `backbone/artifacts/reports/deep-review-$(date +%Y-%m-%d).md`
3. Sections: What's Clean, CRITICAL Security, SOLID, DDD, Architecture, API, Clean Code, Tests, Non-Issues, P0→P3 Recommendations, Summary

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
Remove `.planning/codebase/`

## Output
- Deep review: `backbone/artifacts/reports/deep-review-YYYY-MM-DD.md`
- Remediation plan: `backbone/artifacts/reports/remediation-YYYY-MM-DD.md`
- NCRs: `backbone/artifacts/qms/ncr/NCR-XXX.yml`
- CAPAs: `backbone/artifacts/qms/capa/CAPA-XXX.yml`
