# Design Document: Consultant Management

**PRD Reference:** [20260515-consultant-mgmt.md](../prd/20260515-consultant-mgmt.md)
**Date:** 2026-05-15
**Status:** Draft

---

## 1. System Context

Same as Core Platform — single-user desktop app. Adds consultant CRUD, billing analytics, client grouping, and CSV import.

## 2. Container Diagram

```
Browser SPA ──HTTP──▶ Jooby Server ──JDBI──▶ SQLite
                        │
                        ├── ConsultantController
                        ├── BillingController
                        ├── ClientController
                        └── FileImportController
```

## 3. Component Design

### Domain Layer

| Component | Fields | Responsibility |
|-----------|--------|----------------|
| `Consultant` (record) | id, name, client, position, coef, tariff, startDate, endDate, fees, coefPercentage, coefMargin, managerBonus, simulationInputs, createdAt, updatedAt | Domain entity with factory methods |
| `ConsultantAction` (interface) | save, update, delete, findById | CQRS command port |

### App Layer

| Component | Responsibility |
|-----------|----------------|
| `CreateConsultantUseCase` | Validate input, create Consultant via factory, persist |
| `UpdateConsultantUseCase` | Update fields, recalculate money, persist |
| `DeleteConsultantUseCase` | Soft delete by id |
| `ListConsultantsQuery` (interface) | findAll with pagination/sort/search, count |
| `BillingService` | Compute daily/monthly/annual projections, hire/termination/delta counts |
| `ClientService` | Group consultants by client, compute per-client financials |

### Infra Layer

| Component | Responsibility |
|-----------|----------------|
| `ConsultantController` | REST CRUD on `/api/consultants` |
| `ConsultantSqlCommandRepo` | JDBI implementation of ConsultantAction |
| `ConsultantSqlQueryRepo` | JDBI implementation of ListConsultantsQuery |
| `ConsultantRow` | JDBI row mapper (snake_case to camelCase) |
| `CreateConsultantReq` | Request DTO |
| `UpdateConsultantReq` | Request DTO |
| `ConsultantRes` | Response DTO |
| `BillingController` | `GET /api/billing/summary`, `GET /api/billing/monthly` |
| `BillingSummary` | Daily/monthly/annual projections |
| `MonthlyRow` | Per-month breakdown record |
| `ClientController` | `GET /api/clients`, `GET /api/clients/financial` |
| `ClientSummary` | Client + positionCount |
| `ClientFinancial` | Per-client fees, margins, tenure |
| `FileImportController` | `POST /api/files/upload` (multipart CSV) |
| `ImportResult` | imported/skipped/errors counts |

### Interactions

```
CRUD flow:
  POST /api/consultants ──▶ ConsultantController
                              └── CreateConsultantUseCase
                                      └── Consultant.create() (factory)
                                      └── ConsultantAction.save()

  GET /api/consultants ──▶ ConsultantController
                              └── ListConsultantsQuery.findAll()

Billing flow:
  GET /api/billing/summary ──▶ BillingController
                                  └── BillingService (SQL aggregation)

Client flow:
  GET /api/clients/financial ──▶ ClientController
                                    └── ClientService (SQL via views)
```

## 4. Architecture Decisions

### ADR-001: Money Computation in App Layer

**Decision:** Money = tariff × coef is computed by the CreateConsultantUseCase and UpdateConsultantUseCase, not in SQL. daysInRole computed as `today - startDate` in Java.

**Consequences:** Consistent with domain logic living in app layer. No SQL-side computation for business rules.

### ADR-002: Billing via SQL Aggregation

**Decision:** Billing summaries computed via JDBI SQL queries (`SUM`, `COUNT`, `GROUP BY`) directly from consultants table, not from a separate billing table.

**Consequences:** No billing table needed. Always up-to-date. Slightly more complex SQL.

## 5. API Contracts

### GET /api/consultants

Query params: `page`, `size`, `sort`, `order`, `search`

Response:
```json
{
  "items": [{ "id": 1, "name": "...", "client": "...", "position": "...", "coef": 0.35, "tariff": 500, "fees": 120000, "coefPercentage": 0.22, "coefMargin": 26400, "managerBonus": 1320, "startDate": "2024-01-15", "endDate": null, "daysInRole": 851 }],
  "total": 42, "page": 1, "size": 20
}
```

### POST /api/consultants

Request body: name, client, position, tariff, coef, startDate, endDate (opt), fees (opt)

Response: 201 Created with consultant object.

### PUT /api/consultants/{id}

Same body as POST. Full update.

Response: 200 with consultant.

### DELETE /api/consultants/{id}

Response: 204 No Content.

### GET /api/billing/summary

Response: `{ daily, monthly, annual, hires, terminations, netChange, annualDelta, expectedHires, expectedTerminations }`

### GET /api/billing/monthly

Response: `[{ month, revenue, hires, terminations }]`

### GET /api/clients

Response: `[{ client, positionCount, consultants: [...] }]`

### GET /api/clients/financial

Response: `[{ client, totalFees, totalMargin, totalBonus, avgTenure, maxTenure, consultantCount }]`

### POST /api/files/upload

Multipart form-data with CSV file.

Response: `{ imported: 15, skipped: 2, errors: 0 }`

## 6. Data Model

Consultants table already created in Core Platform schema. See `SqliteConnection.java`.

## 7. Traceability

| Req ID | Summary | Design Section |
|--------|---------|----------------|
| REQ-CON-001 | Consultant CRUD | §3 ConsultantController, ConsultantSqlCommandRepo |
| REQ-CON-002 | Money auto-calculation | §3 CreateConsultantUseCase, §4 ADR-001 |
| REQ-CON-003 | Days in role | §3 ConsultantRes, §4 ADR-001 |
| REQ-CON-004 | Billing Summary | §3 BillingController, BillingService |
| REQ-CON-005 | Hire/Termination Counting | §3 BillingService |
| REQ-CON-006 | Delta Tracking | §3 BillingService |
| REQ-CON-007 | Client Grouping | §3 ClientController, ClientService |
| REQ-CON-008 | Client Financial Analytics | §3 ClientController, ClientService, SQL views |
| REQ-CON-009 | CSV Import | §3 FileImportController |
| REQ-CON-010 | SQL Analytics Views | Already in schema (Core Platform) |
| REQ-CON-011 | Expected Hires/Terminations | §3 BillingService |
