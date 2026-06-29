#!/bin/bash
# pre-tool-use-qms-check.sh: QMS advisory gate — warns about open NCRs linked to the change folder being edited
#
# Fires BEFORE Write/Edit to any file in backbone/artifacts/changes/CHNG-XXX/
# Checks if there are open NCRs linked to that change folder.
# Advisory only — does not block.
#
# Override: export CLAUDE_CODE_SKIP_QMS=1

set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

if [ "${CLAUDE_CODE_SKIP_QMS:-0}" = "1" ]; then
    exit 0
fi

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || true)
TARGET_FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
    exit 0
fi

# Only check files under backbone/artifacts/changes/CHNG-XXX/
if [[ "$TARGET_FILE" != *"backbone/artifacts/changes/CHNG-"* ]]; then
    exit 0
fi

# Extract CHNG-XXX from the file path
CHNG_ID=""
if [[ "$TARGET_FILE" =~ (CHNG-[0-9]{3}) ]]; then
    CHNG_ID="${BASH_REMATCH[1]}"
fi

if [ -z "$CHNG_ID" ]; then
    exit 0
fi

# Check for open NCRs linked to this change
NCR_DIR="$PROJECT_DIR/backbone/artifacts/qms/ncr"
if [ ! -d "$NCR_DIR" ]; then
    exit 0
fi

OPEN_NCR=0
NCR_LIST=""
for ncr in "$NCR_DIR"/*.yml; do
    [ -f "$ncr" ] || continue
    ncr_change=""
    ncr_status=""
    ncr_title=""
    ncr_severity=""
    while IFS= read -r line; do
        case "$line" in
            change:*) ncr_change="${line#change: }" ;;
            status:*) ncr_status="${line#status: }" ;;
            title:*) ncr_title="${line#title: }" ;;
            severity:*) ncr_severity="${line#severity: }" ;;
        esac
    done < "$ncr"
    ncr_change="${ncr_change//\"/}"
    ncr_status="${ncr_status//\"/}"
    ncr_title="${ncr_title//\"/}"
    ncr_severity="${ncr_severity//\"/}"

    if [[ "$ncr_change" == "$CHNG_ID" && "$ncr_status" == "open" ]]; then
        OPEN_NCR=1
        NCR_LIST="$NCR_LIST\n    - $(basename "$ncr" .yml) ($ncr_severity): $ncr_title"
    fi
done

if [ "$OPEN_NCR" = 1 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  QMS: Open NCRs linked to $CHNG_ID${NC}"
    echo -e "${YELLOW}   Address before archiving this change:${NC}"
    echo -e "$NCR_LIST"
    echo ""
    echo -e "${YELLOW}   Commands:${NC}"
    echo -e "${YELLOW}     Create CAPA:   ./scripts/qms-capa-create.sh --ncr NCR-XXX --root-cause \"...\" --owner dev --due YYYY-MM-DD${NC}"
    echo -e "${YELLOW}     Close CAPA:    ./scripts/qms-capa-close.sh --capa CAPA-XXX --verification \"...\"${NC}"
    echo -e "${YELLOW}     Archive:       ./scripts/backbone-change-archive.sh $CHNG_ID${NC}"
    echo ""
fi

exit 0
