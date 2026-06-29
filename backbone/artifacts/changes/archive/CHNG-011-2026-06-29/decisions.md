# CHNG-011: Decision Log

| # | Topic | Decision | Rationale | Alternatives | Type |
|---|-------|----------|-----------|--------------|------|
| 1 | ConsultantTable column set | Extract coefficiency's current 9 columns (no status/profitability) | Status/profitability columns depend on `profitabilityStatus` field not yet on coefficiency's Consultant type; adding it requires backend changes outside this phase | Add status/profitability columns with stub data | auto |
| 2 | StatusBadge creation without wiring | Create StatusBadge as standalone component but don't wire into ConsultantTable | `profitabilityStatus` doesn't exist on coefficiency's Consultant type yet; component is ready for future use when backend adds the field | Skip StatusBadge entirely; add when backend catches up | auto |
| 3 | ConsultantFilterBar scope | Extract only the search input (no status tabs or coef filter pills) | Coefficiency's current page only has a search bar; adding tabs/filters would change behavior beyond extraction scope | Add full Javalin filter bar with tabs and coef filters | auto |
| 4 | ConsultantBrief type location | Keep locally defined in BillingSummaryPage.tsx | Moving to shared `types.ts` would change import paths across multiple files; defer to future type-cleanup phase | Extract to `types.ts` now | auto |
| 5 | RevenueLeaderboard default export | Use default export (matching Javalin reference) | Javalin uses `export default function RevenueLeaderboard`; consistency with reference project simplifies future sync | Named export | auto |
| 6 | Component directory structure | Use `components/consultants/` subdirectory matching Javalin | Keeps consultant-related components grouped; matches Javalin project structure for easier diffing | Flat `components/` directory | auto |
