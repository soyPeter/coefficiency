# Planning: COEF Simulator & Fiscal Configuration

**PRD:** `backbone/prd/20260515-coef-simulator.md`
**Design:** `backbone/design/20260515-coef-simulator-design.md`

## Dependency Graph

```
TaxEngine (IRPF + SS calculations)
    │
    ├── SimulatorService (COEF formula, reads settings)
    │       └── SimulatorController
    │               └── frontend SimulatorPage
    │
    ├── SettingsController (fiscal params CRUD)
    ├── ConceptsController (cost concepts CRUD)
    └── frontend ConfigPage (editable IRPF/SS/working-days tables)
```

## Tasks

### Task 1: [M] feat: create TaxEngine and SimulatorService

TaxEngine with IRPF progressive bracket calculation (state + regional) and SS contribution calculation (per-category base caps). SimulatorService that loads fiscal config from settings DB, runs TaxEngine, computes COEF% = MonthlyMargin / MonthlyFees.

**Files:** `simulator/TaxEngine.java`, `simulator/SimulatorService.java`, `simulator/SimulatorInput.java`, `simulator/SimulatorResult.java`

### Task 2: [M] feat: create SimulatorController, SettingsController, ConceptsController

SimulatorController with defaults + calculate endpoints. SettingsController for GET/PUT /api/settings and /api/fiscal/* endpoints. ConceptsController for CRUD on /api/concepts.

**Files:** `simulator/SimulatorController.java`, `simulator/SettingsController.java`, `simulator/ConceptsController.java`

### Task 3: [S] feat: create frontend SimulatorPage and ConfigPage

SimulatorPage with input form (salary, dailyRate, category, costs) and results display (COEF%, margin, bonus, breakdown). ConfigPage with editable tables for IRPF brackets, SS bases, working days, engine parameters.

**Files:** `frontend/src/pages/SimulatorPage.tsx`, `frontend/src/pages/ConfigPage.tsx`, update `App.tsx`
