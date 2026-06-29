# CHNG-011: Javalin parity phase 4 frontend extraction

**What:** Extract inline components from ConsultantsPage.tsx (878 lines) into separate reusable component files, and add RevenueLeaderboard component to BillingSummaryPage.

**Why:** ConsultantsPage.tsx has grown to 878 lines with inline UI components (DropdownInput, table, search bar) that duplicate logic already extracted in the Javalin reference project. Extraction improves maintainability, reusability, and testability. BillingSummaryPage has an inline leaderboard that should be a standalone component matching the Javalin `RevenueLeaderboard`.

**Scope:**
- `services/coeff/frontend/src/components/consultants/` (new directory, 4 new files)
- `services/coeff/frontend/src/components/RevenueLeaderboard.tsx` (new file)
- `services/coeff/frontend/src/pages/ConsultantsPage.tsx` (modify — replace inline code with imports)
- `services/coeff/frontend/src/pages/BillingSummaryPage.tsx` (modify — use RevenueLeaderboard)

## Requirements

- **REQ-FE-001** When ConsultantsPage renders, DropdownInput shall be imported from `components/consultants/DropdownInput.tsx` instead of defined inline.
- **REQ-FE-002** When ConsultantsPage renders the consultant table, ConsultantTable shall be imported from `components/consultants/ConsultantTable.tsx`.
- **REQ-FE-003** When ConsultantsPage renders the search bar, ConsultantFilterBar shall be imported from `components/consultants/ConsultantFilterBar.tsx`.
- **REQ-FE-004** When any page needs a status badge, StatusBadge shall be available from `components/consultants/StatusBadge.tsx`.
- **REQ-FE-005** When BillingSummaryPage renders the revenue leaderboard, RevenueLeaderboard shall be rendered with consultant data and sortable columns.
- **REQ-FE-006** When RevenueLeaderboard receives a consultant list, it shall support sorting by fees, tariff, coef, coefMargin, name, client, and position.
- **REQ-FE-007** When RevenueLeaderboard renders, it shall paginate results at 10 per page with next/previous controls.

### Acceptance Criteria
- **AC-REQ-FE-001.1:** DropdownInput is removed from ConsultantsPage.tsx inline definition and imported from `@/components/consultants/DropdownInput`.
- **AC-REQ-FE-002.1:** The consultant table renders identically before and after extraction.
- **AC-REQ-FE-005.1:** `RevenueLeaderboard` component renders inside BillingSummaryPage with consultant data passed as prop.
- **AC-REQ-FE-007.1:** Leaderboard shows pagination controls when >10 consultants exist; page resets on sort or filter change.
