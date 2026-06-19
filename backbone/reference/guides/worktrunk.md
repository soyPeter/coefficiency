# Worktrunk Guide

> **Parallel Agent Workflows with Git Worktrees**
>
> Worktrunk is a git worktree manager designed for AI agent workflows. It enables
> multiple agents to work on different features simultaneously without branch conflicts.

## Quick Start

```bash
# Create a new feature worktree
wt switch --create feature-name

# Or manually with git
git worktree add -b feature-name ../feature-name main
cd ../feature-name

# List all worktrees
wt list
# or
git worktree list

# Remove a worktree when done
wt remove feature-name
# or
git worktree remove feature-name
```

## Why Worktrees?

In traditional git workflow, you switch branches with `git checkout`. This forces
agents working in parallel to either:
- Share a branch (merge conflicts, state pollution)
- Use separate clones (disk space, sync overhead)

Worktrees solve this by giving each branch its own working directory while sharing
the same `.git` object database:

```
my-project/                 ← main worktree (main branch)
├── .git/
├── backbone/
├── src/
└── ...

my-project-feature-a/       ← linked worktree (feature-a branch)
├── backbone/
├── src/
└── ...

my-project-feature-b/       ← linked worktree (feature-b branch)
├── backbone/
├── src/
└── ...
```

## Agentic Backbone Enforcement

The `.claude/hooks/pre-tool-use-skill-check.sh` hook **blocks** feature work on
`main`, `master`, `dev`, or `develop` branches when not in a worktree.

### When You're Blocked

```
🚫 BLOCKED: Feature work on main branch

Current branch: main
You have a WIP feature task:
  - [WIP] feat: add payment processing

Agentic Backbone requires parallel feature work in worktrees.
```

### How to Proceed

**Option 1: Create a worktree (recommended for feature work)**
```bash
wt switch --create payment-feature
# or
git worktree add -b payment-feature ../my-project-payment-feature main
cd ../my-project-payment-feature
```

**Option 2: Update the task to use an escape-hatch keyword**

If your work is actually a fix, refactor, or docs update, change the task in
[`backbone/3-TASKS.md`](backbone/3-TASKS.md):

```markdown
# Instead of:
- [WIP] feat: add payment processing

# Use:
- [WIP] fix: resolve payment NPE
- [WIP] refactor: extract payment validator
- [WIP] docs: update payment API docs
```

Allowed escape-hatch keywords: `fix`, `bug`, `docs`, `update`, `refactor`,
`clean`, `remove`, `chore`, `test`, `style`, `perf`, `ci`, `build`, `revert`

### How to Bypass (Emergency Only)

If you absolutely must work on main for a one-off task:
```bash
# Temporarily rename the WIP task to use a fix keyword
# Edit backbone/3-TASKS.md, then restore after
```

## Configuration

The `.worktrunk.toml` file configures worktree behavior:

```toml
[template]
path = "__PROJECT_NAME__-{{branch | slugify}}"

[hooks]
post-create = [
  "echo '🚀 Setting up worktree...'",
  "cd {{worktree_path}} && bash scripts/setup-worktree.sh"
]
post-merge = [
  "echo '🧹 Cleaning up after merge...'"
]

[hooks.merge]
pre-merge = [
  "cd {{worktree_path}} && bash scripts/verify-hook-parity.sh || true",
  "cd {{worktree_path}} && bash scripts/verify-template-sync.sh || true"
]

[aliases]
claude = "switch -x claude -c"
```

## Installation

### macOS / Linux

```bash
# Install worktrunk CLI
curl -sSL https://worktrunk.dev/install.sh | bash

# Or manually
git clone https://github.com/worktrunk/cli.git
cd cli && make install
```

### Verify Installation

```bash
wt --version
```

## Best Practices

1. **One feature per worktree** — Don't reuse worktrees for unrelated work
2. **Clean up after merge** — Remove worktrees once the PR is merged
3. **Run verification before merge** — The pre-merge hooks check hook parity and template sync
4. **Keep main clean** — Only fast-forward merges, hotfixes, and docs updates on main

## Troubleshooting

### "Not a git repository" error

Make sure you're in a git repo. The hook detects git via `git rev-parse`.

### "wt command not found"

Install worktrunk CLI (see Installation above). The hook only enforces the workflow;
you still need the CLI to create/manage worktrees.

### Worktree already exists

```bash
# Remove existing worktree
git worktree remove <path>
# Then recreate
wt switch --create <branch>
```

## Resources

- [Worktrunk Documentation](https://worktrunk.dev/)
- [Git Worktrees Official Docs](https://git-scm.com/docs/git-worktree)
- [Parallel Agent Workflows Blog Post](https://worktrunk.dev/blog/parallel-agents)
