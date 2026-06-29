# CHNG-012: Decisions Log

## ADR-012-001: Inline rendering vs separate components
| Field | Value |
|-------|-------|
| **Decision** | Render forecast and YoY inline within BillingSummaryPage |
| **Rationale** | The page already renders 7+ inline sections. Extraction adds complexity with no reuse benefit. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-012-002: Conditional YTD growth display
| Field | Value |
|-------|-------|
| **Decision** | Show "—" dash when ytdGrowthPct is null |
| **Rationale** | First-year data has no prior year to compare against. Dash is clearer than showing 0%. |
| **Type** | Two-way door |
| **Date** | 2026-06-22 |

## ADR-012-003: i18n keys created despite proposal stating they exist
| Field | Value |
|-------|-------|
| **Decision** | Created `report.forecast.*` and `report.yoy.*` i18n keys in both en.ts and es.ts |
| **Rationale** | The proposal claimed these keys already existed from Javalin parity, but they were never migrated to the frontend i18n files. Creating them was necessary for the UI to render localized labels. 21 keys added total (9 forecast + 12 yoy). |
| **Type** | Two-way door |
| **Date** | 2026-06-23 |
