---
name: learn
description: Extract lessons from recent dotfiles work and save them to the knowledge base. Use after fixing a bug, discovering a gotcha, resolving a config conflict, or any time something non-obvious was learned.
---

You are building a local knowledge base for this specific dotfiles setup (Fedora 43 + i3 + Catppuccin Macchiato + GNU Stow).

**Why this matters:** Lessons prevent re-discovering the same fixes. They accumulate into a setup-specific knowledge base that makes future work faster and safer.

## Steps

1. **Read recent context:**
   - `~/dotfiles/.claude/changelog.md` — what changed recently
   - All files in `~/dotfiles/.claude/lessons/` — what's already known

2. **Check for duplicates:**
   - Compare by **root cause**, not tool name — two lessons about the same underlying issue are duplicates even if they mention different configs
   - If an existing lesson is incomplete, **update it** instead of creating a new one
   - See `.claude/commands/references/lesson-format.md` for dedup rules

3. **Identify new insights** from recent work. Look for:
   - Config values that weren't obvious from docs
   - Interactions between tools (i3 ↔ picom, polybar ↔ fonts, stow ↔ symlinks)
   - Fedora-specific paths or behaviors that differ from Arch wiki
   - Commands that looked safe but caused problems
   - Catppuccin colors that needed manual adjustment

4. **Write lesson files** to `~/dotfiles/.claude/lessons/` following the schema in `.claude/commands/references/lesson-format.md`

5. **Report** what was learned and saved. If nothing new was learned, say so — don't create empty lessons.

## Arguments

If `$ARGUMENTS` is provided, treat it as a hint for what to focus on:
- Topic name (e.g., `stow`) → focus lesson extraction on that area
- `--review` → re-read all lessons and check for outdated or conflicting entries
- `--list` → just list existing lessons without creating new ones
