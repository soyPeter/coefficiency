# Code Review — coefficiency (services/coeff)

**Date:** 2026-05-18 | **Depth:** STANDARD | **Reviewer:** AI code review

---

## Summary

| Category | Count |
|----------|-------|
| Blockers (MUST FIX) | 5 |
| Warnings (SHOULD FIX) | 10 |
| Suggestions (CONSIDER) | 8 |

---

## Blockers (MUST FIX)

### B1 — Token decode mismatch: `atob()` on hex-encoded token — `frontend/src/pages/LoginPage.tsx:22-24`

The backend produces hex-encoded tokens via `HexFormat.of().formatHex(...)` in `AuthService.java:69`. The frontend tries to decode them with `atob()` (base64), which always fails. The `catch` block returns `false`, so `hasValidToken()` **always returns `false`**. Users can never persist a login session; page refresh sends them back to the login screen.

```typescript
// LoginPage.tsx:22 — always fails
const decoded = atob(token); // token is hex, not base64
```

**Fix:** Either hex-decode client-side, or have the backend produce base64 tokens to match.

---

### B2 — `findById` returns `Optional<Consultant>` but column mapping is broken — `consultant/infra/data/sql/ConsultantSqlCommandRepo.java:28-29`

`Consultant` (domain record) has camelCase fields (`startDate`, `endDate`, `coefPercentage`, etc.) but DB columns are snake_case (`start_date`, `end_date`, `coef_percentage`). The record lacks `@ColumnName` annotations. JDBI's default `ConstructorMapper` will fail to map snake_case columns to camelCase constructor parameters.

`@RegisterConstructorMapper(ConsultantRow.class)` on the interface only registers a mapper for `ConsultantRow` — it does not affect the `Optional<Consultant>` return type.

**Impact:** `UpdateConsultantUseCase.findById()` will throw a mapping exception or populate null fields at runtime.

**Evidence:** `ConsultantRow.java:7-21` has `@ColumnName` annotations; `Consultant.java:5-10` does not.

---

### B3 — Sort, order, and search parameters are silently ignored — `consultant/infra/data/sql/ConsultantSqlQueryRepo.java:12-17`

```java
@SqlQuery("SELECT * FROM consultants ORDER BY name ASC LIMIT :limit OFFSET :offset")
List<ConsultantRow> findAll(int offset, int limit, String sort, String order, String search);

@SqlQuery("SELECT COUNT(*) FROM consultants")
long count(String search);
```

The SQL is hardcoded to `ORDER BY name ASC` with no `WHERE` clause. The `sort`, `order`, and `search` parameters are accepted but never used in the queries. The UI sends sort/order/search values that are silently discarded.

**Impact:** Sorting by any column other than name does not work. Text search (search box in consultants page) does not filter results. Pagination counts are wrong when a search term is active.

---

### B4 — CSV parsing breaks on fields containing commas — `file/FileImportController.java:26`

```java
var parts = line.split(",");
```

A naive `String.split(",")` splits every comma, including those inside quoted fields (e.g., `"Acme, Inc"`). No CSV-aware parsing is used.

**Impact:** Any client name, consultant name, or position containing a comma will produce misaligned columns.

---

### B5 — CSV column order mismatch between code and documentation — `file/FileImportController.java:29-33` vs `doc/DocsController.java:73-76`

`FileImportController` expects columns: `name, client, position, coef, tariff, startDate, endDate, fees`. But `DocsController` documents columns as: `name, client, position, tariff, startDate, endDate` (missing `coef` and `fees`). The frontend import page shows yet another format. Three different column schemas exist for the same import.

**Impact:** Users following the documentation will produce incorrect imports.

---

## Warnings (SHOULD FIX)

### W1 — Hardcoded cryptographic secret — `auth/AuthService.java:26`

```java
private static final String HMAC_SECRET = "coeff-hmac-secret-2026";
```

The HMAC secret is hardcoded in source code and committed to the repository. Anyone with source access can forge tokens.

**Rationale:** For a local desktop app this has lower risk, but it should still be loaded from a config file or environment variable.

---

### W2 — Dead code: `ExceptionMapper` never installed — `shared/exceptions/ExceptionMapper.java:8-26`

`ExceptionMapper` duplicates the error handling logic from `CoeffConfig.errorHandling()` but is never registered in `CoeffApplication`. It has the same error-code mapping and JSON responses, but with fewer status codes (missing 409 `ConflictException`).

**Rationale:** Dead code causes confusion. Remove it or use it in place of `CoeffConfig.errorHandling()`.

---

### W3 — Misleading `@RegisterConstructorMapper` on mixed-type interface — `consultant/infra/data/sql/ConsultantSqlCommandRepo.java:12-13`

```java
@RegisterConstructorMapper(ConsultantRow.class)
public interface ConsultantSqlCommandRepo extends ConsultantAction {
```

The interface registers `ConsultantRow` mapper but also contains methods returning `Consultant` (line 29). The annotation only affects `ConsultantRow` return types, not `Consultant`. This is misleading — a reader might think it's configured for all methods.

---

### W4 — Controllers bypassing service layer — `simulator/ConceptsController.java:19-44` and `simulator/SettingsController.java:30-47`

Both controllers inject `Jdbi` directly and execute raw SQL in route handlers. Per the architecture rules, controllers should delegate to services or use cases, not access the database directly.

**Example:**
```java
// ConceptsController.java:31
jdbi.useHandle(h -> h.createUpdate("INSERT INTO cost_concepts ...").execute());
```

Compare to `ConsultantController` which properly delegates to `CreateConsultantUseCase`.

---

### W5 — Auth controller package location is inconsistent — `auth/AuthController.java`

Per the architecture rules, REST controllers belong in `infra/io/rest/`. `ConsultantController` follows this (in `consultant/infra/rest/`), but `AuthController` is at the root package level `io.bitnomio.coeff.auth`. The same applies to `BillingController`, `ClientController`, `DocsController`, `FileImportController`, `SimulatorController`, `SettingsController`, and `ConceptsController` — only `ConsultantController` follows the architecture.

---

### W6 — `ObjectMapper` instantiated per-call — `simulator/SettingsController.java:59,89-90`

```java
new com.fasterxml.jackson.databind.ObjectMapper().readTree(v)
new com.fasterxml.jackson.databind.ObjectMapper().readValue(val, ...)
```

`ObjectMapper` is expensive to construct. It should be a singleton or injected via DI. The app already has `Jackson2Module` installed.

---

### W7 — No content-type or size validation on file upload — `file/FileImportController.java:20`

The endpoint accepts any `POST` body as string content. There's no check for `Content-Type: text/csv`, no file extension validation, and no size limit. A user could send arbitrary binary data.

---

### W8 — Weak password minimum — `auth/AuthController.java:68-69`

```java
if (req.password().length() < 4) throw new IllegalArgumentException("Password must be at least 4 characters");
```

A 4-character minimum is insufficient for any meaningful security. Consider at least 8 characters or implement a configurable policy.

---

### W9 — Duplicate authentication error for 503 status — `frontend/src/api.ts:27-30`

```typescript
if (res.status === 401 || res.status === 503) {
    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
```

A 503 (Service Unavailable) triggers the same logout-redirect as a 401. If the server is temporarily unresponsive, the user gets forcefully logged out.

---

### W10 — `@Inject` on no-arg constructor — `doc/DocsController.java:13-15`

```java
@Inject
public DocsController() {}
```

Avaje injects singletons without `@Inject` on a no-arg constructor. The annotation is unnecessary and misleading.

---

## Suggestions (CONSIDER)

### S1 — Missing input validation on ConceptsController

`ConceptsController.create()` accepts `name`, `type`, and `defaultValue` without validation. The `type` field has a DB CHECK constraint (`IN ('monthly','yearly','onetime')`), but the error message from a constraint violation would be unfriendly.

### S2 — Hardcoded simulator constants differ from DB-backed billing defaults

`SimulatorService` hardcodes `COEF_DAYS_MONTH = 21` and `COEF_DAYS_YEAR = 252`. `BillingService` reads these from the `settings` table. Changing the setting changes billing but not simulator defaults — users see inconsistent numbers.

### S3 — `SecureRandom` instantiated per call — `auth/AuthService.java:50`

```java
new SecureRandom().nextBytes(bytes);
```

Creating a new `SecureRandom` instance per call is slow. Use a `static final` instance.

### S4 — Magic strings for setting keys — `billing/BillingService.java:43-47`

```java
h.createQuery("SELECT COALESCE(value,'21') FROM settings WHERE key='fiscal.coefDaysMonth'")
```

Setting keys like `'fiscal.coefDaysMonth'` are scattered across multiple files. Consolidate into a constants class.

### S5 — Redundant EXEMPT_PATHS — `CoeffConfig.java:38-40`

`/api/auth/status`, `/api/auth/setup`, `/api/auth/login`, `/api/auth/logout` are individually listed in `EXEMPT_PATHS` AND covered by the `/api/auth/` prefix in `EXEMPT_PREFIXES`. The individual paths are redundant.

### S6 — Very large component — `frontend/src/pages/ConsultantsPage.tsx` (878 lines)

The consultants page is nearly 900 lines with inline charts, forms, dropdowns, and CRUD logic. Consider splitting into smaller components (ConsultantTable, ConsultantForm, ConsultantCharts).

### S7 — Very large hook — `frontend/src/hooks/use-file-upload.ts` (387 lines)

The file upload hook mixes validation, drag-and-drop event handling, preview generation, and state management. Consider extracting validation and DnD handling into separate modules.

### S8 — Spanish key name in i18n — `frontend/src/i18n/en.ts:4`

```typescript
'menu.principal': 'Main',
```

The i18n key uses the Spanish word "principal" while all other keys use English. Inconsistent.

---

## Architecture Findings

### Layer compliance (consultant module): PASS
The consultant module follows DDD/Hexagonal architecture correctly:
- `domain/` — `Consultant` (record, no framework imports), `ConsultantAction` (port interface)
- `app/` — `CreateConsultantUseCase`, `UpdateConsultantUseCase`, `DeleteConsultantUseCase`
- `infra/` — REST controller, DTOs (`ConsultantRes`, `Create/UpdateConsultantReq`), SQL repos (`ConsultantRow`, `ConsultantSqlCommandRepo`, `ConsultantSqlQueryRepo`)
- Import direction: `infra → app → domain` (correct, no inversions)

### Layer compliance (all other modules): FAIL
The `auth`, `billing`, `client`, `simulator`, `doc`, and `file` modules do not follow the layered architecture. Controllers and services coexist in flat packages at the root level. Only `ConsultantController` is placed in `infra/rest/`.

### Direct Jdbi usage in controllers
`ConceptsController` and `SettingsController` inject `Jdbi` directly and execute SQL in route handlers. This bypasses the application layer (use cases/services) — an architecture violation per DDD rules.

### Framework-free domain: PASS
`Consultant.java` and `ConsultantAction.java` contain no framework imports (no Jooby, no JDBI, no Jakarta annotations). They use only `java.*` classes.

---

## Security Findings

| Finding | Severity | File |
|---------|----------|------|
| Hardcoded HMAC secret in source | Medium | `auth/AuthService.java:26` |
| CORS `Access-Control-Allow-Origin: *` with credentialed auth | Low | `CoeffConfig.java:73` |
| Password minimum length of 4 characters | Medium | `auth/AuthController.java:69` |
| No input validation on ConceptsController SQL inserts | Low | `simulator/ConceptsController.java:30-32` |
| SQLite file encryption key stored alongside encrypted DB | Info | `shared/db/DbEncryption.java:66` |
| sendBeacon logout on page unload is not guaranteed | Low | `frontend/src/pages/LoginPage.tsx` (via `App.tsx:35`) |

**Note on SQL injection:** All queries use JDBI parameterized bindings (`:param` or `@BindBean`). No raw string concatenation in SQL was found. SQL injection risk is low.

---

## Test Coverage

| Area | Tests Found | Status |
|------|-------------|--------|
| Backend Java (main) | 0 | MISSING |
| Backend Java (integration) | 0 | MISSING |
| Frontend TypeScript | 0 | MISSING |

No test files were found in `src/test/java/`, `src/intTest/java/`, or `frontend/src/__tests__/`. The `build.gradle.kts` configures JUnit 5, an `intTest` source set, and test dependencies, but no tests have been written.

**Key untested paths:**
- `AuthService.createToken()` / `validateToken()` — token lifecycle
- `DbEncryption.encrypt()` / `decrypt()` — crypto operations
- `TaxEngine.calculateIrpf()` — progressive bracket math
- `FileImportController.upload()` — CSV parsing logic
- `useIdleTimer` hook — timer state machine
- All JDBI repository interfaces — database queries

---

*See `docs/project/architecture.md` for the architecture rules referenced in this review. Open items are tracked in `TASKS.md` (M6).*
