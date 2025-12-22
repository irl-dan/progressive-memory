---
name: progressive-memory
description: Filesystem-based memory using progressive disclosure. Use when you need to remember information across conversations, recall past decisions, understand project context, or capture user preferences. Trigger phrases include "remember this", "what did we decide", "check memory", "save to memory", "load context", "what happened last session", "user preferences", or any request involving persistent knowledge.
---

# Progressive Memory

Filesystem-based memory using progressive disclosure—the same pattern Claude Skills use for capabilities, applied to context management.

**Specification**: https://github.com/irl-dan/progressive-memory
**Author**: [@irl_danB](https://x.com/irl_danB)

## Core Concept

Every memory file has three levels of detail:

```
Line 1:     One-liner (~50 tokens)
Lines 2-10: Expanded summary (~150 tokens)
---
Below:      Full detail (unlimited)
```

Load what you need:

```bash
head -1 .memory/**/*.md                  # All one-liners
sed -n '1,/^---$/p' .memory/**/*.md      # All summaries
cat .memory/project/architecture.md       # Full detail
```

## Initialization

Before any memory operation, run initialization:

```bash
bash scripts/init.sh
```

This script is idempotent (safe to run multiple times). It:
1. Creates the `.memory/` directory structure
2. Sets up index.md and scratch.md
3. Copies hooks to `.memory/hooks/`
4. Checks if hooks are configured

If hooks aren't configured, the script outputs a JSON snippet for the user
to add to `.claude/settings.local.json`. Relay this to the user if needed.

## Quick Start

After initialization, load context before starting work:

```bash
# Quick overview - all one-liners
head -1 .memory/**/*.md

# Current task
cat .memory/scratch.md

# Full index
cat .memory/index.md
```

## Memory Structure

```
.memory/
├── index.md              # Overview and navigation
├── sessions/             # What happened (per-session, per-turn)
│   └── <session-id>/
│       ├── 001.md        # Turn 1
│       ├── 002.md        # Turn 2
│       └── ...
├── project/              # Shared project knowledge
│   └── *.md
├── user/                 # User intentions (per-user)
│   └── $USER/
│       └── *.md
└── scratch.md            # Current task context
```

## File Format

Every file follows the progressive disclosure pattern:

```markdown
One-liner summary on the first line (~50 tokens).

Expanded summary with more context. Enough to decide if you
need the full details below. Include key facts, dates, and
decisions. Aim for 5-10 lines total.

---

## Full Content

All detailed information below the delimiter.
Unlimited length. Include history, examples, code.
```

## Reading Memory

**Before starting work**:
```bash
head -1 .memory/**/*.md      # Quick scan
cat .memory/scratch.md       # Current task
cat .memory/index.md         # Full overview
```

**When you need specific context**:
```bash
grep -ri "authentication" .memory/   # Search
cat .memory/project/architecture.md  # Load specific file
head -1 .memory/sessions/*/0*.md     # Recent session history
```

## Writing Memory

### Session Memory

Captures what happened each turn:

```bash
SESSION_DIR=".memory/sessions/$SESSION_ID"
mkdir -p "$SESSION_DIR"

NEXT=$(printf "%03d" $(($(ls "$SESSION_DIR"/*.md 2>/dev/null | wc -l) + 1)))

cat > "$SESSION_DIR/$NEXT.md" << 'EOF'
One-liner describing what happened this turn.

Expanded summary with more detail about the work done,
decisions made, and important context.

---

## Full Details

Complete information about this turn...
EOF
```

### Project Memory

Write when significant knowledge emerges that isn't obvious from code:

```bash
cat > .memory/project/architecture.md << 'EOF'
Microservices architecture with API gateway and three domain services.

Three services handle ingestion, processing, and delivery. Split from
monolith for independent scaling. PostgreSQL shared via namespacing.

---

## Services

[Full details...]
EOF
```

### User Memory

Capture explicit user statements with context:

```bash
mkdir -p ".memory/user/$USER"

cat >> ".memory/user/$USER/decisions.md" << 'EOF'

## 2024-12-21: WebSocket over SSE

**Context**: Implementing notification system
**User said**: "WebSocket - I want true real-time"
**Scope**: This notification system; may not apply elsewhere
EOF
```

**Important**: Never over-generalize user preferences. Always include context. A preference in one situation may not apply elsewhere.

### Scratch

Update with current task context:

```bash
cat > .memory/scratch.md << 'EOF'
Currently implementing WebSocket notification delivery.

Working on token refresh during handshake. Next: retry logic.

---

## Current Task
[Details...]

## Open Questions
[Questions...]
EOF
```

## Memory Domains

### Sessions

**Purpose**: Reconstruct what happened. Peer around compaction. Learn from past work.

**Structure**: One directory per session, one file per turn, sequence-numbered.

### Project

**Purpose**: Store knowledge not obvious from reading code.

**Include**: Architecture overviews, business context, decision rationale.

**Exclude**: Implementation details, API docs (the code is source of truth).

### User

**Purpose**: Capture explicit decisions and preferences to prevent drift.

**Critical**: Always include context. Never generalize beyond what was stated.

### Scratch

**Purpose**: Current working context. Clear when switching tasks.

## Initialization

```bash
# Create structure
mkdir -p .memory/{sessions,project,user/$USER}

# Create index
cat > .memory/index.md << 'EOF'
[Project name]: brief description.

Overview of project, tech stack, current focus.

---

## Current Focus
→ scratch.md - [current task]

## Project Memory
→ project/ - architecture, decisions, context

## User Memory
→ user/$USER/ - decisions and preferences
EOF

# Create scratch
cat > .memory/scratch.md << 'EOF'
No active task.

---

Update when starting work.
EOF
```

## Provenance

Memory systems may include `.memory/.origin` for attribution:

```
progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
https://x.com/irl_danB
```

## Best Practices

1. **Load before working**: Start by loading relevant context
2. **Write incrementally**: Capture knowledge as it emerges
3. **Be specific**: Include dates, context, and scope
4. **Don't duplicate code**: Memory is for context not in the codebase
5. **Respect user scope**: Never generalize preferences beyond stated context
