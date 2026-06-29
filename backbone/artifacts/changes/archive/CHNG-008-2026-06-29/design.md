# Design — CHNG-008: Javalin Parity Phase 1: Value Objects

## Architecture Decision: Java Records for Value Objects

All 7 value objects are implemented as **Java records** (same approach as the
Javalin reference project). This gives us:

- Immutable by default
- Auto-generated `equals`/`hashCode`/`toString`
- Compact constructor for validation
- No boilerplate

## Package Structure

```
io.bitnomio.coeff.shared.domain/
├── Money.java       # non-negative wrapper
├── Coef.java        # non-negative wrapper
├── CoefPct.java     # non-negative wrapper (coefficient percentage)
├── Tariff.java      # non-negative wrapper (daily tariff)
├── Salary.java      # non-negative wrapper (not used by Consultant yet, created for parity)
├── Bonus.java       # non-negative wrapper (manager bonus)
└── TaxRate.java     # [0, 1] bounded wrapper
```

## Data Model

All value objects follow the same pattern:

```java
public record <Name>(double value) {
    public <Name> {
        if (<condition>) throw new IllegalArgumentException("<message>: " + value);
    }
}
```

| Class    | Validation               | Message Prefix        |
|----------|--------------------------|-----------------------|
| `Money`  | `value < 0`              | `"Money must be non-negative"` |
| `Coef`   | `value < 0`              | `"Coef must be non-negative"` |
| `CoefPct`| `value < 0`              | `"CoefPct must be non-negative"` |
| `Tariff` | `value < 0`              | `"Tariff must be non-negative"` |
| `Salary` | `value < 0`              | `"Salary must be non-negative"` |
| `Bonus`  | `value < 0`              | `"Bonus must be non-negative"` |
| `TaxRate`| `value < 0 \|\| value > 1` | `"TaxRate must be between 0 and 1"` |

## Null Strategy

Nullable fields (`fees`, `coefPercentage`, `coefMargin`, `managerBonus`,
salary fields, tax rates) remain nullable in the Consultant record — they are
typed as `Money`, `CoefPct`, `Bonus`, `TaxRate` (nullable via null component).
Only the **inner value** validation is enforced when the object exists.

## Files to Create

| File | Package |
|------|---------|
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Money.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Coef.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/CoefPct.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Tariff.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Salary.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/Bonus.java` | `io.bitnomio.coeff.shared.domain` |
| `services/coeff/src/main/java/io/bitnomio/coeff/shared/domain/TaxRate.java` | `io.bitnomio.coeff.shared.domain` |

## Files to Modify

| File | Change |
|------|--------|
| `Consultant.java` | Replace 13 double/Double fields with typed value objects. Update `create()`/`update()` factories. |
| `ConsultantRow.java` | `toDomain()` constructs typed VOs from raw doubles. |
| `ConsultantRes.java` | `from()` extracts `double` via `.value()` from typed VOs. |
| `ConsultantSqlCommandRepo.java` | SQL `:coef` → `:coefValue` pattern or custom JDBI binding for typed VOs. |
| `SaveCoefUseCase.java` | Convert raw doubles to typed VOs when constructing `Consultant`. |
| `CreateConsultantUseCase.java` | Convert raw doubles to typed VOs in `execute()`. |
| `UpdateConsultantUseCase.java` | Convert raw doubles to typed VOs in `execute()`. |
| `ConsultantController.java` | Minimal changes — signature-compatible with use case refactor. |

## JDBI Binding Approach

`ConsultantSqlCommandRepo` uses `@BindBean Consultant` for `save()`/`update()`.
With typed value objects, JDBI cannot bind `Coef` directly to a SQL `double`
column.

**Decision:** Add a `ConsultantBindings` helper that converts the typed Consultant
to a flat `Map` with `.value()` suffixed keys, and change the repo to bind the map
instead of the bean. This avoids framework magic and keeps the domain free of
persistence concerns.

Alternatively, if a simpler solution is found during implementation (e.g., JDBI
argument factory for value types), that may be used instead — the key constraint
is that DB interaction remains correct.

## Verification

1. Build compiles without errors
2. All existing tests pass
3. `Consultant.create()` rejects negative `Money` via `IllegalArgumentException`
4. `TaxRate` rejects values > 1.0
5. `ConsultantRes.from()` returns correct JSON-compatible doubles
6. `ConsultantRow.toDomain()` correctly reconstructs typed VOs
