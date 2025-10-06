# Development Notes Directory

> **📝 Personal workspace for development documentation, analysis, and technical notes**

This directory is a **gitignored workspace** for internal development notes. All content here (except this README) is **NOT tracked by git** and is **personal to each developer**.

---

## ⚠️ CRITICAL: DO NOT CHANGE THIS APPROACH

**This gitignore policy is PERMANENT and must NEVER be changed.**

### Absolute Rules:

1. ✅ **ONLY `dev-notes/README.md` is tracked** by git
2. ❌ **ALL other files in `dev-notes/` MUST remain gitignored**
3. ❌ **NEVER commit any files from this directory** (except README.md)
4. ❌ **NEVER modify `.gitignore` to track files here**
5. ❌ **NEVER use `git add -f` to force-add files from here**

### Why This Is Permanent:

- **Personal workspace** - Each developer has unique notes
- **Messy by design** - WIP, experiments, temporary findings
- **Privacy** - May contain local paths, personal observations
- **No noise** - Keeps git history clean and focused
- **Safe experimentation** - Write freely without worrying about commits

### If You Need to Share Something:

**DO NOT** add it to git from `dev-notes/`. Instead:

1. **Move to permanent docs** - Copy content to `README.md`, `DOCKER.md`, etc.
2. **Create new doc** - Add a new tracked `.md` file in project root
3. **Update existing docs** - Integrate findings into existing documentation
4. **Use issues/PRs** - Share via GitHub issues or pull request descriptions

**Remember**: If it's important enough to share, it belongs in permanent documentation, not in `dev-notes/`.

---

## 🎯 Purpose

This is your **personal scratchpad** for development work on this project.

### Use this directory for:

- ✅ **Bug investigations** - Root cause analysis, debugging logs
- ✅ **Technical decisions** - Comparison docs, pros/cons analysis
- ✅ **Work-in-progress** - Draft documentation, TODO lists
- ✅ **Meeting notes** - Discussion summaries, action items
- ✅ **Learning notes** - How things work, architecture notes
- ✅ **Build/deploy logs** - Troubleshooting records
- ✅ **API research** - Endpoint testing notes, response examples
- ✅ **Performance analysis** - Profiling results, optimization ideas

### Do NOT use this directory for:

- ❌ **Public documentation** → Use root-level `.md` files
- ❌ **API documentation** → Use `docs/` directory  
- ❌ **User guides** → Use `README.md`
- ❌ **Code or tests** → Use appropriate source directories
- ❌ **Permanent project knowledge** → Move to proper docs when ready

---

## 🔒 Git Status (PERMANENT - DO NOT CHANGE)

```gitignore
# In .gitignore:
dev-notes/*           # All files ignored
!dev-notes/README.md  # ONLY exception - this README
```

**What this means:**
- ✅ This directory exists in the repository
- ✅ **ONLY** this README is tracked and shared
- ❌ All other files are **NOT tracked** by git - **FOREVER**
- ✅ Each developer has their own unique notes
- ✅ Notes are **NOT** pushed to remote repository
- ✅ Safe space for messy/incomplete work

**⚠️ NEVER change this gitignore configuration. This is a permanent project policy.**

---

## 🚀 How to Use (for Humans)

### Creating Notes

Just create any file - it's automatically gitignored:

```bash
# Quick note
echo "# Bug investigation" > dev-notes/2025-10-06-login-issue.md

# Open in editor
vim dev-notes/docker-build-notes.md
code dev-notes/api-research.md
```

### Recommended File Naming

Use descriptive names with context:

```
✅ Good examples:
dev-notes/2025-10-06-license-field-fix.md
dev-notes/bug-lazy-imports-missing.md
dev-notes/decision-docker-vs-local-builds.md
dev-notes/meeting-2025-10-sprint-planning.md
dev-notes/todo-before-v1-release.md
dev-notes/api-endpoint-testing-results.md

❌ Avoid:
dev-notes/notes.md
dev-notes/temp.md
dev-notes/stuff.txt
```

### Suggested Prefixes

Organize by type using prefixes:

- `bug-*` - Bug investigations and fixes
- `decision-*` - Technical decision logs
- `meeting-*` - Meeting notes and summaries
- `todo-*` - Task lists and checklists
- `research-*` - Research and exploration
- `YYYY-MM-DD-*` - Date-based entries

### Finding Your Notes

```bash
# List all your notes
ls -la dev-notes/

# Search across all notes
grep -r "keyword" dev-notes/

# Find specific type
ls dev-notes/bug-*
```

### Maintenance

**When notes become important:**
- Move key findings to permanent documentation
- Update root-level `.md` files with decisions
- Add to `CHANGELOG.md` if user-facing

**Cleaning up:**
```bash
# Safe to delete - everything is gitignored
rm dev-notes/old-notes.md

# Or archive if you want to keep
mkdir dev-notes/archive
mv dev-notes/2024-* dev-notes/archive/
```

---

## 🤖 How to Use (for AI Assistants)

### When to Create Files Here

**✅ DO create files** in `dev-notes/` for:

- **Bug investigations** - Detailed analysis of issues and fixes
- **Technical decisions** - Comparison of options, pros/cons
- **Build/deploy logs** - Troubleshooting sessions
- **Research notes** - API testing, experimentation results
- **Work-in-progress** - Draft documentation before it's ready

**Examples:**
```
"Investigating why Docker build fails"
→ Create: dev-notes/2025-10-06-docker-build-failure.md

"Comparing license field formats"  
→ Create: dev-notes/decision-license-field-format.md

"TODO list before v1.0 release"
→ Create: dev-notes/todo-v1-release.md
```

**❌ DON'T create files** in `dev-notes/` when:

- User asks for public docs → Use root `.md` files
- Adding API docs → Use `docs/` directory
- Creating code examples → Use `examples/` directory
- Writing tests → Use `test/` directory

### File Naming for AI

Use descriptive, dated names:

```
✅ Good:
dev-notes/2025-10-06-setuptools-metadata-bug.md
dev-notes/bug-lazy-imports-missing-dependency.md
dev-notes/decision-why-docker-only-workflow.md

❌ Avoid:
dev-notes/notes.md
dev-notes/temp.md
dev-notes/investigation.md
```

### Recommended Template

```markdown
# [Title - What & Why]

## Date
YYYY-MM-DD

## Context
What prompted this work?

## Problem/Goal
What are we solving or investigating?

## Investigation/Process
What was tried, discovered, tested?

## Solution/Outcome
What worked? What was decided?

## Next Steps (if any)
What remains to be done?

## References
- Links to docs, issues, PRs
- Related files in the project
```

### Important Guidelines

1. **Keep it detailed** - Future you (or others) will thank you
2. **Link to code/files** - Reference specific files and line numbers
3. **Include commands** - Show exact commands used
4. **Capture errors** - Include full error messages
5. **Note the outcome** - Always conclude what happened

### Lifecycle Management

**Don't auto-delete** - These are personal notes. Instead:

- **Suggest promotion**: "This finding should be in DOCKER.md"
- **Offer consolidation**: "Merge with existing note?"
- **Recommend archiving**: "Move old 2024 notes to archive/"

**⚠️ CRITICAL**: Never suggest committing files from `dev-notes/` to git. If content is valuable, it should be moved to permanent documentation, not committed from here.

---

## ✅ Verification

Check that your notes are properly gitignored:

```bash
# Create a test note
echo "test" > dev-notes/test.md

# Check git status
git status
# Should NOT show dev-notes/test.md

# Verify it's ignored
git check-ignore dev-notes/test.md
# Should output: dev-notes/test.md

# Cleanup
rm dev-notes/test.md
```

---

## 📚 Where Things Go

| Type of Content | Location | Tracked by Git? |
|----------------|----------|-----------------|
| User-facing docs | `README.md`, `PUBLISHING.md`, etc. | ✅ Yes |
| API documentation | `docs/` directory | ✅ Yes |
| Development notes | `dev-notes/*.md` | ❌ No (except README) |
| Source code | `orbuculum/` | ✅ Yes |
| Tests | `test/` | ✅ Yes |

---

## 💡 Real-World Examples

**Bug Investigation:**
```markdown
# 2025-10-06: Missing lazy-imports Dependency

## Problem
All 68 tests failing: ModuleNotFoundError: No module named 'lazy_imports'

## Investigation
- ✅ Declared in requirements.txt
- ✅ Declared in pyproject.toml  
- ❌ Missing from Dockerfile

## Solution
Added to Dockerfile line 31: 'lazy-imports>=1,<2'

## Result
✅ All 92 tests now pass
```

**Decision Log:**
```markdown
# Decision: Docker-Only Development Workflow

## Date
2025-10-06

## Options
1. Local development (pip install)
2. Docker-only (docker-compose)

## Decision
Docker-only for ALL operations

## Rationale
- Consistent Python 3.13 + OpenAPI Generator 7.15.0
- Pre-installed dependencies
- Reproducible across all machines
- No host system conflicts

## Implementation
Added warnings to README.md and DOCKER.md
```

---

## 🚨 Final Reminder

**This approach is PERMANENT and MUST NOT be changed:**

- ✅ `dev-notes/README.md` - ONLY tracked file
- ❌ Everything else - NEVER tracked, NEVER committed
- ❌ DO NOT modify `.gitignore` to track files here
- ❌ DO NOT use `git add -f` to force-add files

**If you need to share something, move it to permanent documentation.**

