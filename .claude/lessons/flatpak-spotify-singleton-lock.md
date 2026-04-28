---
topic: flatpak-spotify-singleton-lock
category: config-fix
learned: 2026-04-25
---

**Problem:** Spotify (Flatpak) silently exits on launch — no error output, exit code 0, runs for ~200ms then dies. Journal shows CPU consumed but no crash.
**Solution:** Remove stale singleton files left from a previous unclean exit: `rm ~/.var/app/com.spotify.Client/cache/spotify/Singleton{Lock,Socket,Cookie}`. Spotify (Chromium-based) uses these to enforce single-instance — if they exist, a new launch assumes another instance is running and exits immediately.
**Context:** Flatpak apps store data under `~/.var/app/<id>/` not `~/.config/`. The silent exit with code 0 is misleading — it looks like a successful no-op, not a lock conflict. Diagnosis: check for `SingletonLock`/`SingletonSocket`/`SingletonCookie` in the app's cache dir. This applies to any Chromium-based Flatpak (Spotify, VS Code, Discord, etc.).
