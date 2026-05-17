<!-- FRAMEWORK: GENERAL -->
---
name: security-fixes
description: Guides secure disclosure of security fixes in public repositories. Use when working on a security fix, when the user mentions vulnerability, security issue, CVE, or when creating branches/commits/PRs for security-related changes.
framework: general
---

# Security Fix Hygiene

**This repository is public.** Attackers monitor open-source repos for signals in branch names, commits, PRs, and test descriptions. Never expose the attack vector or vulnerability type in any public-facing artifact.

## Core Rule

**Describe what the code does, not what threat it prevents.**

## Artifact Matrix

| Artifact | BAD (leaks vulnerability) | GOOD (neutral language) |
|----------|---------------------------|-------------------------|
| **Branch** | `fix-sql-injection` | `improve-input-validation` |
| **Commit** | `fix: prevent SSRF` | `fix: validate outgoing URLs` |
| **PR Title** | `fix(core): Prevent buffer overflow` | `fix(core): Add bounds checking` |
| **PR Body** | *"attacker could trigger XSS…"* | *"sanitizes user input before rendering"* |
| **Test** | `'should prevent SQL injection'` | `'should sanitize query parameters'` |
| **Comment** | `// fix for CSRF` | `// validate origin header` |
| **Ticket** | `.../fix-ssrf-vulnerability` | `.../N8N-1234` (ID only) |

## Rules

1. **Describe what the code does** — "add payload size validation"
2. **Never name the attack type** — no SQLi, XSS, SSRF, DoS, RCE, etc.
3. **Never describe the attack scenario** — no "attacker could..."
4. **Use functional language** — validate, sanitize, check, limit, bound
5. **Ticket references** — use ID only, never URL slug with vulnerability name

## Before Publishing

Verify no branch name, commit, PR title, PR body, test name, or code comment hints at the vulnerability.

**When in doubt, ask the user for review before pushing.**
