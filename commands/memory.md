---
name: memory
description: Initialize, view, or manage Progressive Memory for this project
---

# /memory Command

Manage Progressive Memory for this project.

**Specification**: https://github.com/irl-dan/progressive-memory

## Usage

### Initialize Memory

If `.memory/` doesn't exist, create the structure:

```bash
mkdir -p .memory/{sessions,project,user/$USER}
```

Create `index.md` with project overview and `scratch.md` for current task.

### View Status

```bash
echo "=== Progressive Memory Status ==="
echo "Project: $(head -1 .memory/index.md 2>/dev/null || echo 'No index')"
echo "Sessions: $(ls -d .memory/sessions/*/ 2>/dev/null | wc -l | tr -d ' ')"
echo "Project files: $(ls .memory/project/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "User files: $(ls .memory/user/$USER/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "=== Current Context ==="
head -1 .memory/scratch.md 2>/dev/null || echo "No active task"
```

### Load Context

```bash
# All one-liners
head -1 .memory/**/*.md

# All summaries
sed -n '1,/^---$/p' .memory/**/*.md
```

## Subcommands

- `/memory init` - Initialize memory structure
- `/memory status` - Show memory status
- `/memory load` - Load all summaries into context
- `/memory search <query>` - Search across memory
