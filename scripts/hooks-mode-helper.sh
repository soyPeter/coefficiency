#!/bin/bash
# hooks-mode-helper.sh — Source this from hooks/plugins for mode-aware blocking.
# Usage: source scripts/hooks-mode-helper.sh
# Provides: get_hooks_mode, maybe_block(msg), must_block(msg)
#   get_hooks_mode → sets HOOKS_MODE variable (light/standard/full)
#   maybe_block msg → in Light: warn+exit0; Standard/Full: warn+exit1
#   must_block msg  → always warn+exit1 (security, always blocks)

get_hooks_mode() {
    HOOKS_MODE="standard"
    local mode_file=""
    if [ -f "backbone/.MODE" ]; then
        mode_file="backbone/.MODE"
    elif [ -n "$CLAUDE_PROJECT_DIR" ] && [ -f "$CLAUDE_PROJECT_DIR/backbone/.MODE" ]; then
        mode_file="$CLAUDE_PROJECT_DIR/backbone/.MODE"
    fi
    if [ -n "$mode_file" ]; then
        HOOKS_MODE=$(tr -d '[:space:]' < "$mode_file")
    fi
    case "$HOOKS_MODE" in
        light|standard|full) ;;
        *) HOOKS_MODE="standard" ;;
    esac
}

get_hooks_mode

maybe_block() {
    local msg="$1"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  POLICY CHECK                                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  $msg"
    echo ""
    if [ "$HOOKS_MODE" = "light" ]; then
        echo "  ─────────────────────────────────────────────────────────────"
        echo "  🟢 LIGHT MODE: Warning only — proceeding."
        echo "  ─────────────────────────────────────────────────────────────"
        echo ""
        exit 0
    fi
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  🚫 BLOCKED — resolve the issue above and try again."
    echo "  ─────────────────────────────────────────────────────────────"
    echo ""
    exit 1
}

must_block() {
    local msg="$1"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  🚫 SECURITY CHECK — BLOCKED                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  $msg"
    echo ""
    exit 2
}
