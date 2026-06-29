# CHNG-008: Javalin Parity — Phase 1: Value Objects

## Problem

The coefficiency `Consultant` record uses raw `double` / `Double` fields for financial
concepts (fees, coef, tariff, salary, tax rates, etc.). This makes the domain model
anemic — there is no type safety, no self-validating boundaries, and no distinction
between conceptually different quantities that happen to share the same primitive
type. For example, a `double` could represent a daily tariff or a monthly salary,
and the compiler cannot catch a swap.

The Javalin reference project (`javalin-coef-calc`) already defines typed value
objects for all these concepts. This change ports those value objects and refactors
the coefficiency Consultant to use them.

## Scope

**In scope (Phase 1):**
- Create 7 typed value objects in `shared/domain`:
  `Money`, `Coef`, `CoefPct`, `Tariff`, `Salary`, `Bonus`, `TaxRate`
- Refactor `Consultant` record to use typed value objects instead of raw doubles
- Update `ConsultantRow` (`toDomain`), `ConsultantRes` (`from`), and
  `ConsultantSqlCommandRepo` (JDBI binding) for the new types
- Update use cases (`CreateConsultantUseCase`, `UpdateConsultantUseCase`,
  `SaveCoefUseCase`) and `ConsultantController` to handle typed objects

**Not in scope (future phases):**
- Refactoring `SimulatorService`, `SimulatorResult`, `BillingCalculator`, or other
  non-Consultant domain records
- Changing `startDate`/`endDate` from `String` to `LocalDate`
- Creating shared arithmetic operations on value objects (`Money.plus`, etc.)
- Refactoring the persistence schema (DB columns stay as raw doubles)

## Requirements (EARS)

### REQ-VO-MONEY
The `Money` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-COEF
The `Coef` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-COEF-PCT
The `CoefPct` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-TARIFF
The `Tariff` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-SALARY
The `Salary` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-BONUS
The `Bonus` value object SHALL wrap a `double` value and SHALL reject negative
values with `IllegalArgumentException`.

### REQ-VO-TAXRATE
The `TaxRate` value object SHALL wrap a `double` value between `0.0` and `1.0`
(inclusive) and SHALL reject values outside this range with
`IllegalArgumentException`.

### REQ-CONSULTANT-TYPED
The `Consultant` record SHALL use typed value objects instead of raw doubles
for the following fields:

| Field | Current Type | New Type |
|-------|-------------|----------|
| `coef` | `double` | `Coef` |
| `tariff` | `double` | `Tariff` |
| `fees` | `Double` | `Money` |
| `coefPercentage` | `Double` | `CoefPct` |
| `coefMargin` | `Double` | `CoefPct` |
| `managerBonus` | `Double` | `Bonus` |
| `grossMonthlySalary` | `Double` | `Money` |
| `netMonthlySalary` | `Double` | `Money` |
| `netAnnualSalary` | `Double` | `Money` |
| `monthlySs` | `Double` | `Money` |
| `monthlyIrpf` | `Double` | `Money` |
| `irpfRate` | `Double` | `TaxRate` |
| `ssRate` | `Double` | `TaxRate` |

### REQ-CONSULTANT-FACTORIES
The `Consultant.create()` and `Consultant.update()` static factories SHALL accept
raw doubles as input and SHALL construct typed value objects internally.

### REQ-ROW-MAPPING
`ConsultantRow.toDomain()` SHALL convert raw DB doubles into typed value objects.
Null DB values SHALL map to `null` value objects.

### REQ-RES-MAPPING
`ConsultantRes.from(Consultant)` SHALL extract raw `double` values from typed
value objects for JSON serialization. Null value objects SHALL map to `null`
doubles.

### REQ-PERSISTENCE-BINDING
`ConsultantSqlCommandRepo` SHALL bind value object properties as their underlying
`double` values for SQL persistence. When a value object is `null`, the bound
value SHALL be `null`.

### REQ-USE-CASE-SIGNATURES
Use case method signatures (`CreateConsultantUseCase`, `UpdateConsultantUseCase`,
`SaveCoefUseCase`) SHALL continue to accept raw doubles from the controller layer
and SHALL convert to typed value objects internally.

### REQ-CONTROLLER
The `ConsultantController` SHALL continue to accept raw doubles in request DTOs
and SHALL delegate conversion to the use cases.

### REQ-VALIDATION-PARITY
All value object validation SHALL match the Javalin reference implementation
exactly (same bounds, same exception type, same error message format).

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
