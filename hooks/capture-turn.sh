#!/bin/bash
# capture-turn.sh - Progressive Memory turn capture
# https://github.com/irl-dan/progressive-memory
#
# Captures and summarizes session turn after each assistant response.
# Fires on the "Stop" hook event.
# Spawns summarizer in background to avoid blocking.

set -e

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

MEMORY_DIR="${CLAUDE_PROJECT_DIR:-.}/.memory"

if [ ! -d "$MEMORY_DIR" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

# Get the directory where this hook lives
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
SUMMARIZE_SCRIPT="$HOOK_DIR/summarize.sh"

if [ -x "$SUMMARIZE_SCRIPT" ]; then
    # Run summarizer in background to avoid blocking
    nohup "$SUMMARIZE_SCRIPT" "$TRANSCRIPT_PATH" "$SESSION_ID" "$MEMORY_DIR" \
        >> "$MEMORY_DIR/summarize.log" 2>&1 &
fi

echo '{"decision": "continue"}'
