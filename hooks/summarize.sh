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

# Extract conversation content with clear turn delineation
# Group: USER messages separate, ASSISTANT = thinking + tools + response together
CLEAN_CONTENT=$(cat "$TRANSCRIPT_PATH" | jq -r '
  if .type == "user" and (.message.content | type) == "string" then
    "\n>>> USER\n" + .message.content
  elif .type == "assistant" and (.message.content | type) == "array" then
    [.message.content[] |
      if .type == "text" then
        "[response] " + .text
      elif .type == "thinking" then
        "[thinking] " + .thinking
      elif .type == "tool_use" then
        "[tool] " + .name + ": " + (.input | tostring | .[0:500])
      else
        empty
      end
    ] | join("\n") | if . != "" then "\n>>> ASSISTANT\n" + . else empty end
  else
    empty
  end
' 2>/dev/null | grep -v '^$')

if [ -z "$CLEAN_CONTENT" ]; then
    echo "No content to summarize" >&2
    exit 0
fi

# Get recent content - last few complete exchanges
# Using line count as rough proxy; >>> markers help identify turn boundaries
CONTEXT_LINES=50
RECENT_CONTENT=$(echo "$CLEAN_CONTENT" | tail -$CONTEXT_LINES)

# Get existing session summaries for context
EXISTING_SUMMARIES=""
if [ -d "$SESSION_DIR" ]; then
    EXISTING_SUMMARIES=$(head -1 "$SESSION_DIR"/*.md 2>/dev/null | grep -v "^==>" | tail -5)
fi

# Step 1: Summarize into a paragraph
PARAGRAPH=$(claude --model haiku -p "You are a memory system recording turn $TURN_NUM of an ongoing agent session.

CRITICAL RULES:
- Output ONLY the summary, nothing else
- Write in DIRECT ACTIVE VOICE: 'Updated X', 'Fixed Y', 'Decided Z'
- WRONG: 'A discussion was conducted about...' or 'The user and assistant explored...'
- RIGHT: 'Updated summarize.sh to add context parameters. Fixed the prompt to avoid conversational output.'
- Be specific: actual file names, function names, technical decisions
- This is a LOG ENTRY, not commentary about a conversation

Previous turns (for context):
$EXISTING_SUMMARIES

Current turn to synthesize:
$RECENT_CONTENT

Write 3-5 sentences directly stating what happened, what changed, what was decided. Active voice only." 2>/dev/null || echo "Summary generation failed")

if [ "$PARAGRAPH" = "Summary generation failed" ]; then
    echo "Failed to generate paragraph summary" >&2
    exit 1
fi

# Step 2: Summarize paragraph into one-liner (can be 1-3 sentences, must be single line)
ONE_LINER=$(claude --model haiku -p "Condense this into 1-3 short sentences on a SINGLE LINE (no line breaks).

RULES:
- Output ONLY the condensed text, nothing else
- Keep specific details: file names, function names, technical terms
- Active voice: 'Updated X', 'Fixed Y', 'Added Z'
- NO line breaks - everything on one line
- Aim for ~150 characters but can be up to 250 if needed for specificity

Paragraph:
$PARAGRAPH" 2>/dev/null || echo "Turn $TURN_NUM summary")

# Step 3: Get recent content for "full detail" section
# Escape backticks to prevent breaking markdown
FULL_DETAIL=$(echo "$RECENT_CONTENT" | sed 's/```/~~~~/g')

# Write in progressive-memory format (use ~~~~ as code fence to avoid conflicts)
cat > "$TURN_FILE" << EOF
$ONE_LINER

$PARAGRAPH

---

$FULL_DETAIL

## Provenance

progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
EOF

echo "Wrote: $TURN_FILE"
