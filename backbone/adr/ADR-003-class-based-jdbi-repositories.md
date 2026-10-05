# ADR-003: Class-based JDBI repositories with explicit binding helpers

## Status
Accepted

## Date
Before 2026-10-05 (migrated from decision D-008; the original date was not recorded)

## Context
`ConsultantSqlCommandRepo` was a JDBI SqlObject interface using `@BindBean Consultant` for `save()` and `update()`. After `Consultant` was refactored to typed value objects (records), `@BindBean` could no longer bind `Coef`, `Tariff` and the other value objects to SQL `double` columns.

## Decision
- `ConsultantSqlCommandRepo` is a class that takes `Jdbi` directly, instead of a `@RegisterConstructorMapper` interface.
- `ConsultantBindings` flattens the typed value objects to raw `double` values in a `Map<String, Object>`.
- `CoefJdbiFactory` creates `new ConsultantSqlCommandRepo(jdbi)` instead of `jdbi.onDemand(...)`.
- `ConstructorMapper.of(ConsultantRow.class)` is registered once on the shared `Jdbi` bean, because `SqliteConsultantQueryRepo` and `ConsultantController.getById()` also map to `ConsultantRow`.

## Alternatives considered
- A global JDBI argument factory per value type: keeps `@BindBean` working but adds framework coupling and hidden conversion rules.
- Keeping primitive fields in `Consultant`: loses the validation and type safety the value objects were introduced for.

## Consequences
- Persistence stays explicit and debuggable: every column binding is visible in one helper.
- New value objects need a line in the binding helper.
- `ConsultantController.getById()` reads `ConsultantRow` directly, which task 6.1 (no `Jdbi` in controllers) removes.
