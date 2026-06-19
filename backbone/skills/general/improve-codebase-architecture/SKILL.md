<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: improve-codebase-architecture
description: Find deepening opportunities in a codebase — refactors that turn shallow modules into deep ones. Use when codebase feels messy, before major refactors, or as periodic architecture hygiene (recommended: bi-weekly).
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability, AI-navigability, and long-term maintainability.

## When to Use

- Codebase feels like a "ball of mud" or hard to change
- Before starting a major refactor
- Periodic architecture hygiene (recommended: bi-weekly)
- User says "improve architecture", "find refactoring opportunities", "this is too complex"

## Glossary

Use these terms exactly. Consistent language is the whole point. Full definitions in [backbone/knowledge/LANGUAGE.md](../../../knowledge/LANGUAGE.md).

| Term | Meaning | Avoid |
|------|---------|-------|
| **Module** | Anything with an interface and implementation (function, class, package) | unit, component, service |
| **Interface** | Everything a caller must know: types, invariants, error modes, ordering, config | API, signature |
| **Depth** | A lot of behaviour behind a small interface | — |
| **Shallow** | Interface nearly as complex as the implementation | — |
| **Seam** | Where an interface lives; place behaviour can be altered without editing in place | boundary |
| **Adapter** | Concrete thing satisfying an interface at a seam | implementation |
| **Leverage** | What callers get from depth | — |
| **Locality** | What maintainers get from depth | — |

**Key principles:**
- **Deletion test**: deleting a module — if complexity vanishes, it was a pass-through; if complexity reappears across N callers, it was earning its keep
- **The interface is the test surface**
- **One adapter = hypothetical seam. Two adapters = real seam.**

## Process

### 1. Explore

Read the project's domain glossary (`backbone/CONTEXT.md`) and ADRs first. Then explore the codebase using a subagent or your own exploration.

Look for friction:
- Understanding one concept requires bouncing between many small modules?
- Modules are **shallow** — interface nearly as complex as implementation?
- Pure functions extracted just for testability, but real bugs hide in how they're called?
- Tightly-coupled modules leak across their seams?
- Parts untested or hard to test through current interface?

Apply the **deletion test** to anything suspicious.

### 2. Present Candidates

Present a numbered list of deepening opportunities. For each:

- **Files** — which files/modules are involved
- **Problem** — why current architecture causes friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality, leverage, and testability

**Use `CONTEXT.md` vocabulary for the domain, and LANGUAGE.md vocabulary for architecture.**

**ADR conflicts**: If a candidate contradicts an existing ADR, only surface it when friction is real enough to warrant revisiting. Mark clearly: _"Contradicts ADR-0007 — but worth reopening because…"_

**Do NOT propose interfaces yet.** Ask: "Which of these would you like to explore?"

### 3. Grilling Loop

Once the user picks a candidate, drop into a grilling conversation (`grill-me` / `grill-with-docs`):

- Walk the design tree: constraints, dependencies, shape of deepened module
- What sits behind the seam, what tests survive
- Update `CONTEXT.md` inline for new terms
- Offer ADRs for load-bearing rejections
- Explore alternative interfaces with [backbone/knowledge/INTERFACE-DESIGN.md](../../../knowledge/INTERFACE-DESIGN.md)

## Example Output

```markdown
## Architecture Review: 3 Deepening Opportunities

### 1. Consolidate validation scattered across controllers
**Files:** `AuthController.java`, `UserController.java`, `OrderController.java`
**Problem:** Each controller has its own validation logic. Adding a new field 
requires touching N controllers. The seam is at the wrong level.
**Solution:** Extract a single `ValidationModule` at the domain boundary. 
Controllers pass raw input; the module returns validated domain objects.
**Benefits:**
- Locality: validation rules live in one place
- Leverage: one test suite covers all validation paths
- Depth: controllers' interface shrinks to "receive validated object"

### 2. Deepen the OrderRepository seam
**Files:** `OrderRepository.java`, `OrderService.java`, `OrderController.java`
**Problem:** Repository exposes raw CRUD. Business logic leaks into Service 
and Controller. Repository is shallow.
**Solution:** Repository interface should expose domain operations: 
`placeOrder()`, `cancelOrder()`, `fulfillOrder()`. Implementation handles 
persistence, but callers don't know HOW.
**Benefits:**
- Locality: order state transitions in one place
- Leverage: callers get complex behaviour through simple interface
- Depth: interface is 3 methods instead of N CRUD operations
```

## Integration with Backbone Workflow

- **Periodic review:** Run every 2 weeks, or when codebase complexity spikes
- **Before major features:** Run to identify if the feature will make existing shallow modules worse
- **After grilling:** Use `grill-with-docs` to document any new terms or ADRs

## Anti-patterns

❌ **Proposing interfaces prematurely** → Present candidates first, let user pick
❌ **Ignoring ADRs** → Respect existing decisions unless friction is real
❌ **Using generic terms** → "service", "component", "boundary" → use module/seam/adapter
❌ **Theoretical refactors** → Only suggest what you've observed in the code

✅ **Concrete evidence** → "I found X in these 3 files"
✅ **Deletion test** → "If we deleted Y, complexity would vanish → it's a pass-through"
✅ **Domain vocabulary** → "The Order intake module" not "the FooBarHandler"
✅ **Focus on depth** → Interface simplicity, not implementation elegance
