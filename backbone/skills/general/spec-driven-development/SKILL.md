<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: spec-driven-development
description: Keeps implementation and specs in sync. Use when working on a feature that has a proposal in backbone/artifacts/changes/CHNG-XXX/proposal.md, when starting implementation of a documented feature, or when the user asks to verify implementation against a spec or update a spec after changes.
---

# Spec-Driven Development

Specs live in `backbone/artifacts/changes/CHNG-XXX/` with collocated proposal.md (product requirements), design.md (architecture), and tasks.md (implementation breakdown). They are the source of truth for architectural decisions, API contracts, and implementation scope.

## Core Loop

```
Read spec → Implement → Verify alignment → Update spec or code → Repeat
```

## Hierarchy of Technical Impact

Before writing code, know which level needs the most clarity. Derived from [The Three Layers Before Claude Code](https://thebrokentelephone.com/articles/three-layers-before-claude-code/).

| Level | What | Visibility | Cost of Error | How to Handle in Specs |
|-------|------|------------|---------------|------------------------|
| 1 — Foundation | Entities, business logic, integration contracts | Low | **Critical** | Define completely before any code. Ambiguity here = exponential token tax. |
| 2 — Behavior | Flows, states, edge cases | Medium | Medium | Sketch the happy path + 2-3 critical edge cases. Iterate in code. |
| 3 — Aesthetics | Colors, copy, spacing, naming | High | Low | Placeholder or TODO. Fix in one line later. |

**The AI Cascade Effect:** A wrong data model or API contract (Level 1) doesn't just break one file — it poisons every query, every test, and every subsequent prompt that references it. The cost isn't the initial mistake; it's the 20 follow-up prompts explaining why the fix for the fix needs another fix.

**The rule:** If the spec is ambiguous about entities, contracts, or business rules, **stop and clarify** before generating code.

## The Gated Workflow (Addyosmani Pattern)

For new projects or significant changes, use a 4-phase gated workflow. Do not advance to the next phase until the current one is validated.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

### Phase 1: Specify

Start with a high-level vision. Surface assumptions immediately.

**Assumptions template:**
```
ASSUMPTIONS I'M MAKING:
1. This is a [type of system] (not [alternative])
2. Authentication uses [mechanism] (not [alternative])
3. The database is [type] (based on existing schema)
4. We're targeting [environment]
→ Correct me now or I'll proceed with these.
```

**Write a spec covering these areas:**
1. **Objective** — What are we building and why? Who is the user? What does success look like?
2. **Commands** — Full executable commands with flags (`npm test`, `./gradlew test`, etc.)
3. **Project Structure** — Where source code lives, where tests go
4. **Code Style** — One real code snippet showing conventions
5. **Testing Strategy** — Framework, test locations, coverage expectations
6. **Boundaries** — Three-tier system:
   - **Always do:** Run tests before commits, follow naming conventions, validate inputs
   - **Ask first:** Schema changes, adding dependencies, changing CI config
   - **Never do:** Commit secrets, edit vendor directories, remove failing tests without approval

**Reframe vague requirements as success criteria:**
```
REQUIREMENT: "Make the dashboard faster"

REFRAMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

### Phase 2: Plan

Generate a technical implementation plan:
1. Identify major components and dependencies
2. Determine implementation order (bottom-up)
3. Note risks and mitigation strategies
4. Identify what can be parallelized
5. Define verification checkpoints

### Phase 3: Tasks

Break the plan into discrete tasks:
- Each completable in a single focused session
- Each with explicit acceptance criteria
- Each with a verification step (test, build, manual check)
- Ordered by dependency
- No task touches more than ~5 files

**Task sizing:**
| Size | Files | Scope |
|------|-------|-------|
| XS | 1 | Single function/config |
| S | 1-2 | One component/endpoint |
| M | 3-5 | One feature slice |
| L | 5-8 | Multi-component |
| XL | 8+ | **Too large — break down** |

### Phase 4: Implement

Execute tasks one at a time following `incremental-implementation` and `test-driven-development` skills.

## Before Starting Work

1. **Find the spec.** For feature `feature-name`:
   ```bash
   ls backbone/artifacts/changes/CHNG-*/proposal.md
   ls backbone/artifacts/changes/CHNG-*/tasks.md
   ```

2. **Read the full spec.** Understand scope, decisions, API contracts, and open questions before writing code.

3. **If no spec exists** and the task is non-trivial (new module, new API, architectural change), ask the user whether to create one first.

## During Implementation

- **Reference spec decisions** — don't re-decide what the spec already settled.
- **When you diverge from the spec** (better approach found, user requested change, constraint discovered), update the spec immediately in the same session. Don't leave spec and code out of sync.
- **Tick off TODO checkboxes** (`- [ ]` → `- [x]`) as items are completed.
- **Strike through or annotate** items that were deliberately skipped or replaced:
  ```markdown
  - [x] ~~Old approach~~ → New approach: direct execution
  ```

## After Completing Work

Run a spec verification pass:

1. **Re-read the spec** alongside the implementation.
2. **Check each section:**
   - Do API endpoints in spec match the controller?
   - Do config/env vars in spec match the actual config?
   - Does the file structure in spec match the actual file tree?
   - Are all TODO items correctly checked/unchecked?
3. **Update the spec** for any drift found. Common drift:
   - New files added that aren't listed in the structure section
   - API response shapes changed during implementation
   - Config defaults adjusted
   - Architectural decisions refined
4. **Flag unresolved gaps** to the user — things the spec promises but implementation doesn't deliver yet.

## Verification Report Template

When the user asks to "verify" or "self-review":

```
Aligned:
- [list items where spec and code match]

Drift (fixed):
- [list items where they diverged, with fixes applied]

Gaps (future work):
- [list spec items not yet implemented]
```

## Keeping the Spec Alive

The spec is a living document:
- **Update when decisions change** — update spec first, then implement
- **Update when scope changes** — features added or cut reflected in spec
- **Commit the spec** — belongs in version control alongside code
- **Reference spec in PRs** — link to spec section each PR implements

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need *long* specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is in forcing clarity *before* code. |
| "The spec will slow us down" | A 15-minute spec prevents hours of rework. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"
