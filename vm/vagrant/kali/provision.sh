#!/usr/bin/env bash
# First-boot provisioner for the Kali HTB VM. Runs inside the guest via Vagrant.
# Bakes a small HTB starter toolkit + spice-vdagent for smooth GUI integration,
# then bootstraps the host dotfiles (tmux + nvim) so `vagrant ssh kali1` lands
# the user in their familiar environment with zero manual setup.

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  spice-vdagent \
  nmap \
  gobuster \
  ffuf \
  seclists \
  burpsuite \
  openvpn \
  tmux \
  neovim \
  stow \
  git \
  kitty-terminfo

# Bootstrap tmux + nvim dotfiles for the vagrant user. Runs as that user (not root)
# so $HOME points at /home/vagrant and stow lands files under the right ownership.
sudo -u vagrant bash <<'USERSETUP'
cd "$HOME"

# Clone the public dotfiles repo (idempotent — skip if already there).
if [ ! -d "$HOME/dotfiles" ]; then
  git clone https://github.com/tbsauce/dotfiles.git "$HOME/dotfiles"
fi

# Wipe any default configs the box ships with so `stow` doesn't conflict.
rm -f  "$HOME/.tmux.conf"
rm -rf "$HOME/.config/nvim"

# Symlink tmux + nvim into the user's home.
cd "$HOME/dotfiles"
stow -t "$HOME" tmux nvim

# Pre-warm NvChad plugins via lazy.nvim so the first interactive nvim launch
# is instant. Timeout-guarded so a stuck headless run can't hang provisioning.
timeout 240 nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
USERSETUP
