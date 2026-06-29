#!/bin/bash
# scripts/reverse-engineer.sh — Analyze a project and generate backbone metadata
#
# Scans source files, build configurations, and directory structure to
# reverse-engineer the project's architecture, framework, and patterns.
#
# Usage:
#   ./scripts/reverse-engineer.sh [--project-dir PATH] [--output DIR] [--apply]
#
# Flags:
#   --project-dir PATH   Project to analyze (default: current dir)
#   --output DIR         Output directory (default: auto CHNG folder)
#   --apply             Write generated metadata to live backbone/ files
#   --help              Show help

set -euo pipefail
if [[ -f "$HOME/.backbone/scripts/lib/bb-root.sh" ]]; then
    source "$HOME/.backbone/scripts/lib/bb-root.sh"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    BB_ROOT="$PROJECT_ROOT"
fi
PROJECT_ROOT="${1:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

APPLY=false
OUTPUT_DIR=""
PROJECT_DIR="."
SKIP_PATTERNS="docs/ templates/ .claude/ .opencode/ node_modules/ build/ target/ dist/ .gradle/ scripts/"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project-dir) PROJECT_DIR="$2"; shift 2 ;;
            --output) OUTPUT_DIR="$2"; shift 2 ;;
            --apply) APPLY=true; shift ;;
            --help) show_help; exit 0 ;;
            *) echo -e "${RED}Unknown: $1${NC}"; exit 1 ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Usage: reverse-engineer.sh [options]

Analyze a project and generate backbone metadata files.

Options:
  --project-dir PATH   Project to analyze (default: .)
  --output DIR         Output directory
  --apply              Write generated files to live backbone/ directory
  --help               Show help
EOF
}

# ── Detection Functions ──────────────────────────────────────────────────────

detect_framework() {
    local dir="$1"
    # Search project root and common module directories
    local search_dirs="$dir"
    for sub in services/*/ apps/*/ modules/*/; do
        [ -d "$dir/$sub" ] && search_dirs="$search_dirs $dir/$sub"
    done
    for sd in $search_dirs; do
        [ -d "$sd" ] || continue
        if [ -f "$sd/pom.xml" ]; then
            if grep -q 'quarkus' "$sd/pom.xml" 2>/dev/null; then echo "Quarkus (Java)"; return
            elif grep -q 'spring-boot' "$sd/pom.xml" 2>/dev/null; then echo "Spring Boot (Java)"; return
            else echo "Java (Maven)"; return
            fi
        elif [ -f "$sd/build.gradle" ] || [ -f "$sd/build.gradle.kts" ]; then
            local bf="$sd/build.gradle"
            [ -f "$bf" ] || bf="$sd/build.gradle.kts"
            if grep -qi 'quarkus' "$bf" 2>/dev/null; then echo "Quarkus (Java/Kotlin)"; return
            elif grep -qi 'spring' "$bf" 2>/dev/null; then echo "Spring Boot (Java/Kotlin)"; return
            elif grep -qi 'kotlin' "$bf" 2>/dev/null; then echo "Kotlin (Gradle)"; return
            else echo "Java (Gradle)"; return
            fi
        elif [ -f "$sd/composer.json" ]; then echo "Laravel/PHP"; return
        elif [ -f "$sd/package.json" ]; then
            if grep -qi 'next' "$sd/package.json" 2>/dev/null; then echo "Node.js (Next.js)"; return
            elif grep -qi 'react' "$sd/package.json" 2>/dev/null; then echo "Node.js (React)"; return
            else echo "Node.js"; return
            fi
        elif [ -f "$sd/Cargo.toml" ]; then echo "Rust"; return
        elif [ -f "$sd/go.mod" ]; then echo "Go"; return
        elif [ -f "$sd/requirements.txt" ] || [ -f "$sd/setup.py" ]; then echo "Python"; return
        fi
    done
    echo "Unknown"
}

# Check if a path contains any excluded directory component
is_excluded_path() {
    local path="$1"
    for sp in $SKIP_PATTERNS; do
        if echo "$path" | grep -qE "(^|/)$sp"; then
            return 0
        fi
    done
    return 1
}

# Find source directories — searches common patterns, filters out excluded paths
find_source_dirs() {
    local dir="$1"
    local dirs=""
    for pattern in "src" "services/*/src" "app" "lib" "services/*/app" "src/main/java"; do
        local found
        found=$(find "$dir" -type d -path "*/$pattern" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" -not -path "*/build/*" -not -path "*/target/*" 2>/dev/null | head -20)
        while IFS= read -r d; do
            [ -z "$d" ] && continue
            if ! is_excluded_path "$d"; then
                dirs="$dirs $d"
            fi
        done <<< "$found"
    done
    # Fallback: just find any directory with source files
    if [ -z "$(echo "$dirs" | tr -d ' ')" ]; then
        for ext in java kt ts js py go rs rb php; do
            local found_file
            found_file=$(find "$dir" -name "*.$ext" -type f -not -path "*/.git/*" 2>/dev/null | head -1)
            if [ -n "$found_file" ] && ! is_excluded_path "$found_file"; then
                dirs="$dirs $(dirname "$found_file")"
                break
            fi
        done
    fi
    echo "$dirs" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

detect_language() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    local count
    for ext in java kt ts js py go rs rb php; do
        count=0
        for sd in $src_dirs; do
            local c
            c=$(find "$sd" -maxdepth 3 -name "*.$ext" -type f 2>/dev/null | wc -l | tr -d ' ')
            count=$((count + c))
        done
        [ "$count" -gt 0 ] && case "$ext" in
            java) echo "Java"; return ;;
            kt) echo "Kotlin"; return ;;
            ts) echo "TypeScript"; return ;;
            js) echo "JavaScript"; return ;;
            py) echo "Python"; return ;;
            go) echo "Go"; return ;;
            rs) echo "Rust"; return ;;
            rb) echo "Ruby"; return ;;
            php) echo "PHP"; return ;;
        esac
    done
    echo "Unknown"
}

detect_build_tool() {
    local dir="$1"
    [ -f "$dir/pom.xml" ] && echo "Maven" && return
    [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ] && echo "Gradle" && return
    [ -f "$dir/package.json" ] && echo "npm/yarn" && return
    [ -f "$dir/Cargo.toml" ] && echo "Cargo" && return
    [ -f "$dir/go.mod" ] && echo "Go modules" && return
    [ -f "$dir/composer.json" ] && echo "Composer" && return
    echo "Unknown"
}

detect_db() {
    local dir="$1"
    for f in pom.xml build.gradle build.gradle.kts composer.json package.json; do
        local found
        found=$(find "$dir" -name "$f" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -5)
        [ -z "$found" ] && continue
        while IFS= read -r bf; do
            is_excluded_path "$bf" && continue
            grep -qi 'postgresql\|postgres' "$bf" 2>/dev/null && echo "PostgreSQL" && return
            grep -qi 'mysql' "$bf" 2>/dev/null && echo "MySQL" && return
            grep -qi 'mongodb\|mongo-driver' "$bf" 2>/dev/null && echo "MongoDB" && return
            grep -qi 'h2' "$bf" 2>/dev/null && echo "H2" && return
            grep -qi 'sqlite\|sqlite-jdbc' "$bf" 2>/dev/null && echo "SQLite" && return
            grep -qi 'redis' "$bf" 2>/dev/null && echo "Redis" && return
        done <<< "$found"
    done
    for cfg in application.yml application.yaml application.properties; do
        local cfgs
        cfgs=$(find "$dir" -name "$cfg" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -5)
        [ -z "$cfgs" ] && continue
        while IFS= read -r cf; do
            is_excluded_path "$cf" && continue
            grep -qi 'postgres\|postgresql' "$cf" 2>/dev/null && echo "PostgreSQL" && return
            grep -qi 'mysql' "$cf" 2>/dev/null && echo "MySQL" && return
            grep -qi 'mongodb' "$cf" 2>/dev/null && echo "MongoDB" && return
            grep -qi 'h2' "$cf" 2>/dev/null && echo "H2 (dev)" && return
            grep -qi 'redis' "$cf" 2>/dev/null && echo "Redis" && return
            grep -qi 'spring.jpa\|spring.datasource' "$cf" 2>/dev/null && echo "JPA (config-driven)" && return
        done <<< "$cfgs"
    done
    echo "Unknown"
}

detect_architecture() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    local layers=""
    for sd in $src_dirs; do
        [ -d "$sd"/*/domain ] && layers="$layers domain"
        [ -d "$sd"/*/app ] || [ -d "$sd"/*/application ] && layers="$layers application"
        [ -d "$sd"/*/infra ] || [ -d "$sd"/*/infrastructure ] && layers="$layers infrastructure"
        [ -d "$sd"/*/api ] || [ -d "$sd"/*/controller ] || [ -d "$sd"/*/resource ] && layers="$layers api"
    done
    layers=$(echo "$layers" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
    if [ -n "$layers" ]; then echo "Hexagonal (layers:$layers)"
    elif ls "$dir/services/"*/src/main/java/*/ 2>/dev/null | grep -q .; then echo "Multi-module"
    else echo "Unknown"
    fi
}

count_source_files() {
    local dir="$1"
    local total=0
    for pattern in "src" "services/*/src" "app" "lib"; do
        local dirs
        dirs=$(find "$dir" -type d -path "*/$pattern" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" -not -path "*/build/*" -not -path "*/target/*" 2>/dev/null | head -20)
        for sd in $dirs; do
            is_excluded_path "$sd" && continue
            local c
            c=$(find "$sd" -type f \( -name "*.java" -o -name "*.kt" -o -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.rb" -o -name "*.php" -o -name "*.scala" \) 2>/dev/null | wc -l | tr -d ' ')
            total=$((total + c))
        done
    done
    echo "$total"
}

count_test_files() {
    local dir="$1"
    local total=0
    for pattern in "src/test" "services/*/src/test" "test" "tests" "spec"; do
        local dirs
        dirs=$(find "$dir" -type d -path "*/$pattern" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -5)
        for td in $dirs; do
            is_excluded_path "$td" && continue
            local c
            c=$(find "$td" -type f \( -name "*.java" -o -name "*.kt" -o -name "*.ts" -o -name "*.js" -o -name "*.py" \) -maxdepth 5 2>/dev/null | wc -l | tr -d ' ')
            total=$((total + c))
        done
    done
    echo "$total"
}

# ── Project Analysis Functions ───────────────────────────────────────────────

# Extract subdomain/module names from source directory tree
detect_modules() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    for sd in $src_dirs; do
        local rel
        rel=$(echo "$sd" | sed "s|$dir/||" | sed 's|/src/main/java/.*||' | sed 's|/src/.*||' | sed 's|/test/.*||')
        [ -z "$rel" ] && continue
        echo "$rel"
    done | sort -u | grep -v '/src$' | head -10
}

# Detect key dependencies from build files
detect_dependencies() {
    local dir="$1"
    for f in pom.xml build.gradle build.gradle.kts package.json; do
        local bf
        bf=$(find "$dir" -name "$f" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -1)
        [ -z "$bf" ] && continue
        case "$f" in
            pom.xml)
                grep '<artifactId>' "$bf" 2>/dev/null | sed 's/.*<artifactId>//;s|</artifactId>.*||' | grep -v "^$bf$\|^maven-\|^junit\|^assertj\|^mockito\|^spring-boot-starter-test\|^spring-boot-starter$\|^lombok\|^h2$" | head -10
                return ;;
            build.gradle*)
                grep -E "implementation |api |testImplementation " "$bf" 2>/dev/null | sed 's/.*["'\'']\([^:]*:[^:]*\)["'\''"].*/\1/' | head -10
                return ;;
            package.json)
                grep -E '"[^"]+": "' "$bf" 2>/dev/null | sed 's/.*"\([^"]*\)":.*/\1/' | grep -v "^$\|^eslint\|^prettier\|^typescript\|^@types/" | head -10
                return ;;
        esac
    done
}

# Detect available build commands
detect_build_commands() {
    local dir="$1"
    if [ -f "$dir/Makefile" ]; then
        echo "make <target>  (available targets: $(grep -E '^[a-zA-Z][a-zA-Z0-9_-]+:' "$dir/Makefile" 2>/dev/null | sed 's/:.*//' | tr '\n' ' '))"
    fi
    if [ -f "$dir/gradlew" ]; then
        echo "./gradlew build"
        echo "./gradlew test"
    elif [ -f "$dir/mvnw" ]; then
        echo "./mvnw clean install"
        echo "./mvnw test"
    fi
    if ls "$dir/scripts/"*.sh 2>/dev/null | grep -q .; then
        ls "$dir/scripts/"*.sh 2>/dev/null | head -5 | xargs -n1 basename
    fi
}

# Detect test configuration
detect_test_commands() {
    local dir="$1"
    local has_tests
    has_tests=$(find "$dir" -type d -name "test" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -1)
    if [ -n "$has_tests" ]; then
        if [ -f "$dir/gradlew" ]; then echo "./gradlew test"; return; fi
        if [ -f "$dir/mvnw" ]; then echo "./mvnw test"; return; fi
        if [ -f "$dir/Makefile" ] && grep -q 'test' "$dir/Makefile" 2>/dev/null; then echo "make test"; return; fi
        echo "See build tool documentation"
        return
    fi
    echo "No test directory detected"
}

# Load skills based on what the agent found — scans backbone/skills/ dynamically
# List SKILL.md files in a directory
list_skill_dir() {
    local sdir="$1" prefix="$2" skills_root="$3"
    [ -d "$sdir" ] || return 0
    local clean_root="${skills_root%%/}"
    for sf in "${sdir%/}"/*/SKILL.md; do
        [ -f "$sf" ] || continue
        local skill_name skill_path dir_path
        dir_path=$(dirname "$sf")
        skill_name=$(basename "$dir_path")
        skill_path="${dir_path#"$clean_root"/}"
        [ "$skill_path" = "$dir_path" ] && continue
        printf -- "- **%s:** \`%s/%s/SKILL.md\`\n" "$skill_name" "$prefix" "$skill_path"
    done
}

# Load skills based on what the agent found — scans ~/.backbone/skills/ dynamically
detect_skills() {
    local dir="$1" framework="$2" language="$3" db="$4" build_tool="$5"
    local skills_dir="$HOME/.backbone/skills"
    [ ! -d "$skills_dir" ] && return
    local fw_lc lang_lc
    fw_lc=$(echo "$framework" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z')
    lang_lc=$(echo "$language" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z')

    # Framework skill dir (springboot/, quarkus/, laravel/)
    for sdir in "$skills_dir"/*/; do
        [ -d "$sdir" ] || continue
        local base base_lc
        base=$(basename "$sdir")
        base_lc=$(echo "$base" | tr '[:upper:]' '[:lower:]')
        if echo "$fw_lc" | grep -qF "$base_lc" || echo "$base_lc" | grep -qF "$fw_lc"; then
            list_skill_dir "$sdir" "backbone/skills" "$skills_dir"
        fi
    done

    # Language skills (java/, kotlin/, python/, golang/)
    for sdir in "$skills_dir"/*/; do
        [ -d "$sdir" ] || continue
        local base base_lc
        base=$(basename "$sdir")
        base_lc=$(echo "$base" | tr '[:upper:]' '[:lower:]')
        if echo "$lang_lc" | grep -qF "$base_lc" || echo "$base_lc" | grep -qF "$lang_lc"; then
            list_skill_dir "$sdir" "backbone/skills" "$skills_dir"
        fi
    done

    # Cross-cutting skills — always include
    list_skill_dir "$skills_dir/cross-cutting/architecture" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/code-quality" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/databases" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/docker" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/backend" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/frontend" "backbone/skills" "$skills_dir"
    list_skill_dir "$skills_dir/cross-cutting/testing" "backbone/skills" "$skills_dir"
}

# ── Architecture Issue Detection ──────────────────────────────────────────────

# Detect architecture issues: missing tests, missing domain layers, framework leaks, etc.
detect_issues() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    local issues="" issue_modules=""

    # Find test directories
    local test_dirs
    test_dirs=$(find "$dir" -type d -name "test" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" -not -path "*/build/*" 2>/dev/null | head -10)
    local has_tests=""
    for td in $test_dirs; do
        is_excluded_path "$td" && continue
        has_tests="yes"
        break
    done

    # Check each source module for issues
    for sd in $src_dirs; do
        local rel sd_test sd_parent sd_has_domain sd_has_app
        sd_parent=$(dirname "$sd")
        # Extract meaningful module name from package path
        rel=$(echo "$sd_parent" | sed "s|$dir/||" | grep -oE '[a-z]+/[a-z]+$' | head -1)
        [ -z "$rel" ] && rel=$(echo "$sd_parent" | sed "s|$dir/||" | sed 's|/src.*||' | sed 's|/main/java.*||' | grep -oE '[^/]+$')
        # Skip root-level source dirs and build artifact directories
        case "$rel" in src|main|src/main|test|java|resources) continue ;; esac
        sd_test=$(find "$dir" -type d -name "test" -path "*/$rel/*" -not -path "*/.git/*" 2>/dev/null | head -1)
        local sd_has_test=""
        [ -n "$sd_test" ] && sd_has_test="yes"
        sd_has_domain=""
        sd_has_app=""
        [ -d "$sd_parent/domain" ] 2>/dev/null && sd_has_domain="yes"
        [ -d "$sd_parent/app" ] 2>/dev/null && sd_has_app="yes"

        # Missing domain layer (app exists but no domain) — report once per module
        if [ -n "$sd_has_app" ] && [ -z "$sd_has_domain" ] && ! echo "$issue_modules" | grep -qE "^$rel$"; then
            issue_modules="$issue_modules
$rel"
            issues="$issues
REQ-ARCH-001: Module \`$rel\` has app/ layer but no domain/ layer — business logic may leak into app layer"
        fi

        # Missing tests for module (report once)
        local src_count
        src_count=$(find "$sd" -name "*.java" -o -name "*.kt" -o -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$src_count" -gt 5 ] && [ -z "$sd_has_test" ] && ! echo "$issue_modules" | grep -qE "^$rel$"; then
            issue_modules="$issue_modules
$rel"
            issues="$issues
REQ-TEST-001: Module \`$rel\` has $src_count source files but no test directory — add tests"
        fi
    done

    # Check for framework annotations in app layer
    local app_layer_dirs
    app_layer_dirs=$(find "$dir" -type d -path "*/app" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" 2>/dev/null | head -10)
    for ad in $app_layer_dirs; do
        is_excluded_path "$ad" && continue
        local spring_in_app
        spring_in_app=$(grep -rn '@Service\|@Component\|@Autowired\|@Repository' "$ad" --include="*.java" 2>/dev/null | head -3 || true)
        if [ -n "$spring_in_app" ]; then
            local rel_ad
            rel_ad=$(echo "$ad" | sed "s|$dir/||")
            issues="$issues
REQ-ARCH-002: Framework annotations detected in \`$rel_ad\` — app layer should use plain DI, not framework annotations"
        fi
    done

    # Check test coverage ratio
    local total_src total_test
    total_src=$(count_source_files "$dir")
    total_test=$(count_test_files "$dir")
    if [ "$total_src" -gt 0 ] && [ "$total_test" -lt $((total_src / 10)) ] && [ "$total_test" -lt 20 ]; then
        issues="$issues
REQ-TEST-002: Test coverage is low ($total_test tests for $total_src source files) — increase test coverage"
    fi

    # Check CI/CD
    local has_ci
    has_ci=$(detect_ci_cd "$dir")
    if [ -z "$has_ci" ]; then
        issues="$issues
REQ-OPS-001: No CI/CD configuration detected — set up automated build and test pipeline"
    fi

    # Check Docker
    if ! ls "$dir/Dockerfile"* 2>/dev/null | grep -q .; then
        issues="$issues
REQ-OPS-002: No Dockerfile found — containerize for consistent environments"
    fi

    # Check API surface
    local has_routes
    has_routes=$(detect_api_routes "$dir")
    local src_dirs_with_rest
    src_dirs_with_rest=$(grep -rn '@RestController\|@Path' "$dir" --include="*.java" 2>/dev/null | grep -v "import\|test\|Test" | head -1 || true)
    if [ -n "$src_dirs_with_rest" ] && [ -z "$has_routes" ]; then
        issues="$issues
REQ-ARCH-003: REST controllers detected but no route mappings found — endpoint design may need review"
    fi

    # Check dependency freshness in build files
    local build_files
    build_files=$(find "$dir" -maxdepth 2 \( -name "pom.xml" -o -name "build.gradle.kts" -o -name "build.gradle" -o -name "package.json" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | head -3)
    for bf in $build_files; do
        case "$bf" in
            *pom.xml)
                local old_deps
                old_deps=$(grep -E '<version>' "$bf" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -u | head -5 || true)
                if echo "$old_deps" | grep -qE '^1\.|^0\.'; then
                    issues="$issues
REQ-OPS-003: Build file \`$(basename "$bf")\` has dependencies with old major versions (1.x, 0.x) — review for updates"
                fi ;;
            *package.json)
                if grep -qE '"[a-z].*": "\^?0\.' "$bf" 2>/dev/null; then
                    issues="$issues
REQ-OPS-003: \`package.json\` has dependencies at version 0.x — review for stable releases"
                fi ;;
        esac
    done

    # Dockerfile quality check
    local docker_files
    docker_files=$(find "$dir" -maxdepth 2 -name "Dockerfile*" -not -path "*/.git/*" -not -path "*/templates/*" 2>/dev/null | head -3)
    for df in $docker_files; do
        local has_multistage has_user docker_issues
        has_multistage=$(grep -c 'FROM.*AS ' "$df" 2>/dev/null || true)
        has_user=$(grep -c '^USER ' "$df" 2>/dev/null || true)
        if [ "$has_multistage" -eq 0 ]; then
            issues="$issues
REQ-OPS-004: \`$(basename "$df")\` is not a multi-stage build — use multi-stage for smaller images"
        fi
        if [ "$has_user" -eq 0 ]; then
            issues="$issues
REQ-OPS-005: \`$(basename "$df")\` does not set a non-root USER — run containers as non-root for security"
        fi
    done

    # Git churn hotspots (most frequently changed files)
    if [ -d "$dir/.git" ]; then
        local churn
        churn=$(cd "$dir" && git log --pretty=format: --name-only --since="6 months ago" 2>/dev/null | sort | uniq -c | sort -rn | head -5 || true)
        if [ -n "$churn" ]; then
            local top_file
            top_file=$(echo "$churn" | head -1 | sed 's/^[[:space:]]*//' | sed 's/^[0-9]*[[:space:]]*//' | tr -d '\n')
            if [ -n "$top_file" ]; then
                issues="$issues
REQ-OPS-006: Git churn hotspots — top changed file is \`$top_file\` (run 'git log --name-only --since=6mo | sort | uniq -c | sort -rn | head -20' for full list)"
            fi
        fi
    fi

    echo "$issues" | sed '/^$/d' | sort -u
}

# ── Generator Functions ──────────────────────────────────────────────────────

generate_4_knowledge() {
    local framework="$1" language="$2" build_tool="$3" db="$4" arch="$5"
    local source_count="$6" test_count="$7" project_dir="$8"
    local modules mod_list deps_list build_cmds test_cmd skills
    modules=$(detect_modules "$project_dir")
    mod_list=""
    for m in $modules; do
        mod_list="$mod_list
- \`$m\`"
    done
    deps_list=""
    while IFS= read -r d; do
        [ -n "$d" ] && deps_list="$deps_list
- $d"
    done <<< "$(detect_dependencies "$project_dir")"
    build_cmds=$(detect_build_commands "$project_dir")
    test_cmd=$(detect_test_commands "$project_dir")
    skills=$(detect_skills "$project_dir" "$framework" "$language" "$db" "$build_tool")
    cat << KNOWLEDGE_EOF
<!-- Auto-generated by reverse-engineer.sh -->
# 4. Knowledge (Product Soul)

## Current Tech Stack

### Core Technologies
- **Framework:** $framework
- **Language:** $language
- **Build Tool:** $build_tool

### Detected Modules$mod_list

### Key Dependencies$deps_list

### Persistence
- **Database:** $db

### Architecture
$arch$(echo "$arch" | grep -q "layers" && echo "

### Layer Organization
The project follows a layered architecture. Each module should organize code into:
- \`domain/\` — business logic, entities, value objects (no framework imports)
- \`app/\` — application services, use cases, port implementations
- \`infra/\` — framework code, persistence, web controllers
- \`api/ports/\` — inbound/outbound port interfaces
- \`config/\` — configuration classes")

### Project Stats
- Source files: $source_count
- Test files: $test_count

## Build & Test

### Build
\`\`\`
$build_cmds
\`\`\`

### Test
\`\`\`
$test_cmd
\`\`\`

## Load These Skills

$skills

## Never DO List

### Architecture
- **Domain layer MUST be framework-free** — no $framework annotations in \`domain/\`
- **App layer** depends on port interfaces, not concrete infra classes
- **Infra layer** contains all framework code, controllers, persistence
- **No circular dependencies** between modules

### Naming
- Use intention-revealing names — no abbreviations
- Package structure mirrors domain concepts
- Test classes: \`FooTest\` tests \`Foo\`
KNOWLEDGE_EOF
}

generate_5_decisions() {
    local framework="$1" db="$2" arch="$3" project_dir="$4" build_tool="$5" language="$6"
    local modules mod_list deps_list layer_info
    modules=$(detect_modules "$project_dir")
    mod_list=""
    for m in $modules; do
        mod_list="$mod_list
- \`$m\`"
    done
    deps_list=""
    while IFS= read -r d; do
        [ -n "$d" ] && deps_list="$deps_list
- $d"
    done <<< "$(detect_dependencies "$project_dir")"
    layer_info=""
    if echo "$arch" | grep -q "layers"; then
        layer_info="
- D4: Module organization — $(echo "$modules" | wc -w | tr -d ' ') modules
- D5: Dependency injection — via framework DI in app layer"
    fi
    cat << DECISIONS_EOF
<!-- Auto-generated by reverse-engineer.sh -->
# 5. Decision Log

## Decision Index
- D1: Framework — $framework
- D2: Database — $db
- D3: Architecture — $arch$layer_info

---

## Decision 1: Framework — $framework
**Context:** The project is built with $framework.
**Decision:** Continue using $framework.
**Why:** Established codebase, team familiarity, ecosystem support.
**Skills:** Load \`backbone/skills/springboot/\` skills for framework conventions.

## Decision 2: Database — $db
**Context:** Detected $db as the persistence store.
**Decision:** Keep $db as the primary datastore.
**Why:** Existing schema, migrations, queries, and operational experience.

## Decision 3: Architecture — $arch
**Context:** The project follows $arch.
**Decision:** Maintain this architectural pattern.
**Why:** Code organization, layer separation, and dependency rules depend on it.
$(if echo "$arch" | grep -q "layers"; then echo "
## Decision 4: Module Organization
**Context:** The project contains the following modules:$mod_list
**Decision:** Use module boundaries as service/domain boundaries.
**Why:** Modules encapsulate subdomains with explicit dependencies, preventing leaky abstractions across domains.

## Decision 5: Dependency Injection
**Context:** Detected $framework DI annotations in \`app/\` and \`infra/\` layers.
**Decision:** Use constructor injection via $framework DI.
**Why:** Constructor injection provides immutable dependencies, clear testability, and explicit required dependencies."; fi)
$(if [ -n "$deps_list" ]; then echo "
## Decision 6: Build Dependencies
**Context:** Key dependencies detected in build files:$deps_list
**Decision:** Manage dependencies through $build_tool.
**Why:** Standardized dependency management with version control."; fi)
DECISIONS_EOF
}

generate_6_memory() {
    local language="$1" framework="$2" build_tool="$3" arch="$4" project_dir="$5" db="$6"
    local test_cmd
    test_cmd=$(detect_test_commands "$project_dir")
    cat << MEMORY_EOF
<!-- Auto-generated by reverse-engineer.sh -->
# 6. Long-Term Memory

## Patterns That Worked

### Architecture
- **$(echo "$arch" | sed 's/(.*//') architecture:** Modules follow the $(echo "$framework" | sed 's/ .*//') conventions with clear separation of concerns
- **Port/adapter pattern:** Interfaces in \`api/ports/\`, implementations in \`app/\`, framework code in \`infra/\`

### Testing
- **Test framework:** Detected test files — run with \`$test_cmd\`
- **Test naming:** Test classes follow \`*Test.java\` / \`*Spec.java\` convention
- **Test structure:** AAA pattern (Arrange-Act-Assert) for clarity

### Code Organization
- **Package structure:** Reflects domain concepts, not technical layers
- **Naming conventions:** Java/Kotlin standard conventions (camelCase, PascalCase)

## Lessons Learned & Traps to Avoid

### Architecture
- **Domain purity:** Keep \`domain/\` packages free of framework imports — most common regression during refactoring
- **Port discipline:** App layer depends on \`api/ports/\` interfaces, not \`infra/\` implementations
- **Circular deps:** Watch cross-module imports — each module is a one-way dependency

### Build & Test
- **Build consistency:** Run \`$build_tool build\` before every commit
- **Test coverage:** Test count should scale with source count
- **Skill-driven development:** Load framework skills before implementing features (see \`backbone/4-KNOWLEDGE.md\` → Load These Skills)

MEMORY_EOF
}

generate_c4_context() {
    local project_name="$1"
    cat << C4_EOF
## C4 Model (reverse-engineered)

### Context (Level 1)

\`\`\`mermaid
flowchart LR
  User[User] -->|uses| System[$project_name]
  System -->|depends on| DB[(Database)]
  System -->|integrates with| ExternalAPIs[External APIs]
\`\`\`

\`\`\`
[User] ──→ [$project_name]
[$project_name] ──→ [(Database)]
[$project_name] ──→ [External APIs]
\`\`\`

### Container (Level 2)

\`\`\`mermaid
flowchart LR
  Web[Web Application] -->|HTTP| API[API Layer]
  API -->|queries| DB[(Database)]
  API -->|calls| Workers[Background Workers]
\`\`\`

\`\`\`
[Web Application] ──HTTP──→ [API Layer]
[API Layer] ────→ [(Database)]
[API Layer] ────→ [Background Workers]
\`\`\`
C4_EOF
}

# ── Enhanced Analysis Functions ──────────────────────────────────────────────

# Scan for API route annotations (single-pass grep)
detect_api_routes() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    [ -z "$src_dirs" ] && return
    for sd in $src_dirs; do
        grep -rn '@\(Request\|Get\|Post\|Put\|Delete\|Patch\)Mapping\|@Path\b' "$sd" --include="*.java" --include="*.kt" 2>/dev/null | grep -v "import\|test\|Test" | head -20 | while IFS=: read -r file line rest; do
            local rel_file method path
            rel_file=$(echo "$file" | sed "s|$dir/||")
            method=$(echo "$rest" | grep -oE '@(Request|Get|Post|Put|Delete|Patch)Mapping' | head -1 | sed 's/@//;s/Mapping//')
            path=$(echo "$rest" | grep -oE '"[^"]*"' | head -1 | tr -d '"')
            [ -z "$method" ] && method="REQUEST"
            echo "- \`$method\` \`$path\` — $rel_file"
        done || true
    done | sort -u | head -20
}

# Scan for JPA entities
detect_entities() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    [ -z "$src_dirs" ] && return
    for sd in $src_dirs; do
        local entities
        entities=$(grep -rn '@Entity\|@Document\|@MappedSuperclass' "$sd" --include="*.java" 2>/dev/null | grep -v "import" | head -15 || true)
        [ -z "$entities" ] && continue
        while IFS= read -r line; do
            local file entity table
            file=$(echo "$line" | cut -d: -f1 | sed "s|$dir/||" | sed 's|/src/main/java/.*||')
            entity=$(echo "$line" | grep -oE 'class [A-Za-z]+' | head -1 | sed 's/class //')
            table=$(grep -rn '@Table.*name\s*=' "$(echo "$line" | cut -d: -f1)" 2>/dev/null | grep -oE 'name\s*=\s*"[^"]*"' | head -1 | sed 's/name\s*=\s*"//;s/"//')
            [ -z "$entity" ] && continue
            local suffix=""
            [ -n "$table" ] && suffix=" → table: \`$table\`"
            echo "- \`$entity\`$suffix — $file"
        done <<< "$entities"
    done | sort -u | head -15
}

# Find configuration files
detect_config_inventory() {
    local dir="$1"
    for pattern in "application.yml" "application.yaml" "application.properties" "application-*.yml" ".env" ".env.example" ".env.sample" "docker-compose.yml" "Dockerfile"; do
        local hits
        hits=$(find "$dir" -maxdepth 3 -name "$pattern" -not -path "*/.git/*" -not -path "*/docs/*" -not -path "*/templates/*" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/build/*" 2>/dev/null | head -5)
        [ -z "$hits" ] && continue
        while IFS= read -r f; do
            echo "- \`$(echo "$f" | sed "s|$dir/||")\`"
        done <<< "$hits"
    done | sort -u
}

# Find CI/CD configurations
detect_ci_cd() {
    local dir="$1"
    if [ -d "$dir/.github/workflows" ]; then
        for f in "$dir/.github/workflows"/*.yml; do
            [ -f "$f" ] && echo "- GitHub Actions: \`.github/workflows/$(basename "$f")\`"
        done
    fi
    [ -f "$dir/Jenkinsfile" ] && echo "- Jenkins: \`Jenkinsfile\`"
    [ -f "$dir/.gitlab-ci.yml" ] && echo "- GitLab CI: \`.gitlab-ci.yml\`"
    [ -f "$dir/.circleci/config.yml" ] && echo "- CircleCI: \`.circleci/config.yml\`"
    if ls "$dir/Dockerfile"* 2>/dev/null | grep -q .; then
        for f in "$dir/Dockerfile"*; do
            [ -f "$f" ] && echo "- Docker: \`$(basename "$f")\`"
        done
    fi
}

# ── Architecture Map Generator ───────────────────────────────────────────────

generate_architecture_map() {
    local dir="$1"
    local src_dirs
    src_dirs=$(find_source_dirs "$dir")
    local framework language build_tool db arch
    framework=$(detect_framework "$dir")
    language=$(detect_language "$dir")
    build_tool=$(detect_build_tool "$dir")
    db=$(detect_db "$dir")
    arch=$(detect_architecture "$dir")
    local project_name
    project_name=$(basename "$(cd "$dir" && pwd)")

    cat << MAP_HEADER
# Architecture Map — $project_name

**Auto-generated scaffold by reverse-engineer.sh**
> This is a structural scaffold. For the full architecture map with dependency flows,
> layer analysis, port/adapter mapping, and patterns, run the agent-driven
> \`/backbone:map --reverse --deep-arch\` command which replaces this file.

---

## Detected

| Property | Value |
|----------|-------|
| Framework | $framework |
| Language | $language |
| Build tool | $build_tool |
| Database | $db |
| Architecture | $arch |

MAP_HEADER

    echo ""
    echo "## Source Directories"
    echo ""
    for sd in $src_dirs; do
        local pkg_name
        pkg_name=$(echo "$sd" | sed "s|$dir/||" | sed 's|src/main/java/||' | sed 's|src/||')
        echo "- \`$pkg_name\`"
    done
    if [ -z "$(echo "$src_dirs" | tr -d ' ')" ]; then
        echo "- (No source directories found)"
    fi

    echo ""
    echo "---"
    echo ""
    echo "*To generate a complete architecture map with subdomain dependencies, layer"
    echo "analysis, port/adapter mapping, and architectural patterns, run:*"
    echo ""
    echo "\`\`\`"
    echo "/backbone:map --reverse --deep-arch"
    echo "\`\`\`"

    # Enhanced analysis sections
    local routes entities configs ci
    routes=$(detect_api_routes "$dir")
    entities=$(detect_entities "$dir")
    configs=$(detect_config_inventory "$dir")
    ci=$(detect_ci_cd "$dir")

    if [ -n "$routes" ]; then
        echo ""
        echo "## API Routes"
        echo "$routes"
    fi

    if [ -n "$entities" ]; then
        echo ""
        echo "## Data Entities"
        echo "$entities"
    fi

    if [ -n "$configs" ]; then
        echo ""
        echo "## Configuration Files"
        echo "$configs"
    fi

    if [ -n "$ci" ]; then
        echo ""
        echo "## CI/CD"
        echo "$ci"
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"

    if [ ! -d "$PROJECT_DIR/backbone" ]; then
        echo -e "${RED}❌ No backbone/ directory found in $PROJECT_DIR${NC}" >&2
        echo -e "${YELLOW}Run init-backbone.sh first, then reverse-engineer.${NC}" >&2
        exit 1
    fi

    echo -e "${CYAN}🔍 Reverse-engineering project: $PROJECT_DIR${NC}"
    echo ""

    # Detect
    local framework
    framework=$(detect_framework "$PROJECT_DIR")
    local language
    language=$(detect_language "$PROJECT_DIR")
    local build_tool
    build_tool=$(detect_build_tool "$PROJECT_DIR")
    local db
    db=$(detect_db "$PROJECT_DIR")
    local arch
    arch=$(detect_architecture "$PROJECT_DIR")
    local source_count
    source_count=$(count_source_files "$PROJECT_DIR")
    local test_count
    test_count=$(count_test_files "$PROJECT_DIR")

    echo -e "  ${CYAN}Framework:${NC}   $framework"
    echo -e "  ${CYAN}Language:${NC}    $language"
    echo -e "  ${CYAN}Build:${NC}       $build_tool"
    echo -e "  ${CYAN}Database:${NC}    $db"
    echo -e "  ${CYAN}Architecture:${NC} $arch"
    echo -e "  ${CYAN}Source files:${NC} $source_count"
    echo -e "  ${CYAN}Test files:${NC}  $test_count"
    echo ""

    # Generate → CHNG folder
    local project_name
    project_name=$(basename "$(cd "$PROJECT_DIR" && pwd)")
    local date_str
    date_str=$(date +%Y-%m-%d)
    local chng_dir

    if [ -n "$OUTPUT_DIR" ]; then
        chng_dir="$OUTPUT_DIR"
    else
        chng_dir="$PROJECT_DIR/backbone/artifacts/changes/CHNG-001-reverse-engineer-$date_str"
    fi

    mkdir -p "$chng_dir/generated"

    # Detect architecture issues
    local issues
    issues=$(detect_issues "$PROJECT_DIR")

    # Write proposal with concrete requirements
    {
        echo "# CHNG-001: Reverse-Engineer $project_name"
        echo ""
        echo "**What:** Initial project analysis and backbone bootstrapping for $project_name."
        echo "Auto-generated by reverse-engineer.sh on $date_str."
        echo ""
        echo "**Summary**"
        echo "- Framework: $framework | Language: $language | Build: $build_tool"
        echo "- Database: $db | Architecture: $arch"
        echo "- $source_count source files, $test_count test files"
        echo ""
        echo "**Detected Issues:**"
        local issue_count=0
        while IFS= read -r iss; do
            [ -z "$iss" ] && continue
            echo "- $iss"
            issue_count=$((issue_count + 1))
        done <<< "$issues"
        [ "$issue_count" -eq 0 ] && echo "- None — project appears well-structured"
        echo ""
        echo "## Requirements"
        echo ""
        echo "- **REQ-BOOTSTRAP-001** The project shall adopt backbone workflow for feature development."
        echo "- **REQ-BOOTSTRAP-002** All existing source files shall be preserved as-is."
        echo "- **REQ-BOOTSTRAP-003** Team shall review and approve the generated metadata before use."
        while IFS= read -r iss; do
            [ -z "$iss" ] && continue
            local req_id req_desc
            req_id=$(echo "$iss" | grep -oE 'REQ-[A-Z0-9]+-[0-9]+')
            req_desc=$(echo "$iss" | sed 's/REQ-[A-Z0-9]*-[0-9]*: //')
            echo "- **$req_id** $req_desc"
        done <<< "$issues"
    } > "$chng_dir/proposal.md"

    # Write design with C4
    {
        echo "# CHNG-001: Design — $project_name"
        echo ""
        echo "## Decisions"
        echo ""
        echo "**D1:** Use reverse-engineered metadata as baseline."
        echo "**D2:** Framework detected: $framework."
        echo "**D3:** Address architecture issues identified during reverse-engineering."
        echo ""
    } > "$chng_dir/design.md"

    generate_c4_context "$project_name" >> "$chng_dir/design.md"
    generate_architecture_map "$PROJECT_DIR" > "$chng_dir/architecture-map.md" || true

    # Write tasks from detected issues
    {
        echo "# CHNG-001: Tasks"
        echo ""
        echo "## Bootstrap"
        echo ""
        echo "### [ ] Review and approve generated backbone metadata"
        echo "**Parent:** REQ-BOOTSTRAP-002"
        echo ""
        echo "### [ ] Fill in missing project-specific details in 4-KNOWLEDGE.md"
        echo "**Parent:** REQ-BOOTSTRAP-003"
        echo ""
        echo "### [ ] Load framework skills and regenerate metadata via deep-arch agent"
        echo "**Parent:** REQ-BOOTSTRAP-003"
        echo '```'
        echo "/backbone:map --reverse --deep-arch --apply"
        echo '```'
        echo "This spawns a subagent that loads framework-specific skills and produces richer metadata."
        echo ""
        echo "## Architecture Improvements"
        echo ""
        local task_num=0
        while IFS= read -r iss; do
            [ -z "$iss" ] && continue
            local req_id req_desc
            req_id=$(echo "$iss" | grep -oE 'REQ-[A-Z0-9]+-[0-9]+')
            req_desc=$(echo "$iss" | sed 's/REQ-[A-Z0-9]*-[0-9]*: //')
            echo "### [ ] $req_desc"
            echo "**Parent:** $req_id"
            echo ""
            task_num=$((task_num + 1))
        done <<< "$issues"
        if [ "$task_num" -eq 0 ]; then
            echo "### [ ] Set up first feature using /backbone:design"
            echo "**Parent:** REQ-BOOTSTRAP-001"
            echo ""
        fi
    } > "$chng_dir/tasks.md"

    # Register QMS objectives for critical issues
    local qms_dir="$PROJECT_DIR/backbone/artifacts/qms/ncr"
    if [ -n "$(echo "$issues" | grep -E 'ARCH-002|OPS-001')" ]; then
        mkdir -p "$qms_dir"
        local ncr_num ncr_id
        ncr_num=$(ls "$qms_dir"/NCR-*.yml 2>/dev/null | wc -l | tr -d ' ')
        ncr_num=$((ncr_num + 1))
        while IFS= read -r iss; do
            [ -z "$iss" ] && continue
            case "$iss" in
                *"Framework annotations"*)
                    ncr_id=$(printf "NCR-%03d" $ncr_num)
                    local ncr_title
                    ncr_title=$(echo "$iss" | sed 's/REQ-[A-Z0-9]*-[0-9]*: //')
                    cat > "$qms_dir/$ncr_id.yml" << NCR_EOF
# Nonconformance Report — $ncr_id
# Created: $date_str

id: "$ncr_id"
date: "$date_str"
title: "$ncr_title"
severity: major
category: code
source: reverse-engineer
description: "Detected during reverse-engineering of $project_name: $(echo "$iss" | sed 's/REQ-[A-Z0-9]*-[0-9]*: //')"
status: open
change: CHNG-001
NCR_EOF
                    echo -e "  ${YELLOW}⚠ Registered NCR: $ncr_id — $ncr_title${NC}"
                    ncr_num=$((ncr_num + 1)) ;;
                *"No CI/CD"*)
                    ncr_id=$(printf "NCR-%03d" $ncr_num)
                    cat > "$qms_dir/$ncr_id.yml" << NCR_EOF_CI
# Nonconformance Report — $ncr_id
# Created: $date_str

id: "$ncr_id"
date: "$date_str"
title: "No CI/CD pipeline configured"
severity: minor
category: process
source: reverse-engineer
description: "Detected during reverse-engineering of $project_name: no CI/CD configuration found (GitHub Actions, Jenkins, GitLab CI, CircleCI). Automated builds and tests are not verified."
status: open
change: CHNG-001
NCR_EOF_CI
                    echo -e "  ${YELLOW}⚠ Registered NCR: $ncr_id — No CI/CD pipeline${NC}"
                    ncr_num=$((ncr_num + 1)) ;;
            esac
        done <<< "$issues"
    fi

    # Write generated metadata
    generate_4_knowledge "$framework" "$language" "$build_tool" "$db" "$arch" "$source_count" "$test_count" "$PROJECT_DIR" > "$chng_dir/generated/4-KNOWLEDGE.md"
    generate_5_decisions "$framework" "$db" "$arch" "$PROJECT_DIR" "$build_tool" "$language" > "$chng_dir/generated/5-DECISIONS.md"
    generate_6_memory "$language" "$framework" "$build_tool" "$arch" "$PROJECT_DIR" "$db" > "$chng_dir/generated/6-MEMORY.md"

    echo -e "${GREEN}✅ Generated:${NC}"
    echo -e "  ${CYAN}CHNG folder:${NC}    $chng_dir"
    echo -e "  ${CYAN}Proposal:${NC}       proposal.md"
    echo -e "  ${CYAN}Design:${NC}         design.md (C4 Context + Container)"
    echo -e "  ${CYAN}Architecture map:${NC} architecture-map.md"
    echo -e "  ${CYAN}Metadata drafts:${NC} generated/"
    echo -e "  ${YELLOW}  4-KNOWLEDGE.md:${NC} tech stack, constraints"
    echo -e "  ${YELLOW}  5-DECISIONS.md:${NC} architectural decisions (modules, DI, deps)"
    echo -e "  ${YELLOW}  6-MEMORY.md:${NC}    patterns and lessons"
    echo ""

    # --apply: write to live backbone files
    if [ "$APPLY" = true ]; then
        local bb="$PROJECT_DIR/backbone"
        cp "$chng_dir/generated/4-KNOWLEDGE.md" "$bb/4-KNOWLEDGE.md" 2>/dev/null && echo -e "${GREEN}  ✓ Applied: backbone/4-KNOWLEDGE.md${NC}" || echo -e "${YELLOW}  ⚠ Skipped: 4-KNOWLEDGE.md${NC}"
        cp "$chng_dir/generated/5-DECISIONS.md" "$bb/5-DECISIONS.md" 2>/dev/null && echo -e "${GREEN}  ✓ Applied: backbone/5-DECISIONS.md${NC}" || echo -e "${YELLOW}  ⚠ Skipped: 5-DECISIONS.md${NC}"
        cp "$chng_dir/generated/6-MEMORY.md" "$bb/6-MEMORY.md" 2>/dev/null && echo -e "${GREEN}  ✓ Applied: backbone/6-MEMORY.md${NC}" || echo -e "${YELLOW}  ⚠ Skipped: 6-MEMORY.md${NC}"
        echo ""
        echo -e "${GREEN}✅ Applied metadata to backbone/ files.${NC}"
        echo -e "${YELLOW}  Review and customize before using in workflows.${NC}"
    fi
}

main "$@"
