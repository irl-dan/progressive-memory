#!/bin/bash
# pre-compact.sh - Progressive Memory pre-compaction capture
# https://github.com/irl-dan/progressive-memory
#
# Captures memory snapshot before context compaction.
# Last chance to preserve context before history is compressed.

set -e

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')

if [ -z "$SESSION_ID" ]; then
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

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DATE_SHORT=$(date +"%Y-%m-%d %H:%M")

cat > "$SESSION_DIR/compaction-$TIMESTAMP.md" << EOF
Context compaction at $DATE_SHORT ($TRIGGER) - review turns before this point.

Automatic compaction event. Ensure important context was preserved
in project or user memory before this point.

---

## Compaction Event

- **Session**: $SESSION_ID
- **Timestamp**: $TIMESTAMP
- **Trigger**: $TRIGGER

## Action Items

1. Review turns captured before this compaction
2. Ensure key decisions are in project or user memory
3. Update scratch.md if task context was lost

## Provenance

progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
https://x.com/irl_danB
EOF

echo '{"decision": "continue"}'
