# 1. Product Requirements: coefficiency

## What we are building
A local desktop tool for a consulting manager that replaces Excel spreadsheets for tracking consultant profitability. It manages consultants, clients and billing, runs a tax engine (IRPF + Social Security), calculates COEF and bonuses, and produces reports. It runs as a local HTTP server (Jooby) serving a React SPA, with all data in a local, encrypted SQLite database.

## Who it is for
One consulting manager working on their own machine: single user, no cloud, no multi-tenancy.

## What good looks like
- The manager can do everything the previous Javalin app and the Excel sheets did, with feature parity (milestone M7, done).
- Consultant data stays local and encrypted at rest (AES-256-GCM), behind a password with HMAC-signed session tokens.
- COEF and bonus results match the fiscal rules configured in the app (IRPF brackets, SS categories).
- The codebase follows the per-feature `domain/app/infra` layering, so features can change without touching each other (the open M6 work).

## Out of scope
Multi-user access, cloud deployment, mobile apps.

## Detailed PRDs
Each PRD below was grilled when it was written; the grilling Q&A is inside each file.

| Area | PRD | Design | Planning |
|---|---|---|---|
| Core platform | [prd](../docs/project/prd/20260515-core-platform.md) | [design](../docs/project/design/20260515-core-platform-design.md) | [planning](../docs/project/planning/20260515-core-platform-planning.md) |
| Security | [prd](../docs/project/prd/20260515-security.md) | [design](../docs/project/design/20260515-security-design.md) | [planning](../docs/project/planning/20260515-security-planning.md) |
| Consultant management | [prd](../docs/project/prd/20260515-consultant-mgmt.md) | [design](../docs/project/design/20260515-consultant-mgmt-design.md) | [planning](../docs/project/planning/20260515-consultant-mgmt-planning.md) |
| COEF simulator | [prd](../docs/project/prd/20260515-coef-simulator.md) | [design](../docs/project/design/20260515-coef-simulator-design.md) | [planning](../docs/project/planning/20260515-coef-simulator-planning.md) |
| Analytics and UI | [prd](../docs/project/prd/20260515-analytics-ui.md) | (none) | [planning](../docs/project/planning/20260515-analytics-ui-planning.md) |

Specs (`backbone/specs/<id>.md`) point at the PRD section they serve on their `PRD:` line.
