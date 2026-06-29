#!/bin/bash
# post-tool-use-qms-auto-register.sh: Auto-detect test/build failures and suggest NCR registration
#
# PostToolUse/Bash hook: fires after every Bash command.
# If the command was a test/build run that failed, suggests registering an NCR.
# Advisory only — does not block.
#
# Override: export CLAUDE_CODE_SKIP_QMS=1

set -euo pipefail

YELLOW='\033[1;33m'
NC='\033[0m'

if [ "${CLAUDE_CODE_SKIP_QMS:-0}" = "1" ]; then
    exit 0
fi

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# Extract command and result info from JSON
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# PostToolUse JSON has tool_input with the command
inp = d.get('tool_input', {})
print(inp.get('command', ''))
" 2>/dev/null || true)

RESULT=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# Try result/result_text/error fields
print(d.get('result_text', d.get('error', ''))[:2000])
" 2>/dev/null || true)

[ -z "$COMMAND" ] && exit 0

# Check if this is a test/build command
IS_TEST_COMMAND=0
for pattern in 'mvn test' 'mvn verify' 'mvn clean test' 'npm test' 'npm run test' 'npm run build' 'gradle test' 'gradle build' 'pytest' 'go test' 'cargo test'; do
    if echo "$COMMAND" | grep -qiE "$pattern"; then
        IS_TEST_COMMAND=1
        break
    fi
done

[ "$IS_TEST_COMMAND" = 0 ] && exit 0

# Check for failure indicators in the result
FAILURE=0
for indicator in 'BUILD FAIL' 'BUILD FAILURE' 'Tests failed' 'FAILED' 'Test failures' 'BUILD ERROR' 'npm ERR' 'Error:' 'Failed:' 'exited with code 1' 'test failed' 'some tests failed'; do
    if echo "$RESULT" | grep -qiE "$indicator"; then
        FAILURE=1
        break
    fi
done

[ "$FAILURE" = 0 ] && exit 0

echo ""
echo -e "${YELLOW}⚠️  QMS: Test/build failure detected${NC}"
echo -e "${YELLOW}   If this is a new defect, register an NCR:${NC}"
echo -e "${YELLOW}     ./scripts/qms-register-issue.sh \\${NC}"
echo -e "${YELLOW}       --title \"...\" --severity major --category code --change CHNG-XXX${NC}"
echo ""

exit 0
