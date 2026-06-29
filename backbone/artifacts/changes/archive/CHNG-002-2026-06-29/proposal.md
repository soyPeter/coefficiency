---
grilled: true
---

# COEF Simulator & Fiscal Configuration

## Summary

Interactive simulator computes consultant profitability (COEF %) using the Spanish tax engine (IRPF + Social Security). All fiscal parameters — working days, IRPF brackets, SS bases, engine multipliers — are configurable via the settings page.

## Grilling

### Scope
- **Q:** What does the simulator compute?
- **A:** COEF % = Monthly Margin ÷ Monthly Fees. Margin = (AnnualFees − TotalCost) ÷ 252 × 21. TotalCost includes gross salary × 1.7, benefits × 1.7, fixed costs + employee SS + employee IRPF. Manager bonus = margin × 5%.
- **Q:** What fiscal parameters are configurable?
- **A:** coefMultiplier (1.7), mngBonusPct (5%), insuranceMonths (6), mealCardDays (22), ssRate (6.35%), ssContingencies (4.7%), ssUnemployment (1.55%), ssTraining (0.1%), personalMinimum (€5,550), deductionChild (€2,400), deductionAsc (€1,150), deductionDis (€3,000), lirpfExpenses (€2,000), coefAlertThreshold (0.15), coefDaysMonth, coefDaysYear, per-month working days, IRPF brackets (state + regional), SS bases per category.

### Boundaries
- **Q:** Which modules are touched?
- **A:** simulator/ (TaxEngine, SimulatorService, SimulatorController), config/ (FiscalController, SettingsController, SettingsRepository). Frontend: SimulatorPage, ConfigPage.
- **Q:** What must NOT change?
- **A:** The TaxEngine calculation logic (IRPF brackets, SS formulas). Existing COEF formula matching Excel.

### Data & State
- **Q:** What data structures?
- **A:** SimulatorInput (salary, category, age, costs, deductions), SimulatorResult (coef, margin, bonus, breakdown), CoefConfig (computed constants), TaxEngine.FamilyResult (SS, IRPF, total cost).
- **Q:** Where are configs stored?
- **A:** All in settings table as key-value strings. IRPF brackets, working days, SS config stored as JSON strings.

### API
- **Q:** What endpoints?
- **A:** GET /api/simulator/defaults (returns coefDaysMonth, categories, concepts), POST /api/simulator/calculate (input → result), GET/PUT /api/fiscal/* (all config), GET/PUT /api/settings (app settings), GET/PUT/DELETE /api/concepts (cost concepts).

### Implementation Order
- **Q:** First slice?
- **A:** TaxEngine (IRPF + SS) → SimulatorService (COEF formula) → SimulatorController → SimulatorPage frontend.
- **Q:** Dependencies?
- **A:** Config page depends on SettingsRepository. Simulator depends on TaxEngine. SimulatorPage depends on SimulatorController.

## Requirements

### REQ-SIM-001: COEF Calculation
WHEN the user inputs salary, daily rate, and costs, the system SHALL compute COEF % = Margin ÷ Fees.

### REQ-SIM-002: IRPF Calculation
WHEN computing COEF, the system SHALL apply progressive state and regional IRPF brackets with family deductions.

### REQ-SIM-003: SS Calculation
WHEN computing COEF, the system SHALL apply Social Security contributions with per-category base caps.

### REQ-SIM-004: Configurable Multipliers
WHEN computing COEF, the system SHALL read coefMultiplier, mngBonusPct, and other engine params from settings database.

### REQ-SIM-005: Working Days
WHEN computing COEF, the system SHALL use configurable per-month working days and derived coefDaysMonth/coefDaysYear.

### REQ-SIM-006: Cost Concepts
WHEN the user opens the simulator, the system SHALL suggest cost concepts from the cost_concepts table.

### REQ-SIM-007: Save COEF to Consultant
WHEN the user saves COEF, the system SHALL persist fees, coefPercentage, coefMargin, managerBonus, and simulationInputs on the consultant.

### REQ-SIM-008: Fiscal Config Page
WHEN the user configures parameters, the system SHALL provide editable tables for IRPF brackets, SS bases, working days, and engine parameters.

### REQ-SIM-009: Delta Config
WHEN the user sets the annual hiring target, the system SHALL store and return it via /api/settings.

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
