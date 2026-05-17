<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: idea-refine
description: Refines raw ideas into sharp, actionable concepts through structured divergent and convergent thinking. Use when you have a vague concept that needs exploration before spec work.
---

# Idea Refine

Refines raw ideas into sharp, actionable concepts worth building. The output feeds directly into `grill-me` or `spec-driven-development`.

## When to Use

- You have a rough concept that needs exploration
- Before writing a spec — clarify direction first
- When the user says "I have an idea" or "What if we..."
- When requirements feel fuzzy or ambiguous

## Process

### Phase 1: Understand & Expand (Divergent)

**Goal:** Open up the idea.

1. **Restate as "How Might We"** problem statement:
   > "How might we [solve this problem] for [user] so that [outcome]?"

2. **Ask 3-5 sharpening questions:**
   - Who is this for, specifically?
   - What does success look like?
   - What are the real constraints (time, tech, resources)?
   - What's been tried before?
   - Why now?

3. **Generate 5-8 variations** using lenses:
   - **Inversion:** What if we did the opposite?
   - **Constraint removal:** What if budget/time weren't factors?
   - **Audience shift:** What if this were for a different user?
   - **Combination:** What if we merged this with an adjacent idea?
   - **Simplification:** What's the 10x simpler version?
   - **10x version:** What would this look like at massive scale?

**If in a codebase:** Explore existing architecture, patterns, prior art.

### Phase 2: Evaluate & Converge

1. **Cluster** resonant ideas into 2-3 distinct directions
2. **Stress-test** each against:
   - **User value:** Painkiller or vitamin?
   - **Feasibility:** What's the hardest part?
   - **Differentiation:** Would someone switch?
3. **Surface hidden assumptions:**
   - What are you betting is true but haven't validated?
   - What could kill this idea?
   - What are you choosing to ignore (and why)?

### Phase 3: Sharpen & Ship

Produce a markdown one-pager:

```markdown
# [Idea Name]

## Problem Statement
[One-sentence "How Might We" framing]

## Recommended Direction
[The chosen direction and why — 2-3 paragraphs]

## Key Assumptions to Validate
- [ ] [Assumption 1 — how to test it]
- [ ] [Assumption 2 — how to test it]

## MVP Scope
[Minimum version that tests the core assumption]

## Not Doing (and Why)
- [Thing 1] — [reason]
- [Thing 2] — [reason]

## Open Questions
- [Question needing answering before building]
```

## Anti-patterns

❌ **20+ shallow variations** → Quality over quantity
❌ **Skipping "who is this for"** → Every idea starts with a person and their problem
❌ **No assumptions surfaced** → Untested assumptions are the #1 killer
❌ **Yes-machining weak ideas** → Push back with specificity and kindness
❌ **No "Not Doing" list** → Focus is about saying no to good ideas

## Verification

- [ ] Clear "How Might We" problem statement exists
- [ ] Target user and success criteria defined
- [ ] Multiple directions explored, not just the first idea
- [ ] Hidden assumptions explicitly listed
- [ ] "Not Doing" list makes trade-offs explicit
- [ ] User confirmed final direction before spec work
