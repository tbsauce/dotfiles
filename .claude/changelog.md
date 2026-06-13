# Changelog

## 2026-06-12 — Surgical patch to /handoff skill

**What:** Patched `claude/.claude/skills/handoff/SKILL.md` (stow-linked → `~/.claude/skills/handoff/SKILL.md`). Artifact template: added a `branch · sha · dirty · status · UTC` anchor line at top, claim-based State with `(verified: cmd)` / `(unverified)` / IN FLIGHT / TODO labels, new `## Key values` section for blur-resistant data (MACs, IDs, thresholds, endpoints), `## Gotchas` renamed to `## Landmines` with if-then root-caused form, `## Next` retagged `## Next action [SAFE | CONFIRM-FIRST]`, and section order reshuffled so Next action sits at the end (after Landmines). Rules section grew 5 → 8: budget 5-15 → 15-25 lines, Rule 3 folds in the if-then form, Rule 4 softens for bare TODO bullets (dropped the dead Windows clause); new Rules 6/7/8 define the status enum, guard `verified` against rubber-stamping, and list CONFIRM-FIRST criteria.

**Why:** Compaction reliably blurs precision first — exact paths/MACs/error fingerprints survive a summary worst — so Key values gives those a verbatim bunker. Claim+proof labels on State stop the Jupyter-style false-confidence handoff where unrun work gets passed as done. SAFE/CONFIRM-FIRST + anchor staleness check turn the handoff into a fail-safe artifact (HEAD moved → distrust State; destructive next steps require explicit pause). Print-to-screen stays; file output, /learn routing (already global in CLAUDE.md), mandatory "none", and YAML frontmatter were considered and explicitly rejected as overengineering for a launchpad. Plan: `~/.claude/plans/u-can-do-this-async-lobster.md`.

## 2026-06-12 — Disambiguate dossier-pointer order in learn/reflect skills

**What:** Three surgical edits to `~/.claude/skills/{learn,reflect}/SKILL.md` (stow-linked from `claude/`). learn/SKILL.md: added a dossier-pointer example to the canonical Examples block, and rewrote the "Dossier pointer (optional)" paragraph to spell out the order explicitly (`text. (date) → pointer`, pointer always last). reflect/SKILL.md: extended the one-line rule to show the pointered form, and added `pointer-before-date` to the REWRITE trigger list so misordered legacy lines get cleaned up by `/reflect`.

**Why:** Two separate migration agents (dotfiles + a sibling project) independently put the date AFTER the dossier pointer because both skill files said "the line ends with a pointer" AND "date trails" without showing the combined order. The Examples block had no pointered example; the only canonical pointered line was in a `reflect` archive example agents weren't reading deeply. Fix is pure spec — no behavior change, just removes the ambiguity at the three places agents look (example block → spec paragraph → reflect rewrite rule).

## 2026-06-12 — Lesson store migration to new skill format

**What:** Rewrote `.claude/rules/lessons.md` from legacy date-leading `(YYYY-MM-DD) text` to date-trailing `text … (YYYY-MM-DD)` format. Reconstructed three dossiers from git history at `1a2a562^:.claude/lessons/` — `flatpak-spotify-singleton-lock.md`, `ble-mouse-pairing-bluez.md`, `usbc-hub-charging-ucsi.md` — and wired dossier pointers into `rules/lessons.md`, `rules/bluetooth.md`, and `lessons-archive.md`. Archive entry left frozen (date-leading preserved).

**Why:** The 2026-06-09 reorg (1a2a562) compressed three rich dossier files into one-liners; the new skill keeps that evidence in dossiers so one-liners stay terse without losing the saga. Format alignment lets `/learn` and `/reflect` operate on lessons.md without re-interpreting legacy shapes. No lessons deleted; nothing surfaced from git deletion (all three classified as compressed-not-deleted, per user).

## 2026-06-11 — Dossier consistency patch (final review)

**What:** /learn rule 10 ("dossiers follow their lesson" — archive/merge/resurrect/evict keeps the pointer and updates the dossier `status:` header), explicit dossier write after approval in Step 5, and /reflect Step 0's migration-batch remedy scoped to legacy stores only (orphaned dossiers have their own remedy).

**Why:** /learn runs without /reflect loaded, but performs lifecycle transitions itself (Step 6 evictions, merges, resurrection) — the dossier-side instruction had to live locally or those transitions would leave stale dossier headers.

## 2026-06-11 — Dossier auto-draft + lifecycle in learn/reflect

**What:** /learn Step 5 gains a saga check: captures from multi-attempt investigations, dead ends, hard evidence, or counter-intuitive proofs get a dossier draft alongside the one-liner (approve line / both / neither; line-only default; char count is NOT the trigger — over-150 still routes to rules/). Dossiers live at `.claude/dossiers/<slug>.md` in every project, vaults included (replaces the `[[Note]]`/docs/ split), with a fixed template: Rule / What happened / Evidence / Dead ends required (at least one of the last two), Scope / History optional, omit empty sections, 10-40 lines, distill don't transcribe. /reflect gains a Dossier Lifecycle section — pointers travel with the line through ARCHIVE/PROMOTE/GRADUATE/resurrection, dossiers never move/delete/merge, `status:` header updated each transition — plus an orphan scan in Step 0 and a dossiers row in File Locations.

**Why:** The saga is free at capture time (it's in the session) and archaeology later. Dossiers are Claude's operational memory, deliberately separate from the user's knowledge pipeline (never Inbox/Library; invisible to Obsidian indexing by design — real knowledge gets extracted to a note instead). Cold storage = zero context cost, so the layer needs no cap, decay, or curation — only the bidirectional-link invariant.

## 2026-06-11 — Remove version stamps from learn/reflect

**What:** Deleted the `<!-- engine v2 ... canonical: ... -->` HTML comment lines from `claude/.claude/skills/{learn,reflect}/SKILL.md`.

**Why:** Single user, single source of truth via stow symlinks. The stamp had no maintained value and would have rotted the moment a future edit forgot to bump it. Dotfiles git history is the real version record.

## 2026-06-11 — Globalize Claude skills: learn/reflect engine v2 + global capture trigger

**What:** Added `claude/.claude/skills/{learn,reflect,handoff,skill-creator,council}` and `claude/.claude/CLAUDE.md` to the stow package, ran `stow claude` — `~/.claude/skills/*` (5 symlinks) and `~/.claude/CLAUDE.md` now point into dotfiles. learn/reflect upgraded to engine v2: `ov` ledger marker + NARROW action for misfired lessons, promotion destination gradient (hook/permission rule > project-owned skill > rules/), tombstones to archive instead of deletion, graduation at 3+ with synthesis test + mandatory skill-creator scaffolding, uncorrected-inefficiency sweep in /reflect, forced-rank eviction when over budget, version stamps in both files. Global CLAUDE.md carries the lesson-capture trigger (loads in every project). Deleted the now-shadowing project copies: `.claude/skills/{learn,reflect}` here, all five skills in MyBrain. handoff/council got one-word genericizations ("vault-relative" → "project-relative", "the vault's standard" → "the standard").

**Why:** Per-project engine copies had already drifted (QuantTrader's learn skill contradicts itself; learn-vs-reflect `re`-date threshold skew). One canonical copy + symlinks kills that rot class — same pattern as settings.json. The capture trigger moved to always-loaded global text because manual-only capture starves (3 lessons here vs ~60 under QuantTrader's always-loaded protocol). QuantTrader/QuantWebscrapper copies intentionally left for later migration via /reflect Step 0.

## 2026-06-11 — Resolved diverged main: `git pull --rebase` + `git push`

**What:** Remote had `ffc77ed home general` (pushed from another machine), local had `66dc947 more`. Rebased local onto remote (new hash `53c55eb`), then pushed. No conflicts.

## 2026-06-10 — Promote curated settings.json into `claude` package + re-stow

**What:** Copied the fully-curated live `~/.claude/settings.json` into `claude/.claude/settings.json` (overwrote the stale 2-key copy), removed the live real file, and ran `stow claude`. `~/.claude/settings.json` is now a symlink → dotfiles (joins `statusline.sh`, already linked). Verified: valid JSON via symlink, git shows `M claude/.claude/settings.json`. Not yet committed.

## 2026-06-10 — Disable fast mode + drop dead adaptive-thinking flag (live ~/.claude/settings.json)

**What:** (1) Fully disabled Claude Code fast mode so it can't be toggled on — added `CLAUDE_CODE_DISABLE_FAST_MODE: "1"` to `env`, removed the now-pointless `fastMode: false` and `fastModePerSessionOptIn: true`. (2) Removed `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING: "1"` — it's a no-op on Opus 4.7+ (adaptive reasoning can't be disabled there); user committed to staying on Opus 4.8.

**Why:** Fast mode is same-model but billed at a 3–5x premium *outside* the plan's included usage; user wants it off with no opt-in. The adaptive-thinking flag only affects Opus 4.6 / Sonnet 4.6, so it was dormant cruft on 4.8. Edited live file only (not yet promoted to the `claude` stow package).

**Follow-up same day — settings.json cleanup pass:** Removed inert `permissions.defaultMode: "default"` (it's the default, did nothing). Removed undocumented `skipAutoPermissionPrompt: true` (not in official docs, likely legacy/inert). Removed `agentPushNotifEnabled: false` (user doesn't use mobile push). Kept `skipDangerousModePermissionPrompt: true` (user's choice). User set `verbose: false` via /config.

**Second pass — app re-injected default keys via /config.** Curated them: kept `autoUpdatesChannel: stable`, `autoCompactEnabled: true` (auto-summarize at max context — keeps sessions seamless), `awaySummaryEnabled: false` (explicit = no away-recap). Removed `preferredNotifChannel`, `switchModelsOnFlag` (undocumented), `terminalProgressBarEnabled` (cosmetic). NOTE: Claude Code rewrites this file on every /config — undocumented default keys will likely reappear; this file self-modifies under stow, expect occasional git drift.

## 2026-06-09 — Stow Claude Code settings.json

**What:** Added `~/.claude/settings.json` (theme + statusLine config) to the `claude` stow package alongside the existing `statusline.sh`. Removed the loose file and re-stowed so both are symlinked.

## 2026-06-08 — Revert i3 to Alt, move tmux to Alt+Ctrl

- Reverted i3 `$mod` from `Mod4` (Super) back to `Mod1` (Alt)
- Changed tmux direct binds from `M-` (Alt) to `M-C-` (Alt+Ctrl) to avoid conflicts
- Keybind layers: Alt → i3, Alt+Shift → i3 move/secondary, Alt+Ctrl → tmux

## 2026-06-08 — Replace lesson system with MyBrain learn/reflect engine

**What:** Migrated from heavyweight per-file lessons to the MyBrain learn/reflect skill system. Skills are domain-agnostic (copied verbatim); only the lesson content is project-specific.

**Created:**
- `.claude/skills/learn/SKILL.md` — one-liner lesson capture with dupe detection, archive resurrection, quality gates
- `.claude/skills/reflect/SKILL.md` — session review + lesson curation (merge/promote/archive/rewrite, max 3 proposals per run)
- `.claude/rules/lessons.md` — 3 migrated lessons as one-liners (BLE pairing, Flatpak singleton, USB-C hub)
- `.claude/rules/workflow.md` — 4 promoted working rules (ask before executing, incremental logging, keep work in dotfiles, no Co-Authored-By)
- `.claude/rules/user.md` — user profile (from preferences.md)
- `.claude/rules/safety.md` — moved from commands/references/safety-rules.md

**Removed:**
- `.claude/commands/learn.md` (replaced by skill)
- `.claude/commands/references/lesson-format.md` + `safety-rules.md` (moved/absorbed)
- `.claude/commands/references/` directory
- `.claude/never-do.md` (concept absorbed — corrections now go through /learn)
- `.claude/preferences.md` (split into rules/workflow.md + rules/user.md)
- `.claude/lessons/*.md` + directory (migrated to rules/lessons.md one-liners)

**Updated:** `CLAUDE.md` — removed preferences.md pointer, updated safety/workflow/skills sections to reference new paths

## 2026-06-07 — Enhance tmux config with vim navigation, TPM, passthrough

**What:** Merged useful features from colleague's tmux setup into existing config:
- Added clipboard support, passthrough mode (for image.nvim)
- Added `prefix+r` reload, current-path splits/windows
- Added smart Ctrl-h/j/k/l vim-tmux pane navigation (tmux side)
- Added TPM plugin manager with auto-bootstrap + tmux-jump plugin
- Added `christoomey/vim-tmux-navigator` to nvim plugins (seamless split/pane nav)
- Ran `stow -R tmux`

**Files:** `tmux/.tmux.conf`, `nvim/.config/nvim/lua/plugins/init.lua`
**Pending:** User needs to run `sudo dnf install -y ruby` for tmux-jump to work.

## 2026-05-12 — Lesson: USB-C hub charging confirmed as hardware limitation

**What:** Updated lesson `usbc-hub-charging-ucsi.md` after full investigation. BIOS update 302→316 applied via EZ Flash — did not fix the issue. Confirmed no UCSI ACPI device (`PNP0CA0`) exists in firmware at all. This is an ASUS Vivobook M1502YA hardware limitation — ASUS never implemented UCSI. Also corrected hardware memory: laptop has 1x USB-C + USB-A ports (not "USB-C only"). Workaround: USB-C female to USB-A adapter for hub data, charge directly on USB-C.

## 2026-04-26 — Fix BLE auto-reconnect with btmgmt find + custom daemon

**What:** Root cause: kernel LL Privacy bug (since 5.9) breaks IRK resolution for rotated BLE MACs. Fix: `btmgmt find -l` forces LE discovery that resolves MACs via stored IRKs. Deployed three layers:
1. Custom `ble-autoconnect` daemon (polls every 30s, runs `btmgmt find` before connecting) — systemd service at `bluetooth-autoconnect.service`, script at `/usr/local/bin/ble-autoconnect`, source in `scripts/.local/bin/ble-autoconnect`
2. Sleep/resume hook at `/usr/lib/systemd/system-sleep/bt-reconnect.sh` — runs `btmgmt find` on wake
3. Re-paired both devices (R65 keyboard, MX Master 4 mouse) — MACs had rotated

Replaced upstream `bluetooth-autoconnect` (github.com/jrouleau) which only triggered on adapter power-on and didn't handle MAC rotation.

## 2026-04-25 — Improve BlueZ config for BLE auto-reconnect + fix ble-pair script

**What:** Configured `/etc/bluetooth/main.conf`:
- `[General]`: `Privacy = device`, `AutoEnable = true`, `FastConnectable = true`, `JustWorksRepairing = always`
- `[Policy]`: `ReconnectAttempts = 7`, `ReconnectIntervals = 1,2,4,8,16,32,64`

Re-paired MX Master 4 (MAC rotated from `:EE` to `:EF` after restart). Paired Royal Kludge R65 keyboard (advertises as "R65"). Fixed `ble-pair` script name matching to use substring match (`.*` before device name) — BLE devices advertise short names first. Mouse now auto-reconnects after power cycle. Updated lesson with full BlueZ config, troubleshooting, and Linux vs Windows Bluetooth explanation.

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
