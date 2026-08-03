#!/usr/bin/env bash
# Install the Pochita (Catppuccin Macchiato) GRUB theme.
#
# GRUB themes CANNOT be stowed — GRUB reads them at boot before symlinks
# resolve, so files must physically live under /boot (root-owned).
# Source of truth is this repo; this script copies it into place.
# Re-run after ANY edit to pochita/ — editing the repo alone does nothing
# until it's copied to /boot.
set -euo pipefail

THEME_NAME="pochita"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/$THEME_NAME"
DEST="/boot/grub2/themes/$THEME_NAME"
GRUB_DEFAULT="/etc/default/grub"
GRUB_CFG="/boot/grub2/grub.cfg"

info() { printf '\033[38;2;138;173;244m::\033[0m %s\n' "$1"; }

[ -f "$SRC/theme.txt" ] || { echo "error: $SRC/theme.txt missing — run from repo"; exit 1; }

info "Copying theme → $DEST"
sudo rm -rf "$DEST"
sudo mkdir -p "$DEST"
sudo cp -r "$SRC"/. "$DEST"/

info "Backing up $GRUB_DEFAULT → ${GRUB_DEFAULT}.bak"
sudo cp -n "$GRUB_DEFAULT" "${GRUB_DEFAULT}.bak" || true

info "Patching $GRUB_DEFAULT (gfxterm + theme + gfxmode)"
# GRUB_TERMINAL_OUTPUT must be gfxterm or NO graphical theme renders.
if grep -q '^GRUB_TERMINAL_OUTPUT=' "$GRUB_DEFAULT"; then
    sudo sed -i 's|^GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT="gfxterm"|' "$GRUB_DEFAULT"
else
    echo 'GRUB_TERMINAL_OUTPUT="gfxterm"' | sudo tee -a "$GRUB_DEFAULT" >/dev/null
fi

set_kv() { # key value — idempotent set-or-append in /etc/default/grub
    local k="$1" v="$2"
    if grep -q "^$k=" "$GRUB_DEFAULT"; then
        sudo sed -i "s|^$k=.*|$k=$v|" "$GRUB_DEFAULT"
    else
        echo "$k=$v" | sudo tee -a "$GRUB_DEFAULT" >/dev/null
    fi
}
set_kv GRUB_THEME   "\"$DEST/theme.txt\""
set_kv GRUB_GFXMODE "auto"
set_kv GRUB_GFXPAYLOAD_LINUX "keep"

info "Regenerating $GRUB_CFG"
sudo grub2-mkconfig -o "$GRUB_CFG"

info "Done. Reboot to see Pochita. Revert anytime with: ./uninstall.sh"
