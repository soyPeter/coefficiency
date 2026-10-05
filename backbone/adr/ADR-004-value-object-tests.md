# ADR-004: A test class per value object

## Status
Accepted

## Date
Before 2026-10-05 (migrated from decision D-009; the original date was not recorded)

## Context
The value objects and the `Consultant` domain record introduced for Javalin parity (M7) had no tests, and the project ran in TDD mode at the time.

## Decision
Write tests per value object: 44 tests across 8 test classes covering validation, equality and the `Consultant` factory methods.

## Alternatives considered
- Testing value objects only indirectly through service tests: cheaper, but validation failures would surface far from their cause.

## Consequences
- Validation and equality rules of every value object are pinned by fast unit tests, so regressions show up immediately.
- New value objects come with their own test class.
