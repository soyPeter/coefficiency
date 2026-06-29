# Tasks — CHNG-008: Javalin Parity Phase 1: Value Objects

## Task List

- [x] Add `Money.java` value object to `shared/domain/` with non-negative validation
- [x] Add `Coef.java` value object to `shared/domain/` with non-negative validation
- [x] Add `CoefPct.java` value object to `shared/domain/` with non-negative validation
- [x] Add `Tariff.java` value object to `shared/domain/` with non-negative validation
- [x] Add `Salary.java` value object to `shared/domain/` with non-negative validation
- [x] Add `Bonus.java` value object to `shared/domain/` with non-negative validation
- [x] Add `TaxRate.java` value object to `shared/domain/` with [0, 1] validation
- [x] Refactor `Consultant.java` — replace 13 double/Double fields with typed VOs, update `create()`/`update()` factories
- [x] Update `ConsultantRow.toDomain()` to construct typed VOs from raw DB doubles, and `ConsultantRes.from()` to extract raw doubles via `.value()`
- [x] Fix `ConsultantSqlCommandRepo` JDBI `@BindBean` for typed VOs — add binding adapter or map-based persistence
- [x] Update use cases (`SaveCoefUseCase`, `CreateConsultantUseCase`, `UpdateConsultantUseCase`) to convert raw doubles to typed VOs
- [x] Update `ConsultantController` — adjust if use case signatures changed, verify DTO mapping is intact
- [x] Build, run tests, and fix any compilation or test failures across the project

## Task Granularity Legend

| Tag | Scope |
|-----|-------|
| [XS] | Single file, known pattern, ~5-10 lines |
| [S]  | Single file or two related files, ~10-30 lines |
| [M]  | Multiple files across one layer, ~30-80 lines |
