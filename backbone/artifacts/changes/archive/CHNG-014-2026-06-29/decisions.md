# CHNG-014: Decisions Log

## ADR-014-001: Manual insertion vs automated diff script
| Field | Value |
|-------|-------|
| **Decision** | Insert missing keys manually, section by section |
| **Rationale** | 214 additions is finite. Automated scripts risk ordering/whitespace changes. Manual edits preserve formatting conventions. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-014-002: Preserve existing differing translations
| Field | Value |
|-------|-------|
| **Decision** | Keep coeff's existing value when a key already exists with a different translation |
| **Rationale** | Some translations were intentionally customized (e.g., "Annual Delta" vs "Annual Target"). Overwriting would revert past decisions. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-014-003: Section ordering alignment
| Field | Value |
|-------|-------|
| **Decision** | Place new sections (setupWizard, profitability) at the same relative position as Javalin |
| **Rationale** | Maintains cross-project consistency. Developers switching between projects find keys in predictable locations. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |
