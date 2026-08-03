#!/usr/bin/env bash
# Revert the Pochita GRUB theme — restore stock Fedora GRUB.
# Restores /etc/default/grub from the backup (or strips the added keys if no
# backup), removes the theme from /boot, and regenerates grub.cfg.
set -euo pipefail

THEME_NAME="pochita"
DEST="/boot/grub2/themes/$THEME_NAME"
GRUB_DEFAULT="/etc/default/grub"
GRUB_CFG="/boot/grub2/grub.cfg"

info() { printf '\033[38;2;237;135;150m::\033[0m %s\n' "$1"; }

if [ -f "${GRUB_DEFAULT}.bak" ]; then
    info "Restoring $GRUB_DEFAULT from ${GRUB_DEFAULT}.bak"
    sudo cp "${GRUB_DEFAULT}.bak" "$GRUB_DEFAULT"
else
    info "No backup found — stripping theme keys from $GRUB_DEFAULT"
    sudo sed -i \
        -e 's|^GRUB_TERMINAL_OUTPUT=.*|GRUB_TERMINAL_OUTPUT="console"|' \
        -e '/^GRUB_THEME=/d' \
        -e '/^GRUB_GFXMODE=/d' \
        -e '/^GRUB_GFXPAYLOAD_LINUX=/d' \
        "$GRUB_DEFAULT"
fi

if [ -d "$DEST" ]; then
    info "Removing theme $DEST"
    sudo rm -rf "$DEST"
else
    info "Theme dir already gone: $DEST"
fi

info "Regenerating $GRUB_CFG"
sudo grub2-mkconfig -o "$GRUB_CFG"

info "Reverted to stock GRUB. You can delete ${GRUB_DEFAULT}.bak if you like."
