# Hook Architecture Guide

*This document explains the dual-hook system and how hooks are organized.*

---

## Overview

The backbone uses a **two-directory hook system**:

| Directory | Purpose | Runtime |
|-----------|---------|---------|
| `scripts/hooks/` | **Canonical source** for all agent/workflow hooks | Git hooks + Claude Code (via `.claude/settings.json`) |
| `.claude/hooks/` | **Claude-specific overlays** (convention checks, DoD) | Claude Code only (directly referenced in `settings.json`) |

**Key principle:** `scripts/hooks/` is the single source of truth for workflow enforcement. `.claude/hooks/` contains only Claude-specific or lightweight checks that complement the main hooks.

---

## Hook Categories

### 1. Workflow Enforcement Hooks (in `scripts/hooks/`)

These enforce the backbone workflow and are referenced by both git and Claude Code:

| Hook | Event | Purpose |
|------|-------|---------|
| `pre-tool-use-skill-check.sh` | PreToolUse/Write+Edit | **BLOCKS** until skill acknowledged for layer |
| `session-start-workflow-check.sh` | SessionStart | Shows checklist + required skills |
| `session-start-drift-check.sh` | SessionStart | Scans codebase for architecture drift |
| `stop-wip-check.sh` | Stop | Warns if `[WIP]` tasks open |
| `post-edit-layer-check.sh` | PostToolUse/Edit+Write | Detects layer boundary violations |
| `post-write-scaffold-check.sh` | PostToolUse/Write | Validates scaffold file structure |
| `post-doc-check.sh` | PostToolUse/Write | Validates doc index/detail sync |
| `post-commit-dod-reminder.sh` | PostToolUse/Bash | Reminds to update backbone docs after commit |
| `pre-bash-safety-check.sh` | PreToolUse/Bash | Blocks destructive commands |

### 2. Claude-Specific Overlays (in `.claude/hooks/`)

These are lightweight checks that run **only in Claude Code**:

| Hook | Event | Purpose |
|------|-------|---------|
| `check-conventions.sh` | PreToolUse/Write+Edit | Quick framework convention check |
| `check-dod.sh` | Stop | Injects DoD reminder into context |

### 3. Git Hooks (installed to `.git/hooks/`)

| Hook | Purpose |
|------|---------|
| `pre-commit` | Blocks commits on convention violations |
| `commit-msg` | Enforces Conventional Commits format |

---

## Why Two Directories?

### `scripts/hooks/` — The Canonical Source

- Contains the **full logic** for skill enforcement, WIP checks, layer validation
- Referenced by `.claude/settings.json` for Claude Code integration
- Also installed as git hooks via `scripts/install-hooks.sh`
- These are the hooks that **block** or **warn** on violations

### `.claude/hooks/` — Claude-Specific Overlays

- Contains **lightweight, Claude-specific** checks
- Directly referenced in `.claude/settings.json` alongside `scripts/hooks/`
- Can be customized per-project without affecting git hooks
- **Never duplicates** the blocking logic from `scripts/hooks/`

---

## Verification

Run the parity check to ensure hook integrity:

```bash
./scripts/verify-hook-parity.sh
```

This checks:
1. All `settings.json` references exist
2. Critical hooks aren't silently diverging between directories
3. No orphaned hooks in `.claude/hooks/`

**In strict mode** (treats warnings as errors):
```bash
./scripts/verify-hook-parity.sh --strict
```

---

## Adding a New Hook

### For workflow enforcement (blocking/warning):
1. Create the hook in `scripts/hooks/<hook-name>.sh`
2. Reference it in `.claude/settings.json` under the appropriate event
3. Optionally install it as a git hook in `scripts/install-hooks.sh`

### For Claude-specific checks:
1. Create the hook in `.claude/hooks/<hook-name>.sh`
2. Reference it in `.claude/settings.json`
3. Keep it lightweight (< 50 lines if possible)

---

## Current State

As of the latest verification:

- ✅ `scripts/hooks/` is the canonical source for all workflow enforcement
- ✅ `.claude/hooks/` contains only `check-conventions.sh` and `check-dod.sh`
- ⚠️ `pre-tool-use-skill-check.sh` and `stop-wip-check.sh` exist in `.claude/hooks/` but are **not referenced** by `settings.json` (legacy copies)

**Recommendation:** The `.claude/hooks/` versions of `pre-tool-use-skill-check.sh` and `stop-wip-check.sh` are stale and unused. They should either be synced with `scripts/hooks/` or removed to avoid confusion.

---

## Related

- `.claude/settings.json` — Hook configuration
- `scripts/install-hooks.sh` — Git hook installer
- `scripts/verify-hook-parity.sh` — Integrity checker
