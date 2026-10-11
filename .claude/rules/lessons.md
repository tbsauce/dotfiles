# Lessons
# Active constraints — apply these during work.
# If you catch yourself about to violate one, flag it to the user.
# Managed by /learn (capture) and /reflect (curate).

Remove stale SingletonLock/Socket/Cookie from ~/.var/app/<id>/cache/<app>/ when a Chromium-based Flatpak (Spotify, VS Code, Discord) silently exits with code 0 — the empty exit looks like a no-op but is single-instance lock contention. (2026-04-25) → .claude/dossiers/flatpak-spotify-singleton-lock.md
Put session-loaded content in .claude/rules/ rather than separate files referenced from CLAUDE.md — anything in rules/ auto-loads, separate files require manual reference each session. (2026-06-08)
Prefix coreutils with `command` in Bash tool calls and use absolute paths or `git -C` instead of `cd` — the user's zsh aliases are live non-interactively: `cat -v` hits bat's arg parser, a bare `ls` returned empty where `command ls` worked, and `cd` (zoxide) prints a "possible configuration issue" warning; zsh also does NOT word-split unquoted variables, so `$CMD arg` needs `${=CMD}`. (2026-09-06, re 2026-10-11)
i3 scopes `set $var` per file — variables do NOT cross an `include`, so a palette and the `client.*` lines that consume it must live in the SAME included file; symptom is `i3 -C` printing "Could not parse color: $blue" per usage while still reporting the config valid. (2026-09-06)
Set kitty font weights as `font_family family="JetBrainsMono Nerd Font" style=Medium` — the bare `font_family JetBrainsMono Nerd Font Medium` is not a family name and silently falls back to Noto Sans Mono; pin bold/italic too (`auto` italic resolves to Regular Italic, thinner than a Medium base). Polybar has the same trap: use `:style=Medium:`, never a family-name suffix. (2026-09-06)
When a color still looks wrong after a theme switch, grep the configs for hardcoded hex — truecolor escapes (`\033[38;2;R;G;Bm`) bypass the terminal ANSI palette entirely, so no palette fix can reach them; this is what left claude/.claude/statusline.sh at 1.12:1 on the light background. (2026-09-06)
Scripts that generate files into stow packages must write to `~/dotfiles/<pkg>/...`, never the `~` path — most config dirs are stow dir-symlinks where both resolve to the same file, but `~/.tmux` is a real directory with per-file links, so writing there orphans the repo copy. (2026-09-06)
Scan this repo from Python with `os.walk`, not `glob.glob` — glob skips dot-directories, so a `**/*latte*` pattern silently matched 0 files under `*/.config/`. (2026-09-06)
Resolve the active Firefox profile from the `[InstallXXXX]` section's `Default=<path>` in profiles.ini, never a `[ProfileN]` `Default=1` — this machine has a stale `7st630zw.default` marked Default=1 that Firefox never opens. (2026-09-06)
Confirm a command actually succeeded before concluding its empty output means "no matches" — `kitty --debug-config` is not a flag in 0.43.1, and its "Unknown flag" line got misread as a failed grep. (2026-09-06)
