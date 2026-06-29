# Design Document: Security

**PRD Reference:** [20260515-security.md](../prd/20260515-security.md)
**Date:** 2026-05-15
**Status:** Draft

---

## 1. System Context (C4 Level 1)

Security layer for the single-user desktop COEF Calculator application. Handles authentication, API authorization, and database encryption.

### Actors
- **Consulting Manager**: Authenticates via password to access the application.

### External Systems
- None. All security is self-contained (password auth, local tokens, local encryption).

---

## 2. Container Diagram (C4 Level 2)

```
┌──────────────────────────────────────────────────────────────┐
│                      User's Machine                          │
│                                                              │
│  ┌──────────────┐     ┌────────────────┐    ┌─────────────┐  │
│  │              │     │                │    │             │  │
│  │  Browser     │────▶│  Jooby Server  │───▶│  SQLite DB  │  │
│  │  (SPA)       │     │  (Netty)       │    │  (on disk)  │  │
│  │              │     │                │    │             │  │
│  │  localStorage│     │  AuthFilter    │    │  app.db.enc │  │
│  │  token       │     │  AuthService   │    │  (AES-256)  │  │
│  │              │     │  DbEncryption  │    │             │  │
│  └──────────────┘     └────────────────┘    └─────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Containers
| Container | Technology | Responsibility |
|-----------|------------|----------------|
| Browser SPA | React 19 | Login form, token storage, 401/503 redirect |
| Jooby Server | Jooby 4.5.1 | Auth endpoints, token validation filter, DB encryption lifecycle |
| SQLite Database | SQLite | User records, encrypted at rest |

---

## 3. Component Design (C4 Level 3)

### Backend Components

| Component | Layer | Responsibility |
|-----------|-------|----------------|
| `AuthController` | infra/io/rest | `POST /api/auth/setup`, `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/status` |
| `AuthService` | app | Password hashing (SHA-256 + salt), token creation (HMAC-SHA256), token validation |
| `AuthRepository` | app (interface) | Port for user persistence |
| `SqliteAuthRepository` | infra/data/persistence | JDBI-based user CRUD: findByUsername, save, exists |
| `DbEncryption` | infra/config | AES-256-GCM encrypt/decrypt of SQLite file, PBKDF2 key derivation, periodic re-encryption |
| `AuthFilter` | infra/io/rest | Jooby before-filter validating Bearer token on all `/api/*` routes (except exempt) |
| `CoeffApplication` | root | Registers AuthFilter, shutdown hook for re-encryption |

### Frontend Components

| Component | Responsibility |
|-----------|----------------|
| `api.ts` | HTTP client with Bearer token injection |
| `LoginPage` | Login/setup form (auto-detects if first user) |
| `AuthGuard` | Route wrapper that redirects to login on 401/503 |

### Interactions

```
Login flow:
  Browser ──POST /api/auth/login──▶ AuthController ──▶ AuthService
                                                          ├── AuthRepository.findByUsername (SHA-256 verify)
                                                          └── return HMAC token
  Browser ◀── 200 { token } ────────

Authenticated request:
  Browser ──GET /api/consultants (Authorization: Bearer <token>)──▶ AuthFilter
                                                                      └── AuthService.validateToken
                                                                              └── if invalid → 401
  On 401/503:
  Browser ◀── 401 ──▶ api.ts ──▶ App.tsx redirect to /login

DB Encryption:
  Login: .db-key (salt+verifier) + password → PBKDF2 → AES key → decrypt app.db.enc → .app.db
  Logout: .app.db → AES encrypt → app.db.enc, delete .app.db
  Every 5 min: re-encrypt .app.db → app.db.enc
```

---

## 4. Architecture Decisions

### ADR-001: HMAC-SHA256 Tokens

**Status:** Accepted
**Context:** Need session tokens without external auth infrastructure (SSO, OAuth). Desktop app with single user.
**Decision:** Use HMAC-SHA256 with a fixed server-side secret. Token = `HMAC-SHA256(username + expiry, secret)`. Token expiry set to 24 hours. No refresh tokens.
**Consequences:**
- Tokens cannot be revoked individually (no token store)
- If the secret leaks, all tokens are compromised (acceptable for local desktop app)
- No database lookup needed for token validation (fast)

### ADR-002: AES-256-GCM Database Encryption

**Context:** Consultant data (salary, margins, fees) is sensitive and must be encrypted at rest.
**Decision:** Encrypt the entire SQLite file using AES-256-GCM. Key derived from login password via PBKDF2-HMAC-SHA256 (100k iterations). Encrypted file is `app.db.enc`, decrypted to `.app.db` temp file during session.
**Consequences:**
- Database is only accessible while the user is logged in
- Decrypted file is on disk (temp) during session — crash could leak data (mitigated by 5-min periodic re-encryption)
- Encrypted on logout and every 5 minutes
- Password change requires re-encrypting the database with new key

### ADR-003: SHA-256 + Salt Password Storage

**Context:** Need to store passwords securely. bcrypt/scrypt would add dependencies.
**Decision:** Use SHA-256 with per-user 16-byte random salt. Salt stored alongside password hash.
**Consequences:**
- SHA-256 is fast (can be brute-forced with GPUs) — acceptable for local desktop app
- Per-user salt prevents rainbow table attacks
- Minimum password length of 4 chars reduces brute-force risk somewhat

### ADR-004: Auth Before-Filter on All /api/* Routes

**Context:** Must protect all API endpoints except auth and public ones.
**Decision:** Jooby `before()` filter checks for Bearer token on all `/api/*` requests. Exempted: `/api/auth/*`, `/api/health`, `/openapi*`, `/swagger*`, `/redoc*`.
**Consequences:**
- Single point of enforcement — new endpoints are protected by default
- Filter runs on every request (negligible overhead for local app)
- No annotation-based security (simpler for monolithic app)

---

## 5. API Contracts

### GET /api/auth/status

**Response:**
```json
{
  "hasUser": true,
  "authenticated": false
}
```

### POST /api/auth/setup

**Request:**
```json
{
  "username": "admin",
  "password": "secret123"
}
```

**Validation:** username >= 3 chars, password >= 4 chars.

**Response (Success):** 200
```json
{
  "token": "hmac-signed-token-string"
}
```

**Response (Error):** 400 if user already exists or validation fails.

### POST /api/auth/login

**Request:**
```json
{
  "username": "admin",
  "password": "secret123"
}
```

**Response (Success):** 200
```json
{
  "token": "hmac-signed-token-string"
}
```

**Response (Error):** 401 if invalid credentials.

### POST /api/auth/logout

**Headers:** `Authorization: Bearer <token>`

**Response:** 204 No Content.

### Error Responses

| Status | Body | Condition |
|--------|------|-----------|
| 401 | `{"error":"Unauthorized"}` | Invalid/missing token |
| 503 | `{"error":"DB not connected"}` | DB not yet decrypted |

---

## 6. Data Model

### users (existing table)

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | INTEGER | PK AUTOINCREMENT | User ID |
| username | TEXT | UNIQUE NOT NULL | Login name (3+ chars) |
| password_hash | TEXT | NOT NULL | SHA-256(salt + password) |
| salt | TEXT | NOT NULL | 16-byte random hex salt |
| created_at | TEXT | NOT NULL DEFAULT CURRENT_TIMESTAMP | Creation timestamp |

### File-Based State

| File | Purpose | Persistence |
|------|---------|-------------|
| `data/.db-key` | Salt + SHA-256 verifier of the encryption key | Always on disk |
| `data/app.db.enc` | AES-256-GCM encrypted SQLite database | Always on disk |
| `data/.app.db` | Decrypted SQLite temp file | Only while running |
| `data/coeff.db` | Decrypted SQLite (final path) | Only while running |

---

## 7. Traceability

| Requirement ID | Summary | Design Section | Status |
|----------------|---------|----------------|--------|
| REQ-SEC-001 | User Setup | §3 (AuthController), §5, §6 | Draft |
| REQ-SEC-002 | Login + HMAC token | §3 (AuthService), §4 ADR-001 | Draft |
| REQ-SEC-003 | Token Validation Middleware | §3 (AuthFilter), §4 ADR-004 | Draft |
| REQ-SEC-004 | Frontend Token Delivery | §3 (api.ts), §4 ADR-001 | Draft |
| REQ-SEC-005 | 401/503 Auto-Logout | §3 (AuthGuard, api.ts) | Draft |
| REQ-SEC-006 | DB Encryption at Rest | §3 (DbEncryption), §4 ADR-002 | Draft |
| REQ-SEC-007 | Password-Derived Key | §3 (DbEncryption), §4 ADR-002 | Draft |
| REQ-SEC-008 | DB Decryption on Login | §3 (DbEncryption, AuthService) | Draft |
| REQ-SEC-009 | DB Re-Encryption on Logout | §3 (DbEncryption, CoeffApplication) | Draft |
| REQ-SEC-010 | Periodic DB Sync (5 min) | §3 (DbEncryption) | Draft |
| REQ-SEC-011 | sendBeacon Logout | §3 (api.ts, LoginPage) | Draft |
| REQ-SEC-012 | Password Hashing | §3 (AuthService), §4 ADR-003 | Draft |

---

**Review History:**
| Date | Reviewer | Verdict | Notes |
|------|----------|---------|-------|
| | | | |
