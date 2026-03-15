# Changelog

## 2026-03-15 — Skill upgrades + command safety system

**What:** Upgraded `/log` and `/learn` skills with YAML frontmatter, progressive disclosure, and argument handling. Added a command safety system with dangerous pattern detection and a persistent never-do list.

**Files created:**
- `.claude/commands/references/safety-rules.md` — Comprehensive dangerous command patterns (filesystem, privilege, RCE, fork bombs, git, stow-specific)
- `.claude/commands/references/lesson-format.md` — Lesson schema, naming conventions, categories, good/bad examples, dedup rules
- `.claude/never-do.md` — Persistent append-only correction log (starts empty, grows with user corrections)

**Files rewritten:**
- `CLAUDE.md` — Added "why" explanations to safety rules, new Safety System section (refs safety-rules.md + never-do.md), Skills & Commands section, Catppuccin hex values in project rules
- `.claude/commands/log.md` — Added YAML frontmatter, argument filtering (date/keyword/count), edge case handling, output format spec
- `.claude/commands/learn.md` — Added YAML frontmatter, references lesson-format.md, argument support (--review, --list, topic focus), "what to look for" guide

**Why:** The foundation from the previous session was functional but minimal. This upgrade makes skills self-documenting and adds proactive safety — dangerous commands are caught before execution, and user corrections are permanently recorded so mistakes never repeat.

## 2026-03-15 — Foundation: logging, safety rules, /learn skill

**What:** Set up the project infrastructure for safe, tracked, and learnable dotfiles management.

**Files created:**
- `CLAUDE.md` — Safety rules (no destructive/system commands without permission), workflow rules (plan-then-execute, log everything), project rules (stow-based, Catppuccin Macchiato theme)
- `.claude/changelog.md` — This audit log (git-tracked)
- `.claude/commands/log.md` — `/log` slash command to view changelog
- `.claude/commands/learn.md` — `/learn` slash command to extract lessons from recent work
- `.claude/lessons/` — Empty directory for project-specific lessons (grows over time)
- `.gitignore` — Security exclusions (secrets, keys, credentials, SSH/GPG, browser profiles, OS junk, caches)

**Memory created:**
- `security_posture.md` — SELinux enforcing, firewalld active (public + docker zones), sshd inactive, no fail2ban/ClamAV/dnf-automatic. Git email exposed in .gitconfig (private repo, low risk).

**Commands run:**
- `getenforce` — SELinux status
- `systemctl is-active firewalld` / `sshd` — service checks
- `rpm -q fail2ban clamav dnf-automatic` — package checks
- `git config user.email` — personal data check
- `firewall-cmd --list-all` — denied (needs sudo, skipped)

**Why:** Establish guardrails, audit trail, and knowledge-building system before any dotfiles work begins. Everything after this gets logged and lessons accumulate locally.
