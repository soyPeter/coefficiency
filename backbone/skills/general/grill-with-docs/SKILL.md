<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: grill-with-docs
description: Grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates CONTEXT.md and ADRs inline as decisions crystallise. Use when user wants to stress-test a plan against their project's language and documented decisions.
---

# Grill with Docs: Domain-Aware Planning

Extends `grill-me` with documentation discipline. While grilling the user about a plan, this skill challenges against the existing domain model, sharpens terminology, and captures decisions in `CONTEXT.md` and ADRs in real-time.

## When to Use

- Before planning complex features with domain-specific terminology
- When the codebase has an existing `CONTEXT.md` or glossary
- When architectural decisions need to be recorded
- When the user says "grill me" and the project has domain complexity

## Prerequisites

- The project should have (or will create) a `backbone/CONTEXT.md`
- ADR directory lives at `backbone/reference/patterns/adr/` (backbone convention) or `docs/adr/`

## How It Works

### 1. Standard Grilling

Same as `grill-me`: ask questions one at a time, wait for feedback, resolve dependencies.

### 2. Explore Existing Documentation

During codebase exploration, also look for existing documentation:

**Single context (most repos):**
```
/
├── backbone/
│   ├── CONTEXT.md          ← domain glossary
│   └── decisions/          ← ADRs
└── src/
```

**Multiple contexts (rare):**
```
/
├── backbone/
│   ├── CONTEXT-MAP.md      ← lists multiple contexts
│   └── decisions/
└── src/
    ├── ordering/
    │   └── CONTEXT.md
    └── billing/
        └── CONTEXT.md
```

### 3. Challenge Against the Glossary

When the user uses a term that conflicts with `CONTEXT.md`, call it out:

> "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### 4. Sharpen Fuzzy Language

When the user uses vague or overloaded terms, propose a precise canonical term:

> "You're saying 'account' — do you mean the Customer or the User? Those are different things in our glossary."

### 5. Discuss Concrete Scenarios

Stress-test domain relationships with specific scenarios. Invent edge cases that force precision:

> "If a Customer places an Order, then cancels it before Fulfillment, does the Invoice get voided or deleted?"

### 6. Cross-Reference with Code

When the user states how something works, check whether the code agrees:

> "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### 7. Update CONTEXT.md Inline

When a term is resolved, update `CONTEXT.md` **right there**. Don't batch — capture as they happen.

Use the format in [backbone/knowledge/CONTEXT-FORMAT.md](../../../knowledge/CONTEXT-FORMAT.md).

**Rules for CONTEXT.md entries:**
- Only include domain-specific terms, not general programming concepts
- Be opinionated — pick one term, list aliases to avoid
- Flag conflicts explicitly in "Flagged ambiguities"
- Keep definitions tight: one sentence max
- Show relationships with bold term names

### 8. Offer ADRs Sparingly

Only offer to create an ADR when **all three** are true:

1. **Hard to reverse** — changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why?"
3. **Result of a real trade-off** — genuine alternatives, specific reasons for the choice

If any is missing, skip the ADR. Use the format in [backbone/knowledge/ADR-FORMAT.md](../../../knowledge/ADR-FORMAT.md).

**Backbone convention:** ADRs live in `backbone/reference/patterns/adr/` (not `docs/adr/`), using sequential numbering: `NNN-slug.md`.

## Integration with Backbone Workflow

After `grill-with-docs`, the workflow continues:

1. **`to-prd`** — Synthesize the conversation into a PRD
2. **`to-issues`** — Break into vertical slices
3. **`spec-driven-development`** — During implementation, keep spec and code in sync

## Example Session Flow

```
User: "I want to add a refund feature"

Agent: "Before we design, let me check our domain glossary..."
[reads backbone/CONTEXT.md]

Agent: "I see we have Order, Invoice, and Customer defined. 
        But there's no term for refunds. What should we call this concept?"

User: "Let's call it a Credit"

Agent: "Got it. How does a Credit relate to an Order and Invoice?"
[updates CONTEXT.md with Credit definition and relationships]

[continues grilling...]

Agent: "So we've decided: Credits are standalone from Invoices 
        (hard to reverse — many callers assume invoice-based refunds). 
        Want me to record this as an ADR?"

User: "Yes"

Agent: [creates backbone/reference/patterns/adr/003-credits-standalone.md]
```

## Anti-patterns

❌ **Updating CONTEXT.md in bulk at the end** → Terms get lost or misremembered
❌ **Creating ADRs for obvious decisions** → "We use TypeScript" doesn't need an ADR
❌ **Coupling CONTEXT.md to implementation** → Only domain concepts, not file paths
❌ **Ignoring existing glossary** → If CONTEXT.md defines "Order", don't call it "Purchase"

✅ **Update immediately** → Capture decisions while they're hot
✅ **Be opinionated about terms** → Pick one canonical name
✅ **Challenge contradictions** → Code vs. stated behavior
✅ **ADR only for load-bearing decisions** → Skip trivial or reversible ones
