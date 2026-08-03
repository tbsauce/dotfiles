# Lessons
# Active constraints — apply these during work.
# If you catch yourself about to violate one, flag it to the user.
# Managed by /learn (capture) and /reflect (curate).

Remove stale SingletonLock/Socket/Cookie from ~/.var/app/<id>/cache/<app>/ when a Chromium-based Flatpak (Spotify, VS Code, Discord) silently exits with code 0 — the empty exit looks like a no-op but is single-instance lock contention. (2026-04-25) → .claude/dossiers/flatpak-spotify-singleton-lock.md
Copy skills verbatim across projects; never bake domain-specific hints into skill files — skills are the engine (identical everywhere), lessons are the fuel (project-specific). (2026-06-08)
Put session-loaded content in .claude/rules/ rather than separate files referenced from CLAUDE.md — anything in rules/ auto-loads, separate files require manual reference each session. (2026-06-08)
The GRUB theme is NOT stowed — GRUB reads it at boot before symlinks resolve, so files must physically live in /boot/grub2/themes/ (root-owned). Source of truth is ~/dotfiles/grub/ (theme in grub/pochita/); after ANY theme edit run ~/dotfiles/grub/install.sh to sudo-copy into /boot and regenerate grub.cfg. Never just edit the repo and expect a change to appear — it must be re-copied. ~/dotfiles/grub/uninstall.sh reverts to stock. (2026-08-01)
GRUB's PNG reader only accepts 8-bit truecolor RGBA — it rejects palette/indexed PNGs whose IHDR bit-depth is <8 with "png: bit depth must be 8 or 16" (halts boot at a "Press any key" prompt, nothing renders). ImageMagick writes low-color images as sub-8-bit palette PNGs by default, so any generated/recolored theme image must be forced truecolor: `magick in -type TrueColorAlpha -define png:color-type=6 -define png:bit-depth=8 out.png` (write to a temp path, not in place). Verify with `file` (must say "8-bit/color RGBA"), NOT `identify %[bit-depth]` which misreports palette images as 8. (2026-08-01)
