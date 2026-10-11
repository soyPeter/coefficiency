---
grilled: true
---

# Consultant Management

## Summary

Full CRUD for consultants with auto-calculated money (tariff × coef), days in role tracking, billing projections, client grouping, CSV import, and financial analytics.

## Grilling

### Scope
- **Q:** What entities are managed?
- **A:** Consultant (name, client, position, coef, tariff, startDate, endDate, fees, coefPercentage, coefMargin, managerBonus). BillingSummary (daily/monthly/annual totals, hires, terminations, delta). ClientSummary (client, positionCount). ClientFinancial (per-client fees, margins, tenure).
- **Q:** What is NOT included?
- **A:** The COEF simulator and fiscal config have their own PRD. Multi-user, permissions, audit log.

### Boundaries
- **Q:** Which modules are touched?
- **A:** consultant/ (domain, service, controller, repository), billing/ (domain, service, controller), client/ (service, controller), file/ (import service, controller), shared/ (schema, SQL views). Frontend pages: ConsultantsPage, BillingSummaryPage, ClientsPage, FileImportPage.
- **Q:** What must remain unchanged?
- **A:** The Consultant domain record structure. Existing API contracts for GET/consultants and POST/consultants.

### Data & State
- **Q:** What new data structures?
- **A:** Consultant record, BillingSummary record, ClientSummary record, CreateConsultantRequest DTO, ImportResult type, MonthlyRow for per-month breakdown.
- **Q:** What are the read/write patterns?
- **A:** Read-heavy: consultant list, billing summary, client overview. Write: CRUD per consultant, CSV batch import. Billing and client data computed via SQL aggregation.

### API
- **Q:** What endpoints are needed?
- **A:** RESTful CRUD on /api/consultants. GET /api/billing/summary and /monthly. GET /api/clients and /clients/financial. POST /api/files/upload (multipart CSV).
- **Q:** What is the CSV format?
- **A:** 8 columns: name, client, position, coef, tariff, startDate, endDate (optional), honorarios (optional). Header row skipped.

### Implementation Order
- **Q:** What's the first slice?
- **A:** Consultant domain record → Repository → Service → Controller → Frontend CRUD page.
- **Q:** Dependencies between slices?
- **A:** Billing depends on consultants existing. Client depends on consultants. CSV import depends on consultant repository.

## Requirements

### REQ-CON-001: Consultant CRUD
WHEN the user creates, reads, updates, or deletes a consultant, the system SHALL persist changes to SQLite and return the result as JSON.

### REQ-CON-002: Money Auto-Calculation
WHEN the user sets tariff and coef, the system SHALL auto-compute money = tariff × coef.

### REQ-CON-003: Days in Role
WHEN the system returns a consultant, the system SHALL include daysInRole = today − startDate.

### REQ-CON-004: Billing Summary
WHEN the user views billing, the system SHALL show daily (sum tariffs), monthly (daily × coefDaysMonth), and annual (daily × coefDaysYear) projections.

### REQ-CON-005: Hire/Termination Counting
WHEN computing billing, the system SHALL count consultants with startDate in current year as hires and endDate in current year as terminations.

### REQ-CON-006: Delta Tracking
WHEN computing billing, the system SHALL compare net change (hires − terminations) against the configurable annual delta.

### REQ-CON-007: Client Grouping
WHEN the user views clients, the system SHALL group consultants by client with position counts.

### REQ-CON-008: Client Financial Analytics
WHEN the user views client financials, the system SHALL return per-client fees, margins, bonus, avg/max tenure.

### REQ-CON-009: CSV Import
WHEN the user uploads a CSV file, the system SHALL parse rows, create consultants, skip duplicates (INSERT OR IGNORE), and report count.

### REQ-CON-010: SQL Analytics Views
WHEN computing client financials and position profitability, the system SHALL use v_client_financials and v_position_profitability SQL views.

### REQ-CON-011: Expected Hires/Terminations
WHEN computing billing, the system SHALL count future startDates as expectedHires and future endDates as expectedTerminations.
