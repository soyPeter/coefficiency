---
grilled: true
---

# Analytics, UI & User Experience

## Summary

Data visualization, UX enhancements, automated logout, and documentation. Charts include COEF histogram, tenure breakdown, delta gauge, leaderboard, billing analytics, and client financial analysis.

## Grilling

### Scope
- **Q:** What charts are included?
- **A:** Consultants tab: COEF histogram, tenure breakdown, delta gauge, COEF leaderboard, cumulative net change, COEF alert threshold. Billing tab: hires/terminations per month, COEF trend, bonus per month, tariff distribution, tariff vs COEF scatter, position summary, MoM billing growth, revenue per consultant. Clients tab: revenue concentration pie, daily billing by client, COEF by client, profitability ranking, tenure stats, expandable consultant roster.
- **Q:** What UX features?
- **A:** Sortable columns (asc/desc), text search across name/client/position, pagination, consultant detail modal, COEF threshold highlighting with badge, searchable dropdown (Input ↔ select toggle).

### Boundaries
- **Q:** What modules are touched?
- **A:** All frontend pages. No backend changes for charts (data already available from existing endpoints). Auto-logout uses useIdleTimer hook + radix-ui Dialog.
- **Q:** What must NOT change?
- **A:** Backend API contracts. Existing chart libraries (Recharts). Tab structure of each page.

### Data & State
- **Q:** What new data structures?
- **A:** No new backend data structures — all charts derive from existing API responses. Frontend: MonthlyRow interface, useIdleTimer hook state.
- **Q:** Where does state live?
- **A:** Chart data in React state, fetched on mount. Sort/filter/pagination in component state. Idle timer in hook state.

### API
- **Q:** Any new endpoints needed?
- **A:** No. All chart data comes from existing endpoints. The only "new" endpoint was /api/docs (auto-generated documentation).

### Implementation Order
- **Q:** First slice?
- **A:** Sort/filter/search (immediate UX win) → COEF histogram + tenure → billing charts → client charts → auto-logout → docs page.
- **Q:** Dependencies?
- **A:** Sort/filter independent. Charts depend on page being rendered. Auto-logout independent. Docs page depends on DocService.

## Requirements

### REQ-UI-001: Sortable Table
WHEN the user clicks a column header, the system SHALL sort consultants by that field, toggling asc/desc.

### REQ-UI-002: Text Search
WHEN the user types in the search box, the system SHALL filter consultants by name, client, or position.

### REQ-UI-003: Pagination
WHEN the consultant list exceeds the page size, the system SHALL paginate with page navigation and rows-per-page selector.

### REQ-UI-004: Detail Modal
WHEN the user clicks "Show", the system SHALL display a slide-out panel with full consultant data and an Open-in-Simulator button.

### REQ-UI-005: COEF Alert Threshold
WHEN a consultant's COEF % is below the configurable threshold, the system SHALL highlight the row and show a warning badge.

### REQ-UI-006: COEF Histogram
WHEN viewing consultants, the system SHALL display a histogram of COEF % distribution.

### REQ-UI-007: Tenure Breakdown
WHEN viewing consultants, the system SHALL display a bar chart of consultants grouped by tenure range.

### REQ-UI-008: Delta Gauge
WHEN viewing consultants, the system SHALL show net change vs annual delta target with remaining/overshoot.

### REQ-UI-009: COEF Leaderboard
WHEN viewing consultants, the system SHALL show top and bottom COEF % consultants.

### REQ-UI-010: Billing KPIs
WHEN viewing billing, the system SHALL show KPI cards for daily/monthly/annual totals, hires, terminations, delta, fees, avg COEF, margin, bonus.

### REQ-UI-011: Billing Charts
WHEN viewing billing, the system SHALL display hires/terminations per month, COEF trend, bonus per month, tariff distribution, tariff vs COEF scatter, position summary, MoM growth, revenue leaderboard.

### REQ-UI-012: Client Charts
WHEN viewing clients, the system SHALL display revenue pie, daily billing by client, COEF by client, profitability ranking, tenure stats, expandable consultant roster.

### REQ-UI-013: Auto-Logout
WHEN the user is idle for N minutes, the system SHALL show a 60-second countdown dialog and auto-logout on expiry.

### REQ-UI-014: Docs Page
WHEN viewing documentation, the system SHALL display 6 tabs: About, Concepts, API Endpoints, Data Models, Configuration, CSV Format.
