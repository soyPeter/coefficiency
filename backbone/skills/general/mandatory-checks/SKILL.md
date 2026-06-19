<!-- FRAMEWORK: GENERAL -->
---
name: mandatory-checks
description: Enforces mandatory checks before and during development. Use when starting any task, before committing, or when hooks block your progress. Contains all enforcement rules: worktrunk, spec-read, security hygiene, skill lint, layer violations.
framework: general
---

# Mandatory Checks

This skill documents all enforcement mechanisms in the Agentic Backbone. **These checks are mandatory and cannot be bypassed.**

## Enforcement Layers

| Layer | Mechanism | When It Runs | Blocking? |
|-------|-----------|--------------|-----------|
| **Pre-Commit** | `scripts/hooks/pre-commit` | Before `git commit` | ✅ Yes |
| **Pre-Tool-Use** | `.claude/hooks/pre-tool-use-skill-check.sh` | Before Write/Edit | ✅ Yes |
| **Session-Start** | `.claude/hooks/session-start-workflow-check.sh` | At session start | ⚠️ Warns |
| **Post-Tool-Use** | `.claude/hooks/post-*.sh` | After Write/Edit | ⚠️ Warns |

## Check 1: Worktrunk Enforcement (Pre-Commit + Pre-Tool-Use)

**Rule:** Feature work must be done in isolated worktrees, not on `dev`/`main`.

**Trigger:**
- On `dev`/`main`/`master` branch
- NOT in a worktree
- `[WIP]` task exists that is NOT fix/docs/refactor

**Action:**
```bash
# Create worktree
./scripts/worktrunk.sh create <feature-name>

# Or use escape hatch: update 3-TASKS.md to use fix/refactor keywords
[WIP] fix: ...
```

## Check 2: Spec-Read Enforcement (Pre-Tool-Use)

**Rule:** If a `[WIP]` task references a PRD, you MUST read it before writing code.

**Trigger:**
- Task line contains `backbone/artifacts/changes/CHNG-XXX/proposal.md`

- [ ] Proposal exists at `backbone/artifacts/changes/CHNG-XXX/proposal.md`
- [ ] Proposal frontmatter includes `grilled: true`
- [ ] Tasks reference the change folder  
view backbone/artifacts/changes/CHNG-XXX/proposal.md
acknowledge-spec
```

## Check 3: Security Fix Hygiene (Pre-Commit)

**Rule:** Public artifacts must NEVER contain vulnerability keywords.

**Blocked Keywords:**
- sql-injection, xss, ssrf, csrf, dos, ddos, rce
- buffer-overflow, heap-overflow, path-traversal
- And 20+ more (see hook for full list)

**Artifact Types Checked:**
- Commit messages
- Branch names
- Test descriptions (pre-tool-use)

**Good Examples:**
```
fix: add input validation
fix: validate outgoing URLs
fix: sanitize query parameters
```

## Check 4: Skill Quality Lint (Pre-Commit)

**Rule:** New or modified `SKILL.md` files must pass quality checks.

**Checks:**
- ✅ Frontmatter with `name`, `description`, `framework`
- ✅ Size under 300 lines (warning if over)
- ✅ Third-person description (not "I can...")

## Check 5: Skill Acknowledgment (Pre-Tool-Use)

**Rule:** Before writing code in a layer, acknowledge the corresponding skill.

**Layer → Skill Mapping:**
| Layer | Required Skill |
|-------|---------------|
| domain | `backbone/skills/java/java-core` |
| app | `backbone/skills/java/java-cdi` |
| api | `backbone/skills/quarkus/java-quarkus` |

**Action:**
```
view backbone/skills/java/java-core/SKILL.md
acknowledge
```

## Check 6: Layer Pattern Violations (Pre-Tool-Use)

**Rule:** Code must respect hexagonal architecture layer boundaries.

**Blocked Patterns:**
- **Domain:** Framework imports, CDI/JPA annotations, Lombok `@Data`
- **App:** CDI scope annotations (`@ApplicationScoped`)
- **API:** Wrong framework annotations (`@RestController` in Quarkus)

## Bypass Policy

**These checks CANNOT be bypassed.** If you are blocked:

1. Read the error message carefully
2. Follow the suggested action
3. If you believe the check is wrong, ask the user

**Never use `--no-verify` or force commits.** The worktrunk check exists to protect the codebase.

## Emergency Escape

If you are absolutely stuck and the user explicitly tells you to bypass:
1. Document the bypass reason in [`backbone/6-MEMORY.md`](backbone/6-MEMORY.md)
2. Get user confirmation in writing
3. Use `git commit --no-verify` (last resort only)
