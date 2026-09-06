#!/usr/bin/env bash
# Install the Catppuccin Firefox bits into the active Firefox profile.
#
# Firefox profile dirs have random names, so stow cannot link into them —
# this script resolves the default-release profile and symlinks instead.
# Same pattern as ~/dotfiles/grub/install.sh. Re-run it if the profile changes.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FF_HOME="$HOME/.mozilla/firefox"

# Which profile does Firefox actually launch? The [InstallXXXX] section's
# "Default=<path>" is authoritative. A [ProfileN] section's "Default=1" is NOT —
# this box has a stale 7st630zw.default carrying Default=1 that Firefox never opens.
profile=$(awk -F= '
	/^\[Install/       { in_install = 1; next }
	/^\[/              { in_install = 0 }
	in_install && /^Default=/ { print $2; exit }
' "$FF_HOME/profiles.ini" 2>/dev/null || true)

# Fallbacks: any *.default-release dir, then a [ProfileN] marked Default=1.
if [[ -z ${profile:-} ]]; then
	profile=$(basename "$(find "$FF_HOME" -maxdepth 1 -name '*.default-release' | head -1)" 2>/dev/null || true)
fi
if [[ -z ${profile:-} ]]; then
	profile=$(awk -F= '/^Path=/{p=$2} /^Default=1/{found=p} END{print found}' "$FF_HOME/profiles.ini")
fi
PROFILE_DIR="$FF_HOME/$profile"

if [[ ! -d $PROFILE_DIR ]]; then
	echo "firefox profile not found under $FF_HOME" >&2
	exit 1
fi

echo "profile: $PROFILE_DIR"
# ln -sfn into an existing real directory would nest the link inside it.
if [[ -d $PROFILE_DIR/chrome && ! -L $PROFILE_DIR/chrome ]]; then
	echo "refusing to replace existing real directory $PROFILE_DIR/chrome" >&2
	echo "move it aside first, then re-run" >&2
	exit 1
fi
ln -sfn "$SRC/user.js" "$PROFILE_DIR/user.js"
ln -sfn "$SRC/chrome"  "$PROFILE_DIR/chrome"
echo "linked user.js and chrome/"
echo
echo "Now set the theme once, by hand:"
echo "  about:addons -> Themes -> enable 'System theme — auto'"
echo "Then restart Firefox. After that, \`theme light\`/\`theme dark\` switches it live."
