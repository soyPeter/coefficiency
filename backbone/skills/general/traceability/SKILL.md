---
name: "Traceability Conventions"
description: "Maintain bidirectional mapping between requirements, design, code, and tests using per-feature YAML matrices. Ensures nothing is orphaned."
framework: "general"
---
<!-- FRAMEWORK: GENERAL -->
# Traceability Conventions

## Purpose

Maintain a bidirectional mapping between requirements, design documents, code, and tests. Traceability ensures nothing is orphaned and everything is verifiable.

## When to Use

- After requirements are written (link to design)
- After design is approved (link to code and tests)
- During implementation (update code/test links)
- Before commit (verify matrix is complete)

## Format

Per-feature YAML files in `storage/traceability/`:

```yaml
# storage/traceability/<feature>.yml
feature: "user-authentication"
prd: "backbone/prd/2026-05-01-auth.md"
design: "backbone/design/auth-design.md"

requirements:
  REQ-AUTH-001:
    title: "User login"
    design_section: "3.1 Authentication Flow"
    code:
      - "src/auth/controller.ts:login()"
      - "src/auth/service.ts:authenticate()"
    tests:
      - "tests/auth/test_login.py:test_valid_credentials"
      - "tests/auth/test_login.py:test_invalid_password"

  REQ-AUTH-002:
    title: "Session refresh"
    design_section: "3.2 Session Management"
    code:
      - "src/auth/middleware.ts:refreshToken()"
    tests:
      - "tests/auth/test_session.py:test_token_refresh"
```

## Rules

1. **One file per feature** — Avoid merge conflicts.
2. **REQ-ID is the key** — Every requirement from the PRD appears exactly once.
3. **Code references include function/method** — Not just file paths.
4. **Test references include test name** — Not just test file.
5. **No orphaned requirements** — Every REQ must have at least one code and one test entry.
6. **No orphaned code** — Every code entry must link to a REQ.

## Verification

Run `scripts/verify-traceability.sh` before commit:

```bash
# Check specific feature
./scripts/verify-traceability.sh storage/traceability/auth.yml

# Check all features
./scripts/verify-traceability.sh
```

Checks:
- All requirement IDs are unique across all files
- Linked files exist
- No orphaned requirements (missing code or tests)
- No orphaned code (code files not linked to any REQ)

## Anti-Patterns

| Bad | Good |
|-----|------|
| One global traceability.yml | Per-feature YAML files |
| File paths only | File:Function references |
| Test files only | TestFile:TestName references |
| Manual only | Verified by script in CI |

## Updating During Development

1. Write requirement in PRD → Add to traceability YAML
2. Implement code → Add code reference to YAML
3. Write tests → Add test reference to YAML
4. Before commit → Run `verify-traceability.sh`

## Storage Convention

- **Location:** `storage/traceability/<feature>.yml`
- **Index:** Add entry to `storage/traceability/index.yml`
- **Task reference:** Link from `backbone/3-TASKS.md`:
  ```markdown
  - [ ] trace: Auth traceability matrix (Traceability: storage/traceability/auth.yml)
  ```
