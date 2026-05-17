<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: source-driven-development
description: Grounds every implementation decision in official documentation. Use when you want authoritative, source-cited code free from outdated patterns.
---

# Source-Driven Development

Every framework-specific code decision must be backed by official documentation. Don't implement from memory — verify, cite, and let the user see your sources.

## When to Use

- Building boilerplate or starter code
- Implementing framework-specific features
- Reviewing framework-specific code
- User explicitly asks for documented/verified implementation

**Not for:** Pure logic, renaming variables, or speed-over-verification requests.

## Process

```
DETECT → FETCH → IMPLEMENT → CITE
```

### Step 1: Detect Stack and Versions

Read dependency files:

```
package.json    → Node/React/Vue
pom.xml         → Java/Maven
build.gradle    → Java/Gradle
```

State explicitly:
```
STACK DETECTED:
- Quarkus 3.15.1 (from pom.xml)
- Java 21
- PostgreSQL 16
→ Fetching official docs for relevant patterns.
```

### Step 2: Fetch Official Documentation

**Source hierarchy (most to least authoritative):**

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Official documentation | quarkus.io/guides, spring.io/docs |
| 2 | Official blog / changelog | quarkus.io/blog |
| 3 | Web standards | MDN, web.dev |
| 4 | Browser/runtime compatibility | caniuse.com |

**Not authoritative:**
- Stack Overflow
- Blog posts or tutorials
- AI-generated summaries
- Your own training data

### Step 3: Implement Following Documented Patterns

- Use API signatures from docs, not from memory
- If docs show a new way, use the new way
- If docs deprecate a pattern, don't use it
- If docs don't cover something, flag it as unverified

### Step 4: Cite Your Sources

**In code comments:**
```java
// Quarkus 3.15: Panache active record pattern
// Source: https://quarkus.io/guides/hibernate-orm-panache
@Entity
public class Task extends PanacheEntity {
    public String title;
    public TaskStatus status;
}
```

**Citation rules:**
- Full URLs, not shortened
- Quote relevant passages for non-obvious decisions
- If you cannot find documentation, say so explicitly:
  ```
  UNVERIFIED: I could not find official documentation for this pattern.
  This is based on training data and may be outdated.
  ```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident about this API" | Confidence is not evidence. Training data contains outdated patterns. |
| "Fetching docs wastes tokens" | Hallucinating an API wastes more. One fetch prevents hours of rework. |
| "This is a simple task, no need to check" | Simple tasks with wrong patterns become templates copied everywhere. |

## Red Flags

- Writing framework-specific code without checking docs
- Using "I believe" or "I think" about an API
- Citing Stack Overflow instead of official docs
- Using deprecated APIs from training data
- Delivering code without source citations
