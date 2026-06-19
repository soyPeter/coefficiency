---
name: "Create a Product Requirements Document"
description: "Create comprehensive PRDs with 8-section template, EARS requirements, and traceability. Supports interview-based (Mode A) and synthesized (Mode B) workflows."
framework: "general"
---
<!-- FRAMEWORK: GENERAL -->
# Create a Product Requirements Document

## Purpose

You are an experienced product manager responsible for creating a comprehensive Product Requirements Document (PRD) for a feature or product. This document serves as the authoritative specification, aligning stakeholders and guiding development.

## When to Use

- Before starting any non-trivial feature (new capability, architectural change, user-facing change)
- When a task in `3-TASKS.md` lacks a PRD reference
- When the `pre-tool-use-skill-check.sh` hook or `8-WORKFLOW.md` asks for a PRD

## Prerequisites: Grill Before PRD

**Mandatory for feature work**: Before creating a PRD, you MUST use the `grill-me` skill.

1. Load the skill: `view backbone/skills/general/grill-me/SKILL.md`
2. Grill the user on scope, boundaries, data model, API, edge cases
3. Only after grilling is complete, create the PRD
4. Add `grilled: true` to the PRD frontmatter

**Exemptions**: fix, bug, docs, refactor, chore, test tasks do not require grilling.

## Two Modes

### Mode A: Structured PRD (Interview-Based)

Use when you have limited context and need to gather requirements from the user.

1. **Gather Information**: Read existing files, search for related PRDs, ask clarifying questions.

2. **Think Step by Step**:
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
   - Key Results: How will you measure success? (Use SMART format)

   **5. Market Segment(s)**
   - For whom are we building this?
   - What constraints exist?

   **6. Value Proposition(s)**
   - What customer jobs/needs are we addressing?
   - What will customers gain?
   - Which pains will they avoid?

   **7. Solution**
   - 7.1 UX/Prototypes (wireframes, user flows)
   - 7.2 Key Features (detailed feature descriptions)
   - 7.3 Technology (optional)
   - 7.4 Assumptions

   **8. Release**
   - What goes in the first version vs. future versions?
   - Relative timeframes (avoid exact dates)

4. **Add EARS Requirements Section** (after Section 7):
   
   **9. Requirements**
   - List all requirements in EARS format
   - Use `REQ-<DOMAIN>-<NNN>` IDs
   - One SHALL per requirement
   - Group by feature area

   Example:
   ```markdown
   ### REQ-AUTH-001: User Authentication
   WHEN the user provides valid credentials, the system SHALL authenticate the user.

   ### REQ-AUTH-002: Session Management
   WHILE the user session is active, the system SHALL refresh the access token every 15 minutes.
   ```

5. **Use Accessible Language**: Write for a primary school graduate. Avoid jargon.

6. **Save the Output**: Save as `backbone/artifacts/changes/CHNG-XXX/proposal.md`

### Mode B: Synthesized PRD (Context-Based)

Use when you already have rich context from a conversation or existing documents. Do NOT interview the user — synthesize what you already know.

**Process:**

1. **Explore the repo** if not already done. Use domain glossary vocabulary and respect ADRs.

2. **Sketch major modules**. Look for deep module opportunities.

3. **Write the PRD** using this template:

```markdown
## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

1. As an <actor>, I want a <feature>, so that <benefit>

## Implementation Decisions

- Modules to build/modify
- Interfaces of those modules
- Technical clarifications
- Architectural decisions
- API contracts

(Do NOT include specific file paths or code snippets.)

## Testing Decisions

- What makes a good test
- Which modules will be tested

## EARS Requirements

REQ-XXX-001: WHEN <event>, the system SHALL <response>.
REQ-XXX-002: WHILE <state>, the system SHALL <response>.

## Out of Scope

What this PRD explicitly does NOT cover.

## Further Notes

Any additional context.
```

4. **Publish** the proposal to `backbone/artifacts/changes/CHNG-XXX/proposal.md` and reference it from [[`backbone/3-TASKS.md`](backbone/3-TASKS.md)](backbone/3-TASKS.md).

## PRD Template with Grilling Section

Feature PRDs MUST include a `## Grilling` section. Here is the full template:

```markdown
---
grilled: true
---

# <Feature Name>

## Summary
2-3 sentences about the feature.

## Background
Why this feature? What changed?

## Objective
What are we trying to achieve?

## Solution
Key features and technical approach.

## Grilling

### Scope
- **Q:** What exactly should this feature do?
- **A:** [specific answer]
- **Q:** What should it NOT do?
- **A:** [specific answer]
- **Q:** What's the smallest slice that would be valuable?
- **A:** [specific answer]

### Boundaries
- **Q:** What are the integration points with existing code?
- **A:** [specific answer]
- **Q:** Which modules will this touch?
- **A:** [specific answer]
- **Q:** Are there parts we should NOT modify?
- **A:** [specific answer]

### Data & State
- **Q:** What new data structures are needed?
- **A:** [specific answer]
- **Q:** Where does state live?
- **A:** [specific answer]
- **Q:** What are the read/write patterns?
- **A:** [specific answer]

### API
- **Q:** What are the request/response schemas?
- **A:** [specific answer]
- **Q:** What endpoints or interfaces are needed?
- **A:** [specific answer]
- **Q:** How is authentication/authorization handled?
- **A:** [specific answer]

### Implementation Order
- **Q:** What's the first vertical slice?
- **A:** [specific answer]
- **Q:** What are the dependencies between slices?
- **A:** [specific answer]
- **Q:** What are the highest-risk parts?
- **A:** [specific answer]

## Requirements

### REQ-XXX-001: Feature Name
WHEN <event>, the system SHALL <response>.

## Out of Scope
What this PRD explicitly does NOT cover.

## Further Notes
Any additional context.
```

**Rules:**
- ALL 5 branches MUST be present in the Grilling section
- Each branch MUST have at least 2 Q/A pairs (4 lines minimum)
- Answers MUST be specific — "we'll figure it out" is not acceptable

## PRD Storage Convention

- **Location:** `backbone/artifacts/changes/CHNG-XXX/proposal.md`
- **Frontmatter (required for feature PRDs):**
  ```markdown
  ---
  grilled: true
  ---
  ```
- **Grilling section (required for feature PRDs):** `## Grilling` with all 5 branches
- **Index:** Add entry to [`backbone/1-PRD.md`](backbone/1-PRD.md) (or link from change folder)
- **Task reference:** Link from `backbone/3-TASKS.md`:
  ```markdown
   - [ ] [S] feat: Add OAuth login (PRD: backbone/artifacts/changes/archive/prd/20260424-oauth.md)
  ```

## Notes

- **Mode A** is for green-field planning with user input
- **Mode B** is for post-grilling synthesis when context is already rich
- Be specific and data-driven where possible
- Flag assumptions clearly so the team can validate them
- Keep the document concise but complete
