---
name: "EARS Requirements Format"
description: "Write unambiguous, testable requirements using Easy Approach to Requirements Syntax (EARS). Eliminates ambiguity with 5 constrained natural language patterns."
framework: "general"
---
<!-- FRAMEWORK: GENERAL -->
# EARS Requirements Format

## Purpose

Write unambiguous, testable requirements using the Easy Approach to Requirements Syntax (EARS). EARS eliminates ambiguity by enforcing a constrained natural language pattern that is both human-readable and machine-parseable.

## When to Use

- Writing PRD requirements sections
- Defining acceptance criteria for tasks
- Creating testable specifications before implementation
- Any time you need to communicate "what the system shall do" without prescribing "how"

## The 5 EARS Patterns

### 1. Ubiquitous Requirements (Always true)
```
The <system> SHALL <response>.
```
**Example:**
> The system SHALL validate all user input before processing.

### 2. Event-Driven Requirements (When something happens)
```
WHEN <event>, the <system> SHALL <response>.
```
**Example:**
> WHEN the user submits the login form, the system SHALL authenticate the credentials.

### 3. State-Driven Requirements (While in a state)
```
WHILE <state>, the <system> SHALL <response>.
```
**Example:**
> WHILE the user session is active, the system SHALL refresh the access token every 15 minutes.

### 4. Optional Feature Requirements (If applicable)
```
IF <condition>, THEN the <system> SHALL <response>.
```
**Example:**
> IF the user has enabled two-factor authentication, THEN the system SHALL prompt for an OTP code.

### 5. Complex Requirements (Multiple conditions)
```
WHEN <event> AND <condition>, the <system> SHALL <response>.
```
**Example:**
> WHEN the payment is submitted AND the amount exceeds $10,000, the system SHALL require manager approval.

## EARS Rules

1. **One SHALL per requirement** — Each requirement contains exactly one `SHALL` statement.
2. **No conjunctions in SHALL clause** — "The system SHALL validate and save" → split into two requirements.
3. **Active voice only** — "The user SHALL be authenticated" → "The system SHALL authenticate the user."
4. **Measurable responses** — "The system SHALL be fast" → "The system SHALL respond within 200ms."
5. **No implementation details** — "The system SHALL use Redis" → "The system SHALL cache session data."

## Requirement ID Convention

```
REQ-<DOMAIN>-<NNN>
```

- **DOMAIN**: 3-4 letter feature area (AUTH, USER, PAYM, ORDR, etc.)
- **NNN**: Zero-padded sequence number (001, 002, ...)
- **Example:** REQ-AUTH-001, REQ-AUTH-002

## Traceability

Every requirement MUST be traceable:
```
REQ-AUTH-001: WHEN the user provides valid credentials, the system SHALL authenticate the user.
  → Design: design/auth-design.md#session-management
  → Code: src/auth/service.ts:authenticate()
  → Tests: tests/auth/test_login.py:test_valid_credentials
```

## Anti-Patterns

| Bad | Good |
|-----|------|
| The system should validate input. | The system SHALL validate all user input. |
| The user can log in. | WHEN the user submits valid credentials, the system SHALL authenticate the user. |
| The system must be secure. | The system SHALL encrypt all passwords using bcrypt with cost factor 12. |
| Fast response time. | The system SHALL respond to API requests within 200ms at p99. |

## Verification

Before finalizing requirements:
1. [ ] Every requirement has exactly one SHALL
2. [ ] Every requirement has a unique ID
3. [ ] No implementation details in requirements
4. [ ] Every requirement is testable (can write a test that passes/fails)
5. [ ] Requirements trace to design docs
