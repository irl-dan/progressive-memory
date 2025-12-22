#!/bin/bash
# init.sh - Progressive Memory initialization
# https://github.com/irl-dan/progressive-memory
#
# Idempotent setup: creates .memory structure and checks hook configuration.
# Safe to run multiple times.

set -e

MEMORY_DIR="${CLAUDE_PROJECT_DIR:-.}/.memory"
SKILL_DIR="$(dirname "$0")/.."
HOOKS_SOURCE="$(dirname "$0")/../../hooks"

# Create directory structure
mkdir -p "$MEMORY_DIR/sessions"
mkdir -p "$MEMORY_DIR/project"
mkdir -p "$MEMORY_DIR/user/$USER"

# Create index.md if missing
if [ ! -f "$MEMORY_DIR/index.md" ]; then
    PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
    cat > "$MEMORY_DIR/index.md" << EOF
$PROJECT_NAME: Project memory initialized.

Progressive Memory enabled. Use this index to navigate memory domains.

---

## Current Focus
→ scratch.md - Current task context

## Project Memory
→ project/ - Architecture, decisions, background context

## User Memory
→ user/$USER/ - Your decisions and preferences

## Sessions
→ sessions/ - Per-turn conversation history
EOF
    echo "✓ Created $MEMORY_DIR/index.md"
fi

# Create scratch.md if missing
if [ ! -f "$MEMORY_DIR/scratch.md" ]; then
    cat > "$MEMORY_DIR/scratch.md" << 'EOF'
No active task.

---

Update this file when starting work on a task.
Clear when switching to a different task.
EOF
    echo "✓ Created $MEMORY_DIR/scratch.md"
fi

# Copy hooks if missing
if [ ! -d "$MEMORY_DIR/hooks" ]; then
    if [ -d "$HOOKS_SOURCE" ]; then
        cp -r "$HOOKS_SOURCE" "$MEMORY_DIR/hooks"
        chmod +x "$MEMORY_DIR/hooks"/*.sh
        echo "✓ Copied hooks to $MEMORY_DIR/hooks/"
    fi
fi

# Check if hooks are configured
SETTINGS_FILE=".claude/settings.local.json"
HOOKS_CONFIGURED=false

if [ -f "$SETTINGS_FILE" ] && grep -q "capture-turn" "$SETTINGS_FILE" 2>/dev/null; then
    HOOKS_CONFIGURED=true
fi

echo ""
if [ "$HOOKS_CONFIGURED" = true ]; then
    echo "✓ Progressive Memory initialized and hooks configured"
    echo ""
    echo "Memory structure:"
    echo "  $MEMORY_DIR/index.md      - Overview and navigation"
    echo "  $MEMORY_DIR/scratch.md    - Current task context"
    echo "  $MEMORY_DIR/sessions/     - Per-turn history"
    echo "  $MEMORY_DIR/project/      - Project knowledge"
    echo "  $MEMORY_DIR/user/$USER/   - Your preferences"
else
    echo "⚠ Progressive Memory initialized, but hooks not configured."
    echo ""
    echo "To enable automatic turn capture, add this to $SETTINGS_FILE:"
    echo ""
    cat << 'SNIPPET'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ".memory/hooks/capture-turn.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ".memory/hooks/pre-compact.sh"
          }
        ]
      }
    ]
  }
}
SNIPPET
    echo ""
    echo "Then restart Claude Code."
    echo ""
    echo "You can still use memory manually without hooks configured."
fi
