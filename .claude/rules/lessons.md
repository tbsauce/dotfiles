# Lessons
# Active constraints — apply these during work.
# If you catch yourself about to violate one, flag it to the user.
# Managed by /learn (capture) and /reflect (curate).

Remove stale SingletonLock/Socket/Cookie from ~/.var/app/<id>/cache/<app>/ when a Chromium-based Flatpak (Spotify, VS Code, Discord) silently exits with code 0 — the empty exit looks like a no-op but is single-instance lock contention. (2026-04-25) → .claude/dossiers/flatpak-spotify-singleton-lock.md
Copy skills verbatim across projects; never bake domain-specific hints into skill files — skills are the engine (identical everywhere), lessons are the fuel (project-specific). (2026-06-08)
Put session-loaded content in .claude/rules/ rather than separate files referenced from CLAUDE.md — anything in rules/ auto-loads, separate files require manual reference each session. (2026-06-08)
