# Dotfiles Project Rules

## Safety Rules (HARD — never break these)

- NEVER run destructive commands (`rm -rf`, `git reset --hard`, `git push --force`, `stow -D` on all packages) without explicit user permission — *one wrong flag can nuke the entire config*
- NEVER modify system files (`/etc/`, `/usr/`, systemd units) without explicit user permission — *this isn't our territory*
- NEVER install/remove packages (`dnf install/remove`) without explicit user permission — *package changes affect the whole system*
- NEVER touch files outside `~/dotfiles` and `~/.claude` project dir unless asked — *stay in our lane*
- NEVER run commands that require `sudo` without explicit user permission — *privilege escalation is always explicit*
- NEVER commit files matching `.gitignore` patterns — *secrets and caches don't belong in git*
- Always confirm before running anything that changes system state — *ask first, execute second*

## Safety System

- **Before running any Bash command that modifies the system**, check `.claude/rules/safety.md` for dangerous patterns
- **When the user says "never do X"** or corrects a dangerous action, capture it with `/learn`

## Workflow Rules

- Always plan before executing — outline what you'll do, then do it
- Log to `.claude/changelog.md` after **each system-affecting action** (stow, systemctl, dnf, config edits, git commits/pushes, file writes to dotfiles) — not after read-only commands (ls, cd, cat, grep). Log incrementally as actions happen, not batched at end of session.
- Read `.claude/changelog.md` at start of each conversation to understand recent history
- When something breaks or gets fixed, capture it with `/learn`

## Skills & Commands

- `/log` — View changelog (recent actions, filtered by date/keyword)
- `/learn` — Capture a lesson to `.claude/rules/lessons.md` (one-liner, immediately active)
- `/reflect` — Review session for missed lessons, then curate: merge duplicates, promote proven lessons to `rules/`, archive stale ones

## Project Rules

- This is a GNU Stow dotfiles repo — each top-level dir is a stow package
- Don't create new stow packages without asking
- Don't modify configs for tools the user didn't mention
- Keep Catppuccin Macchiato theme consistent everywhere — *colors: `#24273a` base, `#cad3f5` text, `#8aadf4` blue, `#a6da95` green, `#ed8796` red*
