---
name: backbone:plan
description: Plan a new feature with PRD → task breakdown → verification checklist. Follows spec-driven development workflow.
argument-hint: "<feature-name> [--framework=<fw>] [--epic=<M#>]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

<objective>
Plan a new feature for the Agentic Backbone generator following formal spec-driven development.

**When to use:**
- Starting a new feature
- Adding a new template type
- Implementing a new dev portal page
- Adding new agent capabilities

**Output:**
- `backbone/prd/2026XXXXX-feature.md` — Product Requirements Document
- `backbone/planning/2026XXXXX-feature.md` — Implementation Plan
- Entries in `backbone/3-TASKS.md` — Task tracking
- Verification checklist

**Workflow:**
PRD → Planning → Task Breakdown → Verification Criteria
</objective>

<process>
1. **Gather Requirements** (AskUserQuestion)
   - Feature name and one-line description
   - Problem being solved
   - Who benefits (user persona)
   - Must-have vs nice-to-have
   - Estimated complexity (small/medium/large)

2. **Generate Feature Slug**
   - Lowercase, hyphens, max 30 chars
   - Example: "Node.js Service Template" → "nodejs-service-template"

3. **Create PRD**
   - File: `backbone/prd/2026MMDD-{slug}.md`
   - Sections:
     1. Problem Statement
     2. Objectives & Success Metrics (SMART)
     3. Solution (high-level)
     4. Release Timeline
     5. Success Criteria
   - Use existing PRD as template
   - Fill with gathered requirements

4. **Create Implementation Plan**
   - File: `backbone/planning/2026MMDD-{slug}.md`
   - Reference PRD file
   - Task breakdown with phases
   - Dependencies between phases
   - Definition of Done per phase

5. **Update 3-TASKS.md**
   - Add new milestone/phase under appropriate epic
   - Mark as [WIP] if starting immediately
   - Reference PRD in task description

6. **Update PRD Index**
   - Add entry to `backbone/prd/index.md`

7. **Verification Checklist**
   - Does PRD have all required sections?
   - Are success metrics measurable?
   - Are tasks granular enough (< 1 day each)?
   - Does plan reference the PRD?
   - Are dependencies identified?

8. **Present Summary**
   ```
   ✅ Feature Planned: {feature-name}
   
   Files created:
     - backbone/prd/2026MMDD-{slug}.md
     - backbone/planning/2026MMDD-{slug}.md
   
   Tasks added:
     - Phase X: {description} (PRD: backbone/prd/2026MMDD-{slug}.md)
   
   Next steps:
     - Read the PRD thoroughly
     - Begin implementation with /backbone:quick or /backbone:debug
   ```
</process>

<success_criteria>
- [ ] Requirements gathered via AskUserQuestion
- [ ] PRD created with all required sections
- [ ] Implementation plan references PRD
- [ ] 3-TASKS.md updated with new tasks
- [ ] PRD index updated
- [ ] Verification checklist completed
</success_criteria>
