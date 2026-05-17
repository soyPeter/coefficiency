<!-- VERSION: 2026.05.04 -->
# 9. AI Agent Skills (Standard Capabilities)

*This file defines the skills and operating procedures for AI Agents.*
*Active framework and tech stack are defined in `backbone/4-KNOWLEDGE.md`.*

---

## Required Skills for Development

**ALL development tasks MUST load these skills before coding:**

```bash
view backbone/skills/general/coding-standards/SKILL.md
view backbone/skills/cross-cutting/code-quality/SKILL.md
view backbone/skills/cross-cutting/testing/test-quality/SKILL.md
```

These skills are loaded automatically when you start a development session. See `backbone/3-TASKS.md` for task tracking.

---

<!-- SECTION:general -->
## Core Skills (Standard Operating Procedures)

### Skill 1: Git Commit Messages (`git-commit`)
**Goal:** Generate conventional, informative commit messages.

All commits MUST use Conventional Commits format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `perf`, `build`, `chore`

### Skill 2: Issue Triage (`issue-triage`)
**Goal:** Categorize and prioritize GitHub issues.

- Use labels appropriately
- Set priorities
- Add relevant metadata

### Skill 3: New Service (`new-service`)
**Goal:** Create new services following project conventions.

- Follow the service template structure
- Use the `new-service.sh` script

### Skill 4: Coding Standards (`coding-standards`)
**Goal:** Follow project coding conventions.

- Use framework-specific patterns
- Maintain consistent naming

### Skill 5: Build & Gradle (`build-gradle`)
**Goal:** Manage Gradle build configuration.

- Use version catalog
- Follow multi-project conventions

<!-- SECTION_END:general -->


## Cross-Cutting Skills

| Skill | Path |
|-------|------|
| `ai/ai-guardrails` | `view backbone/skills/cross-cutting/ai/ai-guardrails/SKILL.md` |
| `architecture/api-contract-review` | `view backbone/skills/cross-cutting/architecture/api-contract-review/SKILL.md` |
| `architecture/architecture-review` | `view backbone/skills/cross-cutting/architecture/architecture-review/SKILL.md` |
| `architecture/concurrency-review` | `view backbone/skills/cross-cutting/architecture/concurrency-review/SKILL.md` |
| `architecture/cqrs-event-sourcing` | `view backbone/skills/cross-cutting/architecture/cqrs-event-sourcing/SKILL.md` |
| `architecture/domain-driven-design` | `view backbone/skills/cross-cutting/architecture/domain-driven-design/SKILL.md` |
| `architecture/infinitic-patterns` | `view backbone/skills/cross-cutting/architecture/infinitic-patterns/SKILL.md` |
| `architecture/software-architectures` | `view backbone/skills/cross-cutting/architecture/software-architectures/SKILL.md` |
| `backend/api-design` | `view backbone/skills/cross-cutting/backend/api-design/SKILL.md` |
| `backend/backend-patterns` | `view backbone/skills/cross-cutting/backend/backend-patterns/SKILL.md` |
| `code-quality/clean-code` | `view backbone/skills/cross-cutting/code-quality/clean-code/SKILL.md` |
| `code-quality/code-review` | `view backbone/skills/cross-cutting/code-quality/code-review/SKILL.md` |
| `code-quality/design-patterns` | `view backbone/skills/cross-cutting/code-quality/design-patterns/SKILL.md` |
| `code-quality/solid-principles` | `view backbone/skills/cross-cutting/code-quality/solid-principles/SKILL.md` |
| `crossplane/crossplane-patterns` | `view backbone/skills/cross-cutting/crossplane/crossplane-patterns/SKILL.md` |
| `data/data-ingestion-patterns` | `view backbone/skills/cross-cutting/data/data-ingestion-patterns/SKILL.md` |
| `data/data-ingestion-tool-selection` | `view backbone/skills/cross-cutting/data/data-ingestion-tool-selection/SKILL.md` |
| `databases/database-migrations` | `view backbone/skills/cross-cutting/databases/database-migrations/SKILL.md` |
| `databases/postgres-patterns` | `view backbone/skills/cross-cutting/databases/postgres-patterns/SKILL.md` |
| `databases/query-optimization` | `view backbone/skills/cross-cutting/databases/query-optimization/SKILL.md` |
| `databases/schema-design` | `view backbone/skills/cross-cutting/databases/schema-design/SKILL.md` |
| `databases/setup` | `view backbone/skills/cross-cutting/databases/setup/SKILL.md` |
| `devops/devops-patterns` | `view backbone/skills/cross-cutting/devops/devops-patterns/SKILL.md` |
| `docker/docker-patterns` | `view backbone/skills/cross-cutting/docker/docker-patterns/SKILL.md` |
| `documentation/changelog-generator` | `view backbone/skills/cross-cutting/documentation/changelog-generator/SKILL.md` |
| `documentation/getting-started` | `view backbone/skills/cross-cutting/documentation/getting-started/SKILL.md` |
| `documentation/patterns-guide` | `view backbone/skills/cross-cutting/documentation/patterns-guide/SKILL.md` |
| `frontend/frontend-patterns` | `view backbone/skills/cross-cutting/frontend/frontend-patterns/SKILL.md` |
| `frontend/frontend-slides` | `view backbone/skills/cross-cutting/frontend/frontend-slides/SKILL.md` |
| `kubernetes/kubernetes-patterns` | `view backbone/skills/cross-cutting/kubernetes/kubernetes-patterns/SKILL.md` |
| `messaging/nats-patterns` | `view backbone/skills/cross-cutting/messaging/nats-patterns/SKILL.md` |
| `messaging/outbox-pattern` | `view backbone/skills/cross-cutting/messaging/outbox-pattern/SKILL.md` |
| `observability/logging-patterns` | `view backbone/skills/cross-cutting/observability/logging-patterns/SKILL.md` |
| `observability/observability` | `view backbone/skills/cross-cutting/observability/observability/SKILL.md` |
| `oci/oci-security` | `view backbone/skills/cross-cutting/oci/oci-security/SKILL.md` |
| `oci/oci-standards` | `view backbone/skills/cross-cutting/oci/oci-standards/SKILL.md` |
| `performance/performance-smell-detection` | `view backbone/skills/cross-cutting/performance/performance-smell-detection/SKILL.md` |
| `security/security-audit` | `view backbone/skills/cross-cutting/security/security-audit/SKILL.md` |
| `security/security-devsecops` | `view backbone/skills/cross-cutting/security/security-devsecops/SKILL.md` |
| `security/security-review` | `view backbone/skills/cross-cutting/security/security-review/SKILL.md` |
| `security/security-scan` | `view backbone/skills/cross-cutting/security/security-scan/SKILL.md` |
| `security/user-impersonation` | `view backbone/skills/cross-cutting/security/user-impersonation/SKILL.md` |
| `testing/browser-testing-with-devtools` | `view backbone/skills/cross-cutting/testing/browser-testing-with-devtools/SKILL.md` |
| `testing/test-quality` | `view backbone/skills/cross-cutting/testing/test-quality/SKILL.md` |

## General Skills

| Skill | Path |
|-------|------|
| `api-and-interface-design` | `view backbone/skills/general/api-and-interface-design/SKILL.md` |
| `browser-testing-with-devtools` | `view backbone/skills/general/browser-testing-with-devtools/SKILL.md` |
| `ci-cd-and-automation` | `view backbone/skills/general/ci-cd-and-automation/SKILL.md` |
| `code-review-and-quality` | `view backbone/skills/general/code-review-and-quality/SKILL.md` |
| `code-simplification` | `view backbone/skills/general/code-simplification/SKILL.md` |
| `coding-standards` | `view backbone/skills/general/coding-standards/SKILL.md` |
| `context-engineering` | `view backbone/skills/general/context-engineering/SKILL.md` |
| `create-prd` | `view backbone/skills/general/create-prd/SKILL.md` |
| `create-skill` | `view backbone/skills/general/create-skill/SKILL.md` |
| `debugging-and-error-recovery` | `view backbone/skills/general/debugging-and-error-recovery/SKILL.md` |
| `delta-spec` | `view backbone/skills/general/delta-spec/SKILL.md` |
| `deprecation-and-migration` | `view backbone/skills/general/deprecation-and-migration/SKILL.md` |
| `design-document` | `view backbone/skills/general/design-document/SKILL.md` |
| `documentation-and-adrs` | `view backbone/skills/general/documentation-and-adrs/SKILL.md` |
| `ears-requirements` | `view backbone/skills/general/ears-requirements/SKILL.md` |
| `frontend-ui-engineering` | `view backbone/skills/general/frontend-ui-engineering/SKILL.md` |
| `git-commit` | `view backbone/skills/general/git-commit/SKILL.md` |
| `git-workflow-and-versioning` | `view backbone/skills/general/git-workflow-and-versioning/SKILL.md` |
| `grill-me` | `view backbone/skills/general/grill-me/SKILL.md` |
| `grill-with-docs` | `view backbone/skills/general/grill-with-docs/SKILL.md` |
| `idea-refine` | `view backbone/skills/general/idea-refine/SKILL.md` |
| `improve-codebase-architecture` | `view backbone/skills/general/improve-codebase-architecture/SKILL.md` |
| `incremental-implementation` | `view backbone/skills/general/incremental-implementation/SKILL.md` |
| `issue-triage` | `view backbone/skills/general/issue-triage/SKILL.md` |
| `mandatory-checks` | `view backbone/skills/general/mandatory-checks/SKILL.md` |
| `new-service` | `view backbone/skills/general/new-service/SKILL.md` |
| `performance-optimization` | `view backbone/skills/general/performance-optimization/SKILL.md` |
| `planning-and-task-breakdown` | `view backbone/skills/general/planning-and-task-breakdown/SKILL.md` |
| `security-and-hardening` | `view backbone/skills/general/security-and-hardening/SKILL.md` |
| `security-fixes` | `view backbone/skills/general/security-fixes/SKILL.md` |
| `shipping-and-launch` | `view backbone/skills/general/shipping-and-launch/SKILL.md` |
| `source-driven-development` | `view backbone/skills/general/source-driven-development/SKILL.md` |
| `spec-driven-development` | `view backbone/skills/general/spec-driven-development/SKILL.md` |
| `test-driven-development` | `view backbone/skills/general/test-driven-development/SKILL.md` |
| `to-issues` | `view backbone/skills/general/to-issues/SKILL.md` |
| `traceability` | `view backbone/skills/general/traceability/SKILL.md` |

## Skill Safety Check

Before loading ANY skill:
1. Read the first line of `SKILL.md`
2. Verify it says `<!-- FRAMEWORK: jooby -->` or `<!-- FRAMEWORK: GENERAL -->`
3. If different or missing, ask the user before loading

## Quick Find

```bash
# Find skills by keyword
grep -r "keyword" backbone/skills --include="*.md" | head -10

# List all skills
ls backbone/skills/*/*/
```
