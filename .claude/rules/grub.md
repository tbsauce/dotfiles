---
paths:
  - "grub/**"
---

# GRUB Theme Rules

- The GRUB theme is NOT stowed. GRUB reads it at boot before any symlink in /home can resolve, so the files must physically live in `/boot/grub2/themes/` (root-owned). The source of truth is `~/dotfiles/grub/` (theme in `grub/pochita/`). After ANY theme edit, run `~/dotfiles/grub/install.sh` to sudo-copy it into /boot and regenerate grub.cfg. Editing the repo alone changes nothing at boot. `~/dotfiles/grub/uninstall.sh` reverts to stock. (learned 2026-08-01)
- Every PNG in the theme must be 8-bit truecolor RGBA. GRUB rejects palette/indexed PNGs with IHDR bit-depth <8 with `png: bit depth must be 8 or 16`, which halts boot at a "Press any key" prompt with nothing rendered. ImageMagick writes low-color images as sub-8-bit palette PNGs by default, so force truecolor on every generated/recolored image, writing to a temp path rather than in place:
  `magick in.png -type TrueColorAlpha -define png:color-type=6 -define png:bit-depth=8 out.png`
  Verify with `file` (must say "8-bit/color RGBA"), NOT `identify -format %[bit-depth]`, which misreports palette images as 8. (learned 2026-08-01)
