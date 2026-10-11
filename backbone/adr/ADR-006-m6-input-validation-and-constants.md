# ADR-006: Simulator input validation, reconciled defaults, named constants and English i18n keys

## Status
Accepted

## Date
Before 2026-10-05 (migrated from decision D-011; the original date was not recorded)

## Context
Four M6 code-review suggestions remained open:
- input validation for the simulator's concept parameters;
- reconciling hardcoded defaults with `application.conf`;
- extracting repeated map-key strings into constants;
- standardising i18n keys to English.

## Decision
1. `SimulatorController.validateInput()` checks that every numeric parameter is non-negative, and throws `BadRequestException` otherwise.
2. The missing `fiscal.report_target_revenue` and `fiscal.report_target_margin` seed entries were added in `CoeffConfig`.
3. Repeated map-key and settings-key literals in `BillingService` and `ReportService` became `private static final` constants.
4. Spanish-origin i18n keys were renamed to English (e.g. `menu.principal` to `menu.main`) in both `en.ts` and `es.ts`, and hard-coded labels in `SimulatorPage.tsx` and `ReportsPage.tsx` use `<FormattedMessage>`.

## Alternatives considered
- Validating simulator input only in the frontend: the API would still accept malformed requests from other clients.
- Leaving map keys as literals: fewer lines, but typos and contract changes go unnoticed.

## Consequences
- Malformed simulator requests fail early with 400 instead of producing wrong results.
- Programmatic defaults match the seeded database values.
- All i18n keys follow the English-only naming rule (`7-CONVENTIONS.md`).
