---
name: "Design Document Conventions"
description: "Bridge PRD and implementation with structured design documents using C4 model, ADR format, API contracts, and traceability links."
framework: "general"
---
<!-- FRAMEWORK: GENERAL -->
# Design Document Conventions

## Purpose

Bridge the gap between PRD (what) and implementation (how) with structured design documents. Design docs capture architectural decisions, system structure, and technical contracts before code is written.

## When to Use

- After PRD is approved (Gate R→D)
- Before implementation starts (Gate D→I)
- Any architectural decision that affects multiple components
- API design between services or layers

## Design Document Structure

### 1. System Context (C4 Level 1)

Describe the system boundary and external actors.

```markdown
## System Context

[Who uses this system? What external systems does it interact with?]

Actors:
- [Actor 1]: [Role]
- [Actor 2]: [Role]

External Systems:
- [System 1]: [Purpose]
```

### 2. Container Diagram (C4 Level 2)

Describe the high-level containers (apps, databases, queues).

```markdown
## Container Diagram

[Diagram or description of major containers]

Containers:
- [Container 1] (e.g., Web Application)
- [Container 2] (e.g., API Service)
- [Container 3] (e.g., Database)
```

### 3. Component Design (C4 Level 3)

Describe components within each container.

```markdown
## Component Design

### [Container Name]

Components:
- [Component 1]: [Responsibility]
- [Component 2]: [Responsibility]

Interactions:
- [Component 1] → [Component 2]: [Data/Trigger]
```

### 4. Architecture Decisions (ADR Format)

Each significant decision gets an ADR.

```markdown
## ADR-001: [Decision Title]

**Status:** Proposed / Accepted / Deprecated
**Context:** [What is the problem?]
**Decision:** [What did we decide?]
**Consequences:** [What are the tradeoffs?]
**Alternatives Considered:** [What else did we evaluate?]
```

### 5. API Contracts

Document external interfaces.

```markdown
## API Contracts

### [Endpoint/Interface Name]

**Request:**
```
[Schema or example]
```

**Response:**
```
[Schema or example]
```

**Errors:**
- [Error Code]: [Condition]
```

### 6. Data Model

Document data structures and relationships.

```markdown
## Data Model

### [Entity Name]

| Field | Type | Constraints |
|-------|------|-------------|
| | | |

Relationships:
- [Entity A] → [Entity B]: [Relationship type]
```

### 7. Traceability

Link back to PRD requirements.

```markdown
## Traceability

| Requirement | Design Section | Implementation |
|-------------|----------------|----------------|
| REQ-XXX-001 | Section 3.1 | [File:Line] |
```

## Design Principles

1. **No Implementation Details** — Design docs describe structure and contracts, not code.
2. **One Concern Per Section** — Each section answers one question.
3. **Diagrams Over Paragraphs** — Use C4, sequence diagrams, or ER diagrams when possible.
4. **Decision Rationale** — Every ADR explains WHY, not just WHAT.
5. **Version Controlled** — Design docs live in `backbone/design/` and are versioned with code.

## Storage Convention

- **Location:** `backbone/design/<feature>-design.md`
- **Index:** Add entry to `backbone/design/index.md`
- **Task reference:** Link from `backbone/3-TASKS.md`:
  ```markdown
  - [ ] design: Auth system architecture (Design: backbone/design/auth-design.md)
  ```

## Review Checklist (Gate D→I)

Before implementation starts:
- [ ] System context describes all actors and external systems
- [ ] Container diagram shows all major runtime units
- [ ] Component design specifies responsibilities and interactions
- [ ] ADRs document all significant architectural decisions
- [ ] API contracts define request/response schemas and error codes
- [ ] Data model specifies entities, fields, and relationships
- [ ] Traceability links every requirement to a design section
- [ ] No implementation details (file paths, code snippets) in design doc
