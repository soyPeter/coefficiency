# Design Document: COEF Simulator & Fiscal Configuration

**PRD Reference:** [20260515-coef-simulator.md](../prd/20260515-coef-simulator.md)
**Date:** 2026-05-15
**Status:** Draft

---

## 1. System Context

Single-user desktop app. Adds interactive COEF profitability calculator with Spanish tax engine (IRPF + SS) and fiscal configuration management.

## 2. Container Diagram

```
Browser SPA ──HTTP──▶ Jooby Server ──JDBI──▶ SQLite (settings, cost_concepts)
                       │
                       ├── SimulatorController
                       ├── SettingsController
                       └── ConceptsController
```

## 3. Component Design

### simulator slice

| Component | Responsibility |
|-----------|----------------|
| `TaxEngine` | IRPF progressive bracket calc, SS contribution calc per category |
| `SimulatorService` | COEF % formula = MonthlyMargin / MonthlyFees, loads config from settings |
| `SimulatorController` | `GET /api/simulator/defaults`, `POST /api/simulator/calculate` |
| `SimulatorInput` | salary, dailyRate, category, age, fixedCosts, benefits, deductions |
| `SimulatorResult` | coefPercentage, monthlyMargin, monthlyFees, managerBonus, breakdown |

### fiscal slice (under `simulator/` or inline)

| Component | Responsibility |
|-----------|----------------|
| `SettingsController` | `GET/PUT /api/settings`, `GET/PUT /api/fiscal/*` |
| `ConceptsController` | `GET/PUT/DELETE /api/concepts` |

## 4. Key Formulas

```
TotalCost = (salary × coefMultiplier) + (benefits × coefMultiplier) + fixedCosts + employeeSS + employeeIRPF
AnnualFees = dailyRate × coefDaysYear
AnnualMargin = AnnualFees − TotalCost
MonthlyMargin = AnnualMargin / coefDaysYear × coefDaysMonth
MonthlyFees = AnnualFees / coefDaysYear × coefDaysMonth
COEF% = MonthlyMargin / MonthlyFees
ManagerBonus = MonthlyMargin × mngBonusPct
```

IRPF: Progressive brackets applied to taxable income (salary − lirpfExpenses − deductions). State + regional brackets summed.

SS: Per-category base caps. Rates applied to the minimum of (salary, base cap).

## 5. API Contracts

### GET /api/simulator/defaults
```json
{ "coefDaysMonth": 21, "coefDaysYear": 252, "categories": ["engineer","senior","lead"], "concepts": [...] }
```

### POST /api/simulator/calculate
Request: `{ salary, dailyRate, category, age, fixedCosts, benefits, deductions }`
Response: `{ coefPercentage, monthlyMargin, monthlyFees, managerBonus, breakdown: { salary, irpf, ss, totalCost, annualFees } }`

### GET /api/settings → `[{ key, value }]`
### PUT /api/settings → save key-value
### GET/PUT /api/fiscal/irpf-brackets, /api/fiscal/ss-bases, /api/fiscal/working-days
### GET /api/concepts, POST /api/concepts, PUT/DELETE /api/concepts/:id

## 6. Traceability

| Req | Design Section |
|-----|----------------|
| REQ-SIM-001 COEF Calc | §3 SimulatorService, §4 |
| REQ-SIM-002 IRPF | §3 TaxEngine |
| REQ-SIM-003 SS | §3 TaxEngine |
| REQ-SIM-004 Multipliers | §3 SimulatorService loads from settings |
| REQ-SIM-005 Working Days | §3 SimulatorService loads coefDaysMonth/coefDaysYear |
| REQ-SIM-006 Cost Concepts | §3 ConceptsController |
| REQ-SIM-007 Save COEF | SimulatorController saves to consultant via ConsultantAction |
| REQ-SIM-008 Fiscal Config | §3 SettingsController |
| REQ-SIM-009 Delta Config | §3 SettingsController |
