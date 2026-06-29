# Decisions — CHNG-008: Javalin Parity Phase 1: Value Objects

## D-001: Use Java records for value objects

**Type:** Two-way door  
**Rationale:** Javalin reference uses records. They provide immutability, compact
validation, and zero boilerplate. No future change prevents migrating to classes
if needed.
**Status:** Accepted

## D-002: Keep same validation and error messages as Javalin

**Type:** Two-way door  
**Rationale:** Exact parity ensures the same domain invariants apply. Error
messages follow the pattern `"<Name> must be non-negative: " + value` for
consistency. TaxRate uses `"TaxRate must be between 0 and 1: " + value`.
**Status:** Accepted

## D-003: Nullable value objects instead of Optional

**Type:** Two-way door  
**Rationale:** Fields like `fees`, `coefPercentage`, `coefMargin`, `managerBonus`,
salary fields, and tax rates are nullable in the current model. Wrapping them in
`Optional` would break JDBI `@BindBean` compatibility and add complexity. Keeping
them as nullable records (null value object = "not set") is the simplest migration
path. The inner value is still validated when non-null.
**Status:** Accepted

## D-004: Use case signatures stay on raw doubles

**Type:** Two-way door  
**Rationale:** Use cases are called by the controller layer with raw doubles from
DTOs. Changing use case signatures to typed VOs would push the conversion burden
to the controller or DTO layer. Keeping raw doubles in application boundaries and
converting inside the use case isolates the change and preserves backward
compatibility.
**Status:** Accepted

## D-005: Persistence binding via adapter / map, not `@BindBean`

**Type:** One-way door (changes how repo works)  
**Rationale:** `@BindBean Consultant` breaks when a field is a `Coef` record
instead of a `double`. Rather than registering a global JDBI argument factory
(which adds framework coupling), we add a thin adapter that flattens typed VOs
to raw doubles for SQL. This keeps persistence explicit and debuggable.
**Status:** Accepted

## D-006: `Salary` value object created but not yet used

**Type:** Two-way door  
**Rationale:** The Javalin reference includes `Salary.java` in the shared domain,
so we create it for parity. It is not wired into `Consultant` in this phase
(Consultant uses `Money` for salary fields). Wiring `Salary` is deferred to a
future phase.
**Status:** Accepted

## D-007: Shared domain package uses `io.bitnomio.coeff.shared.domain`

**Type:** Two-way door  
**Rationale:** The coefficiency project already has `io.bitnomio.coeff.shared.db`,
`shared.exceptions`, and `shared.util` packages. Adding `shared.domain` is
consistent with existing conventions. The Javalin project uses
`io.bitnomio.javalin_coef_calc.shared.domain`.
**Status:** Accepted
