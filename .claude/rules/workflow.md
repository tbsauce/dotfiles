# Workflow Rules
# Established working rules — these are promoted, not lessons.

- Always ask before executing: present the plan and wait for explicit approval before running anything that changes state. Never start mkdir/cp/stow/etc without a yes.
- Log incrementally to .claude/changelog.md: log each system-affecting action the moment it happens (stow, systemctl, dnf, config edits, git commits/pushes, file writes). Don't log read-only commands. Never batch at end of session.
- Keep all project work inside ~/dotfiles: new scripts → scripts/.local/bin/, new configs → the appropriate stow package. Before ending a session, scan for strays (real files not symlinks) in ~/.local/bin or ~/. Exception: ~/.claude/ auto-memory is system data, not project work.
- No Co-Authored-By in commits: never add the Co-Authored-By trailer.
