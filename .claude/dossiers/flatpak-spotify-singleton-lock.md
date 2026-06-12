---
status: active — owner: lessons.md
created: 2026-04-25
---

# Flatpak Spotify silent-exit on stale singleton locks

## Rule

Remove stale SingletonLock/Socket/Cookie from ~/.var/app/<id>/cache/<app>/ when a Chromium-based Flatpak (Spotify, VS Code, Discord) silently exits with code 0 — the empty exit looks like a no-op but is single-instance lock contention.

## What happened

Spotify (Flatpak) launches, consumes CPU for ~200ms, then exits cleanly with code 0. No error output, no journal crash entry — looks like a successful no-op. Reality: Chromium's single-instance enforcement saw `SingletonLock`/`SingletonSocket`/`SingletonCookie` in the cache dir and assumed another instance was already running, so the new process self-terminated immediately.

Original capture lived in `.claude/lessons/flatpak-spotify-singleton-lock.md`, compressed to one-liner in commit `1a2a562`.

## Evidence

- `rm ~/.var/app/com.spotify.Client/cache/spotify/Singleton{Lock,Socket,Cookie}` and Spotify launches normally on next invocation.
- Exit code 0 with brief CPU spike is the diagnostic signature — distinguishes from a true crash (non-zero exit, journal entry).

## Scope

Applies to *any* Chromium-based Flatpak: Spotify, VS Code, Discord, Element, etc. The path pattern is always `~/.var/app/<flatpak-id>/cache/<app-internal-name>/Singleton*`. The app-internal-name often matches the binary, not the Flatpak ID.
