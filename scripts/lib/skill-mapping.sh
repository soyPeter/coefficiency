#!/bin/bash
# =============================================================================
# scripts/lib/skill-mapping.sh — Maps file paths to required skills
#
# Usage:
#   source "$(dirname "$0")/../lib/skill-mapping.sh"
#   get_required_skills_for_file "src/main/java/io/example/domain/User.java"
#   # outputs: java/java-core
#
#   get_required_skills_for_files "$STAGED_FILES"
#   # outputs: java/java-core java/java-cdi quarkus/java-quarkus
# =============================================================================

# ── Skill Mapping Rules ─────────────────────────────────────────────────────
# Each rule: pattern → space-separated skill names
# Patterns are matched with case statement (first match wins)

get_skill_for_file() {
    local file="$1"
    local framework="${FRAMEWORK:-}"
    
    # Detect framework from 4-KNOWLEDGE.md if not set
    if [ -z "$framework" ] && [ -f "backbone/4-KNOWLEDGE.md" ]; then
        framework=$(grep -oE 'quarkus|springboot|laravel|kotlin|golang|python' backbone/4-KNOWLEDGE.md | head -1 || true)
    fi
    
    case "$file" in
        # Domain layer — entities, value objects, domain services
        */domain/*|*/model/*|*/entity/*|*/vo/*|*/valueobject/*)
            echo "java/java-core"
            return 0
            ;;
        
        # Application layer — use cases, app services, DTOs
        */app/*|*/application/*|*/usecase/*|*/service/*|*/dto/*|*/mapper/*)
            case "$framework" in
                quarkus) echo "java/java-cdi" ;;
                springboot) echo "springboot/springboot-di" ;;
                *) echo "java/java-cdi" ;;
            esac
            return 0
            ;;
        
        # API/Infrastructure layer — controllers, resources, filters
        */api/*|*/infra/*|*/infrastructure/*|*/controller/*|*/resource/*|*/filter/*|*/endpoint/*|*/rest/*|*/web/*)
            case "$framework" in
                quarkus) echo "quarkus/java-quarkus" ;;
                springboot) echo "springboot/springboot-patterns" ;;
                laravel) echo "laravel/laravel-patterns" ;;
                *) echo "quarkus/java-quarkus" ;;
            esac
            return 0
            ;;
        
        # Tests
        */test/*|*/tests/*|*Test.java|*Test.kt|*_test.go|test_*.py)
            echo "cross-cutting/testing/test-quality"
            return 0
            ;;
        
        # PRDs
        backbone/prd/*)
            echo "general/create-prd"
            return 0
            ;;
        
        # Design docs
        backbone/design/*)
            echo "general/design-document"
            return 0
            ;;
        
        # Planning docs
        backbone/planning/*)
            echo "general/planning-and-task-breakdown"
            return 0
            ;;
        
        # Build files
        pom.xml|build.gradle*|*.gradle)
            echo "build-gradle"
            return 0
            ;;
        
        # Docker / K8s
        Dockerfile*|docker-compose*|*.yml|*.yaml)
            echo "cross-cutting/docker/docker-patterns"
            return 0
            ;;
        
        # Default: no specific skill required
        *)
            return 0
            ;;
    esac
}

# Get all unique required skills for a list of files
get_required_skills_for_files() {
    local files="$1"
    local all_skills=""
    
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local skill
        skill=$(get_skill_for_file "$file")
        if [ -n "$skill" ]; then
            all_skills="$all_skills $skill"
        fi
    done <<< "$files"
    
    # Deduplicate and sort
    echo "$all_skills" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ' | sed 's/ $//' || true
}

# Check if a skill is acknowledged
# Looks in: .backbone/session/skills.json OR commit message
is_skill_acknowledged() {
    local skill="$1"
    local commit_msg="${2:-}"
    local session_file=".backbone/session/skills.json"
    
    # Check session file
    if [ -f "$session_file" ]; then
        if grep -q "\"$skill\"" "$session_file" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Check commit message for Skills: line
    if [ -n "$commit_msg" ]; then
        local skills_line
        skills_line=$(echo "$commit_msg" | grep -iE '^Skills:' | head -1 || true)
        if [ -n "$skills_line" ]; then
            # Extract skill short names from line
            local short_name
            short_name=$(echo "$skill" | sed 's|.*/||')
            if echo "$skills_line" | grep -qi "$short_name"; then
                return 0
            fi
        fi
    fi
    
    return 1
}
