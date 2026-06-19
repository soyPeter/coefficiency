<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable issues using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work.
---

# To Issues: Vertical Slice Decomposition

Break a plan, PRD, or spec into independently-grabbable issues using **tracer-bullet vertical slices**. Each slice cuts through ALL integration layers end-to-end, NOT a horizontal layer.

## When to Use

- After creating a PRD (`create-prd` or `to-prd`)
- User says "break this into tickets" or "create issues"
- Preparing work for a sprint or for agents to pick up
- Any plan needs to become actionable work items

## Process

### 1. Gather Context

Work from whatever is already in the conversation. If the user references an issue, PRD file, or plan document, read it fully.

### 2. Explore the Codebase (Optional)

If you haven't explored the codebase, do so to understand current state. Issue titles and descriptions should use the project's domain glossary vocabulary and respect ADRs in the area.

### 3. Draft Vertical Slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL layers end-to-end.

**Vertical Slice Rules:**
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- **Avoid horizontal slices**: "set up database", "create API", "build UI" — these are NOT slices

**Slice Types:**
- **HITL** — requires human interaction (architectural decisions, design reviews, security sign-off)
- **AFK** — can be implemented and merged without human interaction

Prefer AFK over HITL where possible.

### 4. Quiz the User

Present the proposed breakdown as a numbered list:

```
1. **[Slice title]** (AFK)
   - What: concise description of end-to-end behavior
   - Blocked by: none
   - User stories covered: #1, #3

2. **[Slice title]** (HITL)
   - What: ...
   - Blocked by: #1
   - User stories covered: #2
```

Ask:
- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split?
- Are the correct slices marked as HITL/AFK?

Iterate until the user approves.

### 5. Publish

For backbone generator projects, publish issues to [`backbone/3-TASKS.md`](backbone/3-TASKS.md) under the relevant milestone.

For generated projects with GitHub:
- Publish each approved slice as a GitHub issue
- Use the issue template below
- Apply the `needs-triage` label
- Publish in dependency order (blockers first)

**Issue Template:**
```markdown
## Parent
Reference to the parent PRD or issue.

## What to Build
A concise description of this vertical slice. Describe the end-to-end 
behavior, not layer-by-layer implementation.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked By
- Issue #X (or "None - can start immediately")
```

## Example: Adding User Authentication

**Bad (horizontal):**
```
1. Set up auth database tables
2. Create login API endpoint
3. Build login UI
4. Add tests
```

**Good (vertical slices):**
```
1. **[Tracer] Basic email/password login** (AFK)
   - Database: users table with email, password_hash
   - API: POST /login returns JWT
   - UI: login form with email/password fields
   - Tests: happy path + invalid credentials
   - Blocked by: none

2. **[Tracer] Registration flow** (AFK)
   - Database: insert user with hashed password
   - API: POST /register
   - UI: registration form
   - Tests: duplicate email, weak password
   - Blocked by: #1

3. **[Tracer] Password reset** (AFK)
   - Database: reset_tokens table
   - API: POST /forgot-password, POST /reset-password
   - UI: forgot password form, reset link page
   - Tests: expired token, valid token
   - Blocked by: #2
```

## Integration with Backbone Workflow

```
grill-me / grill-with-docs
       ↓
   to-prd (synthesize into PRD)
       ↓
  to-issues (break into slices)
       ↓
  issue-triage / triage (manage lifecycle)
       ↓
  Implementation (spec-driven-development)
```

## Anti-patterns

❌ **Horizontal slices** — "build database", "create API", "make UI" → No single slice is demoable
❌ **One giant issue** — "Implement user auth" → Too big, unclear when done
❌ **No acceptance criteria** — Can't tell when a slice is complete
❌ **Wrong HITL/AFK** — Marking design decisions as AFK or trivial refactors as HITL

✅ **Thin and vertical** — Each slice is a complete, demoable thread
✅ **Many small over few big** — Easier to parallelize and track
✅ **Clear acceptance criteria** — "When I do X, I see Y"
✅ **Dependency order** — Blockers first, so issue numbers exist for references
