# Changelog

## 2026-08-01 — GRUB theme: Pochita (HyDE) recolored to Catppuccin Macchiato

**What:** Adopted the Pochita GRUB theme from HyDE-Project/hyde (Source/arcs/Grub_Pochita.tar.gz — the cute Chainsaw Man mascot), recolored from its original Catppuccin Latte (light) to our Macchiato (dark).

**Changes vs upstream:**
- background.png → solid #24273a base (was near-white Latte)
- item_color #4C4F69 → #cad3f5; selected_item_color → #24273a (dark text on blue bar)
- select_*.png selection caps recolored to blue #8aadf4 (alpha shape preserved via `-fill … -colorize 100`)
- countdown label color → #a5adcb
- Font swapped Unifont → JetBrains Bold 16 (`grub2-mkfont`), dropped bundled font.pf2, to match system font
- Kept Pochita logo.png + all 72 OS icons (incl. fedora.png)

**Files (repo only — no system change yet):** `grub/pochita/{theme.txt,background.png,logo.png,jetbrains-bold-16.pf2,select_*.png,icons/}`, `grub/install.sh`, `grub/uninstall.sh`

**Install/revert (needs sudo — user runs):** `~/dotfiles/grub/install.sh` / `~/dotfiles/grub/uninstall.sh`

**Fix (same day):** First boot failed with `png.c:310: bit depth must be 8 or 16` — the generated background + recolored select_*.png were palette PNGs (sub-8-bit IHDR). Re-encoded ALL 77 theme PNGs to forced 8-bit truecolor RGBA (`magick -type TrueColorAlpha -define png:color-type=6 -define png:bit-depth=8`, via temp files). Verified with `file` = "8-bit/color RGBA". User to re-run install.sh.

## 2026-07-20 — Fix black-screen-after-lock (AMD s2idle suspend never wakes)

**Symptom:** Locked the PC + closed the lid, came back to a black screen — machine powered but display dead, forcing a hard power-off every time. Reboot history was full of `crash` entries.

**Root cause:** Closing the lid triggered `systemd-logind` suspend → `PM: suspend entry (s2idle)`, and the AMD **Barcelo** APU (`1002:15e7`) never resumed the display. BIOS only exposes `s2idle` (no deep S3 — `/sys/power/mem_sleep` = `[s2idle]` only), and s2idle resume is broken on this chip. 4 of the last 5 shutdowns ended immediately after `suspend entry (s2idle)` with no resume.

**Fix:** Created `/etc/systemd/logind.conf.d/nosleep.conf` → `HandleLidSwitch=lock`, `HandleLidSwitchExternalPower=lock`, `HandleLidSwitchDocked=ignore`, `IdleAction=ignore`. Restarted `systemd-logind` (session + xss-lock survived). Lid close / idle now just locks the screen (xss-lock picks up the logind Lock signal); the machine never enters the broken s2idle path. Verified live via `busctl`.

**Tradeoff:** Slightly higher idle draw (screen-off ~5–10W vs ~3W sleep), but this machine's s2idle barely saved power anyway. No more black screen / hard resets.

## 2026-07-18 — Stable Stremio: web UI + standalone streaming server (ditch buggy v1.x shell)

**What:** The Flatpak `com.stremio.Stremio` is the new v1.0.3 Rust/WebKitGTK shell — buggy (freezes, black video, background hangs). Flathub no longer retains v4.4 (only 8 commits, all v1.x). Downloaded the official v4.4.168 `.deb` from dl.strem.io → extracted (no install) into `~/.local/opt/stremio-4.4/`. Main Qt binary needs `libcrypto.so.1.1` + `libmpv.so.1` (absent on F43) — skipped that. Instead ran the extracted `server.js` (official streaming server) directly on system Node v22 → listening on `:11470`, found ffmpeg/ffprobe, detected external MPV/VLC. Paired with Stremio Web in Firefox = full stable playback, no old libs, no sudo.

**Why:** server.js only needs Node; sidesteps both the buggy shell and the old Qt/OpenSSL1.1/libmpv.so.1 dependency hell. Casting to native MPV avoids browser video issues entirely.

**Note:** streaming server currently started manually (`setsid -f node ~/.local/opt/stremio-4.4/tree/opt/stremio/server.js`). TODO: autostart via i3 exec_always or systemd --user unit. App data in `~/.local/opt/` + `~/.stremio-server/` (not dotfiles-tracked).

## 2026-07-18 — REAL CAUSE: picom use-damage artifact (not a Stremio bug)

**What:** After a screenshot, the "fuzzy" turned out to be a full-screen torn/static band at the top of the display when switching GPU apps (Firefox, Stremio) — a compositor artifact, NOT Stremio's window. picom v13 was running with `use-damage = true` + glx backend + gaussian blur on amdgpu, which leaves stale framebuffer garbage in "undamaged" regions after a fullscreen GPU app releases the screen. Fix: set `use-damage = false;` in `~/.config/picom/picom.conf`, restarted picom.

**Also:** the earlier Stremio flatpak overrides (`LIBGL_ALWAYS_SOFTWARE=1` etc.) were the WRONG fix — they caused BLACK video (working controls/audio, black picture) because forcing software GL breaks mpv's GPU video output. Reset with `flatpak override --user --reset com.stremio.Stremio`. Stremio now runs clean; picom fix handles the display artifact.

**Note:** live `~/.config/picom/picom.conf` is a real file, NOT a stow symlink — drifted from `~/dotfiles/picom/`. Needs reconciliation once the fix is confirmed.

## 2026-07-18 — Fix Stremio fuzzy/garbled window (WebKitGTK render glitch on AMD) [SUPERSEDED — see above]

**What:** Stremio's window rendered garbled/fuzzy (unreadable) on the AMD Barcelo iGPU. First tried `WEBKIT_DISABLE_DMABUF_RENDERER=1` alone — glitch RECURRED. Escalated to forcing full software rendering. Permanent override now carries all three:
```
flatpak override --user \
  --env=WEBKIT_DISABLE_DMABUF_RENDERER=1 \
  --env=WEBKIT_DISABLE_COMPOSITING_MODE=1 \
  --env=LIBGL_ALWAYS_SOFTWARE=1 \
  com.stremio.Stremio
```
Verified clean after relaunch. Undo: `flatpak override --user --reset com.stremio.Stremio`.

**Why:** WebKitGTK's GPU rendering path (DMABUF + compositing) glitches on this AMD iGPU inside the flatpak sandbox. DMABUF-only wasn't enough; `LIBGL_ALWAYS_SOFTWARE=1` (llvmpipe) forces CPU rendering so the GPU can't produce the artifact. Tradeoff: higher CPU, possibly choppy on high-res video — revisit if playback suffers. User-level override, no install.

**Launch caveat:** don't launch the flatpak GUI via a tracked background Bash task — killing the task kills the app. Use `setsid -f flatpak run ...` to detach.

**Still open:** (1) playback-freeze — user to toggle Settings → Player → Hardware-accelerated decoding OFF; (2) won't-quit/no-tray on i3+polybar (snixembed not in Fedora repos) — deferred, pragmatic keybind route recommended.

## 2026-07-18 — Kill stuck Stremio background processes

**What:** Stremio (Flatpak `com.stremio.Stremio`) stayed running after the window was closed — 5 processes including a WebKit render process at ~23% CPU and the Node streaming server. Ran `flatpak kill com.stremio.Stremio`; verified `pgrep -i stremio` returns none.

**Why:** Stremio launches with `--gapplication-service`, so closing the window leaves the background service alive. `flatpak kill` tears down the whole sandbox cleanly.

## 2026-07-09 — Fix Spotify silent-exit (stale singleton locks)

**What:** Removed stale `SingletonLock`, `SingletonSocket`, `SingletonCookie` symlinks from `~/.var/app/com.spotify.Client/cache/spotify/`. Spotify was launching then exiting immediately — same signature as the 2026-04-25 fix (no running process, but the three `Singleton*` links present from a 2026-06-30 session).

**Why:** Chromium's single-instance enforcement saw the leftover locks and self-terminated the new process. Documented in `.claude/dossiers/flatpak-spotify-singleton-lock.md`. Recurring issue.

## 2026-06-25 — Re-stow claude package (fix settings.json drift)

**What:** Ran `stow --adopt claude` from `~/dotfiles`. The live `~/.claude/settings.json` was a real file (not a symlink) and had drifted from the repo copy — it carried the correct current content (`"tui": "fullscreen"` plus the GitKraken cleanup) while the repo copy was stale. `--adopt` moved the live file into `~/dotfiles/claude/.claude/settings.json` and replaced it with a symlink.

**Why:** settings.json had become a standalone real file, so edits weren't flowing to the repo and `stow claude` would have conflicted. Verified before adopting that every other package file was byte-identical between live and repo (only settings.json differed), so adopt was non-destructive. After: the whole `claude` package is correctly linked — `CLAUDE.md`, `statusline.sh`, `settings.json` are file symlinks, and the five skill dirs (`council`, `handoff`, `learn`, `reflect`, `skill-creator`) are folded directory symlinks into the repo. Leaves `claude/.claude/settings.json` modified in git (uncommitted).

## 2026-06-25 — Uninstall GitKraken (full wipe)

**What:** Removed the system Flatpak `com.axosoft.GitKraken` (v12.0.1) via `flatpak uninstall --system --delete-data -y`, then deleted leftover home-dir data: `~/.gitkraken` and `~/.local/share/kraken`.

**Why:** User no longer wanted GitKraken installed and chose a complete removal. It was a system Flatpak (not an RPM), so removal went through Flatpak with `--delete-data` to clear the sandbox, plus manual cleanup of the two config/cache dirs Flatpak leaves in `$HOME`. Verified: no kraken entry in `flatpak list`, both home dirs gone.

**Follow-up:** GitKraken had also installed a Claude Code plugin (`gitkraken-hooks@gitkraken`) that registered a `gk ai hook run` command on every lifecycle event (SessionStart, UserPromptSubmit, PreToolUse, etc.). After the uninstall the `gk` binary was gone, so every prompt threw a hook error. Removed it fully: dropped `enabledPlugins` + `extraKnownMarketplaces` blocks from `~/.claude/settings.json`, deleted `~/.claude/plugins/marketplaces/gitkraken` and `~/.claude/plugins/cache/gitkraken`, and cleared the gitkraken entries from `installed_plugins.json` and `known_marketplaces.json`. All three JSON files re-validated. The hook only fed session activity to the GitKraken app — no loss of Claude Code functionality.

## 2026-06-16 — Alias `vagrant` to force `TERM=xterm-256color`

**What:** Added `alias vagrant='TERM=xterm-256color vagrant'` to `zsh/.zshrc` in a new Vagrant section between the git shortcuts (`alias lg='lazygit'`) and the FZF Catppuccin block.

**Why:** Host kitty sets `TERM=xterm-kitty` which SSH propagates to the guest. Remote bash readline mishandles kitty's extended keyboard protocol: typed characters echo doubled (`tmux` → `tmuxmux`), arrow keys produce literal escape sequences instead of cycling history. `kitty-terminfo` in the guest fixes screen drawing for full-screen apps (tmux/nvim) but the input garble happens at the outer bash shell before any of that helps. Cleanest fix is host-side — override TERM before SSH starts. Aliasing the `vagrant` command itself (not per-VM aliases) means every `vagrant ssh <name>` and any future Vagrant project gets the fix for free. Bash/zsh aliases aren't recursive, so the inner `vagrant` resolves to the real binary cleanly; `\vagrant` bypasses the alias if ever needed.

## 2026-06-15 — Add `kitty-terminfo` to VM provisioner

**What:** Appended `kitty-terminfo` to the apt install list in `vm/vagrant/kali/provision.sh`.

**Why:** Host kitty sets `TERM=xterm-kitty` and SSH propagates it. Without the kitty terminfo entry in the guest, `tmux` (and many other apps) refuse to start with `missing or unsuitable terminal: xterm-kitty`. The `kitty-terminfo` package installs `/usr/share/terminfo/x/xterm-kitty` — tiny package, big quality-of-life. Hit immediately on first `vagrant ssh kali1` test.

## 2026-06-15 — Auto-bootstrap tmux + nvim dotfiles in Kali VM provisioner

**What:** Extended `vm/vagrant/kali/provision.sh` to install `tmux`, `neovim`, `stow`, `git` and then, as the `vagrant` user, clone `https://github.com/tbsauce/dotfiles.git` into `~/dotfiles`, wipe any default `.tmux.conf` / `.config/nvim/` the Kali box ships, `stow tmux nvim` into `~/`, and pre-warm NvChad via `timeout 240 nvim --headless '+Lazy! sync' +qa` so the first interactive nvim launch is instant. Bootstrap block is idempotent (skips clone if `~/dotfiles` already exists) and timeout-guarded (lazy.nvim hang can't hang the whole provision).

**Why:** Sauce uses tmux + nvim everywhere as muscle-memory tools — manually re-cloning + stowing on every fresh HTB box would be friction that breaks the "throwaway VM" workflow. zsh + starship + the rest of the CLI stack deliberately excluded — pure aesthetic value in an SSH session, ~2 min cheaper provisioning, and bash works fine for HTB. Public-repo HTTPS clone avoids credential sprawl (no SSH keys in disposable VMs). Trade-off: provisioning grows from ~5 min to ~7 min; subsequent `vagrant ssh kali1` is instant with full muscle-memory env.

## 2026-06-15 — VM NAT fix (Docker breaks libvirt FORWARD) + `openvpn` in provisioner

**What:** (1) Created `vm/systemd/libvirt-docker-fix.service`: oneshot systemd unit that runs `After=docker.service libvirtd.service` and idempotently inserts two rules in iptables `DOCKER-USER` — `-i virbr0 -j ACCEPT` (VM egress) and `-o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT` (stateful VM ingress). Uses `iptables -C ... || iptables -I ...` so re-runs don't duplicate rules. (2) Added `openvpn` to `vm/vagrant/kali/provision.sh` apt-install list — fresh Kali VMs come ready to run the HTB lab VPN. (3) Patched top-level `README.md` Install block with the systemd unit install commands (`sudo cp` + `daemon-reload` + `enable --now`).

**Why:** Docker installs DOCKER-USER (FORWARD sub-chain) and sets FORWARD policy to DROP — libvirt VM traffic (192.168.122.0/24 → internet) gets blackholed because no rule covers it. Today's session burned ~30 min hitting this: provisioning failed twice with `E: Unable to locate package seclists` because the VM couldn't reach the Kali mirrors. Earlier attempt with `firewall-cmd --permanent --direct` failed: firewalld rebuilds the iptables ruleset on `--reload` and DOCKER-USER doesn't exist at that point (Docker creates it later), producing `iptables-restore: line 2 failed: No chain/target/match by that name` and leaving firewalld in `RUNNING_BUT_FAILED` state (recovered via `firewall-offline-cmd --direct --remove-rule` + restart). A systemd unit ordered `After=docker.service` waits until DOCKER-USER exists, applies idempotently, survives reboots, and doesn't fight firewalld.

## 2026-06-15 — Upgrade `vm/vagrant/kali/Vagrantfile` to multi-VM (3 slots)

**What:** Rewrote the Vagrantfile to define 3 predefined VM slots (`kali1`, `kali2`, `kali3`) via an iterator over a `VMS` array constant. All slots share the same config (kalilinux/rolling box, 6 GB / 4 vCPU, SPICE + virtio GPU + 64 MB VRAM, spice-vdagent channel, synced folder disabled, provision.sh shell provisioner) defined once in the loop body. Each slot has `autostart: false` so a bare `vagrant up` (no args) is a no-op — invocation must specify which slot.

**Why:** HTB workflow needs the ability to pause one VM (preserve state mid-challenge) and switch to another. Predefined slots show all three in `vagrant status` at once; numbered names keep them generic per challenge. Adding a 4th slot is a one-element edit to the `VMS` array. `autostart: false` prevents `vagrant up` from accidentally booting all three at once (each is 6 GB RAM).

## 2026-06-15 — Add `vm/` stow package: Kali HTB VMs via Vagrant + libvirt

**What:** Created `vm/vagrant/kali/Vagrantfile` (kalilinux/rolling box, 6 GB RAM, 4 vCPUs, SPICE graphics with virtio video + 64 MB VRAM, spice-vdagent channel for clipboard/resize, default `/vagrant` synced folder disabled to avoid NFS dependency) and `vm/vagrant/kali/provision.sh` (first-boot installer for `spice-vdagent`, `nmap`, `gobuster`, `ffuf`, `seclists`, `burpsuite`). Added `vm/.stow-local-ignore` matching `^vagrant$` so `stow vm` is a no-op (the package claims a slot in the for-loop but the Vagrantfile is invoked by absolute path, never symlinked into `~`). Patched top-level `README.md` "Dependencies" block with `sudo dnf install @virtualization vagrant vagrant-libvirt virt-manager virt-viewer libvirt-daemon-config-network spice-vdagent` + `systemctl enable --now libvirtd` + `usermod -aG libvirt $USER`. Added `.vagrant/` to `.gitignore` (per-VM state directory auto-generated next to the Vagrantfile).

**Why:** HackTheBox / CTF workflow needs throwaway Kali VMs that never trigger an installer — `vagrant destroy && vagrant up` rebuilds a clean box from the pre-built kalilinux/rolling image in ~5 min, zero clicks. vagrant-libvirt chosen over VirtualBox to avoid DKMS kernel-module churn on Fedora kernel updates; libvirt+KVM is in-kernel. Provisioner deliberately minimal (no ~3 GB `kali-linux-default` metapackage) to keep first-boot fast. No helper scripts and no `setup.sh` — matches the existing dotfiles convention of inline install in the top-level README. Helper scripts (`kali-fresh`, etc.), libvirt snapshot tooling, Parrot OS, and isolated networks explicitly out of scope for v1.

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

---

## 2026-06-27 — Kali VM memory footprint fix (anti-freeze)

**Problem:** `vagrant up kali1` froze the host (15 GB RAM); VM was set to 6144 MB + desktop apps → OOM thrash, forced hard reboot.

**Changed:**
- `vm/vagrant/kali/Vagrantfile` — lowered `v.memory` 6144 → 4096 MB (CPUs kept at 4); extracted `VM_MEMORY`/`VM_CPUS` constants. Added a `trigger.before :up` guard that reads `/proc/meminfo` MemAvailable and aborts boot if free RAM < VM_MEMORY + 2048 MB reserve.

**Verified:** `ruby -c Vagrantfile` → Syntax OK; `vagrant validate` → validated successfully.

**Note:** Takes effect on next `vagrant reload`/`up`; running kali1 untouched.

## 2026-08-03 — kali1 stuck restore recovery
- `virsh destroy kali_kali1` — force power-off (VM was stuck `running (restored)`, no SSH/IP)
- `vagrant up kali1` — fresh boot, got IP 192.168.122.33, SSH ready
- `vagrant upload traffic.pcapng → /home/vagrant/trafic.pcapng` (556132 bytes, verified in guest)
- Note: box update available (2026.1.0 → 2026.2.0), not applied

## 2026-08-27
- Installed Minecraft Java Edition launcher: `flatpak install flathub com.mojang.Minecraft` (v2.1.3, stable). Bundles its own Java runtime — no system JDK needed. Not a stow package; nothing added to the repo.
- Killed hung Minecraft launcher: `flatpak kill com.mojang.Minecraft` (launcher UI only, game not running — no world data at risk). Cause per launcher_cef_log.txt: CEF/GDK frame-clock + X WindowError under i3.
- Added i3 floating rule for Minecraft launcher (`for_window [class="(?i)minecraft launcher"] floating enable`) in `i3/.config/i3/config` after `default_floating_border`. Reason: CEF/Chromium launcher hangs when tiled (GDK frame-clock assertion + X WindowError). Validated with `i3 -C`, applied via `i3-msg reload`; existing window floated. Confirmed ~/.config/i3 is a stow dir-symlink, so source edit is live.
- Closed hung Minecraft launcher gracefully (i3 WM close ignored → SIGTERM worked). Removed stale Chromium locks `webcache2/Singleton{Lock,Socket,Cookie}` (dead-PID symlinks) per the Chromium-flatpak lesson.
- Diagnosed login-not-persisting: flatpak has NO dbus access (no session-bus / org.freedesktop.secrets) despite gnome-keyring running, so Chromium `os_crypt` has no encrypted_key and the cookie jar holds only 1 cookie. Proposed fix pending user approval: `flatpak override --user com.mojang.Minecraft --socket=session-bus --talk-name=org.freedesktop.secrets`.
- Applied flatpak override for Minecraft: `--socket=session-bus --talk-name=org.freedesktop.secrets` (verified: DBUS_SESSION_BUS_ADDRESS now set inside sandbox). Remaining bus errors are system-bus only = harmless.
- Installed Prism Launcher (`org.prismlauncher.PrismLauncher` v11.0.3) for modpack support. Microsoft login SUCCEEDS and PERSISTS there: accounts.json holds account "Shugu1" (MSA) with refresh+ygg tokens — solves the login-not-sticking problem. No instance created yet; Java auto-download enabled (AutomaticJavaDownload=true), MaxMemAlloc=4096.
- Built custom Prism instance "Sauce Pack": MC 1.21.1 + NeoForge 21.1.247, 31 mods (96MB), council-reviewed list. Create+CreateAddition+AE2+Pipez, Sophisticated Storage/Backpacks, QoL (JEI/Jade/FallingTree/CarryOn/Nemos Sorting/MouseTweaks/Waystones/Corpse/AppleSkin/Clumps), Aether, perf stack (Sodium/Lithium/FerriteCore/ModernFix/EntityCulling/DynamicFPS/ImmediatelyFast/Noisium), CC:Tweaked, Patchouli. Memory pinned 4096MB fixed + G1GC args; options.txt set to lang:pt_br, RD8/sim6, no vsync, no shaders. GOTCHA: initially pinned NeoForge 21.1.228 copied from an older instance — sophisticated* need >=21.1.229 and JEI >=21.1.238; bumped to 21.1.247 and it launches clean (0 dependency errors, sound engine started).
- Added VeinMiner (veinminer-neoforge-2.11.2+1.21.1) to "Sauce Pack" on user request — I had cut it on council advice re: FallingTree overlap, but user explicitly wanted vein mining. It is keybind-activated so the automatic-FallingTree conflict is unlikely; exclude logs in its config if double-breaking appears. Pack now 32 mods. FallingTree confirmed INSTANTANEOUS/WHOLE_TREE with SNEAK_DISABLE.
- "Sauce Pack" crash + fix: VeinMiner 2.11.2 crashed at pre-load with "needs language provider klf:1 or above". Adding Kotlin for Forge 5.12.0 did NOT satisfy it (KFF provides `kotlinforforge`, not `klf`) — crashed again. Removed both jars (moved to scratchpad, not deleted); game launches clean at 31 mods. LESSON: check a mod jar for exotic language-provider requirements before adding, and always relaunch-verify after adding any mod.
- "Sauce Pack" now 39 mods. Fixed VeinMiner properly: its jar declares `modLoader = "klf"` (KotlinLangForge), NOT kotlinforforge — installed KotlinLangForge 2.13.0 which declares modId="klf". Added TorchMaster + Full Brightness Toggle (+ required collective 8.39; default bind is key G, verified in options.txt). Added RightClickHarvest (+ required architectury 13.0.11, jamlib 1.3.6). Removed Sodium Dynamic Lights as redundant with fullbright and costly on the iGPU. WORKFLOW NOW: always `unzip -p <jar> META-INF/neoforge.mods.toml` to read modLoader + required deps BEFORE installing.
- "Sauce Pack" expanded to 47 mods (verified clean launch, 0 crash indicators). Added from a second councils advice: Terralith (+lithostitched), YUNGs Better Dungeons (+YUNGs API), Dungeons and Taverns (+apollib), Chunky (pregen), spark (profiler). Confirmed empirically that Create bundles Flywheel+Ponder as jar-in-jar (both appear in the loaded mod list though absent from mods/), so a naive outer-jar dependency scan reports them as false-positive missing.
- "Sauce Pack" 49 mods: swapped adventure content for dimensions+automation per user preference. REMOVED YUNGs Better Dungeons, YUNGs API, Dungeons and Taverns, apollib. ADDED Deeper and Darker, The Undergarden, Deep Aether (+aeroblender), Industrial Foregoing (+titanium). Verified clean launch, 0 crash indicators. Note: Aether mod ships an EMPTY pt_br.json (2 bytes) so it displays in English despite lang:pt_br.
- "Sauce Pack" final at 56 mods: added Mekanism + Generators + Tools, Mystical Agriculture (+Cucumber 8.0.16, NOT bundled - fetched separately). Switched options.txt to lang:en_us at user request (he reads English fine; the pt_br setting was an over-correction). All 5 new mods verified loaded, 0 crash indicators. GOTCHA: Mystical Agriculture declares deps with the legacy `mandatory=true` syntax, not `type="required"` - a parser looking only for type="required" misses them.
- "Sauce Pack" now 67 mods (271MB): restored YUNGs Better Dungeons/API + Dungeons and Taverns + apollib, and added Xaeros Minimap + World Map (xaerolib is BUNDLED jar-in-jar, no separate download), Towns and Towers (+cristel-lib), When Dungeons Arise, Explorers Compass, YUNGs Extras. SKIPPED Structory Towers: its jar is datapack-style with 1.21.5/1.21.11 overlays despite the API reporting 1.21.1 support - would not have worked. Still missing and worth adding: Create Power Loader (chunks unload when away, so farms stop).
- "Sauce Pack" final round -> 82 mods (293MB). Added: Create Power Loader (chunk loading for farms), Create Enchantment Industry (+CreateDragonsPlus), Steam n Rails, Applied Mekanistics, Productive Bees (productivelib bundled JiJ), Functional Storage, Controlling (+Searchables), Jade Addons, Effortless Building, Trash Cans (+supermartijn642 config/core libs), Ksyxis. Wrote a dependency-closure checker that reads META-INF/jarjar nested jars - without that, bundled libs (flywheel, ponder, xaerolib, productivelib) show as false-positive missing.
- Regenerated "New World" terrain: backed up to world-backups/New World-BEFORE-REGEN (851MB, 102 regions), then deleted all region/entities/poi .mca files except r.4.1 and r.4.2 (243 files removed). Kept 512x1024 blocks around the player at X=2303 Z=1028. World shrank 851MB -> 22MB. Untouched terrain now regenerates with Terralith + all structure/ore mods on first visit. NOTE: pgrep -f "java-runtime-delta" self-matches the invoking shell - must use the [j] bracket form to check if the game is really closed.
- Final audit of top-100 popular 1.21.1/neoforge mods vs installed set: no content gaps, but found 5 worth adding -> Sodium Extra, More Culling (+cloth-config), BadOptimizations, and VeinMiner Hotkey (slug veinminer-client, uses klf loader which KotlinLangForge already provides - the base veinminer mod does NOT ship a keybind on its own). Pack now 74 mods, dependency closure verified clean.
- Removed veinminer-client (hotkey/pattern GUI mod) from "Sauce Pack" - MY REGRESSION: I added it during the top-100 popularity audit assuming the base mod needed it for a keybind. It does not (settings.json has client.require=false), and adding it CHANGED activation from always-on to key-required plus a pattern-picker popup. Base veinminer with mustSneak=false is always-on, which is what the user had and wanted. Also cleared the staged copy in config/Veinminer/update/ (autoUpdate was already false). Pack now 73 mods.

## 2026-09-06 — System-wide light/dark theme switcher (Macchiato ⇄ Latte)
- Installed Catppuccin Latte GTK theme: downloaded `catppuccin-latte-blue-standard+default.zip` (v1.0.3, 276921 bytes, HTTP 200) from the official catppuccin/gtk GitHub release, unzipped into `~/.themes/`. User-level, no sudo. Matches the naming of the existing macchiato theme.
- Built `scripts/.local/bin/theme` (light|dark|toggle|apply|status) — swaps per-app `colors.*` symlinks + rewrites single flavor lines, then live-reloads kitty (SIGUSR1), i3, polybar, dunst, tmux, and rebuilds nvim base46 highlights. Sets `gsettings color-scheme`/`gtk-theme`/`icon-theme`, which is what makes Firefox + GTK apps follow via xdg-desktop-portal. State: `~/.local/state/theme/flavor`.
- Refactored configs to flavor-neutral includes (macchiato + latte variants committed, `colors.*` pointer gitignored): kitty (`include colors.conf`), i3 (`include colors.conf`), polybar (`include-file`), dunst (`dunstrc.d/50-colors.conf` drop-in), rofi (`@import "colors.rasi"` in all 3 themes), tmux (`source-file ~/.tmux/colors.conf`), yazi/lazygit (whole-file swap), zsh fzf colors (`~/.config/theme/fzf.sh`), gtk-3.0 settings.ini, bat/starship/flameshot (single-line rewrites). nvim chadrc reads the state file and picks base46 `catppuccin` vs `catppuccin-latte`.
- GOTCHA: i3 scopes `set $var` per file — variables do NOT cross an `include` boundary. The `client.*` lines that consume the palette had to move INTO the included colors file. Verified with `i3 -C` (0 errors, both flavors).
- Renamed rofi themes catppuccin-macchiato*.rasi -> catppuccin*.rasi (flavor-neutral); updated the 3 rofi-* scripts that referenced them.
- i3: added `bindsym $mod+Shift+t exec theme toggle` and `exec theme apply` at startup. Validated with `i3 -C`.
- Stowed scripts/zsh/tmux (new files: ~/.local/bin/theme, ~/.config/theme, ~/.tmux/colors*.conf).
- Added non-stow `firefox/` package (grub/ pattern): user.js + chrome/userChrome.css + install.sh; ran install.sh, symlinked into profile e51js0wg.default-release. GOTCHA: the authoritative profile is the `[InstallXXXX]` section's `Default=<path>`, NOT a `[ProfileN]` `Default=1` — this box has a stale 7st630zw.default carrying Default=1 that Firefox never opens.
- Updated README.md: new "Light / Dark Theme" section (usage, architecture, Firefox one-time step, i3 include gotcha), added $mod+Shift+t to the keybindings table, noted both GTK flavors + Papirus-Light in install steps, added theme-state/firefox-profile to Useful Paths.
- Added `theme apply --no-reload` for the i3 startup path (a mid-startup `i3-msg reload` re-fires exec_always and races polybar's own launch); i3 config uses the flag. polybar restart now uses `setsid` so the bar survives the invoking shell/keybind.
- TESTED: `theme light` / `theme dark` / `theme toggle` round-trip verified — all 9 colors.* symlinks repoint, bat/starship lines rewrite, gsettings flips, and `xdg-desktop-portal` ReadOne org.freedesktop.appearance color-scheme returns 2 (light) / 1 (dark), which is the signal Firefox follows. `i3 -C` valid for both flavors. Polybar confirmed alive after restart. System currently left in LATTE (light).
- PENDING USER ACTION: Firefox about:addons -> Themes -> enable "System theme — auto" (currently "Catppuccin Macchiato - Blue" add-on theme, which pins content-theme=0 and blocks all switching), then restart Firefox.

## 2026-09-06 — Light mode contrast + weight fix (council-reviewed)
**Problem:** user reported light mode text hard to read. Measured it: stock Catppuccin Latte accents run 2.3-3.3:1 against its own base #eff1f5 (median 2.8:1), where every Macchiato accent clears 5.2:1 on its base. An audit script found **53 foreground values below 3.0:1** across the latte configs. Worst: kitty color15 #bcc0cc at 1.61:1, color11 #eea437 at 1.86:1, color7 #acb0be at 1.91:1.

**Root cause:** Latte's accents were designed as hue-matched siblings of the dark flavors (fills/highlights), not as body text on a near-white background. Its ANSI mapping is a mechanical port: color7/color15 = surface2/surface1, which in Latte sit just *below* the background.

**Changed (all latte-only; macchiato verified byte-identical after):**
- Regenerated every `*-latte.*` file through a new OKLCH-darkened palette (hue held, <=8.1 deg drift, all accents >=4.5:1, decorative roles >=3.0:1). overlay0 maps to subtext0 — it cannot reach text grade without collapsing into subtext0.
- kitty `colors-latte.conf` rewritten: color7=#4c4f69 (text), color15=#2c2f42, and **"bright" (8-15) now means DARKER, not lighter** — on a light bg more contrast is darker. color8 is the deliberate exception (de-emphasis role; zsh-autosuggestions uses fg=8).
- Typography, latte-only: `text_composition_strategy 1.35 0` — kitty's man page states the first number "controls the thickness of dark text on light backgrounds... light text on dark backgrounds is affected very little", so it is asymmetric by design. Plus Medium face with all four faces pinned.
- starship latte palette replaced (prompt frame/❯ used overlay0 at 2.3:1); tmux separators 1.6->3.2:1; fzf pointer/marker/spinner 3.1->5.6:1; kitty/tmux/yazi borders raised to >=3.0:1 per WCAG 1.4.11.
- Audit after: **0 values below 3.0:1** (was 53).

**GOTCHA (silent, no error):** kitty's bare-string `font_family JetBrainsMono Nerd Font Medium` is NOT a family name — it falls back to Noto Sans Mono with no warning. Must use `font_family family="JetBrainsMono Nerd Font" style=Medium`. Verified via kitty's own resolver. Same trap in polybar: `...Nerd Font Mono Medium:size=10` falls back to NotoSans; use `:style=Medium:`.
**GOTCHA:** kitty `auto` italic does not follow a Medium base — it resolves to Regular Italic, thinner than surrounding roman text. All four faces must be pinned explicitly.
**GOTCHA:** `kitty --debug-config` is not a flag in 0.43.1; dump resolved options with `kitty +runpy` + `kitty.config.load_config`.
**Verified:** `kitty +runpy` shows latte resolving Medium/1.35/#4c4f69/#2c2f42 and macchiato resolving Regular/platform/dim 0.4/#b8c0e0. `i3 -C` valid both flavors.

**Known remaining:** bat's built-in "Catppuccin Latte" theme renders strings at 2.96:1 (compiled into bat, not our config). i3/rofi/polybar stay Regular weight — only the terminal got the weight bump, to avoid mixed weights across the desktop.
- Made `claude/.claude/statusline.sh` flavor-aware (reads the same state file). It hardcoded Catppuccin **Mocha** truecolor escapes, which bypass the terminal palette entirely — so the earlier ANSI fix could not touch it. Measured on #eff1f5: Opus amber #f9e2af = **1.12:1** (same luminance as the background), cyan #94e2d5 = 1.32:1, green #a6e3a1 = 1.31:1, dim #939ab7 = 2.46:1. Light branch now uses the corrected Latte set (all >=4.69:1); dark branch unchanged Mocha, verified byte-identical.
- Swept the repo for other flavor-blind hardcoded palettes: none remain. zsh has no ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE override so autosuggestions use fg=8 -> color8 #63667d (4.98:1).
- Fixed a fresh-clone bootstrap bug found while checking portability: `dunst/.config/dunst/dunstrc.d/` contains ONLY the generated (gitignored) pointer, so git cannot store the directory and it is absent on a new machine — `theme` then failed to create the dunst drop-in. `relink()` now does `mkdir -p` on the target dir. Verified with a fake-clone simulation (tracked + untracked-not-ignored files copied to a temp tree, no pointers): `theme apply` regenerates all 10 pointers correctly.
- README deploy section now documents `theme apply` as a REQUIRED post-stow step (configs `include` gitignored pointers absent from a clone) and notes grub/ + firefox/ are not stow packages.
- /reflect session: captured 8 lessons to .claude/rules/lessons.md (13 active, budget 20). Also corrected memory/hardware_peripherals.md frontmatter + MEMORY.md index which still said "USB-C only" while the body said 1x USB-C + USB-A.
- Committed + pushed as `a4c7628` "light/dark theme switcher (catppuccin latte + macchiato)" → origin/main (46 files). Verified before staging that no generated `colors.*` pointer was included and that the staged diff contained no secrets. `claude/.claude/settings.json` carried a pre-existing `theme: dark-daltonized → auto` change from the user's own /theme run; kept.
