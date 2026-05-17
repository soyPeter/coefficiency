# Design Document: [Feature Name]

**PRD Reference:** [Link to PRD]
**Date:** [YYYY-MM-DD]
**Status:** Draft / Review / Approved

---

## 1. System Context (C4 Level 1)

[Describe the system boundary and external actors]

### Actors
- **[Actor Name]**: [Role and interaction with system]

### External Systems
- **[System Name]**: [Purpose and interface]

## 2. Container Diagram (C4 Level 2)

[Describe high-level containers: applications, databases, queues, caches]

```
[ASCII diagram or PlantUML link]
```

### Containers
| Container | Technology | Responsibility |
|-----------|------------|----------------|
| | | |

## 3. Component Design (C4 Level 3)

### [Container Name]

#### Components
| Component | Responsibility |
|-----------|----------------|
| | |

#### Interactions
```
[Component A] → [Component B]: [Data/Trigger]
```

## 4. Architecture Decisions

### ADR-001: [Decision Title]

**Status:** Proposed
**Context:** [What problem are we solving?]
**Decision:** [What did we decide?]
**Consequences:** [Tradeoffs and implications]
**Alternatives Considered:**
- [Alternative 1]: [Why rejected]
- [Alternative 2]: [Why rejected]

## 5. API Contracts

### [Interface/Endpoint Name]

**Request:**
```json
{
  "field": "type"
}
```

**Response (Success):**
```json
{
  "field": "type"
}
```

**Response (Errors):**
| Status | Code | Condition |
|--------|------|-----------|
| | | |

## 6. Data Model

### [Entity Name]

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| | | | |

### Relationships
- [Entity A] → [Entity B]: [Relationship type (1:1, 1:N, N:M)]

## 7. Traceability

| Requirement ID | Requirement Summary | Design Section | Status |
|----------------|---------------------|----------------|--------|
| REQ-XXX-001 | | | |

---

**Review History:**
| Date | Reviewer | Verdict | Notes |
|------|----------|---------|-------|
| | | | |
