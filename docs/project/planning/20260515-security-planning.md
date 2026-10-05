# Planning: Security

**PRD Reference:** `docs/project/prd/20260515-security.md`
**Design Reference:** `docs/project/design/20260515-security-design.md`

## Summary

Three security layers: auth (login/setup/tokens), API authorization (before-filter), DB encryption (AES-256-GCM). Builds on existing coeff infrastructure (SqliteConnection, CoeffApplication).

## Dependency Graph

```
AuthService (HMAC tokens, password hashing)
    │
    ├── AuthController + AuthRepository + SqliteAuthRepository
    │       │
    │       └── AuthFilter (before-filter on /api/*)
    │
    ├── frontend/api.ts (token injection, 401/503 handling)
    ├── frontend/LoginPage (login/setup form)
    └── frontend/AuthGuard (route protection)
    
DbEncryption (AES-256-GCM, PBKDF2)
    │
    ├── SqliteConnection integration (lazy init after decrypt)
    └── CoeffApplication shutdown hook
```

## Vertical Slices

### Slice 1: Backend Auth
AuthService + AuthController + AuthRepository + AuthFilter. Login, setup, token validation, before-filter.

### Slice 2: Database Encryption
DbEncryption + SqliteConnection integration. File encrypt/decrypt, key derivation, periodic sync.

### Slice 3: Frontend Auth
api.ts + LoginPage + AuthGuard. Token handling, auto-redirect, sendBeacon logout.

## Tasks

### Task 1: [S] feat: create AuthService with HMAC token and password hashing

AuthService handles password hashing (SHA-256 + salt), HMAC-SHA256 token creation/validation, and token expiry checking. Token format: `HMAC-SHA256(username + expiry, secret)`. Secret constant stored in the class.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/app/AuthService.java`

### Task 2: [XS] feat: create AuthRepository and SqliteAuthRepository

AuthRepository port interface in app layer. SqliteAuthRepository JDBI-based implementation. findByUsername, save, exists methods on the users table.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/app/AuthRepository.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/data/persistence/sql/SqliteAuthRepository.java`

### Task 3: [S] feat: create AuthController with setup/login/logout endpoints

AuthController with POST /api/auth/setup, POST /api/auth/login, POST /api/auth/logout, GET /api/auth/status endpoints. Setup validates username/password length, creates first user. Login validates credentials, returns token. Logout is a no-op (stateless tokens).

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/io/rest/AuthController.java`

### Task 4: [S] feat: create AuthFilter for token validation on /api/* routes

Jooby before-filter that validates Bearer token on all /api/* requests. Exempts /api/auth/*, /api/health, /openapi*, /swagger*, /redoc*. Returns 401 on invalid/missing token, 503 on missing DB connection.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/io/rest/AuthFilter.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/CoeffApplication.java` (register filter, add exempt paths to error handler)

### Task 5: [M] feat: create DbEncryption for AES-256-GCM file encryption

DbEncryption handles AES-256-GCM encrypt/decrypt of the SQLite file. PBKDF2-HMAC-SHA256 (100k iterations) key derivation from login password. .db-key file stores salt + SHA-256 verifier. Periodic re-encryption every 5 minutes. Re-encrypts on logout/shutdown via CoeffApplication hook.

**Files:**
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/config/DbEncryption.java`
- `services/coeff/src/main/java/io/bitnomio/coeff/infra/config/SqliteConnection.java` (lazy init after decrypt)
- `services/coeff/src/main/java/io/bitnomio/coeff/CoeffApplication.java` (shutdown hook)

### Task 6: [S] feat: create frontend api.ts with auth headers and 401/503 handling

HTTP client wrapper that injects Bearer token from localStorage into all requests. On 401 or 503 responses, clears token and dispatches auth:unauthorized event for App.tsx to redirect to login. sendBeacon on page unload for logout.

**Files:**
- `services/coeff/frontend/src/api.ts`
- `services/coeff/frontend/src/App.tsx` (auth:unauthorized handler, AuthGuard)

### Task 7: [S] feat: create LoginPage with login/setup forms

LoginPage component. On first run (no user exists, determined by GET /api/auth/status), shows setup form (username + password). On subsequent runs, shows login form. On success, stores token in localStorage and redirects to /consultants. Protected routes (existing pages) require valid token.

**Files:**
- `services/coeff/frontend/src/pages/LoginPage.tsx`
- `services/coeff/frontend/src/App.tsx` (auth routing)

## Skills Required

- jooby/java-core — domain layer
- jooby/jooby-mvc — infra controllers
- frontend/frontend-patterns — React

## Risks

1. **AES-GCM nonce reuse**: If the encryption is called twice with the same key+nonce, the security breaks. Must ensure unique nonce per encryption operation.
2. **Crash during encryption**: In-progress re-encryption could corrupt both files. Use atomic write (write to .tmp, rename).
3. **Key derivation speed**: PBKDF2 with 100k iterations takes ~100ms on modern hardware. Acceptable for login but should not block the UI.
