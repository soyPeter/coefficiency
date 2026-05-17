#!/bin/bash
# backbone-sync.sh: Detect drift between backbone docs and codebase reality
#
# Usage:
#   ./scripts/backbone-sync.sh              # Interactive mode (default)
#   ./scripts/backbone-sync.sh --dry-run    # Preview only
#   ./scripts/backbone-sync.sh --auto-approve  # Auto-apply changes

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
AUTO_APPROVE=false

# Parse args
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --auto-approve) AUTO_APPROVE=true ;;
    esac
done

echo -e "${BLUE}🔄 Backbone Drift Detection${NC}"
echo ""

# ── Detect Tech Stack ──────────────────────────────────────────────────────

detect_tech_stack() {
    local stack=""
    
    if [ -f "package.json" ]; then
        stack="${stack}Node.js, "
        if grep -q "react" package.json 2>/dev/null; then
            stack="${stack}React, "
        fi
        if grep -q "typescript" package.json 2>/dev/null; then
            stack="${stack}TypeScript, "
        fi
    fi
    
    if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
        stack="${stack}Gradle, "
        if [ -d "src/main/kotlin" ]; then
            stack="${stack}Kotlin, "
        else
            stack="${stack}Java, "
        fi
    fi
    
    if [ -f "pom.xml" ]; then
        stack="${stack}Maven, "
        if [ -d "src/main/kotlin" ]; then
            stack="${stack}Kotlin, "
        else
            stack="${stack}Java, "
        fi
    fi
    
    if [ -f "composer.json" ]; then
        stack="${stack}PHP (Laravel), "
    fi
    
    if [ -f "go.mod" ]; then
        stack="${stack}Go, "
    fi
    
    if [ -f "Cargo.toml" ]; then
        stack="${stack}Rust, "
    fi
    
    # Remove trailing comma and space
    echo "${stack%, }"
}

# ── Detect Dependencies ────────────────────────────────────────────────────

detect_dependencies() {
    local deps=""
    
    if [ -f "package.json" ]; then
        deps=$(python3 -c "
import json
with open('package.json') as f:
    data = json.load(f)
deps = list(data.get('dependencies', {}).keys())[:10]
print(', '.join(deps))
" 2>/dev/null || echo "")
    fi
    
    echo "$deps"
}

# ── Detect Directory Structure ─────────────────────────────────────────────

detect_structure() {
    local structure=""
    
    if [ -d "src" ]; then
        structure="${structure}src/, "
    fi
    if [ -d "tests" ] || [ -d "test" ]; then
        structure="${structure}tests/, "
    fi
    if [ -d "docs" ]; then
        structure="${structure}docs/, "
    fi
    if [ -d "scripts" ]; then
        structure="${structure}scripts/, "
    fi
    if [ -d ".github" ]; then
        structure="${structure}.github/, "
    fi
    
    echo "${structure%, }"
}

# ── Read Current backbone/4-KNOWLEDGE.md ──────────────────────────────────

read_current_knowledge() {
    if [ -f "backbone/4-KNOWLEDGE.md" ]; then
        grep -E '^\s*-\s+\*\*(Core|Build|Test):' backbone/4-KNOWLEDGE.md 2>/dev/null || echo ""
    fi
}

# ── Compare and Report ─────────────────────────────────────────────────────

echo -e "${BLUE}Scanning codebase...${NC}"

DETECTED_STACK=$(detect_tech_stack)
DETECTED_DEPS=$(detect_dependencies)
DETECTED_STRUCTURE=$(detect_structure)
CURRENT_KNOWLEDGE=$(read_current_knowledge)

echo ""
echo "Detected stack: $DETECTED_STACK"
echo "Detected structure: $DETECTED_STRUCTURE"
echo ""

DRIFT_FOUND=false

# Check tech stack drift
if [ -f "backbone/4-KNOWLEDGE.md" ] && [ -n "$DETECTED_STACK" ]; then
    if ! grep -q "$DETECTED_STACK" backbone/4-KNOWLEDGE.md 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Tech stack drift detected${NC}"
        echo "  Detected: $DETECTED_STACK"
        echo "  backbone/4-KNOWLEDGE.md may be outdated"
        DRIFT_FOUND=true
    fi
fi

# Check structure drift
if [ -f "backbone/4-KNOWLEDGE.md" ] && [ -n "$DETECTED_STRUCTURE" ]; then
    # Simple check: if backbone mentions directories not present, or vice versa
    if [ -d "src" ] && ! grep -q "src/" backbone/4-KNOWLEDGE.md 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Structure drift: src/ directory exists but not documented${NC}"
        DRIFT_FOUND=true
    fi
fi

# Check VERSION drift
if [ -f "backbone/VERSION" ] && [ -f "package.json" ]; then
    PKG_VERSION=$(python3 -c "import json; print(json.load(open('package.json')).get('version',''))" 2>/dev/null || echo "")
    BACKBONE_VERSION=$(head -n1 backbone/VERSION 2>/dev/null || echo "")
    if [ -n "$PKG_VERSION" ] && [ "$PKG_VERSION" != "$BACKBONE_VERSION" ]; then
        echo -e "${YELLOW}⚠️  Version drift: package.json ($PKG_VERSION) ≠ backbone/VERSION ($BACKBONE_VERSION)${NC}"
        DRIFT_FOUND=true
    fi
fi

# ── Action ─────────────────────────────────────────────────────────────────

echo ""

if [ "$DRIFT_FOUND" = false ]; then
    echo -e "${GREEN}✅ No drift detected. Backbone docs are in sync.${NC}"
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}ℹ️  Dry run mode — no changes applied${NC}"
    exit 0
fi

if [ "$AUTO_APPROVE" = true ]; then
    echo -e "${BLUE}📝 Auto-approving updates to backbone docs...${NC}"
    # TODO: Implement auto-update logic
    echo -e "${YELLOW}⚠️  Auto-update not yet implemented. Manual review required.${NC}"
    exit 0
fi

# Interactive mode
echo "Detected drift. Please review and update:"
echo "  - backbone/4-KNOWLEDGE.md (tech stack, structure)"
echo "  - backbone/VERSION (if version changed)"
echo "  - backbone/6-MEMORY.md (document drift detection)"
echo ""
echo -e "${BLUE}Run with --auto-approve to auto-apply (not recommended for first use)${NC}"

exit 1
