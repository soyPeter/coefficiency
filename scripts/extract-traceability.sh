#!/bin/bash
# extract-traceability.sh: Auto-extract REQ-IDs from code and test files
#
# Scans source files for REQ-XXX-NNN references in comments
# and updates traceability matrices automatically.
#
# Usage:
#   ./scripts/extract-traceability.sh                    # Extract all
#   ./scripts/extract-traceability.sh <feature>          # Extract specific feature

set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
FEATURE="${1:-}"

# Temp files for data transfer
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${BLUE}🔍 Extracting traceability from codebase...${NC}"
echo ""

# ── Step 1: Collect all REQ-ID references ──────────────────────────────────

# Format: REQ-ID|type|file
# type = code or tests

> "$TMP_DIR/refs.txt"

# Scan source code
if [ -d "$PROJECT_DIR/src" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ids=$(grep -oE 'REQ-[A-Z]+-[0-9]+' "$file" 2>/dev/null | sort -u || true)
        while IFS= read -r id; do
            [ -z "$id" ] && continue
            echo "$id|code|$file" >> "$TMP_DIR/refs.txt"
        done <<< "$ids"
    done < <(find "$PROJECT_DIR/src" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.java" -o -name "*.py" -o -name "*.go" \) 2>/dev/null)
fi

# Scan tests
if [ -d "$PROJECT_DIR/tests" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ids=$(grep -oE 'REQ-[A-Z]+-[0-9]+' "$file" 2>/dev/null | sort -u || true)
        while IFS= read -r id; do
            [ -z "$id" ] && continue
            echo "$id|tests|$file" >> "$TMP_DIR/refs.txt"
        done <<< "$ids"
    done < <(find "$PROJECT_DIR/tests" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.java" -o -name "*.py" -o -name "*.go" \) 2>/dev/null)
fi

# Scan shell scripts for test references
if [ -d "$PROJECT_DIR/scripts" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        ids=$(grep -oE 'REQ-[A-Z]+-[0-9]+' "$file" 2>/dev/null | sort -u || true)
        while IFS= read -r id; do
            [ -z "$id" ] && continue
            echo "$id|tests|$file" >> "$TMP_DIR/refs.txt"
        done <<< "$ids"
    done < <(find "$PROJECT_DIR/scripts" -type f -name "*.sh" 2>/dev/null)
fi

if [ ! -s "$TMP_DIR/refs.txt" ]; then
    echo -e "${YELLOW}⚠️  No REQ-IDs found in codebase${NC}"
    echo "  Add REQ-XXX-NNN comments to your code and tests, then run again."
    exit 0
fi

# ── Step 2: Map REQ-IDs to features via PRDs ───────────────────────────────

# Build feature mapping: for each REQ-ID, find which PRD contains it
> "$TMP_DIR/feature_map.txt"

while IFS='|' read -r id type file; do
    feature=""
    
    if [ -d "$PROJECT_DIR/backbone/prd" ]; then
        for prd in "$PROJECT_DIR/backbone/artifacts/prd/"*.md; do
            [ -f "$prd" ] || continue
            if grep -q "$id" "$prd" 2>/dev/null; then
                feature=$(basename "$prd" .md | sed 's/^[0-9]*-[0-9]*-[0-9]*-//')
                break
            fi
        done
    fi
    # Also check changes/proposal.md files
    if [ -z "$feature" ] && [ -d "$PROJECT_DIR/backbone/changes" ]; then
        for proposal in "$PROJECT_DIR/backbone/changes"/CHNG-*/proposal.md; do
            [ -f "$proposal" ] || continue
            if grep -q "$id" "$proposal" 2>/dev/null; then
                change_dir=$(basename "$(dirname "$proposal")")
                feature="${change_dir#CHNG-}"
                break
            fi
        done
    fi
    
    # If no PRD match and specific feature requested, use that
    if [ -z "$feature" ] && [ -n "$FEATURE" ]; then
        feature="$FEATURE"
    fi
    
    # Skip unmapped IDs when no specific feature requested
    if [ -z "$feature" ]; then
        continue
    fi
    
    # Filter by requested feature
    if [ -n "$FEATURE" ] && [ "$feature" != "$FEATURE" ]; then
        continue
    fi
    
    echo "$feature|$id|$type|$file" >> "$TMP_DIR/feature_map.txt"
done < "$TMP_DIR/refs.txt"

if [ ! -s "$TMP_DIR/feature_map.txt" ]; then
    echo -e "${YELLOW}⚠️  No REQ-IDs could be mapped to features${NC}"
    echo "  Ensure proposals exist in backbone/artifacts/changes/CHNG-XXX/proposal.md or backbone/artifacts/prd/ containing REQ- IDs."
    exit 0
fi

# ── Step 3: Generate traceability YAML files ───────────────────────────────

mkdir -p "$PROJECT_DIR/backbone/artifacts/traceability"

export TMP_DIR PROJECT_DIR

python3 << 'PYEOF'
import os
import sys

TMP_DIR = os.environ.get('TMP_DIR', '/tmp')
PROJECT_DIR = os.environ.get('PROJECT_DIR', '.')

# Read feature map
feature_data = {}
with open(f'{TMP_DIR}/feature_map.txt', 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split('|')
        if len(parts) != 4:
            continue
        feature, req_id, ref_type, file_path = parts
        
        if feature not in feature_data:
            feature_data[feature] = {}
        if req_id not in feature_data[feature]:
            feature_data[feature][req_id] = {'code': set(), 'tests': set()}
        feature_data[feature][req_id][ref_type].add(file_path)

# Generate YAML files
updated = 0
for feature in sorted(feature_data.keys()):
    trace_file = os.path.join(PROJECT_DIR, 'backbone/artifacts/traceability', f'{feature}.yml')
    reqs = feature_data[feature]
    
    lines = []
    lines.append(f'feature: "{feature}"')
    lines.append(f'prd: "backbone/artifacts/changes/CHNG-XXX/proposal.md"')
    lines.append(f'design: "backbone/artifacts/changes/CHNG-XXX/design.md"')
    lines.append('')
    lines.append('requirements:')
    
    for req_id in sorted(reqs.keys()):
        lines.append(f'  {req_id}:')
        
        code_files = sorted(reqs[req_id]['code'])
        if code_files:
            lines.append('    code:')
            for f in code_files:
                lines.append(f'      - "{f}"')
        else:
            lines.append('    code: []')
        
        test_files = sorted(reqs[req_id]['tests'])
        if test_files:
            lines.append('    tests:')
            for f in test_files:
                lines.append(f'      - "{f}"')
        else:
            lines.append('    tests: []')
        
        lines.append('')
    
    with open(trace_file, 'w') as f:
        f.write('\n'.join(lines))
        f.write('\n')
    
    print(f'  Updated: {trace_file} ({len(reqs)} requirements)')
    updated += 1

print(f'\nGenerated {updated} traceability file(s)')
PYEOF

echo ""
echo -e "${GREEN}✅ Traceability extraction complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Review files in backbone/artifacts/traceability/"
echo "  2. Update PRD and design doc paths if needed"
echo "  3. Run: ./scripts/verify-traceability.sh"
