<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: create-prd
description: "Create a Product Requirements Document using a comprehensive 8-section template covering problem, objectives, segments, value propositions, solution, and release planning. Use when writing a PRD, documenting product requirements, preparing a feature spec, or reviewing an existing PRD."
---

# Create a Product Requirements Document

## Purpose

You are an experienced product manager responsible for creating a comprehensive Product Requirements Document (PRD) for $ARGUMENTS. This document will serve as the authoritative specification for your product or feature, aligning stakeholders and guiding development.

## Context

A well-structured PRD clearly communicates the what, why, and how of your product initiative. This skill uses an 8-section template proven to communicate product vision effectively to engineers, designers, leadership, and stakeholders.

## Two Modes

### Mode A: Structured PRD (Interview-Based)

Use when you have limited context and need to gather requirements from the user.

1. **Gather Information**: If the user provides files, read them carefully. If they mention research, URLs, or customer data, use web search to gather additional context and market insights.

2. **Think Step by Step**: Before writing, analyze:
   - What problem are we solving?
   - Who are we solving it for?
   - How will we measure success?
   - What are our constraints and assumptions?

3. **Apply the PRD Template**: Create a document with these 8 sections:

   **1. Summary** (2-3 sentences)
   - What is this document about?

   **2. Contacts**
   - Name, role, and comment for key stakeholders

   **3. Background**
   - Context: What is this initiative about?
   - Why now? Has something changed?
   - Is this something that just recently became possible?

   **4. Objective**
   - What's the objective? Why does it matter?
   - How will it benefit the company and customers?
   - How does it align with vision and strategy?
   - Key Results: How will you measure success? (Use SMART OKR format)

   **5. Market Segment(s)**
   - For whom are we building this?
   - What constraints exist?
   - Note: Markets are defined by people's problems/jobs, not demographics

   **6. Value Proposition(s)**
   - What customer jobs/needs are we addressing?
   - What will customers gain?
   - Which pains will they avoid?
   - Which problems do we solve better than competitors?
   - Consider the Value Curve framework

   **7. Solution**
   - 7.1 UX/Prototypes (wireframes, user flows)
   - 7.2 Key Features (detailed feature descriptions)
   - 7.3 Technology (optional, only if relevant)
   - 7.4 Assumptions (what we believe but haven't proven)

   **8. Release**
   - How long could it take?
   - What goes in the first version vs. future versions?
   - Avoid exact dates; use relative timeframes

4. **Use Accessible Language**: Write for a primary school graduate. Avoid jargon. Use clear, short sentences.

5. **Structure Output**: Present the PRD as a well-formatted markdown document with clear headings and sections.

6. **Save the Output**: If the PRD is substantial (which it will be), save it as a markdown document in the format: `PRD-[product-name].md`

### Mode B: Synthesized PRD (Context-Based)

Use when you already have rich context from a conversation (`grill-me`, `grill-with-docs`). Do NOT interview the user — synthesize what you already know.

**Process:**

1. **Explore the repo** (if not already done). Use the project's domain glossary vocabulary and respect ADRs.

2. **Sketch major modules**. Actively look for deep module opportunities — modules that encapsulate a lot of functionality in a simple, testable interface.
   - Check with the user that these modules match their expectations
   - Check which modules need tests

3. **Write the PRD** using the template below:

#### Synthesis PRD Template

```markdown
## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

Cover ALL aspects of the feature extensively.

## Implementation Decisions

- Modules to build/modify
- Interfaces of those modules
- Technical clarifications
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

(Do NOT include specific file paths or code snippets.)

## Testing Decisions

- What makes a good test (external behavior, not implementation details)
- Which modules will be tested
- Prior art for tests

## Out of Scope

What this PRD explicitly does NOT cover.

## Further Notes

Any additional context.
```

4. **Publish** the proposal to `backbone/artifacts/changes/CHNG-XXX/proposal.md` and reference it from [`backbone/3-TASKS.md`](backbone/3-TASKS.md).

## Notes

- **Mode A** is for green-field planning with user input
- **Mode B** is for post-grilling synthesis when context is already rich
- Be specific and data-driven where possible
- Link each section back to the overall strategy
- Flag assumptions clearly so the team can validate them
- Keep the document concise but complete

---

### Further Reading

- [How to Write a Product Requirements Document? The Best PRD Template.](https://www.productcompass.pm/p/prd-template)
- [A Proven AI PRD Template by Miqdad Jaffer (Product Lead @ OpenAI)](https://www.productcompass.pm/p/ai-prd-template)
