<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: grill-me
description: Socratic questioning to stress-test a plan or design before implementation. Use when user wants to "grill me", stress-test a plan, get challenged on their design, or before starting any non-trivial feature work. When in doubt, grill first.
---

# Grill Me: Socratic Planning

Interview the user relentlessly about a plan or design until reaching shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one.

## When to Use

**Always grill before building when:**
- Starting a new feature or module
- Making architectural changes
- Any task where requirements feel fuzzy or ambiguous
- User says "grill me" or wants to stress-test a plan

**You may skip grilling when:**
- Fixing a clear, well-specified bug
- Updating documentation
- Refactoring with no behavior change
- The change touches ≤3 lines in one file

## How to Grill

### 1. Ask questions one at a time

Wait for feedback on each question before continuing. Don't batch questions — the user needs to think through each branch.

### 2. Provide a recommended answer

For each question, offer your recommended answer based on codebase exploration, conventions, or best practices. The user can accept it, modify it, or reject it.

### 3. Walk the decision tree

Resolve dependencies between decisions one-by-one:

```
Scope → Boundaries → Data model → API → Implementation order
```

Don't skip ahead. If the scope isn't clear, don't talk about implementation.

### 4. Explore instead of asking

If a question can be answered by exploring the codebase, explore it instead of asking. For example: "What does the current auth middleware do?" → explore the middleware code.

### 5. Flag ambiguity

When you detect ambiguity, name it explicitly: "I'm unclear on whether X or Y — let's resolve this before proceeding."

## Sample Questions by Topic

### Scope
- What exactly should this feature do? What should it NOT do?
- What's the smallest slice that would be valuable?
- Are there existing features this replaces or extends?

### Boundaries
- What are the integration points with existing code?
- Which modules will this touch?
- Are there parts we should NOT modify?

### Data & State
- What new data structures are needed?
- Where does state live?
- What are the read/write patterns?

### Edge Cases
- What happens when [common failure mode]?
- How should partial failures be handled?
- What are the concurrency/ordering concerns?

### Testing
- What's the most critical behavior to verify?
- Are there existing tests we can build on?
- What would a minimal tracer-bullet test look like?

## Output: Grilling Section in PRD

After grilling, the agent MUST write a **Grilling** section inside the PRD itself (before the Requirements section). This section is the audit trail proving all branches were covered.

### Required Format

```markdown
## Grilling

### Scope
- **Q:** What exactly should this feature do?
- **A:** [Answer]
- **Q:** What should it NOT do?
- **A:** [Answer]
- **Q:** What's the smallest slice that would be valuable?
- **A:** [Answer]

### Boundaries
- **Q:** What are the integration points with existing code?
- **A:** [Answer]
- **Q:** Which modules will this touch?
- **A:** [Answer]
- **Q:** Are there parts we should NOT modify?
- **A:** [Answer]

### Data & State
- **Q:** What new data structures are needed?
- **A:** [Answer]
- **Q:** Where does state live?
- **A:** [Answer]
- **Q:** What are the read/write patterns?
- **A:** [Answer]

### API
- **Q:** What are the request/response schemas?
- **A:** [Answer]
- **Q:** What endpoints or interfaces are needed?
- **A:** [Answer]
- **Q:** How is authentication/authorization handled?
- **A:** [Answer]

### Implementation Order
- **Q:** What's the first vertical slice?
- **A:** [Answer]
- **Q:** What are the dependencies between slices?
- **A:** [Answer]
- **Q:** What are the highest-risk parts?
- **A:** [Answer]
```

### Rules
- **ALL 5 branches MUST be present** — missing a branch means the PRD is incomplete
- **Each branch MUST have at least 2 Q/A pairs** — one question is not enough
- **Answers MUST be specific** — "we'll figure it out" is not an answer
- **Ambiguities MUST be flagged** — if a question can't be answered, note it as unresolved

### Mechanical Enforcement
- `pre-tool-use-grill-check.sh` blocks PRDs without a complete Grilling section
- It checks for all 5 branch headings (`### Scope`, `### Boundaries`, `### Data`, `### API`, `### Implementation`)
- It verifies each branch has at least 2 Q/A pairs

## Integration with Backbone Workflow

After grilling, the natural next steps are:

1. **`grill-with-docs`** — If the feature is complex and domain terminology needs clarification
2. **`to-prd`** — Synthesize the conversation into a PRD (including the Grilling section)
3. **`to-issues`** — Break the PRD into vertical slice issues

## Integration with 3-TASKS.md

If grilling reveals the task is larger than expected:
- Update [`backbone/3-TASKS.md`](backbone/3-TASKS.md) with the clarified scope
- Mark the original task as `[x]` if it was a placeholder
- Create new, more granular tasks

## Example Session

```
User: "I want to add caching to the dev portal"

Agent: "Scope question first: do you want to cache the build output, 
        the runtime API responses, or both?"

User: "Runtime API responses"

Agent: "Got it. Next: what's the cache key strategy? 
        Per-endpoint, or per-user+endpoint? 
        [Recommended: per-endpoint with a short TTL 
         since the data is mostly static]"

[... continues until all branches resolved ...]

Agent: "Great, we have clarity. Let me synthesize this into a PRD."
```

## Anti-patterns

❌ **Asking 5 questions at once** → User can't think through all branches simultaneously
❌ **Accepting vague answers** → "It should be fast" → ask: how fast? measured how?
❌ **Skipping to implementation** → Don't suggest code until the decision tree is resolved
❌ **Assuming you know best** → Offer recommendations, but let the user decide

✅ **One question at a time** → Maximum clarity per branch
✅ **Concrete scenarios** → "What happens when 2 users edit simultaneously?"
✅ **Code exploration** → "Let me check how this is currently done..."
✅ **Summarize before moving on** → "So we've agreed: X for scope, Y for boundaries"
