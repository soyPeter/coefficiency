<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: deprecation-and-migration
description: Manages deprecation and migration. Use when removing old systems, APIs, or features. Use when migrating users from one implementation to another.
---

# Deprecation and Migration

Code is a liability, not an asset. Every line has ongoing cost. Deprecation is the discipline of removing code that no longer earns its keep.

## When to Use

- Replacing an old system, API, or library
- Sunsetting a feature that's no longer needed
- Consolidating duplicate implementations
- Removing dead code nobody owns but everybody depends on
- Planning lifecycle of a new system

## Core Principles

### Code Is a Liability

Every line has ongoing cost: tests, documentation, security patches, dependency updates, onboarding. When the same functionality can be provided with less code, remove the old code.

### Hyrum's Law Makes Removal Hard

With enough users, every observable behavior becomes depended on — including bugs. Deprecation requires active migration, not just announcement.

### Deprecation Planning Starts at Design Time

Ask: "How would we remove this in 3 years?"

## The Deprecation Decision

1. Does this system still provide unique value?
2. How many users/consumers depend on it?
3. Does a replacement exist?
4. What's migration cost for each consumer?
5. What's ongoing maintenance cost of NOT deprecating?

## Compulsory vs Advisory

| Type | When | Mechanism |
|------|------|-----------|
| Advisory | Migration optional, old system stable | Warnings, documentation, nudges |
| Compulsory | Security issues, blocks progress | Hard deadline + migration tooling |

**Default to advisory.**

## The Migration Process

### Step 1: Build the Replacement

- Must cover all critical use cases
- Must have documentation and migration guides
- Must be proven in production

### Step 2: Announce and Document

```markdown
## Deprecation Notice: OldService

**Status:** Deprecated as of 2025-03-01
**Replacement:** NewService
**Removal date:** Advisory — no hard deadline
**Reason:** OldService lacks observability. NewService handles it.

### Migration Guide
1. Replace imports
2. Update configuration
3. Run verification: ./gradlew check
```

### Step 3: Migrate Incrementally

One consumer at a time. **The Churn Rule:** If you own the infrastructure, you're responsible for migrating users.

### Step 4: Remove the Old System

Only after all consumers migrated:
1. Verify zero active usage
2. Remove code, tests, docs, config
3. Remove deprecation notices
4. Celebrate — removing code is an achievement

## Migration Patterns

### Strangler Pattern

Run old and new in parallel. Route traffic incrementally.

### Adapter Pattern

Create adapter translating old interface calls to new implementation.

### Feature Flag Migration

Switch consumers from old to new one at a time.

## Zombie Code

Code nobody owns but everybody depends on. Signs:
- No commits in 6+ months but active consumers
- No assigned maintainer
- Failing tests nobody fixes
- Dependencies with known vulnerabilities

**Response:** Assign owner and maintain, or deprecate with concrete migration plan.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It still works, why remove it?" | Working unmaintained code accumulates security debt. |
| "Someone might need it later" | If needed, it can be rebuilt. Keeping costs more than rebuilding. |
| "The migration is too expensive" | Compare to ongoing maintenance cost over 2-3 years. |
| "Users will migrate on their own" | They won't. Provide tooling, documentation, incentives. |

## Red Flags

- Deprecated systems with no replacement
- No migration tooling or documentation
- "Soft" deprecation advisory for years with no progress
- Zombie code with no owner and active consumers
- New features added to deprecated system

## Verification

- [ ] Replacement is production-proven
- [ ] Migration guide exists with concrete steps
- [ ] All active consumers migrated (verified)
- [ ] Old code, tests, docs fully removed
- [ ] No references to deprecated system remain
