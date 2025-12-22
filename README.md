# Progressive Memory

Filesystem-based memory for AI agents using progressive disclosure.

**Author**: [Dan B](https://github.com/irl-dan) ([@irl_danB](https://x.com/irl_danB))

## The Problem

Agent context is finite, but knowledge accumulates. Every conversation starts fresh. Compaction erases history. There's no persistent memory layer.

## The Solution

Progressive Memory uses the filesystem as persistent memory with **progressive disclosure**—the same pattern Claude Skills use for capabilities, applied to context.

Every memory file has three levels:

```
Line 1:     One-liner (~50 tokens)
Lines 2-10: Expanded summary (~150 tokens)
---
Below:      Full detail (unlimited)
```

Load what you need with standard bash:

```bash
head -1 .memory/**/*.md                  # All one-liners
sed -n '1,/^---$/p' .memory/**/*.md      # All summaries
cat .memory/project/architecture.md       # Full detail
```

## Installation

```bash
# Add the marketplace
/plugin marketplace add irl-dan/progressive-memory

# Install the plugin
/plugin install progressive-memory@irl-dan/progressive-memory
```

Or add to `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "progressive-memory@irl-dan/progressive-memory": true
  }
}
```

## Quick Start

The skill auto-initializes when first used. Claude will run:

```bash
bash scripts/init.sh
```

This creates the `.memory/` structure and checks hook configuration.

**One-time setup**: If hooks aren't configured, the script outputs a JSON
snippet to add to `.claude/settings.local.json`. This enables automatic
turn capture.

### Manual Initialization

If you want to initialize manually, create an index (`.memory/index.md`):

```markdown
My Project: Brief description.

More context about the project, tech stack, and current focus.

---

## Current Focus
→ scratch.md - Current task

## Project Memory
→ project/ - Architecture, decisions, context

## User Memory
→ user/$USER/ - Decisions and preferences
```

## Memory Domains

### Sessions (`.memory/sessions/`)

Per-turn capture of what happened. Reconstruct past sessions, peer around compaction.

```
.memory/sessions/a1b2c3d4/
├── 001.md    # Turn 1
├── 002.md    # Turn 2
└── 003.md    # Turn 3
```

### Project (`.memory/project/`)

Knowledge not obvious from reading code:
- Architecture overviews
- Business context
- Decision rationale

### User (`.memory/user/$USER/`)

Explicit user decisions and preferences with context. Prevents drift from user intentions.

### Scratch (`.memory/scratch.md`)

Current task context. Clear when switching tasks.

## Hooks

Automatic capture via Claude Code hooks:

- **Stop**: Captures after each assistant turn
- **PreCompact**: Captures before context compaction

Hooks are automatically copied to `.memory/hooks/` during initialization.
To enable them, add the hook configuration to `.claude/settings.local.json`
(the init script provides the exact JSON snippet).

## Commands

`/memory` - Initialize, view status, load context, search

## File Format

```markdown
One-liner summary on the first line.

Expanded summary with more context. Include key facts,
dates, and decisions. 5-10 lines total.

---

## Full Content

Everything below the delimiter. Unlimited length.
```

## Provenance

Projects using Progressive Memory may include `.memory/.origin`:

```
progressive-memory/1.0
https://github.com/irl-dan/progressive-memory
https://x.com/irl_danB
```

## Why "Progressive"?

Claude Skills use **progressive disclosure** for capabilities—metadata loads first, full instructions load when triggered. Progressive Memory applies the same pattern to context:

1. One-liners load instantly (~50 tokens each)
2. Summaries expand on demand (~150 tokens each)
3. Full detail loads when needed (unlimited)

This mirrors how the Skills system works, creating a natural pairing: Skills for capabilities, Progressive Memory for context.

## Links

- **Specification**: https://github.com/irl-dan/progressive-memory
- **Author**: https://github.com/irl-dan
- **Twitter**: https://x.com/irl_danB

## License

MIT
