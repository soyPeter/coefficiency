#!/bin/bash
# setup-hooks.sh: One-command setup for all backbone workflow hooks
# This script sets up both git hooks and Claude Code project hooks in one go.
# Usage: ./scripts/setup-hooks.sh

set -e

if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
HOOKS_SOURCE_DIR="$SCRIPT_DIR/hooks"
CLAUDE_SETTINGS="$PROJECT_ROOT/.claude/settings.json"
SETTINGS_TEMPLATE="$PROJECT_ROOT/templates/backbone/.claude/settings.json"

# Detect framework and build tool from 4-KNOWLEDGE.md
KNOWLEDGE_FILE="$PROJECT_ROOT/backbone/4-KNOWLEDGE.md"
DETECTED_FRAMEWORK=""
DETECTED_BUILD_TOOL=""
if [ -f "$KNOWLEDGE_FILE" ]; then
    DETECTED_FRAMEWORK=$(grep -E '^\s*-\s+\*\*Core:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Quarkus|Spring Boot|Laravel|Kotlin|Go|Python|PostgreSQL)' | head -1 || true)
    DETECTED_BUILD_TOOL=$(grep -E '^\s*-\s+\*\*Build:' "$KNOWLEDGE_FILE" 2>/dev/null | grep -oE '(Gradle|Maven|Composer|Go|pip)' | head -1 || true)
fi
CONVENTIONS_STATUS="${DETECTED_FRAMEWORK:-project} conventions"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}🔧 Backbone Workflow Hooks Setup${NC}"
echo ""

# Check we're in the right place
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo -e "${RED}❌ Error: Not in a git repository. Are you in the project root?${NC}"
  exit 1
fi

if [ ! -f "$HOOKS_SOURCE_DIR/pre-commit" ]; then
  echo -e "${RED}❌ Error: Hook scripts not found in $HOOKS_SOURCE_DIR${NC}"
  exit 1
fi

# Step 1: Install git hooks
echo -e "${BLUE}Step 1: Installing git hooks${NC}"
"$SCRIPT_DIR/install-hooks.sh"

# Step 2: Update Claude Code project settings
echo ""
echo -e "${BLUE}Step 2: Configuring Claude Code project hooks${NC}"

if [ ! -f "$CLAUDE_SETTINGS" ]; then
  echo "  ℹ️  Creating new .claude/settings.json"
  mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
  if [ -f "$SETTINGS_TEMPLATE" ]; then
    BUILD_TOOL_LOWER=$(echo "${DETECTED_BUILD_TOOL:-gradle}" | tr '[:upper:]' '[:lower:]')
    sed "s|__FRAMEWORK__|${DETECTED_FRAMEWORK:-project}|g; s|__BUILD_TOOL__|${BUILD_TOOL_LOWER}|g" "$SETTINGS_TEMPLATE" > "$CLAUDE_SETTINGS"
    echo "  ✅ Created from template (framework: ${DETECTED_FRAMEWORK:-unknown})"
  else
    cat > "$CLAUDE_SETTINGS" << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git diff *)"
    ]
  }
}
EOF
  fi
else
  echo "  ℹ️  Found existing .claude/settings.json"
fi

# Always write canonical hooks config (idempotent — safe to run repeatedly)
echo "  ✅ Writing canonical hooks config to .claude/settings.json"

cd "$PROJECT_ROOT" 2>/dev/null || true
git_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT_ROOT")"

export CONVENTIONS_STATUS

python3 -c '
import json, os
sentinel = "SENTINEL_GIT_ROOT"
git_root = os.environ.get(sentinel, "")
if not git_root or not os.path.isdir(git_root):
    git_root = "'"$PROJECT_ROOT"'"
settings_file = "'"$CLAUDE_SETTINGS"'"
with open(settings_file, "r") as f:
    settings = json.load(f)

git_cmd = git_root + "/scripts/hooks"
claude_cmd = git_root + "/.claude/hooks"

settings["hooks"] = {
    "PreToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/pre-bash-safety-check.sh"}]},
        {"matcher": "Task", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-subagent-conflict-check.sh", "timeout": 5, "statusMessage": "Checking subagent conflicts..."}]},
        {"matcher": "Write|Edit", "hooks": [
            {"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-wip-check.sh", "timeout": 5, "statusMessage": "Checking WIP policy..."},
            {"type": "command", "command": "bash " + git_cmd + "/review-gate-check.sh", "timeout": 5, "statusMessage": "Checking review gates..."},
            {"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-rd-gate.sh", "timeout": 5, "statusMessage": "Checking PRD\u2192Design gate..."},
            {"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-grill-check.sh", "timeout": 5, "statusMessage": "Checking grill evidence..."},
            {"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-task-granularity-check.sh", "timeout": 5, "statusMessage": "Checking task granularity..."},
            {"type": "command", "command": "bash " + git_cmd + "/pre-tool-use-conventions-check.sh", "timeout": 5, "statusMessage": "Checking conventions read..."},
            {"type": "command", "command": "bash " + claude_cmd + "/check-conventions.sh", "timeout": 10, "statusMessage": "\uD83D\uDD0D Checking " + os.environ.get("CONVENTIONS_STATUS", "project conventions") + "..."}
        ]}
    ],
    "SessionStart": [
        {"matcher": "*", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/session-start-workflow-check.sh"}]},
        {"matcher": "*", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/session-start-drift-check.sh"}]}
    ],
    "Stop": [
        {"matcher": "*", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/stop-wip-check.sh"}]},
        {"matcher": "*", "hooks": [{"type": "command", "command": "bash " + claude_cmd + "/check-dod.sh", "timeout": 5}]}
    ],
    "PostToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/post-commit-dod-reminder.sh"}]},
        {"matcher": "Edit|Write", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/post-edit-layer-check.sh"}]},
        {"matcher": "Write", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/post-write-scaffold-check.sh"}]},
        {"matcher": "Write.*backbone/decisions|Write.*backbone/prd|Write.*backbone/tasks|Write.*backbone/changes|Write.*5-DECISIONS|Write.*1-PRD|Write.*3-TASKS|Write.*proposal\\.md|Write.*design\\.md|Write.*tasks\\.md", "hooks": [{"type": "command", "command": "bash " + git_cmd + "/post-doc-check.sh", "timeout": 10, "statusMessage": "Checking documentation sync..."}]}
    ]
}
with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print("  Updated .claude/settings.json with canonical hooks configuration")
'

# Step 3: Configure OpenCode plugins (if OpenCode is detected)
echo ""
echo -e "${BLUE}Step 3: Configuring OpenCode plugins${NC}"

OPENCODE_VERSION="$(opencode --version 2>/dev/null || echo "")"
if [ -n "$OPENCODE_VERSION" ]; then
    echo "  ℹ️  OpenCode detected ($OPENCODE_VERSION)"

    # Create .opencode/plugins directory
    mkdir -p "$PROJECT_ROOT/.opencode/plugins"

    # Copy plugin files from template
    if [ -f "$PROJECT_ROOT/templates/backbone/.opencode/opencode.json" ]; then
        cp "$PROJECT_ROOT/templates/backbone/.opencode/opencode.json" "$PROJECT_ROOT/.opencode/"
        echo "  ✅ Configured OpenCode plugins"
    else
        # Fallback: write minimal config referencing backbone plugins
        cat > "$PROJECT_ROOT/.opencode/opencode.json" << 'OPENCODE_CONFIG'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    ".opencode/plugins/backbone-wip-check.js",
    ".opencode/plugins/backbone-conventions-check.js",
    ".opencode/plugins/backbone-skill-check.js",
    ".opencode/plugins/backbone-bash-safety.js",
    ".opencode/plugins/backbone-grill-check.js",
    ".opencode/plugins/backbone-task-granularity.js",
    ".opencode/plugins/backbone-rd-gate.js",
    ".opencode/plugins/backbone-subagent-conflict.js",
    ".opencode/plugins/backbone-layer-check.js"
  ]
}
OPENCODE_CONFIG
        echo "  ✅ Created OpenCode plugin config"
    fi
    echo "  ℹ️  OpenCode plugins active (blocks on: WIP, conventions, skills, bash safety, grill, task granularity, RD gate, subagent conflicts, layer violations)"
else
    echo "  ℹ️  OpenCode not detected — skipping plugin setup"
    echo "  ℹ️  To enable: install OpenCode from https://opencode.ai"
fi

# Step 4: Summary
echo ""
echo -e "${GREEN}✅ Hooks setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Installed Hooks:${NC}"
echo ""
echo -e "  ${GREEN}Git Hooks${NC} (run on every commit):"
echo "    • pre-commit      — Validates Quarkus conventions (Spring, Lombok, domain leakage)"
echo "    • pre-commit      — Optional: Runs Gradle compilation check (SKIP_BUILD=1 to skip)"
echo "    • commit-msg      — Validates conventional commit format: feat(scope): description"
echo ""
echo -e "  ${GREEN}Claude Code Project Hooks${NC} (run during Claude sessions):"
echo "    • PreToolUse/Bash        — Blocks destructive commands (git reset --hard, rm -rf, force-push)"
echo "    • PreToolUse/Write|Edit  — Quarkus convention check BEFORE write (Spring, Lombok, layer boundaries)"
echo "    • SessionStart           — Workflow checklist + WIP resume + architecture drift scan"
echo "    • Stop                   — Detects open [WIP] tasks + commit frequency nudge + DoD reminder"
echo "    • PostToolUse/Bash       — DoD reminder + content quality check after git commit"
echo "    • PostToolUse/Edit|Write — Real-time layer boundary check after each Java file edit/write"
echo "    • PostToolUse/Write      — New module scaffold validator when build.gradle created"
echo ""

# Step 4: Verification instructions
echo -e "${BLUE}🧪 Verification:${NC}"
echo ""
echo "  Test git hooks:"
echo "    git commit -m 'bad message'              # Should fail (bad format)"
echo "    git commit -m 'feat(test): good'         # Should pass"
echo ""
echo "  Test Claude Code hooks:"
echo "    - Leave [WIP] in backbone/3-TASKS.md"
echo "    - End a Claude turn → should show WIP warning"
echo "    - Commit only Java files → should show DoD reminder"
echo ""

# Step 5: Optional compilation check
echo -e "${BLUE}❓ Optional: Enable compilation check${NC}"
echo ""
echo "  Currently, the pre-commit hook includes an optional compilation check."
echo "  This validates that code compiles before allowing commits."
echo ""
echo "  Speed: 5-25 seconds per commit (Gradle daemon warmth dependent)"
echo "  Skip with: SKIP_BUILD=1 git commit -m '...'"
echo ""
echo "  The check is already installed. No action needed."
echo ""

# Step 5: Next steps
echo -e "${BLUE}📖 Next Steps:${NC}"
echo ""
echo "  1. Read backbone/HOOKS-SETUP.md for detailed hook documentation"
echo "  2. Test each hook with the commands above"
echo "  3. See backbone/0-START-HERE.md for full onboarding"
echo ""
echo -e "${GREEN}🚀 Ready to develop!${NC}"
echo ""
