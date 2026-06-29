<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: caveman-compact
description: Output compression mode — cuts ~65% tokens by dropping filler, keeping substance. Optional mode for /backbone:task and /backbone:review commands. Inspired by JuliusBrussee/caveman and DietrichGebert/ponytail.
---

# Caveman Compact Mode (REQ-COMPACT-001)

Compress agent output to reduce token consumption by ~65%. Use when token budgets are tight, or when you want faster, denser responses.

## Levels

| Level | Style | Token Savings | When |
|-------|-------|---------------|------|
| `lite` | Drop filler words, keep full sentences | ~30% | Default when mode is active |
| `full` | Fragments, no articles/prepositions | ~65% | Heavy saving mode |
| `ultra` | Telegraphic, single words where possible | ~80% | Extreme: debugging or one-line fixes |

## What Gets Compressed

| Content | Treatment |
|---------|-----------|
| Explanations | Drop polite openers ("Sure!", "I'd be happy to"), hedge words ("perhaps", "might"), summaries |
| Code reviews | One-line per finding: `L42: 🔴 bug: user null. Add guard.` |
| Plan steps | Bullet fragments, no narrative |
| File contents | Keep verbatim — code, paths, URLs, error strings stay exact |

## What Never Gets Compressed
- Error messages and stack traces (verbatim)
- Code changes (exact)
- Commands and their output (exact)
- Security warnings (full detail)
- User-facing text in the project (copy, docs)

## Example

**Normal (69 tokens):**
> "The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every time."

**Caveman (19 tokens):**
> "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."

## Activation

Load with `view backbone/skills/general/caveman-compact/SKILL.md` or use the command:

```
/backbone:compact-mode full
```

When active, the agent applies compact mode to all output until deactivated:

```
/backbone:compact-mode off
```

## Usage Examples

### Before (normal, 42 tokens):
"Let me analyze the error. The database connection is failing because the connection pool is exhausted. You have 100 connections but 150 concurrent requests. I would recommend increasing the pool size to 200."

### After (caveman full, 14 tokens, -67%):
"Connection pool exhausted. 100 pool, 150 requests. Increase to 200."

### Code review before (normal):
"I found an issue on line 42 of auth.ts. The null check for the user object is missing, which means this could throw a NullPointerException when user is null. I'd recommend adding a guard clause before accessing user.email."

### Code review after (caveman):
"L42: 🔴 bug: user null. Add guard before user.email."

### Self-review check (caveman ultra):
"L86: warning: magic number 500. Name as TIMEOUT_MS."

### Plan step before (normal):
"The first task is to create a new file called KillSwitchState.java in the killswitch/model/ directory with three enum values: RESUMED, TIMED_OUT, and MANUALLY_HALTED."

### Plan step after (caveman):
"Create KillSwitchState enum (RESUMED, TIMED_OUT, MANUALLY_HALTED) in killswitch/model/."

## Workflow Integration

Recommended usage pattern:
1. Start session normally for design/grilling (full context needed)
2. Enable compact mode before task execution (`/backbone:compact-mode full`)
3. Disable for code review and close (detail matters)
4. Re-enable for parallel subagent dispatch (saves context for orchestrator)


