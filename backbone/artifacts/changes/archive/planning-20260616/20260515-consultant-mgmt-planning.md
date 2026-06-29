# Planning: Consultant Management

**PRD:** `backbone/prd/20260515-consultant-mgmt.md`
**Design:** `backbone/design/20260515-consultant-mgmt-design.md`

## Dependency Graph

```
Consultant domain entity + Action interface
    │
    ├── ConsultantSqlCommandRepo (JDBI)
    ├── ConsultantSqlQueryRepo (JDBI)
    ├── ConsultantRow (mapper)
    ├── DTOs (Create/Update/Res)
    ├── Use cases (Create, Update, Delete)
    │
    ├── ConsultantController ──── frontend/ConsultantsPage
    │
    ├── BillingService ──── BillingController ──── frontend/BillingSummaryPage
    ├── ClientService  ──── ClientController  ──── frontend/ClientsPage
    └── FileImportService ─── FileImportController ─ frontend/FileImportPage
```

## Tasks

### Task 1: [S] feat: create Consultant domain entity, action, and use cases

Consultant record in domain, ConsultantAction interface, Create/Update/Delete use cases in app layer.

### Task 2: [S] feat: create Consultant JDBI repositories, DTOs, and controller

ConsultantSqlCommandRepo, ConsultantSqlQueryRepo, ConsultantRow, CreateConsultantReq/UpdateConsultantReq/ConsultantRes, ConsultantController.

### Task 3: [S] feat: create Billing service and controller

BillingService with SQL aggregation queries for daily/monthly/annual projections, hires/terminations/delta. BillingController for GET /api/billing/summary and /monthly.

### Task 4: [S] feat: create Client grouping and financial analytics endpoints

ClientService with SQL queries for client grouping and financial analytics. ClientController for GET /api/clients and /clients/financial.

### Task 5: [S] feat: create CSV import endpoint

FileImportController with multipart CSV upload. Parses 8-column CSV, creates consultants, skips duplicates. Returns import/skip/error counts.

### Task 6: [M] feat: create frontend ConsultantsPage, BillingPage, ClientsPage, ImportPage

React components for all 4 pages with the UI features from the Analytics PRD (sort, search, pagination, charts). Integrates with backend endpoints.
