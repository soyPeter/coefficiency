# Security Checklist

Pre-commit and pre-launch security verification.

## Pre-Commit Checks

- [ ] No secrets in diff (`git diff --staged | grep -i "password\|secret\|token"`)
- [ ] No hardcoded credentials
- [ ] No `TODO(security)` or `FIXME(security)` left unresolved
- [ ] Dependencies audited (`npm audit` / `mvn dependency:check`)

## Input Validation

- [ ] All user input validated at system boundaries
- [ ] SQL queries parameterized (no string concatenation)
- [ ] HTML output encoded/escaped
- [ ] File uploads: type and size restrictions
- [ ] Path traversal prevented

## Authentication

- [ ] Passwords hashed with bcrypt/scrypt/argon2 (salt >= 12)
- [ ] Session tokens: httpOnly, secure, sameSite
- [ ] Login rate limited
- [ ] Password reset tokens expire
- [ ] JWTs have reasonable expiry

## Authorization

- [ ] Every endpoint checks user permissions
- [ ] Users can only access own resources
- [ ] Admin actions require admin verification
- [ ] No privilege escalation paths

## Data Protection

- [ ] No secrets in code or version control
- [ ] Sensitive fields excluded from API responses
- [ ] PII encrypted at rest (if applicable)
- [ ] Logs don't contain sensitive data
- [ ] Stack traces not exposed to users

## Infrastructure

- [ ] Security headers configured (CSP, HSTS, X-Frame-Options)
- [ ] CORS restricted to known origins (not wildcard)
- [ ] HTTPS enforced
- [ ] Rate limiting active
- [ ] Error messages don't expose internals

## AI Agent / Claude Code Security

Protect against secret leakage when using AI coding agents.

### Deny Rules (settings.json)

- [ ] `.claude/settings.json` has `deny` rules for `.env*` files
- [ ] `.claude/settings.json` denies reading `*.pem`, `*.key`, `secrets/**`, `credentials/**`
- [ ] `.claude/settings.json` denies reading `.aws/**`, `.ssh/**`, `.npmrc`, `.pypirc`
- [ ] `.claude/settings.json` denies writing `.env*`, `secrets/**`, `.ssh/**`
- [ ] `.claude/settings.json` denies dangerous Bash: `rm -rf *`, `sudo *`, `git push *`, `curl * | sh`

### Three Leak Paths to Block

1. **Direct file read** — Blocked by deny rules in settings.json
2. **Runtime output capture** — Use `.env.test` with dummy values for test runs
3. **Grep/search tools** — Blocked by deny rules; secrets in config files won't be searched

### Test Environment Safety

- [ ] `.env.test` exists with dummy values (Stripe: `sk_test_not_real`, AWS: `AKIA...EXAMPLE`)
- [ ] Test framework points to `.env.test`, not `.env`
- [ ] `.env.test` is committed to repo (safe — all values are fake)
- [ ] `.env` and `.env.local` are in `.gitignore`

### Pre-Commit Secret Scan

- [ ] `scripts/secret-scan.py` runs on every commit
- [ ] Patterns cover: AWS keys, GitHub tokens, Stripe keys, Anthropic keys, JWTs, private keys
- [ ] False positives excluded (`.env.test`, `.env.example`)

### Container Isolation (Optional)

For maximum security with production credentials:
```bash
# Mount /dev/null over .env so agent can't see it
docker run -v /dev/null:/app/.env:ro your-dev-container
```
