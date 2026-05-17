#!/bin/bash
# =============================================================================
# new-service.sh - Generate new microservice from template
# =============================================================================
# Usage: ./scripts/new-service.sh <service-name> [options]
# Examples:
#   ./scripts/new-service.sh order
#   ./scripts/new-service.sh order -e Order --framework springboot
#   ./scripts/new-service.sh order -p com.mycompany --table orders
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load cross-platform utilities (optional — needed for sed_i and other helpers)
if [ -f "$SCRIPT_DIR/../../lib/cross-platform.sh" ]; then
    source "$SCRIPT_DIR/../../lib/cross-platform.sh"
fi

# Defaults
FRAMEWORK="quarkus"
PACKAGE=""       # required — must be provided via -p/--package
TABLE_NAME=""    # explicit override; defaults to ${SERVICE_NAME}s
TABLE_URL=""     # REST path segment; defaults to $SERVICE_NAME
VERIFY=false     # run post-generation verification
GITOPS=false     # generate GitOps config
ENABLE_KAFKA=false
ENABLE_REDIS=false
ENABLE_RABBITMQ=false
INCLUDE_FRONTEND=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--entity)
            ENTITY_NAME="$2"
            shift 2
            ;;
        --framework)
            FRAMEWORK="$2"
            shift 2
            ;;
        --framework=*)
            FRAMEWORK="${1#*=}"
            shift
            ;;
        -p|--package)
            PACKAGE="$2"
            shift 2
            ;;
        --table)
            TABLE_NAME="$2"
            shift 2
            ;;
        --table-url)
            TABLE_URL="$2"
            shift 2
            ;;
        --verify)
            VERIFY=true
            shift
            ;;
        --gitops)
            GITOPS=true
            shift
            ;;
        --kafka)
            ENABLE_KAFKA=true
            shift
            ;;
        --redis)
            ENABLE_REDIS=true
            shift
            ;;
        --rabbitmq)
            ENABLE_RABBITMQ=true
            shift
            ;;
        --frontend)
            INCLUDE_FRONTEND=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./scripts/new-service.sh <service-name> [options]"
            echo ""
            echo "Arguments:"
            echo "  service-name        Name of the service (lowercase, alphanumeric)"
            echo ""
            echo "Options:"
            echo "  -e, --entity NAME   Entity name (default: capitalized service-name)"
            echo "  --framework FW      Framework: quarkus (default), quarkus-kotlin-panache, quarkus-langchain4j-ai, sboot, spring-ai, or laravel"
            echo "  -p, --package PKG   Base Java package (default: io.bitnomio)"
            echo "  --table NAME        Override DB table name (default: \${service-name}s)"
            echo "  --table-url SEG     Override REST URL path segment (default: service-name)"
            echo "  --verify            Run post-generation validation (check placeholders + compile)"
            echo "  --gitops            Generate GitOps config alongside source code"
            echo "  --kafka             Enable Kafka messaging"
            echo "  --redis             Enable Redis caching"
            echo "  --rabbitmq          Enable RabbitMQ messaging"
          echo "  --frontend          Generate React + Vite + shadcn/ui frontend"
            echo ""
            echo "Examples:"
            echo "  ./scripts/new-service.sh order"
            echo "  ./scripts/new-service.sh order -e Order --framework springboot"
            echo "  ./scripts/new-service.sh order -p com.mycompany --table orders"
            echo "  ./scripts/new-service.sh category --table categories --table-url categories"
            echo "  ./scripts/new-service.sh order --gitops --kafka --redis"
            exit 0
            ;;
        *)
            # Skip unknown flags (starting with --) to prevent them from being
            # treated as positional arguments (e.g., --template passed by caller)
            if [[ "$1" == --* ]]; then
                echo -e "${YELLOW}Warning: Unknown flag '$1' ignored${NC}" >&2
                shift
                continue
            fi
            if [ -z "$SERVICE_NAME" ]; then
                SERVICE_NAME="$1"
            elif [ -z "$ENTITY_NAME" ]; then
                ENTITY_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Validate service name
if [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}Error: Service name required${NC}"
    echo ""
    echo "Usage: ./scripts/new-service.sh <service-name>"
    exit 1
fi

if [ -z "$PACKAGE" ]; then
    echo -e "${RED}Error: Package required — use -p/--package (e.g., com.mycompany)${NC}"
    echo ""
    echo "Usage: ./scripts/new-service.sh <service-name> -p <package>"
    exit 1
fi

if [[ ! "$SERVICE_NAME" =~ ^[a-z][a-z0-9]*$ ]]; then
    echo -e "${RED}Error: Service name must be lowercase alphanumeric (e.g., 'order', 'payment')${NC}"
    exit 1
fi

# Validate framework
if [[ ! "$FRAMEWORK" =~ ^(quarkus|quarkus-kotlin-panache|quarkus-langchain4j-ai|sboot|springboot|spring-ai|laravel|jooby)$ ]]; then
    echo -e "${RED}Error: Invalid framework '$FRAMEWORK'. Use 'quarkus', 'quarkus-kotlin-panache', 'quarkus-langchain4j-ai', 'sboot', 'springboot', 'spring-ai', 'laravel', or 'jooby'${NC}"
    exit 1
fi

# Map framework aliases to template directory names
TEMPLATE_NAME="$FRAMEWORK"
case "$FRAMEWORK" in
    sboot) TEMPLATE_NAME="springboot" ;;
    jooby) TEMPLATE_NAME="jooby" ;;
esac

# Function to capitalize first letter (macOS compatible)
capitalize() {
    echo "$(echo "$1" | cut -c1 | tr '[:lower:]' '[:upper:]')$(echo "$1" | cut -c2-)"
}

# Derived values
ENTITY_NAME=${ENTITY_NAME:-$(capitalize "$SERVICE_NAME")}
SERVICE_PASCAL=$(capitalize "$SERVICE_NAME")

# Table name: handle pluralization - avoid "userss" by checking if name ends in 's'
if [ -n "$TABLE_NAME" ]; then
    : # use explicit override
elif [[ "$SERVICE_NAME" =~ s$ ]]; then
    TABLE_NAME="$SERVICE_NAME"  # ends in 's', no need to pluralize (users → users)
else
    TABLE_NAME="${SERVICE_NAME}s"  # add 's' (order → orders)
fi

TABLE_URL="${TABLE_URL:-$SERVICE_NAME}"
PACKAGE_PATH=$(echo "$PACKAGE" | tr '.' '/')

# Guard: service directory must not already exist
if [ -d "services/$SERVICE_NAME" ]; then
    echo -e "${RED}Error: services/$SERVICE_NAME already exists${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../../../templates/services/${TEMPLATE_NAME}-service-template"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}Error: Template not found at $TEMPLATE_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}Generating $FRAMEWORK service: $SERVICE_NAME${NC}"
echo -e "  Package:   $PACKAGE"
echo -e "  Entity:    $ENTITY_NAME"
echo -e "  DB table:  $TABLE_NAME"
echo -e "  REST path: /api/v1/$TABLE_URL"
echo ""

# Create services directory if needed
mkdir -p "$PROJECT_ROOT/services"

# ---------------------------------------------------------------------------
# Step 1: Copy template
# ---------------------------------------------------------------------------
echo "Step 1/5: Copying template..."
cp -r "$TEMPLATE_DIR" "$PROJECT_ROOT/services/$SERVICE_NAME"
SERVICE_DIR="$PROJECT_ROOT/services/$SERVICE_NAME"

# ---------------------------------------------------------------------------
# Step 1b: Install shared libs to services/libs/ (idempotent — first service wins)
# ---------------------------------------------------------------------------
LIBS_IN_SERVICE="$SERVICE_DIR/libs"
LIBS_TARGET="$PROJECT_ROOT/services/libs"

if [ -d "$LIBS_IN_SERVICE" ]; then
    if [ ! -d "$LIBS_TARGET" ]; then
        echo "  - Installing shared libs to services/libs/..."
        cp -r "$LIBS_IN_SERVICE" "$LIBS_TARGET"
        # Remove IDE/build artifacts that don't belong in a template
        find "$LIBS_TARGET" \( -name ".DS_Store" -o -name "*.class" \) -delete 2>/dev/null || true
        rm -rf "$LIBS_TARGET/shared-infrastructure/old" 2>/dev/null || true
        find "$LIBS_TARGET" -type d -name ".settings" | xargs rm -rf 2>/dev/null || true
        find "$LIBS_TARGET" -type d -name "build"     | xargs rm -rf 2>/dev/null || true
        find "$LIBS_TARGET" -type d -name "bin"       | xargs rm -rf 2>/dev/null || true
        echo "  - Shared libs installed at services/libs/"
    else
        echo "  - services/libs/ already exists, skipping (shared libs already installed)"
    fi
    rm -rf "$LIBS_IN_SERVICE"
fi

# ---------------------------------------------------------------------------
# Step 2: Rename files and directories with name placeholders
# ---------------------------------------------------------------------------
echo "Step 2/5: Renaming files and directories..."

cd "$SERVICE_DIR"

# Rename directories deepest-first (SERVICE, ENTITY, SERVICE_PASCAL)
while IFS= read -r dir; do
    newdir=$(echo "$dir" | sed \
        -e "s|__SERVICE_PASCAL__|$SERVICE_PASCAL|g" \
        -e "s|__SERVICE__|$SERVICE_NAME|g" \
        -e "s|__ENTITY__|$ENTITY_NAME|g")
    if [ "$dir" != "$newdir" ] && [ -d "$dir" ]; then
        mv "$dir" "$newdir" 2>/dev/null || true
    fi
done < <(find src -type d \( -name "*__SERVICE__*" -o -name "*__ENTITY__*" -o -name "*__SERVICE_PASCAL__*" \) 2>/dev/null | sort -r)

# Rename files with placeholders
while IFS= read -r file; do
    newfile=$(echo "$file" | sed \
        -e "s|__SERVICE_PASCAL__|$SERVICE_PASCAL|g" \
        -e "s|__SERVICE__|$SERVICE_NAME|g" \
        -e "s|__ENTITY__|$ENTITY_NAME|g" \
        -e "s|__TABLE__|$TABLE_NAME|g")
    if [ "$file" != "$newfile" ] && [ -f "$file" ]; then
        mv "$file" "$newfile" 2>/dev/null || true
    fi
done < <(find src -type f -name "*__*" 2>/dev/null)

# ---------------------------------------------------------------------------
# Step 2b: Rename base package directory (io/bitnomio → PACKAGE_PATH)
# ---------------------------------------------------------------------------
DEFAULT_PACKAGE_PATH="io/bitnomio"
if [ "$PACKAGE_PATH" != "$DEFAULT_PACKAGE_PATH" ]; then
    for java_root in "src/main/java" "src/test/java" "src/main/kotlin" "src/test/kotlin"; do
        OLD_DIR="$java_root/$DEFAULT_PACKAGE_PATH"
        NEW_DIR="$java_root/$PACKAGE_PATH"
        if [ -d "$OLD_DIR" ]; then
            mkdir -p "$(dirname "$NEW_DIR")"
            mv "$OLD_DIR" "$NEW_DIR"
            # Clean up empty ancestor dirs
            rmdir "$java_root/io" 2>/dev/null || true
        fi
    done
fi

cd "$PROJECT_ROOT"
echo "  - Renamed all files and directories"

# ---------------------------------------------------------------------------
# Step 3: Replace content placeholders
# ---------------------------------------------------------------------------
echo "Step 3/5: Replacing content placeholders..."

find "$SERVICE_DIR" -type f \( \
    -name "*.java" -o -name "*.kt" -o -name "*.properties" -o -name "*.yml" -o \
    -name "*.yaml" -o -name "*.sql" -o -name "*.kts" -o \
    -name "*.md" -o -name "*.xml" -o -name "*.template" \
    \) 2>/dev/null | while read -r file; do
    if [ -f "$file" ]; then
        sed_i "s|__PACKAGE__|$PACKAGE|g" "$file"
        sed_i "s|__PROJECT_NAME__|$PROJECT_NAME|g" "$file"
        sed_i "s|__SERVICE__|$SERVICE_NAME|g" "$file"
        sed_i "s|__SERVICE_PASCAL__|$SERVICE_PASCAL|g" "$file"
        sed_i "s|__ENTITY__|$ENTITY_NAME|g" "$file"
        sed_i "s|__TABLE_URL__|$TABLE_URL|g" "$file"
        sed_i "s|__TABLE__|$TABLE_NAME|g" "$file"
    fi
done

echo "  - Replaced all content placeholders"

# ---------------------------------------------------------------------------
# Step 4: Handle Gradle files
# ---------------------------------------------------------------------------
echo "Step 4/5: Processing Gradle files..."

TEMP_DIR="$SERVICE_DIR/gradle-temp"
if [ -d "$SERVICE_DIR/gradle" ]; then
    mv "$SERVICE_DIR/gradle" "$TEMP_DIR"
fi

mkdir -p "$PROJECT_ROOT/gradle"

if [ -f "$TEMP_DIR/build.gradle.kts.template" ]; then
    mv "$TEMP_DIR/build.gradle.kts.template" "$SERVICE_DIR/build.gradle.kts.template"
fi
if [ -f "$TEMP_DIR/settings.gradle.kts" ]; then
    if [ -f "$PROJECT_ROOT/settings.gradle.kts" ]; then
        rm "$TEMP_DIR/settings.gradle.kts"
    else
        mv "$TEMP_DIR/settings.gradle.kts" "$PROJECT_ROOT/settings.gradle.kts"
    fi
fi
if [ -f "$TEMP_DIR/libs.versions.toml" ]; then
    mv "$TEMP_DIR/libs.versions.toml" "$PROJECT_ROOT/gradle/libs.versions.toml"
fi
if [ -f "$TEMP_DIR/root-build.gradle.kts.template" ]; then
    if [ ! -f "$PROJECT_ROOT/build.gradle.kts" ]; then
        mv "$TEMP_DIR/root-build.gradle.kts.template" "$PROJECT_ROOT/build.gradle.kts.template"
    else
        rm "$TEMP_DIR/root-build.gradle.kts.template"
    fi
fi

if [ -f "$TEMP_DIR/root-settings.gradle.kts.template" ]; then
    rm "$TEMP_DIR/root-settings.gradle.kts.template"
fi
if [ -f "$TEMP_DIR/gradle.properties" ]; then
    mv "$TEMP_DIR/gradle.properties" "$PROJECT_ROOT/gradle.properties"
fi
if [ -f "$TEMP_DIR/wrapper/gradle-wrapper.properties" ]; then
    if [ ! -f "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties" ]; then
        mkdir -p "$PROJECT_ROOT/gradle/wrapper"
        cp "$TEMP_DIR/wrapper/gradle-wrapper.properties" "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
        echo "  - Installed gradle/wrapper/gradle-wrapper.properties"
    fi
fi

rm -rf "$TEMP_DIR"

# Rename .template files
find "$SERVICE_DIR" -type f -name "*.template" | while read -r file; do
    mv "$file" "${file%.template}"
done

# Register in settings.gradle.kts
if [ -f "$PROJECT_ROOT/settings.gradle.kts" ]; then
    if grep -q "__SERVICES_LIST__" "$PROJECT_ROOT/settings.gradle.kts"; then
        python3 << PYEOF
settings_file = "$PROJECT_ROOT/settings.gradle.kts"
service_name = "$SERVICE_NAME"

with open(settings_file, 'r') as f:
    content = f.read()

content = content.replace(
    '__SERVICES_LIST__',
    f'include(":services:{service_name}")\n'
).replace(
    '__SERVICES_CONFIG__',
    f'project(":services:{service_name}").projectDir = file("services/{service_name}")\n'
)

with open(settings_file, 'w') as f:
    f.write(content)
PYEOF
    elif ! grep -q ":services:$SERVICE_NAME" "$PROJECT_ROOT/settings.gradle.kts"; then
        echo "" >> "$PROJECT_ROOT/settings.gradle.kts"
        echo "include(\":services:$SERVICE_NAME\")" >> "$PROJECT_ROOT/settings.gradle.kts"
        echo "project(\":services:$SERVICE_NAME\").projectDir = file(\"services/$SERVICE_NAME\")" >> "$PROJECT_ROOT/settings.gradle.kts"
    fi
    # Ensure shared libs are registered (idempotent — appends only if missing)
    if [ -d "$PROJECT_ROOT/services/libs" ] && ! grep -q ":services:libs:shared-domain" "$PROJECT_ROOT/settings.gradle.kts"; then
        cat >> "$PROJECT_ROOT/settings.gradle.kts" << 'LIBS_BLOCK'

// Common libraries
include(":services:libs:shared-domain")
include(":services:libs:shared-application")
include(":services:libs:shared-infrastructure")
include(":services:libs:shared-security")

project(":services:libs:shared-domain").projectDir = file("services/libs/shared-domain")
project(":services:libs:shared-application").projectDir = file("services/libs/shared-application")
project(":services:libs:shared-infrastructure").projectDir = file("services/libs/shared-infrastructure")
project(":services:libs:shared-security").projectDir = file("services/libs/shared-security")
LIBS_BLOCK
        echo "  - Registered shared libs in settings.gradle.kts"
    fi
else
    echo -e "${YELLOW}Warning: settings.gradle.kts not found, skipping project registration${NC}"
fi

# Set up Gradle wrapper scripts (gradlew, gradlew.bat, wrapper JAR) if missing.
# Must run AFTER settings.gradle.kts placeholders are resolved so Gradle can
# evaluate the settings file without compile errors.
if [ ! -f "$PROJECT_ROOT/gradlew" ]; then
    GRADLE_VERSION=$(grep 'distributionUrl' "$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties" 2>/dev/null \
        | sed 's/.*gradle-\([0-9.]*\)-.*/\1/')
    GRADLE_VERSION="${GRADLE_VERSION:-9.0}"
    if command -v gradle &> /dev/null; then
        echo "  - Running 'gradle wrapper --gradle-version=${GRADLE_VERSION}'..."
        (cd "$PROJECT_ROOT" && gradle wrapper --gradle-version="$GRADLE_VERSION" --quiet)
        echo "  - Gradle wrapper installed (gradlew, gradlew.bat, wrapper JAR)"
    else
        echo -e "${YELLOW}  ⚠  gradlew not installed — Gradle CLI not found.${NC}"
        echo -e "     Run inside the project root: gradle wrapper --gradle-version=${GRADLE_VERSION}"
    fi
fi

# ---------------------------------------------------------------------------
# Step 5: Process Docker files
# ---------------------------------------------------------------------------
echo "Step 5/8: Processing Docker files..."
for f in "$SERVICE_DIR/Dockerfile" "$SERVICE_DIR/docker-compose.yml"; do
    if [ -f "$f.template" ]; then
        mv "$f.template" "$f"
    fi
    if [ -f "$f" ]; then
        sed_i "s|__PACKAGE__|$PACKAGE|g" "$f"
        sed_i "s|__PROJECT_NAME__|$PROJECT_NAME|g" "$f"
        sed_i "s|__SERVICE__|$SERVICE_NAME|g" "$f"
        sed_i "s|__SERVICE_PASCAL__|$SERVICE_PASCAL|g" "$f"
        sed_i "s|__ENTITY__|$ENTITY_NAME|g" "$f"
        sed_i "s|__TABLE_URL__|$TABLE_URL|g" "$f"
        sed_i "s|__TABLE__|$TABLE_NAME|g" "$f"
    fi
done
echo "  - Docker files ready"

# ---------------------------------------------------------------------------
# Step 6: Apply infrastructure toggles
# ---------------------------------------------------------------------------
echo "Step 6/8: Applying infrastructure toggles..."

# Read toggles from template.yaml if not explicitly set via CLI
if command -v python3 &> /dev/null; then
    PYTHON_DIR="$SCRIPT_DIR/../../lib/python"
    if [ -f "$PYTHON_DIR/template-config.py" ]; then
        TEMPLATE_INFRA=$(python3 "$PYTHON_DIR/template-config.py" --template "$TEMPLATE_DIR" --get-infrastructure 2>/dev/null || echo '{}')
        # Only use template defaults if CLI flags weren't explicitly set
        # (CLI flags default to false, so we always prefer CLI if user passed them)
        : # CLI flags already parsed, use them directly
    fi
fi

# Apply toggles to build.gradle.kts
BUILD_FILE="$SERVICE_DIR/build.gradle.kts"
if [ -f "$BUILD_FILE" ]; then
    # Use Python for reliable build file modification
    python3 << PYEOF
import sys

build_file = "$BUILD_FILE"
framework = "$FRAMEWORK"
kafka = "$ENABLE_KAFKA" == "true"
redis = "$ENABLE_REDIS" == "true"
rabbitmq = "$ENABLE_RABBITMQ" == "true"

deps = []
is_quarkus = framework.startswith("quarkus")
if kafka:
    if is_quarkus:
        deps.append('    implementation(libs.quarkus.kafka.client)')
    else:
        deps.append('    implementation(libs.spring.kafka)')
if redis:
    if is_quarkus:
        deps.append('    implementation(libs.quarkus.redis.client)')
    else:
        deps.append('    implementation(libs.spring.data.redis)')
if rabbitmq:
    if is_quarkus:
        deps.append('    implementation(libs.quarkus.rabbitmq)')
    else:
        deps.append('    implementation(libs.spring.rabbitmq)')

if not deps:
    sys.exit(0)

with open(build_file, 'r') as f:
    lines = f.readlines()

# Find the line with "dependencies {" and insert after it
new_lines = []
inserted = False
for line in lines:
    new_lines.append(line)
    if not inserted and 'dependencies {' in line:
        new_lines.append('\n')
        for dep in deps:
            new_lines.append(dep + '\n')
        inserted = True

with open(build_file, 'w') as f:
    f.writelines(new_lines)

for dep in deps:
    print(f"  - Added: {dep.strip()}")
PYEOF
fi

# ---------------------------------------------------------------------------
# Step 6b: Generate frontend (optional)
# ---------------------------------------------------------------------------
if [ "$INCLUDE_FRONTEND" = true ]; then
    echo -e "${BLUE}  Generating frontend...${NC}"
    FRONTEND_TEMPLATE="$PROJECT_ROOT/templates/frontend/react-shadcn"

    if [ -d "$FRONTEND_TEMPLATE" ]; then
        cp -r "$FRONTEND_TEMPLATE" "$SERVICE_DIR/frontend/"

        # Replace placeholders
        sed_i "s/__SERVICE__/$SERVICE_NAME/g" "$SERVICE_DIR/frontend/index.html"
        sed_i "s/__SERVICE__/$SERVICE_NAME/g" "$SERVICE_DIR/frontend/package.json.template"
        sed_i "s/__SERVICE_PASCAL__/$SERVICE_PASCAL/g" "$SERVICE_DIR/frontend/src/App.tsx"
        sed_i "s/__TABLE_URL__/$TABLE_URL/g" "$SERVICE_DIR/frontend/src/App.tsx"
        sed_i "s/__ENTITY__/$ENTITY_NAME/g" "$SERVICE_DIR/frontend/src/App.tsx"

        # Rename .template
        mv "$SERVICE_DIR/frontend/package.json.template" "$SERVICE_DIR/frontend/package.json"

        echo -e "${GREEN}  ✅ Frontend generated at frontend/${NC}"
        echo -e "     cd $SERVICE_DIR/frontend && npm install && npm run dev"
    else
        echo -e "${YELLOW}  ⚠️  Frontend template not found at $FRONTEND_TEMPLATE${NC}"
    fi
fi

# ---------------------------------------------------------------------------
# Step 7: GitOps config generation (optional)
# ---------------------------------------------------------------------------
if [ "$GITOPS" = true ]; then
    echo "Step 7/8: Generating GitOps config..."
    CONFIG_DIR="$PROJECT_ROOT/services/$SERVICE_NAME-config"
    FRAGMENTS_DIR="$SCRIPT_DIR/../../../backbone/skeleton-fragments"

    if [ ! -d "$FRAGMENTS_DIR" ]; then
        echo -e "  ${YELLOW}⚠️  skeleton-fragments not found at $FRAGMENTS_DIR — skipping GitOps${NC}"
    else
        # Determine health check path based on framework
        if [ "$FRAMEWORK" = "quarkus" ] || [ "$FRAMEWORK" = "quarkus-kotlin-panache" ] || [ "$FRAMEWORK" = "quarkus-langchain4j-ai" ]; then
            HEALTH_PATH="/q/health/live"
        elif [ "$FRAMEWORK" = "spring-ai" ]; then
            HEALTH_PATH="/actuator/health"
        else
            HEALTH_PATH="/actuator/health"
        fi

        # Build values JSON for template processor
        VALUES_JSON=$(python3 -c "
import json
print(json.dumps({
    'appName': '$SERVICE_NAME',
    'namespace': 'default',
    'version': 'latest',
    'containerPort': 8080,
    'servicePort': 80,
    'replicas': 3,
    'imageRegistry': 'image-registry.openshift-image-registry.svc:5000',
    'host': 'api.example.com',
    'tlsEnabled': True,
    'gitRepoUrl': 'https://github.com/org/$SERVICE_NAME',
    'branch': 'main',
    'argocdProject': 'default',
    'healthPath': '$HEALTH_PATH',
}))
")

        if command -v python3 &> /dev/null && [ -f "$PYTHON_DIR/template-processor.py" ]; then
            python3 "$PYTHON_DIR/template-processor.py" \
                --input "$FRAGMENTS_DIR" \
                --output "$CONFIG_DIR" \
                --values "$VALUES_JSON"
            echo "  - GitOps config generated at services/$SERVICE_NAME-config/"
        else
            echo -e "  ${YELLOW}⚠️  Python/template-processor.py not available — skipping GitOps${NC}"
        fi
    fi
else
    echo "Step 7/8: Skipping GitOps (use --gitops to enable)"
fi

# ---------------------------------------------------------------------------
# Step 8: Cleanup artifacts
# ---------------------------------------------------------------------------
echo "Step 8/8: Cleaning up artifacts..."
find "$SERVICE_DIR" -type f \( -name "*.class" -o -name "*.jar" -o -name ".DS_Store" \) -delete 2>/dev/null || true
find "$SERVICE_DIR" -type d \( -name "build" -o -name "bin" -o -name ".settings" \) -exec rm -rf {} + 2>/dev/null || true
echo "  - Removed build artifacts"

# ---------------------------------------------------------------------------
# Step 9: Verify
# ---------------------------------------------------------------------------
echo ""
echo "Step 9/9: Verifying..."
JAVA_SRC="$SERVICE_DIR/src/main/java"
if [ -f "$SERVICE_DIR/build.gradle.kts" ] && [ -d "$JAVA_SRC" ]; then
    echo -e "${GREEN}✅ Service created at services/$SERVICE_NAME${NC}"
else
    echo -e "${RED}Error: Service creation failed — expected build.gradle.kts and src/main/java${NC}"
    exit 1
fi

# Check for unreplaced placeholders
echo "  - Checking for unreplaced placeholders..."
PLACEHOLDER_ISSUES=$(grep -r "__\(SERVICE\|ENTITY\|PACKAGE\|TABLE\|PROJECT_NAME\)__" "$SERVICE_DIR" --include="*.java" --include="*.kt" --include="*.php" --include="*.properties" --include="*.yml" --include="*.yaml" --include="*.kts" --include="*.sql" --include="*.md" 2>/dev/null || true)
if [ -n "$PLACEHOLDER_ISSUES" ]; then
    echo -e "${RED}❌ Found unreplaced placeholders:${NC}"
    echo "$PLACEHOLDER_ISSUES" | head -10
    exit 1
else
    echo -e "  ${GREEN}✅ No placeholders found${NC}"
fi

# Optional compilation verification
if [ "$VERIFY" = true ]; then
    echo "  - Running compilation check..."
    if [ -f "$PROJECT_ROOT/gradlew" ]; then
        if (cd "$PROJECT_ROOT" && ./gradlew :services:$SERVICE_NAME:compileJava --quiet 2>&1); then
            echo -e "  ${GREEN}✅ Compilation successful${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Compilation failed — check generated code${NC}"
            exit 1
        fi
    else
        echo -e "  ${YELLOW}⚠️  gradlew not found — skipping compilation check${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review generated files in services/$SERVICE_NAME"
echo "  2. Customize entity fields in domain/model/vo/${ENTITY_NAME}.java"
echo "  3. Add migrations in src/main/resources/db/migration/"
echo "  4. Configure database URL in application.properties / application.yml"
echo "  5. Run locally:   docker compose -f services/$SERVICE_NAME/docker-compose.yml up"
echo "  6. Validate:      bash scripts/service-generator/scripts/validate-setup.sh $SERVICE_NAME"
echo "  7. Build:         ./gradlew :services:$SERVICE_NAME:build"
if [ "$GITOPS" = true ]; then
    echo "  8. GitOps config: services/$SERVICE_NAME-config/"
fi
echo ""
echo -e "${BLUE}Shared module:${NC} Services depend on \${PACKAGE}.shared.* — ensure your"
echo "  shared library is available as a project dependency."
echo ""
