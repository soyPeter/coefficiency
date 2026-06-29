#!/bin/bash
# scripts/install-hooks.sh — Install git and Claude Code hooks
# Usage: ./scripts/install-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
SCRIPTS_HOOKS_DIR="$SCRIPT_DIR/hooks"
CLAUDE_HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"

if [ ! -d "$GIT_HOOKS_DIR" ]; then
  echo "❌ Error: .git/hooks directory not found. Are you in the project root?"
  exit 1
fi

echo "📦 Installing hooks..."
echo ""

# ── Install Git Hooks ──────────────────────────────────────────────────────

install_hook() {
  local name="$1"
  local src="$2"
  local target="$GIT_HOOKS_DIR/$name"

  if [ ! -f "$src" ]; then
    echo "  ⚠️  $src not found, skipping"
    return
  fi

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -f "$target" ]; then
    echo "  ⚠️  Backing up existing $name"
    mv "$target" "$target.backup.$(date +%s)"
  fi

  ln -sf "$src" "$target"
  chmod +x "$src"
  echo "  ✅ $name"
}

echo "Git hooks → .git/hooks/"
install_hook "pre-commit" "$SCRIPTS_HOOKS_DIR/pre-commit"
install_hook "commit-msg" "$SCRIPTS_HOOKS_DIR/commit-msg"
install_hook "pre-commit-test-gate" "$SCRIPTS_HOOKS_DIR/pre-commit-test-gate"
install_hook "pre-commit-version-gate" "$SCRIPTS_HOOKS_DIR/pre-commit-version-gate"

# ── Ensure Claude Code Hooks are Executable ────────────────────────────────

echo ""
echo "Claude Code hooks → .claude/hooks/"

if [ -d "$CLAUDE_HOOKS_DIR" ]; then
  for hook in "$CLAUDE_HOOKS_DIR"/*.sh; do
    if [ -f "$hook" ]; then
      chmod +x "$hook"
      echo "  ✅ $(basename "$hook")"
    fi
  done
else
  echo "  ⚠️  .claude/hooks/ not found"
fi

# ── Ensure worktrunk.sh is Executable ─────────────────────────────────────

if [ -f "$PROJECT_ROOT/scripts/worktrunk.sh" ]; then
  chmod +x "$PROJECT_ROOT/scripts/worktrunk.sh"
  echo ""
  echo "  ✅ scripts/worktrunk.sh"
fi

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "🎉 Hook installation complete!"
echo ""
echo "Active protections:"
echo "  • Commit message format (Conventional Commits)"
echo "  • Build gate (skip with SKIP_BUILD=1)"
echo "  • Backbone VERSION bump gate"
echo "  • WORKTRUNK enforcement — feature work requires worktree"
echo "  • WIP task reminder"
echo ""
echo "Worktree management:"
echo "  ./scripts/worktrunk.sh status   — Check current status"
echo "  ./scripts/worktrunk.sh create   — Create feature worktree"
echo "  ./scripts/worktrunk.sh merge    — Merge feature back"
echo ""
echo "To reinstall after updates:"
echo "  ./scripts/install-hooks.sh"
