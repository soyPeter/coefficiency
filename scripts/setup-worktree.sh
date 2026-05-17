#!/bin/bash
# scripts/setup-worktree.sh — Runs after Worktrunk creates a new worktree
# https://worktrunk.dev/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

PROJECT_NAME="coefficiency"

echo "🔧 Worktree setup for $PROJECT_NAME"

# Install dev portal dependencies if present
if [ -d "dev-portal" ] && [ -f "dev-portal/package.json" ]; then
    echo "  → Installing dev portal dependencies..."
    cd dev-portal && npm install && cd ..
fi

# Build Gradle project if present
if [ -f "gradlew" ]; then
    echo "  → Building Gradle project..."
    ./gradlew build -x test || true
fi

# Install root Node dependencies if present (and not dev-portal)
if [ -f "package.json" ] && [ ! -d "dev-portal" ]; then
    echo "  → Installing Node dependencies..."
    npm install
fi

# Start dev portal in background if present (optional)
if [ -d "dev-portal" ] && [ -f "dev-portal/start.sh" ]; then
    echo ""
    echo "💡 To start the dev portal:"
    echo "   cd dev-portal && npm start"
    echo ""
    echo "   The portal will auto-detect an available port."
fi

echo "✅ Worktree ready for $PROJECT_NAME"
