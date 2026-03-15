# Lesson File Format

Reference for the `/learn` skill. Lessons live in `.claude/lessons/` and capture reusable knowledge from this specific dotfiles setup (Fedora + i3 + Catppuccin Macchiato).

---

## File Schema

```markdown
---
topic: short-topic-name
category: config-fix | theme-consistency | stow-gotcha | package-conflict | keybinding-conflict | performance-tweak | workflow-tip
learned: YYYY-MM-DD
---

**Problem:** What went wrong or what was discovered
**Solution:** What fixed it or what to do
**Context:** Why this matters for this specific setup
```

## Naming Conventions

- Kebab-case, descriptive: `picom-glx-fix.md`, `polybar-font-issue.md`, `stow-adopt-trap.md`
- Name should hint at the problem, not the tool: `transparency-flicker.md` > `picom-config.md`
- One lesson per file — if a fix touches multiple tools, focus on the root cause

## Categories

| Category | When to use |
|----------|-------------|
| `config-fix` | A config value that was wrong/missing and caused breakage |
| `theme-consistency` | Catppuccin color mismatches, font inconsistencies across apps |
| `stow-gotcha` | Stow-specific issues: conflicts, adopt traps, symlink ordering |
| `package-conflict` | Two packages fighting over the same config or resource |
| `keybinding-conflict` | Keybinding collisions between i3, apps, or system shortcuts |
| `performance-tweak` | Compositor, rendering, or startup optimizations |
| `workflow-tip` | Process improvements for managing dotfiles |

## Good vs Bad Lessons

**Good — specific, actionable, has the fix:**
```markdown
---
topic: picom-glx-backend
category: performance-tweak
learned: 2026-03-15
---

**Problem:** Screen tearing on Firefox with picom's default xrender backend
**Solution:** Set `backend = "glx"` in `picom/picom.conf` and add `vsync = true`
**Context:** AMD GPU on Fedora 43 — glx works better than xrender for this driver. Don't use egl, it causes flickering with i3.
```

**Bad — vague, no actionable detail:**
```markdown
**Problem:** Picom was slow
**Solution:** Changed the config
**Context:** It works now
```

## Dedup Rules

Before creating a new lesson:
1. Read ALL existing files in `.claude/lessons/`
2. Check if any existing lesson covers the same **root cause** (not just same tool)
3. If a lesson exists but is incomplete, **update it** rather than creating a duplicate
4. If the new insight is a refinement of an existing lesson, append to the existing file

## What Makes a Good Lesson (Dotfiles Context)

Look for:
- Config values that aren't obvious from docs (e.g., "this option requires X to be set too")
- Interactions between tools (e.g., "i3 and picom both try to manage opacity")
- Fedora-specific paths or package names that differ from Arch wiki guides
- Stow ordering or symlink gotchas
- Catppuccin color values that need manual adjustment for specific apps
- Commands that look safe but aren't (e.g., `stow --adopt` without backup)
