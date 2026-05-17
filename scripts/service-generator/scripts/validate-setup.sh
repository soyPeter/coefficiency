#!/bin/bash
# =============================================================================
# validate-setup.sh - Validate service configuration before first run
# =============================================================================
# Usage: ./scripts/validate-setup.sh <service-name>
# Example: ./scripts/validate-setup.sh order
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICE_NAME=$1
ERRORS=0
WARNINGS=0

if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}Error: Service name required${NC}"
    echo "Usage: ./scripts/validate-setup.sh <service-name>"
    exit 1
fi

# Get project root - use current working directory
PROJECT_ROOT="$(pwd)"
SERVICE_DIR="$PROJECT_ROOT/services/$SERVICE_NAME"

if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}Error: Service directory not found: $SERVICE_DIR${NC}"
    exit 1
fi

echo "Validating service: $SERVICE_NAME"
echo "================================="
echo ""

# Check 1: Service directory exists
echo -n "1. Service directory exists... "
if [ -d "$SERVICE_DIR" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Check 2: build.gradle.kts exists
echo -n "2. build.gradle.kts exists... "
if [ -f "$SERVICE_DIR/build.gradle.kts" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Check 3: No placeholder names remaining
echo -n "3. No placeholder names (__SERVICE__, __ENTITY__)... "
if grep -rq "__SERVICE__\|__ENTITY__\|__TABLE__" "$SERVICE_DIR" 2>/dev/null; then
    echo -e "${RED}FAIL - Placeholders found${NC}"
    grep -rl "__SERVICE__\|__ENTITY__\|__TABLE__" "$SERVICE_DIR" 2>/dev/null | head -5
    ((ERRORS++))
else
    echo -e "${GREEN}PASS${NC}"
fi

# Check 4: Application.java has correct package
echo -n "4. Application.java has correct package... "
APP_FILE=$(find "$SERVICE_DIR" -name "*Application.java" | head -1)
if [ -n "$APP_FILE" ] && grep -q "package io.bitnomio.$SERVICE_NAME" "$APP_FILE"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Check 5: At least one Flyway migration exists
echo -n "5. Flyway migration exists... "
if [ -d "$SERVICE_DIR/src/main/resources/db/migration" ] && ls "$SERVICE_DIR/src/main/resources/db/migration"/*.sql 1>/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Check 6: application.properties exists
echo -n "6. application.properties exists... "
if [ -f "$SERVICE_DIR/src/main/resources/application.properties" ]; then
    echo -e "${GREEN}PASS${NC}"

    # Warning if still using localhost
    echo -n "   - Database URL configured... "
    if grep -q "localhost:5432/${SERVICE_NAME}db" "$SERVICE_DIR/src/main/resources/application.properties"; then
        echo -e "${YELLOW}WARNING - Still using default localhost URL${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}PASS${NC}"
    fi
else
    echo -e "${RED}FAIL${NC}"
    ((ERRORS++))
fi

# Check 7: Service registered in settings.gradle.kts
echo -n "7. Service in settings.gradle.kts... "
if [ -f "$PROJECT_ROOT/settings.gradle.kts" ] && grep -q ":services:$SERVICE_NAME" "$PROJECT_ROOT/settings.gradle.kts"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARNING - Not registered in settings.gradle.kts${NC}"
    ((WARNINGS++))
fi

# Check 8: Compiles successfully (optional, skip if gradle not available)
echo -n "8. Compiles successfully... "
if command -v ./gradlew &> /dev/null; then
    if ./gradlew :services:$SERVICE_NAME:compileJava --quiet 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}SKIP - Gradle not available${NC}"
fi

echo ""
echo "================================="
echo "Validation complete"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}VALIDATION FAILED${NC}"
    echo "Fix the errors above before running the service."
    exit 1
else
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}VALIDATION PASSED with warnings${NC}"
        echo "Review warnings before deploying to production."
    else
        echo -e "${GREEN}VALIDATION PASSED${NC}"
    fi
    echo ""
    echo "Ready to build: ./gradlew :services:$SERVICE_NAME:build"
    echo "Ready to run:   ./gradlew :services:$SERVICE_NAME:quarkusDev"
fi