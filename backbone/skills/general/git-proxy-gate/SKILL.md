<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: git-proxy-gate
description: Use before pushing feature branches upstream, during feature close (/backbone:close), or when the user asks to validate changes before they reach the remote. Runs verification in an isolated worktree before forwarding.
---

# Git Proxy Gate

The git proxy gate validates every push in an isolated worktree before forwarding upstream. It catches issues that pre-commit hooks might miss because it runs against the full merged state.

## How It Works

```
    git push origin feature-x
              │
              ▼
   ┌─────────────────────────┐
   │  gate-push.sh           │
   │  ┌─────────────────┐   │
   │  │ isolate worktree │   │
   │  │ run pipeline     │   │
   │  │ auto-fix safe    │   │
   │  │ escalate rest    │   │
   │  └────────┬────────┘   │
   └───────────┼─────────────┘
               │ all green
               ▼
         git push origin
```

## Usage

```bash
# Push current branch through gate
bash scripts/gate-push.sh

# Push a specific branch
bash scripts/gate-push.sh --branch feature/nats-events

# Auto-fix safe findings (lint, formatting) without asking
bash scripts/gate-push.sh --yes
```

## Pipeline Steps

| Step | Auto-fix? | Description |
|------|-----------|-------------|
| Build | Yes | Build project, fix if safe |
| Lint | Yes | Apply auto-formatting |
| Tests | No | Run test suite |
| Secret scan | No | Check for leaked credentials |
| Template sync | No | Verify template parity |

## Integration with Close

`/backbone:close` calls `gate-push.sh` before marking the feature complete.
If the gate fails, the worktree is preserved for inspection at `<project>-gate/<branch>/`.
Fix the findings and re-run gate-push, or use `--skip-gate` to bypass.

## Finding Escalation

- **Auto-fix** (with `--yes`): Safe mechanical fixes applied automatically
- **Ask-user** (default): Findings presented for human approval/skip
- **Blocking** (always): Test failures, secrets in code, template drift
