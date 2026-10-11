# Planning: Analytics, UI & User Experience

**PRD Reference:** `docs/project/prd/20260515-analytics-ui.md`

## Dependency Graph

```
ConsultantsPage (existing)
    ├── Sortable columns (client-side sort)
    ├── Text search filter (client-side)
    ├── Pagination (client-side)
    ├── COEF histogram (Recharts BarChart)
    ├── Tenure breakdown (Recharts BarChart)
    ├── Delta gauge (text + color)
    ├── COEF leaderboard (top/bottom 5)
    ├── COEF alert threshold (row highlighting + badge)
    └── Detail modal (sidebar panel)

BillingSummaryPage (existing)
    ├── KPI cards (stats display)
    ├── Hires/terminations bar chart
    ├── COEF trend line chart
    ├── Bonus bar chart
    ├── Tariff distribution histogram
    ├── Tariff x COEF scatter plot
    ├── Position summary table
    ├── MoM revenue growth line
    └── Revenue per consultant leaderboard

ClientsPage (existing)
    ├── Revenue pie chart
    ├── Daily billing by client bar chart
    ├── COEF by client bar chart
    ├── Profitability ranking table
    ├── Tenure stats display
    └── Expandable consultant roster

Auto-logout (new hook + dialog)
    ├── useIdleTimer hook (independent)
    └── AutoLogoutDialog (radix-ui)

Docs page (new)
    └── DocService + DocController (backend)
    └── DocsPage (frontend)
```

## Tasks

### Task 1: [M] feat: add sortable columns with asc/desc toggle to consultant table

**Description:** Click column header to sort by that field. Toggle asc/desc on subsequent clicks. Default sort by ID descending. Sort by: name, client, position, startDate, endDate, daysInRole, coefPercentage, tariff, managerBonus.

**Files:**
- `frontend/src/pages/ConsultantsPage.tsx`

### Task 2: [S] feat: add text search filtering to consultant list

**Description:** Filter by name, client, or position. Real-time filtering as user types.

**Files:**
- `frontend/src/pages/ConsultantsPage.tsx`

### Task 3: [S] feat: add pagination to consultant table

**Description:** Page navigation with previous/next and rows-per-page selector (25 default).

**Files:**
- `frontend/src/pages/ConsultantsPage.tsx`

### Task 4: [M] feat: add COEF histogram + tenure breakdown + delta gauge charts

**Description:** Histogram of coefPercentage distribution. Tenure bar chart grouped by <6m, 6-12m, 1-2y, 2-3y, 3y+. Delta gauge showing hires-terminations vs target.

**Files:**
- `frontend/src/pages/ConsultantsPage.tsx`

### Task 5: [S] feat: add COEF leaderboard and alert threshold highlighting

**Description:** Top/bottom 5 by coefPercentage. Red row highlighting for consultants below configurable threshold. Warning badge showing count of flagged consultants.

**Files:**
- `frontend/src/pages/ConsultantsPage.tsx`

### Task 6: [M] feat: add billing KPI cards and chart collection

**Description:** KPI cards for daily/monthly/annual totals, hires, terminations, delta, fees, avg COEF, margin, bonus. Hires/terminations per month bar chart. COEF trend line. Bonus bar chart. Tariff distribution. Tariff vs COEF scatter. Position summary. MoM growth. Revenue leaderboard.

**Files:**
- `frontend/src/pages/BillingSummaryPage.tsx`

### Task 7: [S] feat: add client financial chart collection

**Description:** Revenue pie chart, daily billing by client bar, COEF by client bar, profitability ranking with color coding, tenure stats, expandable per-client consultant roster.

**Files:**
- `frontend/src/pages/ClientsPage.tsx`

### Task 8: [M] feat: create useIdleTimer hook with state machine

**Description:** Tracks mouse/keyboard/scroll events. State: ACTIVE -> (idle N min) -> COUNTDOWN -> (60s) -> EXPIRED. Resets on activity. Configurable idleTimeout.

**Files:**
- `frontend/src/hooks/useIdleTimer.ts`

### Task 9: [S] feat: create AutoLogoutDialog with radix-ui countdown

**Description:** Modal with 60-second countdown, "Stay Logged In" button. Uses radix-ui Dialog. i18n labels.

**Files:**
- `frontend/src/components/AutoLogoutDialog.tsx`

### Task 10: [M] feat: create DocService with auto-generated API documentation

**Description:** Reads all API endpoints, entity fields, config keys, and CSV format. Serves as JSON via GET /api/docs. Frontend DocsPage renders 6 tabs: About, Concepts, Endpoints, Entities, Config, CSV.

**Files:**
- `doc/app/DocService.java`
- `doc/infra/rest/DocController.java`
- `frontend/src/pages/DocsPage.tsx`
