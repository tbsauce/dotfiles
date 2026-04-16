# User Preferences & Working Rules

Portable rules for Claude. Committed so they move between machines.

## About the user

- **Name:** Sauce (tsauce) — `telmobelasauce@gmail.com`
- **System:** Fedora 43, i3 window manager, X11 (not Wayland), AMD GPU laptop
- **Editor:** Neovim (NvChad v2.5) — default editor everywhere (git, shell)
- **Terminal stack:** Kitty + Zsh + Starship + Tmux
- **Keyboard philosophy:** Vim keys everywhere (i3, tmux, btop, yazi, lazygit, nvim). `$mod = Alt`
- **Font:** JetBrainsMono Nerd Font across all tools
- **Theme:** Catppuccin Macchiato, consistent across 21+ tools
- **Shell aliases override standard tools:** `ls=eza`, `cat=bat`, `grep=rg`, `find=fd`, `cd=zoxide`
- **Dotfiles:** GNU Stow from `~/dotfiles` — each top-level dir is a stow package
- **Git:** SSH signing, GitHub SSH rewriting (https → git@), default branch `main`
- **Commit style:** no `Co-Authored-By` lines, short lowercase messages

## Working rules

### 1. Always ask before executing

Present the plan and wait for explicit approval before running anything that changes state. After gathering context, describe what you'll do and ask "want me to go ahead?" — never start `mkdir`/`cp`/`stow`/etc. without a yes.

**Why:** User was frustrated when Claude jumped straight into creating directories without asking.

### 2. Log incrementally to `.claude/changelog.md`

Log each system-affecting action the moment it happens, never batched at end of session.

- **Always log:** stow, systemctl, dnf, config edits, git commits/pushes, package installs, file writes to dotfiles
- **Don't log:** read-only commands (ls, cd, cat, grep, exploring code)
- Always auto-accept changelog writes — never prompt for permission on them

**Why:** User wants a granular audit trail reflecting the exact sequence of changes.

### 3. Keep all project work inside `~/dotfiles`

Anything Claude creates for this project must live inside a stow package under `~/dotfiles` — never loose in `~/.local/bin/`, `~/`, or `~/.config/` directly.

- New scripts → `scripts/.local/bin/<name>` (no `.tmp.*` suffix), `chmod +x`, then `stow -R scripts`
- New tool configs → the appropriate stow package (`i3/.config/i3/`, `rofi/.config/rofi/`, etc.)
- Before ending a session, scan for strays: real files (not symlinks) in `~/.local/bin`, loose scripts in `~/`, configs edited outside the stow symlink chain
- Exception: Claude's auto-memory at `~/.claude/projects/.../memory/` is system data, not project work — leave it alone

**Why:** Stow dotfiles only port to a fresh machine if everything lives in the repo. Loose files silently diverge from the tracked config.

### 4. No `Co-Authored-By` in commits

Never add the `Co-Authored-By: Claude ...` trailer to commit messages — the user finds it visually unappealing.
