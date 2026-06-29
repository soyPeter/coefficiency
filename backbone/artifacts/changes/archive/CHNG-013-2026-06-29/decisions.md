# CHNG-013: Decisions Log

## ADR-013-001: Type placement (inline vs @/types)
| Field | Value |
|-------|-------|
| **Decision** | Export Concept, ConceptDraft, BackupFile interfaces from hooks files |
| **Rationale** | Keeps hooks self-contained. BackupFile already exists in api.ts — deduplicate by importing from hooks. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-013-002: authFetch parameter pattern
| Field | Value |
|-------|-------|
| **Decision** | Hooks accept `authFetch` as a function parameter rather than importing api.ts |
| **Rationale** | Dependency injection for testability. Matches Javalin's approach. Callers wrap `request<T>` from api.ts. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-013-003: No behavioral changes during port
| Field | Value |
|-------|-------|
| **Decision** | Port hooks verbatim from Javalin. No refactoring, no combining, no simplifying. |
| **Rationale** | Javalin hooks are proven in production. Behavior-changing modifications belong in a follow-up change. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |
