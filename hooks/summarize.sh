#!/bin/bash
# summarize.sh - Progressive Memory turn summarizer
# https://github.com/irl-dan/progressive-memory
#
# Extracts meaningful conversation content from Claude Code transcript,
# summarizes the latest turn using haiku, and writes to session memory.

set -e

# Input from hook
TRANSCRIPT_PATH="$1"
SESSION_ID="$2"
MEMORY_DIR="${3:-.memory}"

if [ -z "$TRANSCRIPT_PATH" ] || [ -z "$SESSION_ID" ]; then
    echo "Usage: summarize.sh <transcript_path> <session_id> [memory_dir]" >&2
    exit 1
fi

if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "Transcript not found: $TRANSCRIPT_PATH" >&2
    exit 1
fi

SESSION_DIR="$MEMORY_DIR/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

# Count existing entries to determine turn number
TURN_NUM=$(ls "$SESSION_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
TURN_NUM=$((TURN_NUM + 1))
TURN_FILE="$SESSION_DIR/$(printf '%03d' $TURN_NUM).md"

# Extract conversation content including thinking and tool use
# Skip: file-history-snapshot, tool_result content (too large)
CLEAN_CONTENT=$(cat "$TRANSCRIPT_PATH" | jq -r '
  if .type == "user" and (.message.content | type) == "string" then
    "USER: " + .message.content
  elif .type == "assistant" and (.message.content | type) == "array" then
    [.message.content[] |
      if .type == "text" then
        "ASSISTANT: " + .text
      elif .type == "thinking" then
        "THINKING: " + (.thinking | .[0:500])
      elif .type == "tool_use" then
        "TOOL: " + .name + " - " + (.input | tostring | .[0:100])
      else
        empty
      end
    ] | join("\n")
  else
    empty
  end
' 2>/dev/null | grep -v '^$')

if [ -z "$CLEAN_CONTENT" ]; then
    echo "No content to summarize" >&2
    exit 0
fi

# Get the last N entries for context (last ~10 exchanges)
CONTEXT_LINES=20
RECENT_CONTENT=$(echo "$CLEAN_CONTENT" | tail -$CONTEXT_LINES)

# Step 1: Summarize into a paragraph
PARAGRAPH=$(echo "$RECENT_CONTENT" | claude --model haiku -p "Summarize this conversation excerpt into a single paragraph (3-5 sentences). Focus on what was discussed, decisions made, and outcomes. Be concise.

Conversation:
" 2>/dev/null || echo "Summary generation failed")

if [ "$PARAGRAPH" = "Summary generation failed" ]; then
    echo "Failed to generate paragraph summary" >&2
    exit 1
fi

# Step 2: Summarize paragraph into one-liner
ONE_LINER=$(echo "$PARAGRAPH" | claude --model haiku -p "Summarize this paragraph into a single sentence (under 100 characters). Capture the main point.

Paragraph:
" 2>/dev/null || echo "Turn $TURN_NUM summary")

# Step 3: Get recent content for "full detail" section
# Last few meaningful exchanges (truncated for readability)
FULL_DETAIL=$(echo "$RECENT_CONTENT" | tail -10)

# Write in progressive-memory format
cat > "$TURN_FILE" << EOF
$ONE_LINER

$PARAGRAPH

---

## Turn $TURN_NUM - Full Detail

\`\`\`
$FULL_DETAIL
\`\`\`

## Provenance

progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
EOF

echo "Wrote: $TURN_FILE"
