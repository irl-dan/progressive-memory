#!/bin/bash
# capture-turn.sh - Progressive Memory turn capture
# https://github.com/irl-dan/progressive-memory
#
# Captures session turn to memory after each assistant response.
# Fires on the "Stop" hook event.

set -e

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

if [ -z "$SESSION_ID" ] || [ -z "$TRANSCRIPT_PATH" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

MEMORY_DIR="${CLAUDE_PROJECT_DIR:-.}/.memory"
SESSION_DIR="$MEMORY_DIR/sessions/$SESSION_ID"

if [ ! -d "$MEMORY_DIR" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

mkdir -p "$SESSION_DIR"

EXISTING=$(ls "$SESSION_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
NEXT_SEQ=$(printf "%03d" $((EXISTING + 1)))

if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

TRANSCRIPT_LINES=$(wc -l < "$TRANSCRIPT_PATH" | tr -d ' ')

MARKER_FILE="$SESSION_DIR/.last_line"
LAST_LINE=0
if [ -f "$MARKER_FILE" ]; then
    LAST_LINE=$(cat "$MARKER_FILE")
fi

if [ "$TRANSCRIPT_LINES" -le "$LAST_LINE" ]; then
    echo '{"decision": "continue"}'
    exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_SHORT=$(date +"%Y-%m-%d %H:%M")

cat > "$SESSION_DIR/$NEXT_SEQ.md" << EOF
Turn $NEXT_SEQ captured at $DATE_SHORT - pending summarization.

Automatically captured by progressive-memory. Run summarization
to generate proper one-liner and expanded summary.
Transcript lines: $((LAST_LINE + 1))-$TRANSCRIPT_LINES

---

## Capture Info

- **Session**: $SESSION_ID
- **Timestamp**: $TIMESTAMP
- **Transcript**: $TRANSCRIPT_PATH
- **Lines**: $((LAST_LINE + 1)) to $TRANSCRIPT_LINES

## Provenance

progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
https://x.com/irl_danB
EOF

echo "$TRANSCRIPT_LINES" > "$MARKER_FILE"

echo '{"decision": "continue"}'
