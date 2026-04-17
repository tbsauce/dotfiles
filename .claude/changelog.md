# Changelog

## 2026-04-17 — Switch statusline palette to Catppuccin Mocha accents

**What:** Replaced the Macchiato accent hexes (too washed out against the dark terminal) with Catppuccin Mocha accents — same family, higher saturation. Also replaced `\033[2m` dim attribute with explicit Overlay2 `#939ab7` color for consistent rendering.

**Palette:** blue `#89b4fa`, yellow `#f9e2af` (Opus + on-pace), teal `#94e2d5` (Haiku + low-usage), green `#a6e3a1`, peach `#fab387` (med warn), red `#f38ba8`, mauve `#cba6f7` (git branch), overlay2 `#939ab7` (labels/separators).

**Why:** User wanted "easier to see" while staying Catppuccin-like. Mocha accents are the natural brighter variant.

## 2026-04-17 — Fix statusline colors to actual Catppuccin Macchiato

**What:** Swapped 8 hex values in `claude/.claude/statusline.sh`. The script claimed Catppuccin but was using OneDark (Atom) values.

**Mapping:** blue `#61AFEF`→`#8aadf4`, amber `#E5C07B`→Yellow `#eed49f`, cyan `#56B6C2`→Teal `#8bd5ca`, green `#50C878`→`#a6da95`, orange `#FFB055`→Peach `#f5a97f`, yellow `#E6C800`→`#eed49f`, red `#EB5757`→`#ed8796`, magenta `#C678DD`→Mauve `#c6a0f6`. Amber and yellow collapse to the same Catppuccin Yellow (palette is pastel, no "bright" yellow) — they never appear in the same segment so no visual conflict.

**Why:** CLAUDE.md mandates Catppuccin Macchiato consistency; script was drifting.

## 2026-04-17 — Make statusline rate-limit segments readable

**What:** Reformatted the 5h/7d rate-limit blocks in `claude/.claude/statusline.sh` for clarity. Before: `97m:60%→ 2h`. After: `5h 60% → 2h15m · reset 1h37m`.

**Changes:**
- `fmt_time` now preserves minutes in hour ranges (`1h37m` not `97m`) and switches to days for >24h (`6d4h` not `148h`)
- Space on both sides of the pace arrow
- Each segment leads with a dim window label (`5h` / `7d`) so it's self-explanatory; `time-at-pace` comes right after the arrow; a dim `· reset Nh` tail shows when the window clears
- Pace arrow output now adds its own leading space; under-pace (↓) still omits time-at-pace

## 2026-04-17 — Stow Claude Code statusline with merged style

**What:** Created new `claude/` stow package and stowed a colorized statusline merged from two versions.

**Files changed:**
- `claude/.claude/statusline.sh` — new; Catppuccin-style colors + pace arrows (↑→↓) projecting 5h/7d limit burn + context/branch/cwd/lines-changed segments
- `~/.claude/statusline.sh` — now a symlink into the dotfiles repo (old file backed up as `statusline.sh.bak`)
- `~/.claude/settings.json` — `statusLine.command` switched from `sh` to `bash` (new script uses bash-only features: `+=`, `local`, `${var/pat/sub}`)

**Why:** Old statusline was plain text despite claiming Catppuccin. User wanted best-of-both from a pasted variant with real colors and pace arrows, stowed so it travels with the repo.

## 2026-04-16 — Move portable rules out of auto-memory into repo

**What:** Consolidated 4 feedback rules + user profile into a single committed file; removed their auto-memory copies. Machine-specific memory (debug, security) stays in auto-memory.

**Files changed:**
- `.claude/preferences.md` — new; contains user profile + 4 rules (ask before executing, incremental logging, keep work in dotfiles, no Co-Authored-By)
- `CLAUDE.md` — added top-level pointer telling Claude to read `.claude/preferences.md` each session
- Auto-memory: deleted `feedback_no_coauthor.md`, `feedback_incremental_logging.md`, `feedback_ask_before_executing.md`, `feedback_keep_work_in_dotfiles.md`, `user_profile.md`, `project_architecture.md` (last one was derivable from code anyway)
- Auto-memory `MEMORY.md` — trimmed to only machine-specific entries, points at the repo file for portable rules

**Why:** User wanted the rules to travel with the repo to new PCs via git, not live in per-machine auto-memory.

## 2026-04-16 — Promote ble-pair script to first-class command

**What:** Renamed in-progress `ble-pair.tmp.86349.1776338994153` to `ble-pair`, made it executable, re-stowed. Updated the BLE mouse pairing lesson with a "Fast path" note pointing at the script.

**Files changed:**
- `scripts/.local/bin/ble-pair` — renamed from `.tmp.*`, chmod +x, now symlinked into `~/.local/bin/`
- `.claude/lessons/ble-mouse-pairing-bluez.md` — added "Fast path: `ble-pair \"MX Master 4\"`" line so future sessions skip re-exploration

**Why:** User paired mouse successfully via the tmp script and asked to lock it in so the next pairing is a one-liner instead of re-deriving the workflow.

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
