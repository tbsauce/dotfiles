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
- Retuned ATM10SKY memory after it swapped 4GB: was -Xms6144/-Xmx6144 WITH AlwaysPreTouch (my error - that is dedicated-server tuning, it claims the whole heap at startup; RSS hit 7.22GB and 90% RAM with no world loaded). Now MinMemAlloc=2048 / MaxMemAlloc=5120, AlwaysPreTouch REMOVED, added UseStringDeduplication + SoftRefLRUPolicyMSPerMB. Also deduped instance.cfg (my edit script had appended a second JvmArgs key). Backups: instance.cfg.bak, instance.cfg.bak2.
- Fixed ATM10SKY instance.cfg after I corrupted it twice: my dedupe script sorted the file and kept the wrong duplicate `name=` (Prism then showed "Unnamed Instance"), and Prism re-added its own keys creating further dups. Resolution: restored instance.cfg.bak (clean original) and applied ONLY the memory change with targeted sed on existing keys. Final state verified: 1 name line, no duplicate keys, MinMemAlloc=2048 MaxMemAlloc=5120, no AlwaysPreTouch. LESSON: do not rewrite/sort a whole Prism instance.cfg - edit single keys in place with sed and diff against a backup, because Prism owns and rewrites that file.

## 2026-09-20 — autoclicker for Minecraft (X11)

- **Added** `scripts/.local/bin/autoclick` — toggleable xdotool autoclicker.
  Modes: `hold` (holds left button, for mining), `left`, `right`, `stop`, `status`.
  Bounded loop, hard stop after `AUTOCLICK_MAX_SECONDS` (default 1800), always
  releases mouse buttons on exit. Tunable via `AUTOCLICK_INTERVAL_MS` (default 100ms).
- **Stowed** `scripts` → symlink `~/.local/bin/autoclick` created (only new link).
- **Edited** `i3/.config/i3/config` — 4 bindings inserted above the brightness block:
  `$mod+F8` hold · `$mod+F7` left · `$mod+F6` right · `$mod+F5` stop.
  Chose `$mod+F*` deliberately: Minecraft uses bare F7 (light overlay) and F9
  (chunk borders), and i3 only grabs the Alt-modified combos, so nothing is stolen.
  Validated with `i3 -C` (exit 0), then `i3-msg reload`.
- **BLOCKED**: `sudo dnf install -y xdotool` denied by sandbox classifier — user must
  run it manually. Script exits with a clear message until then.

## 2026-09-25 — Stremio blank UI: WebKit GPUProcess never spawned (DMABUF renderer)

**Symptom:** Flatpak `com.stremio.Stremio` v1.0.3 opens its window but the content area
is blank/black — no catalogs, no posters.

**Ruled out (all healthy):** bundled streaming server v4.21.0 answering on :11470/:12470;
Cinemeta manifest 200 + api.strem.io reachable; libmpv 2.5.0 present in `/app/lib`;
`/dev/dri/{card1,renderD128}` + radeon Vulkan ICD visible inside the sandbox; no crash,
segfault or OOM in either journal. picom's `use-damage = false` fix from 2026-07-18 is
still in place and `~/.config/picom/picom.conf` now matches the repo copy byte-for-byte
(the July drift note is resolved). Nothing updated since Jul 8 — app, org.gnome.Platform/50
runtime, mesa 25.3.6 and kernel are all unchanged, so this is not an update regression.

**Root cause (evidence):** the app ran `WebKitWebProcess` + `WebKitNetworkProcess` but
**no `WebKitGPUProcess`** — that process does the accelerated compositing, so the page was
never painted. Relaunching with `WEBKIT_DISABLE_DMABUF_RENDERER=1` makes GPUProcess spawn.

**Actions:**
- `flatpak kill com.stremio.Stremio` — tore down the stuck instance (freed :11470).
- Relaunched detached: `setsid -f env WEBKIT_DISABLE_DMABUF_RENDERER=1 flatpak run com.stremio.Stremio`
  (detached per the July caveat: a tracked background Bash task dies with the task).
- **No persistent `flatpak override` written yet** — pending visual confirmation.

**Deliberately NOT used:** `LIBGL_ALWAYS_SOFTWARE=1`. Per 2026-07-18 that forces llvmpipe,
breaks mpv's GPU video output and yields black *video* (audio+controls fine). DMABUF disable
touches only WebKit compositing, not mpv.

**Still noisy in stderr (both pre-existing, harmless):** tray icon fails to register
(`StatusNotifierWatcher` not activatable — the known i3/no-snixembed gap) and
`Cannot load libcuda.so.1` (AMD box, no CUDA).

**Open question:** `ERROR stremio_linux_shell::app::webview: Failed to send message:
TypeError: undefined is not a function` — shell↔web-UI bridge error, may or may not matter.

**Fallback if the shell stays broken:** the 2026-07-18 known-good path is intact —
`~/.local/opt/stremio-4.4/tree/opt/stremio/server.js` present, node v22.22.2, firefox,
mpv 0.40.0. User chose manual start (no systemd unit) for that route.

## 2026-09-25 — Sauce Pack trimmed to near-vanilla + QoL (73 → 43 mods)

User got burned out on tech/skyblock; wants vanilla + quality of life, keeping backpacks,
Sophisticated Storage chest tiers/upgrades, and Mystical Agriculture for ores-without-mining.

- **Moved 30 jars** to `instances/Sauce Pack/minecraft/mods/disabled/` (moved, NOT deleted —
  reversible). Removed: AE2+GuideME, Create ×3, Industrial Foregoing+Titanium, Mekanism ×3,
  Pipez, CC:Tweaked, 5 dimension mods (Aether/Deep Aether/AeroBlender/Undergarden/
  Deeper and Darker), 8 adventure/structure mods (Dungeons Arise, YUNG's ×3, Dungeons and
  Taverns, Towns and Towers, Cristel Lib, Explorer's Compass), Waystones+Balm,
  Visual Workbench+Puzzles Lib, owo-lib (orphan).
- **Verified** 43 remaining jars have **zero missing required dependencies** — wrote a
  tomllib scanner that also reads `META-INF/jarjar/` bundled mods. First pass reported 8
  "missing" deps; all were false positives because the scanner ignored the NeoForge 1.21
  `type` field. Re-checked each toml: every one is `optional` or `incompatible`
  (Sodium→embeddium and Noisium→biox are *incompatibility* declarations, not requirements).
- **Edited** `instances/Sauce Pack/instance.cfg` via targeted `sed` only (Prism owns this
  file — never rewrite or sort it): `MinMemAlloc=1024`, `MaxMemAlloc=3072`,
  dropped `-XX:+AlwaysPreTouch`, added `-XX:+UseStringDeduplication`.
  Backup at `instance.cfg.bak-43mods`. Verified: 0 duplicate keys, 1 `name=` line.
- **Renamed** `saves/New World` → `saves/ARCHIVED-old-world-had-machines` (2.9 GB) so it
  can't be opened by accident — its chunks reference Mekanism/Create/AE2 blocks that no
  longer exist. User chose a fresh world. Kept Terralith (verified near-zero runtime cost;
  earlier lag was chunk generation).

## 2026-09-25 — Sauce Pack: added Apothic Spawners (43 → 45 mods)

- **Downloaded** to `instances/Sauce Pack/minecraft/mods/`:
  `Placebo-1.21.1-9.9.2.jar` (316 KB), `ApothicSpawners-1.21.1-1.4.0.jar` (127 KB).
  Both fetched from Modrinth API v2 and **sha512-verified against the API hash**.
- **Verified** both declare `modLoader="javafml"`, require NeoForge `[21.1.187,)` — instance
  runs 21.1.247 ✓ — and Apothic Spawners requires `placebo [9.9.0,)` ✓ (9.9.2 installed).
- **Why this mod**: user wanted craftable/movable spawners. Vanilla forbids both, and the
  obvious "change mob with a spawn egg" is useless in survival since spawn eggs are
  creative-only. Apothic Spawners closes that loop itself with the **Capturing** enchantment
  (max_level 3, `primary_items` = swords, listed in `minecraft:tags/enchantment/non_treasure`
  so it rolls on a normal enchanting table) — mobs drop their spawn egg on death.

## 2026-09-25 (evening) — Stremio still black after user updated Flatpak 1.0.3 -> 1.2.0

**User action:** ran `flatpak update` at 18:09-18:10 today. App went 1.0.3 (`b11b42ab`, Jul 6)
-> **1.2.0** (`7580e7db`, Aug 3); `org.gnome.Platform/50` also updated to a Sep 23 build
(which is where WebKitGTK lives). Window still blank/black afterwards.

**Revert question answered: reverting does NOT help.** The blank UI was diagnosed at ~10:51
this morning on 1.0.3 + the OLD runtime — i.e. it was already broken BEFORE either update, so
neither is the trigger. All four commits Flathub retains (Jul 6, Jul 20, Jul 23, Aug 3) are the
same v1.x Rust/WebKitGTK shell. Downgrade command if ever wanted:
`flatpak update --commit=b11b42ab35d16c22b387811b18417009e4526710ff326b89129bd11024ddae19 com.stremio.Stremio`

**Confirmed root cause of the blank window:** the v1.x shell has no local UI bundle — `/app/share`
carries no web assets and the binary contains `web.stremio.com`, so it loads the ENTIRE UI into a
WebKitGTK webview. The page is reachable from inside the sandbox (index 200/10759 B, main.js
200/10119325 B, worker.js + main.css 200) but never executes:
`ERROR stremio_linux_shell::app::webview: Failed to send message: TypeError: undefined is not a function`.
Identical error under all three render configs tried, so it is not a rendering knob:
- `WEBKIT_DISABLE_DMABUF_RENDERER=1` — DOES fix the missing `WebKitGPUProcess` (it now spawns),
  but the UI stays blank. Worth keeping in mind: the absent GPUProcess was a real, separate defect.
- `+ WEBKIT_DISABLE_COMPOSITING_MODE=1` — no change.
- `+ WEBKIT_FORCE_SANDBOX=0` (WebKit's nested sandbox inside flatpak) — no change.
**No flatpak override was ever written** — all three were one-shot `setsid -f env ...` launches.

**Working setup restored (the 2026-07-18 path):**
- `flatpak kill com.stremio.Stremio` (note: takes ~8s to fully exit, two polls needed).
- `setsid -f node ~/.local/opt/stremio-4.4/tree/opt/stremio/server.js` -> :11470, v4.20.8,
  found /usr/bin/ffmpeg + ffprobe, registered **MPV and VLC** as external cast targets.
  Log now at `~/.stremio-server/server.log`.
- `firefox --new-tab https://web.stremio.com/` — UI connected, 17 requests hit the server.
- User chose manual start; no systemd unit created.

**GOTCHA — the :12470 HTTPS endpoint is dead** on BOTH server builds (4.20.8 and the flatpak's
4.21.0): `HTTPS: Request error Could not get a valid HTTPS certificate`, curl gets TLS
`unexpected eof`. It does not block this setup: Firefox treats `http://127.0.0.1` as a
potentially-trustworthy origin (since FF84), so the https web UI reaches the plain-http server
on :11470 without mixed-content blocking. Don't chase the cert.

**Note:** server's hw-transcode probe found **no viable acceleration profile**
(`vaapi-renderD128` tests failed), so transcoded playback is CPU-bound — cast to MPV to
direct-play and skip transcoding entirely.

## 2026-09-25 (evening, cont.) — ROOT CAUSE: system has no h264/hevc decoders (Fedora ffmpeg-free)

**The blank Stremio window and the "never plays" were TWO SEPARATE faults.** The second one is
the real blocker and has nothing to do with Stremio:

`ffmpeg -decoders` on this machine: **h264 MISSING, hevc MISSING, eac3 MISSING, vc1 MISSING**
(ac3, aac, vp9, av1, mpeg4 present). Installed: `ffmpeg-free-7.1.5` + `libavcodec-free-7.1.5`
(Fedora's patent-stripped build). NOT installed: `ffmpeg`, `libavcodec-freeworld`,
`mesa-va-drivers-freeworld`. **RPM Fusion free/nonfree + updates are already enabled.**

Every layer failed for this one reason — Firefox can't decode H.264/HEVC, mpv can't
(`Failed to initialize a decoder for codec 'hevc'` / `'eac3'`), and the Stremio server can't
transcode around it because `/usr/bin/ffmpeg` lacks the decoder as well. It also explains the
earlier `no viable acceleration profiles detected`: `mesa-va-drivers` has H.264/HEVC VAAPI
disabled on AMD; `mesa-va-drivers-freeworld` is the RPM Fusion build that enables it.
Corroboration: YouTube plays fine for the user because YouTube serves VP9/AV1, both present.

**Proposed fix (NOT run — needs explicit permission + sudo):**
```
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
```

**Diagnostics proven along the way (all healthy, rule these out in future):**
- BitTorrent works: CC-licensed Big Buck Bunny test hit 42 peers / 33 unchoked and pulled
  409600 B at ~80 KB/s. Peer discovery, DHT and trackers are all fine.
- The user's own stream (Spider-Noir S01E03 720p **HEVC** x265, eac3 audio) resolved and had
  already cached its first 5 MB locally — serving it back at 274 MB/s from
  `~/.stremio-server` with `downloaded: 0`. So the torrent side worked all along.
- Firefox <-> local server has NO mixed-content problem: the https web UI successfully drove
  `http://127.0.0.1:11470` (engine create + ~50 stats.json polls). Confirms the FF84+
  loopback-is-trustworthy behaviour; the dead :12470 cert is a red herring.
- Tailscale is Running but **ExitNode: None**, default route is direct via wlp1s0 — no VPN
  interception.

**GOTCHA for diagnosing torrents:** `stats.json` showing `down=0` with `selections:[]` does NOT
mean a dead swarm — EngineFS only fetches pieces once a file is actually requested. Pull a byte
range from `/<infoHash>/<fileIdx>` to force selection before judging swarm health. Equally, a
huge instant speed means a CACHE hit, not a fast swarm — check `downloaded` in stats to tell them apart.

## 2026-09-25 (evening, resolved) — Codec swap applied; playback verified end-to-end

**User ran (approved):**
```
sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
```
Result: `ffmpeg-7.1.5` + `mesa-va-drivers-freeworld-25.3.6` installed; `ffmpeg-free` and
`mesa-va-drivers` removed. All decoders now PRESENT: h264, hevc, eac3, vc1, ac3, aac, vp9, av1.

**Verified working (not assumed):**
- mpv on the real stream: `Using hardware decoding (vaapi-copy)` on hevc 1330x720 + eac3 6ch,
  zero decoder errors. (`Cannot load libcuda.so.1` is harmless — no NVIDIA in this laptop.)
- Server-side transcode, which previously could not run at all: `/hlsv2/.../video0.m3u8`
  with `profile=vaapi-renderD128` now returns a valid playlist, and the segments are real —
  `init.mp4` 872 B + `segment1.m4s` 1237710 B at 2.2 MB/s, ffprobe reports **h264 1280x692**.
  So the HEVC -> H.264 path Firefox depends on is confirmed working.
- Standalone server restarted on :11470 (v4.20.8), MPV + VLC registered, and the live Firefox
  tab reconnected to it on its own (seen polling stats.json for the episode's infoHash).

**Still broken / unchanged:** the Flatpak v1.2.0 shell window is still blank — that is the
separate WebKit defect from earlier today and the codec fix does not touch it. Use the Firefox
tab. The flatpak's own bundled server was seen running but never bound :11470, so leaving the
app open just risks a port fight — close it.

**GOTCHA (cost a dead shell):** `pkill -f 'stremio-4.4.*server.js'` killed the Bash tool's OWN
zsh wrapper, because the wrapper's command line contains the pattern being matched (exit 144).
Kill node helpers by PID from `pgrep -af ... | grep -v 'zsh -c'`, never with a broad `pkill -f`.

**Restart after reboot (manual by user's choice):**
`setsid -f node ~/.local/opt/stremio-4.4/tree/opt/stremio/server.js`

## 2026-09-25 (night) — Native app: stale-cache 404 FIXED, repaint bug remains

**Fix #1 (worked): stale WebKit HTTP cache.** `--dev` dev-tools console showed the real error:
the app loads its UI via `http://127.0.0.1:11470/proxy/d=https%3A%2F%2Fweb.stremio.com/`
(its default `--url`), and every asset 404'd against build hash `6ed4463d94baf...`, a build
Stremio has deleted from their CDN. Proof: upstream `/6ed4463d.../scripts/main.js` -> 404 while
`/a6b71620.../scripts/main.js` -> 200, and the proxy's own HTML correctly references a6b71620.
The stale index.html was cached in `~/.var/app/com.stremio.Stremio/cache/stremio/WebKitCache/`.
**Deleted that dir (65M, user approved)** -> app now loads for real: posters, cards, play button
all render. This is why no render/GPU knob ever helped and why update/reinstall can't fix it —
the bad copy lives in app cache, which neither touches.

**Fix #2 (worked): WebKitWebProcess SIGABRT.** `ANOM_ABEND sig=6`, core dump 43.9M. Stack:
`abort()` <- libwebkitgtk-6.0.so.4.19.3 <- JIT frames <- libjavascriptcoregtk — an abort during
JIT'd JS, not a GPU fault. **`JSC_useJIT=0` eliminates it** (0 aborts since; costs JS speed).

**UNRESOLVED: partial repaint.** Only regions that receive input events paint; rest stays black
(user screenshots show correct poster art in patches). Ruled out, each tested and still patchy:
- `WEBKIT_DISABLE_DMABUF_RENDERER=1` (does fix the missing WebKitGPUProcess, but not painting)
- `WEBKIT_DISABLE_COMPOSITING_MODE=1`
- `JSC_useJIT=0` (fixes the crash only)
- `GSK_RENDERER=cairo` (GTK4 software renderer)
- **picom stopped entirely** — still patchy, so NOT the compositor this time (unlike 2026-07-18).
  picom restarted identically: `picom --config ~/.config/picom/picom.conf`.
- i3 fullscreen toggle (forces full re-damage) — still patchy, so not a tiling/resize bug.

**Context the user had forgotten:** the 2026-07-18 entry already called this v1.x shell "buggy
(freezes, black video, background hangs)" — the Firefox route exists BECAUSE of that. The app
has been broken since the Qt->WebKit switch; today's update did not cause it.

**Only untested lead:** downgrade `org.gnome.Platform//50` (system install) from the Sep 23
build to an earlier commit, e.g. `545da92354a265d2c3572c91c39ac14dd7e74f9d8f9b66744ad50f478d2497c5`
(Aug 23) or `de3b0b88...` (Aug 2). Affects every flatpak on that runtime; needs sudo/polkit.

**GOTCHA:** `pgrep -f`/`pkill -f` with a pattern also matches the Bash tool's own zsh wrapper and
kills the shell (exit 144) — hit twice. Anchor it: `pgrep -f '^/app/libexec/stremio/stremio'`.
**GOTCHA:** `import -window root` + i3 rect coords is unreliable while the user is switching
workspaces — captured Firefox twice and nearly misreported it as a fix. Confirm the focused
workspace in the SAME call as the capture, or just ask the user.

## 2026-09-25 (night, RESOLVED) — Native Stremio fixed: WebKitGTK 4.19.3 regression in GNOME runtime

**ROOT CAUSE of the repaint bug + crash: the org.gnome.Platform//50 runtime build of 2026-09-23
(WebKitGTK 4.19.3).** Downgrading the runtime to the 2026-08-23 build (**WebKitGTK 4.16.9**)
fixed everything at once — full correct painting, no SIGABRT, and `WebKitGPUProcess` now spawns
BY ITSELF with **no env vars at all** (previously it only appeared with
`WEBKIT_DISABLE_DMABUF_RENDERER=1`, which was a symptom of the same regression).
The user's original "maybe an update broke it" instinct was right — just the RUNTIME, not the app.

**Command that worked:**
```
sudo flatpak update --commit=545da92354a265d2c3572c91c39ac14dd7e74f9d8f9b66744ad50f478d2497c5 org.gnome.Platform//50
```
**Blast radius: nil** — `com.stremio.Stremio` is the ONLY app on this machine using
org.gnome.Platform//50 (verified by walking every installed app's Runtime field).

**GOTCHA — downgrade targets expire twice over:** the Aug 2 commit (`de3b0b88...`) failed with
`GPG verification enabled, but no signatures found` — Flathub prunes old signed objects even
though `remote-info --log` still LISTS the commit. And the previously-deployed runtime was gone
from disk too (`/var/lib/flatpak/runtime/.../50/` held only the new commit; the update pruned the
old deployment). So a rollback must happen while a target is still fetchable. `flatpak remote-info
flathub <ref> --commit=<hash>` is the cheap availability probe before committing to a 400MB pull.
Available at time of fix: Sep 22, Sep 19, Sep 10, Aug 23. NOT available: Aug 2 and older, incl.
the Jun 21 build the user had actually been running.

**MUST PIN:** the next `flatpak update` will pull the runtime forward again and re-break the app:
`sudo flatpak mask org.gnome.Platform//50`  (undo: `sudo flatpak mask --remove org.gnome.Platform//50`)
Revisit when a runtime newer than Sep 23 ships a WebKit past 4.19.3.

**Full picture of today — THREE independent faults, all now fixed:**
1. System had no h264/hevc/eac3 decoders (Fedora ffmpeg-free) -> nothing could play anywhere.
   Fixed by RPM Fusion swap.
2. Stremio's WebKit cache held a dead build hash -> every UI asset 404'd -> blank window.
   Fixed by deleting `cache/stremio`.
3. WebKitGTK 4.19.3 regression -> partial repaint + SIGABRT. Fixed by runtime downgrade.
Each masked the next, which is why this took so long to unpick.

## 2026-09-25 — New instance "Sauce OneBlock" (46 mods)

User wanted a OneBlock world with the same near-vanilla pack. Built as a SEPARATE instance
so the open world in "Sauce Pack" is untouched.

- **Created** `instances/Sauce OneBlock/` (43 MB) by copying only `instance.cfg`,
  `mmc-pack.json`, `minecraft/{mods,config,options.txt}` from Sauce Pack — deliberately NOT
  `saves/`, `xaero/`, `logs/`, `crash-reports/`, or `mods/disabled/`. Reset the
  lastLaunchTime/lastTimePlayed/totalTimePlayed counters; `name=Sauce OneBlock`.
- **Downloaded** `neoblock-neoforge-1.21.1-0.8.0-Beta.jar` (792 KB) from Modrinth,
  **sha512-verified**. Requires NeoForge `[21.1.128,)` and MC `[1.21.1, 1.21.3]` — instance
  is 21.1.247 / 1.21.1 ✓. No other dependencies. Ships a **world preset**
  (`data/neoblock/worldgen/world_preset/neoblock.json`), so it only applies to worlds
  created with that world type.
- **Why it was needed**: verified that **no recipe in Mystical Agriculture produces a
  Prosperity Shard** — it drops only from Prosperity Ore, which is worldgen-only. On a plain
  OneBlock that softlocks the entire mod (no shard → no seed base → no seeds). Soulstone/
  Soulium and dungeon spawners have the same problem.
- **Extracted** the mod's `configs/` to `minecraft/config/neoblock/` (path derived from
  `IConfig.class`: `ResourceUtil.pathOf("neoblock", ...)`) and **patched the tier block
  tables** so those ores actually appear:
  - tier-1: +inferium_ore
  - tier-2: +inferium_ore ×2, +prosperity_ore
  - tier-3: +deepslate_prosperity_ore ×3, +deepslate_inferium_ore ×3, +soulstone ×2,
    +soulium_ore, +minecraft:spawner
  - tier-4: +soulium_ore
- **Caught my own bug**: first patch wrote `"id"  # comment,` — TOML treats `#` as
  comment-to-end-of-line, so the array separator was swallowed. Rewrote to put the comma
  before the `#`, then **validated every file with `tomllib`**: all 7 tier files + chests/
  config/sequences/tags/trades parse OK. `tier-template.toml` fails to parse, but a `diff`
  against the jar shows it is byte-identical to what the mod ships — pre-existing, untouched.

## 2026-09-25 — Sauce OneBlock: dropped Terralith (46 → 43 mods)

- **Read all three NeoBlock world presets.** In every one the Overworld is
  `minecraft:flat` with a single `minecraft:air` layer, and the Nether uses vanilla
  `multi_noise`/`minecraft:nether`. Terralith only edits Overworld biomes, so it has
  nothing to act on — pure dead weight (2051 json files loaded for no effect).
- **Moved to `mods/disabled/`**: Terralith, Lithostitched, Apollib. Verified with the
  dependency scanner that lithostitched is required only by Terralith and apollib only by
  lithostitched, so nothing else breaks.
- **Preset guidance given**: `neoblock` = void Overworld + REAL Nether + real End;
  `neoblock_no_nether` = Nether is also void; `neoblock_oceans` = Overworld is an infinite
  ocean over gravel/bedrock. Recommended plain `neoblock` so the Nether stays a real
  dimension (keeps Veinminer, Xaero maps and exploration meaningful).

## 2026-09-25 — Sauce OneBlock: added Only Paxels (43 → 44 mods)

- **Downloaded** `onlypaxel-1.21.1-0.3.jar` (43 KB) from Modrinth, **sha512-verified**.
  Requires NeoForge `[21,)`, MC `[1.21.1,1.22)`. No dependencies.
- **Compared three candidates** first by unzipping each: Only Paxels (174k dl, shaped —
  3 tools + 2 sticks), Paxels for Dummies (6k dl, shapeless — literally just the 3 tools),
  Simplest Paxels (39k dl, shaped + smelt-back-to-nuggets). All three ship the *same* six
  tiers (wood→netherite) and none support modded tool materials, so picked on adoption.
- **Installed while the game was running** — safe because mod jars are only read at startup;
  deliberately did NOT touch options.txt or instance.cfg, which Prism/MC rewrite on exit.
  Takes effect on next launch.
- **CONFIRMED the NeoBlock config path guess was correct**: the running game created
  `config/neoblock/schematics/` at 20:58, proving the mod reads `config/neoblock/` — the
  same folder the patched tier-*.toml files were placed in. The Mystical Agriculture ore
  additions are live, not ignored.

## 2026-09-25 — Sauce OneBlock: added Squat Grow (44 → 45 mods)

- **Downloaded** `squatgrow-neoforge-21.1.4+mc1.21.1.jar` (43 KB), **sha512-verified**.
  308k downloads. Crouch near plants to force growth ticks.
- **Dependency check**: its toml declares `architectury required = true, versionRange
  [13.0.1,)`. Instance already ships `architectury-13.0.11-neoforge.jar` ✓ — no extra jar
  needed. (ATM10SKY carries 21.1.2; took the newer 21.1.4 from Modrinth.)
- Adds keybind `key.squatgrow.toggle` (unbound by default in this instance's options.txt —
  user must bind it in Controls if they want the on/off toggle; the crouch behaviour itself
  works with no binding).
- Installed while the game was running; takes effect on next launch.

## 2026-09-25 — autoclick: added squat + dig modes

User wanted the autoclicker to drive Squat Grow (which needs Shift tapped repeatedly, not
held) and optionally mine at the same time.

- **Edited** `scripts/.local/bin/autoclick`: new modes `squat` (tap Shift on a loop) and
  `dig` (hold left mouse button AND tap Shift). New tunable `AUTOCLICK_SQUAT_MS`
  (default 150 = ~3 squats/sec). `release_buttons()` now also sends `keyup Shift_L`, so a
  stop can never leave the player stuck crouching.
- Used the explicit X keysym **`Shift_L`**, not xdotool's `shift` modifier alias —
  verified against `xmodmap -pke` (keycode 50 = Shift_L).
- Replaced `[ "$mode" = "dig" ] && xdotool mousedown 1` with an explicit `if` block: under
  `set -e` a bare `test && cmd` list is a footgun when the test is false.
- Loop is bounded by `MAX_SECONDS` like the other modes — cannot run away.
- **Edited** `i3/.config/i3/config`: `$mod+F9` = squat, `$mod+F10` = dig. Validated with
  `i3 -C` (exit 0), reloaded. Script is a stow symlink so the edit was live immediately.
- xdotool confirmed installed (3.20211022.1) — the user ran the blocked dnf command.

## 2026-09-25 — autoclick: `farm` mode (right-click + squat)

User corrected the request: wanted RIGHT-click combined with Shift, not left.

- **Added** mode `farm` to `scripts/.local/bin/autoclick`: taps Shift on a loop and
  right-clicks once per cycle. Refactored the squat branch from an `if` into a `case` so
  squat/dig/farm share one bounded loop.
- **Design detail**: the right-click fires only while Shift is **released**. Sneaking in
  Minecraft suppresses block interaction (a sneak-right-click places the held item instead
  of using the block), so clicking mid-crouch would break Right Click Harvest. Interleaving
  gives both the growth ticks and clean harvest clicks.
- **Rebound** `$mod+F10` from `dig` to `farm` in `i3/.config/i3/config`. `dig` is still
  available from the terminal. Validated with `i3 -C`, reloaded.

## 2026-09-26 — autoclick: squat/farm loop made ~2.4x faster

- **Rewrote** the squat/dig/farm loop in `scripts/.local/bin/autoclick` to use ONE chained
  `xdotool` invocation per cycle (`keydown Shift_L sleep D keyup Shift_L [click 3] sleep D`)
  instead of 3 xdotool processes plus 2 shell `sleep` processes. Benchmarked: 10 cycles at
  60ms took 1.23s chained vs 1.31s unchained — ~3ms/cycle overhead instead of ~11ms.
- **Lowered** default `AUTOCLICK_SQUAT_MS` 150 → 60. Cycle is now ~123ms ≈ **8 squats/sec**
  (was ~3.3/sec).
- **Did NOT go below 60ms on purpose**: Minecraft ticks every 50ms, so a shorter hold risks
  the sneak toggle landing inside a single tick and being dropped entirely — faster input
  would yield *fewer* registered squats. Documented the floor in the script header.

## 2026-09-26 — autoclick: farm mode much faster (user override)

I had argued 60ms was the floor because Minecraft ticks every 50ms. User said to make it
faster anyway — their call, they are the one watching it in game.

- **Lowered** default `AUTOCLICK_SQUAT_MS` 60 → 30.
- **Decoupled the click rate from the squat rate** — the real bottleneck. Farm mode now
  fires `click --repeat $CLICKS --delay $CLICK_GAP_MS 3` inside the same chained xdotool
  call. New knobs: `AUTOCLICK_CLICKS` (default 3), `AUTOCLICK_CLICK_GAP_MS` (default 15).
- Measured cycle: 108ms → **~9.3 squats/sec and ~27.8 right-clicks/sec**
  (was 3.3 and 3.3 before today).
- Note kept for future reference: if squats stop registering, the sneak toggle is landing
  inside a single 50ms game tick — raise AUTOCLICK_SQUAT_MS back toward 60. The click rate
  is unaffected by that and can stay high independently.

## 2026-09-26 — Sauce OneBlock: trader/chest economy rebuild (council-designed)

World was maxed (BlockCount 3300, all 7 tiers researched). A 5-seat council reviewed the
configs and the decompiled jar; the original plan (add tier-7..10) was **abandoned** —
`WorldManager.load` flags status UPDATED when the saved Tiers list is shorter than the
config list, and `BlockManager.updateBlock` then places BEDROCK, freezing the world until
`/neoblock force stop` + `/neoblock force setblock`. Rebuilt the trader/chest economy
instead, which is hash-stable (tier hash = id + unlock requirements only).

- **Backup**: `config/neoblock.bak-preTraderRebuild/` (92K). Restore = one `cp -r`.
- **tags.toml**: +3 random pools — `tribute` (20 farm/mob drops), `relic` (8 trip items),
  `trophy` (14 toys/vanity). `#neoblock:<list>` resolves to ONE random member per trader
  spawn and works in a trade's result or either cost slot — this is the user's own
  "random block for diamonds" idea, no mods needed.
- **trades.toml**: +4 groups — `neo-floor` (spawn guarantee), `neo-lottery` (random-tribute
  costs), `neo-vault` (priced in soulium_dust), `neo-revived` (13 offers rescued from the
  dead `[on-research]` blocks).
- **tier-1..6**: added `%` to offers (only **4 of 137** lines had one before, which is why
  every trader looked identical). Fixed a shipped bug: `tier-2.toml` referenced
  `trade:most-saplings`, which is not defined in trades.toml → repointed to `saplings-1`.
  tier-6 gained the four new groups, with `neo-floor` left unconditional because NeoBlock
  spawns no trader at all if every offer fails its roll.
- **chests.toml**: `casual-chest` pool widened 5 → **36** items (min/max kept 2-4, so the
  variety comes from the pool). It was the ONLY chest still reachable — tier1/tier2/tier4
  chests are `starting-blocks`, which fire once at unlock and never again. Added `neo-lucky`.
- **Chests returned to rotation**: `neo-lucky` → tier-3 blocks, `tier4-chest` → tier-4
  (restores blaze rods / ender pearls), `casual-chest` → tier-5, all at weight 2.
- **config.toml**: +2 global `[on-every-N-blocks]` streams (2000, and 5000 offset 2500).
  A global event carrying `trades` spawns its OWN trader under a different entity tag, so
  it bypasses the one-trader-at-a-time check — an endless trader stream with no tier ladder.
- **Currency correction**: council priced jackpots in `mysticalagriculture:soulium_ore`, but
  the loot table shows that block only drops itself under Silk Touch — normal mining yields
  `soulium_dust`. Repriced in dust, else the trades would have been unpayable.
- **Verified**: all 20 TOML files parse; 0 missing trade-group refs; 0 missing `#neoblock:`
  tags; all 6 `[unlock]` blocks byte-identical to backup; tier count still 7.
  (`tier-template.toml` still fails to parse — ships that way, inert, untouched.)

## 2026-09-26 — Sauce OneBlock: council round 3 fixes (v2)

Second backup before changes: `config/neoblock.bak-v1/` (v1 build);
`config/neoblock.bak-preTraderRebuild/` is still the original.

Four real defects found by auditing the SHIPPED build, all verified independently:

- **Chest truncation (worst).** The chest roll walks its item list **in order and stops at
  `max`**, so the 9 rare items I appended to the bottom of `casual-chest` were being
  truncated away. Simulated 200k rolls: diamond fired **2.00%** at max=4 vs 3.94% at max=8.
  Fixed by **reordering rares to the top** rather than raising max — the Slot Machine seat
  wanted max=8, but the Economy and Burnout seats showed that inflates supply. Reordering
  fixes the bug at zero inflation. Verified after: diamond 4.01%, e-gapple 1.00%.
- **Chest spam.** Measured 106 chests/hour. Removed my own tier-5 `casual-chest` addition
  (it was nearly half the total) → **67/hr**.
- **Trader offer wall.** `tier-template.toml:36` — trades are the **union of every enabled
  tier**, and all 7 are enabled, so the v1 percentages stacked to ~10.7 expected offers,
  10.6 of them commons. Lowered per-tier percentages to land near 6 offers.
- **Vault arbitrage.** Three of four `neo-vault` items were purchasable elsewhere for
  diamonds — which Mystical Agriculture grows as a crop — so soulium dust bought nothing.
  Removed the duplicate shulker-shell and trophy lines, moved budding_amethyst in, repriced
  `tier-5`'s trims offer in dust. `neo-vault` is now 3 dust-only lines.
- Also: XP-bottles-for-cobblestone uses 6-10 → 2-3 (~110/hr off a free resource);
  wind_charge uses 32-64 → 4-8; `[on-every-2000-blocks]` → 3000 (2000 = exactly two per
  60-min session, a learnable metronome); tribute pool lost `ink_sac` (squid need an ocean
  biome; void platform) and `red_mushroom` (still vended 1x elsewhere) for copper_ingot/flint.
- **Elytra** retuned to one offer per **3.9 h** (was 8.8) — stream `neo-vault` 35%→60%,
  tier-6 6%→10%, vault narrowed to 3 lines.

**Refuted two council claims by checking the save**: `doMobSpawning` is **true** in
level.dat (tier-1's on-unlock set it), and the world's Nether is
`generator.type=minecraft:noise / settings=minecraft:nether` — a REAL Nether, not the
`no_nether` void preset the agent assumed. So blaze rods / ghast tears / magma cream are
obtainable and the `relic` pool is sound. (DIM-1 and DIM1 have 0 region files — never visited.)

Own bug caught mid-edit: `line.split("#")` split on the `#` in `#neoblock:trims` and
destroyed tier-5's trims offer; repaired and repriced.

Validation after: 0 parse failures, 0 missing trade groups, 0 missing tags.

## 2026-09-26 — Sauce OneBlock: villagers, spawn eggs, spawners (v3)

Backup before this change: `config/neoblock.bak-v2/`.

- **Found the gap**: the traders sell 18 animals and **zero villagers**, and a void overworld
  has no villages — so villagers (and therefore librarian Silk Touch, which is what picks up
  a spawner) were unobtainable except by curing a zombie villager.
- **tags.toml**: +`eggs` pool, 14 hostile spawn eggs. Verified against Apothic Spawners'
  `data/apothic_spawners/tags/entity_type/blacklisted_from_spawners.json` — only `warden`,
  `elder_guardian` and `#c:bosses` are banned, so passive mobs would work too; left them out
  deliberately since the trader already sells the animals and breeding is free.
- **trades.toml**: +`neo-menagerie` — villager (16-24 emerald + 2-4 relic), random spawn egg
  (4-6 soulium dust), spawner (12-16 dust + 2-4 relic). All dust-priced so the autoclicker
  cannot rush them.
- Wired at 12% on tier-6 and 40% on the 5000-block stream → any one line offered roughly
  once per 3.9 hours.
- Validated: 0 parse failures, 0 missing groups, 0 missing tags.

## 2026-09-26 — Sauce OneBlock: FallingTree paxel fix + 3 mods from Oneblock Ultimate (45 → 51)

- **FIXED: paxel would not fell trees.** Only Paxels ships correct tags (its items ARE in
  `minecraft:tags/item/axes.json`), but FallingTree's `isValidTool` references
  `net.minecraft.world.item.AxeItem` — it checks the item CLASS, not the tag, so a custom
  paxel class never matches. Whitelisted 18 tools in `config/fallingtree.json`
  (`tools.allowed`): 6 vanilla axes + 6 paxels + 6 Mystical Agriculture axes, so it keeps
  working as he upgrades. Backup: `fallingtree.json.bak`.
- **Compared his 45-mod pack against Oneblock Ultimate** (79 mods, NeoForge 1.21.1) after he
  challenged whether I'd really looked for OneBlock MODPACKS — I had not; I'd only searched
  mods and datapacks. Correction owned. Result: his pack is better for his goals — theirs
  has no Mystical Agriculture, no Apothic Spawners, no Veinminer, no Sophisticated
  Backpacks/Storage, and much of its 79 is libraries + performance + things he'd never use
  (voice chat, a dog mod, shaders — bad on a 512MB-VRAM iGPU).
- **Took 3 worth stealing**, all sha512-verified from Modrinth:
  `ironfurnaces 4.3.2` (tiered furnaces — he explicitly asked for this weeks-equivalent ago),
  `Controlling 19.0.5` + `Searchables` (search box in the Controls menu — he has hit keybind
  conflicts repeatedly: B vs waypoints, `'` vs grave, F7 double-bound),
  `enchdesc 21.1.11` + `prickle` + `bookshelf` (enchantment tooltips).
- **Verified**: 51 jars, 0 missing required dependencies.
- Also noted for later: Xaero's Minimap 26.4.2 → 26.5.0 and World Map 1.45.0 → 1.46.0 are
  available; declined for now (point releases, mid-session nag only).

## 2026-10-04 — Google Takeout disk cleanup
- **Freed space for Takeout downloads**: deleted stale `takeout-20261003T094137Z-1-001.eUiJOUJQ.zip.part`
  (8.5 GB, abandoned first attempt — 001 already complete as `001(1).zip`) + its 0-byte `001.zip`
  placeholder; emptied Trash via `gio trash --empty` (33 GB, old Sept 28 2 GB-split Takeout zips).
  `/home` went 104 GB → 136 GB free. Active 002/003/004 downloads left untouched.

## 2026-10-04 — Permission rule cleanup
- **Removed wildcard grep allow rule** from `.claude/settings.local.json` (`Bash(grep -r "screenshot\|Pictures\|save.*path" ...)`):
  the regex `*` was parsed as a permission wildcard, triggering Claude Code's mid-command wildcard warning. Stale one-off rule, 51 → 50 entries.

## 2026-10-04 — Home dir bash temp cleanup + zsh history tuning
- **Deleted 1,513 `~/.bash_history-*.tmp`** leftovers (1,379 from the 2025-11-16 16:27 runaway-fork
  event — `fork rejected by pids controller`, only occurrence in the kernel logs; rest trickled in until
  2026-03-11 when zsh became the shell). Real `~/.bash_history` kept. Bash config untouched.
- **zsh/.zshrc history**: HISTSIZE/SAVEHIST 10000 → 100000; HIST_IGNORE_DUPS → HIST_IGNORE_ALL_DUPS +
  HIST_SAVE_NO_DUPS + HIST_FIND_NO_DUPS; added EXTENDED_HISTORY; `alias history='history -i 1'`
  (zsh's bare `history` only prints the last 16). `zsh -n` ok, alias verified.
