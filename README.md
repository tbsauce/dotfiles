# dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), themed with **Catppuccin Macchiato** across the board. Built for Fedora 43 on i3.

![Catppuccin Macchiato](https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png)

## What's Included

### System

| Package | Tool | What it does |
|---------|------|--------------|
| `i3` | [i3](https://i3wm.org/) | Tiling window manager — gaps, vim keys, Catppuccin colors |
| `polybar` | [polybar](https://github.com/polybar/polybar) | Status bar — workspaces, audio, backlight, battery, wifi, date |
| `picom` | [picom](https://github.com/yshui/picom) | Compositor — shadows, fading, blur, rounded corners (8px) |
| `dunst` | [dunst](https://github.com/dunst-project/dunst) | Notification daemon |
| `rofi` | [rofi](https://github.com/davatorium/rofi) | App launcher + power/display menus |
| `flameshot` | [flameshot](https://github.com/flameshot-org/flameshot) | Screenshot tool |
| `gtk` | GTK 3 | Catppuccin theme, Papirus-Dark icons, Catppuccin cursors |
| `scripts` | — | Custom scripts: `lockscreen`, `rofi-powermenu`, `rofi-displaymenu`, `rofi-keybindings` |

### Terminal & Shell

| Package | Tool | What it does |
|---------|------|--------------|
| `kitty` | [kitty](https://sw.kovidgoyal.net/kitty/) | Terminal — JetBrainsMono NF 11pt, 0.95 opacity |
| `zsh` | [zsh](https://www.zsh.org/) | Shell — aliases, history, completions, env |
| `starship` | [starship](https://starship.rs/) | Prompt — git, directory, duration |
| `tmux` | [tmux](https://github.com/tmux/tmux) | Multiplexer — 256color, vim keys, mouse |
| `fzf` | [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — fd integration |

### CLI Tools

| Package | Tool | What it does |
|---------|------|--------------|
| `nvim` | [Neovim](https://neovim.io/) | Editor — full Lua config (NvChad-based) |
| `bat` | [bat](https://github.com/sharkdp/bat) | `cat` replacement — syntax highlighting, line numbers |
| `yazi` | [yazi](https://github.com/sxyazi/yazi) | Terminal file manager |
| `lazygit` | [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI |
| `btop` | [btop](https://github.com/aristocratos/btop) | System monitor — vim keys |
| `git` | [git](https://git-scm.com/) | Git config — SSH signing, nvim as editor |

### Not stow-managed (but used)

| Tool | Purpose |
|------|---------|
| [eza](https://github.com/eza-community/eza) | `ls` replacement with icons |
| [fd](https://github.com/sharkdp/fd) | `find` replacement |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` replacement |
| [zoxide](https://github.com/ajlj/zoxide) | Smarter `cd` (replaces `cd` via `zoxide init --cmd cd`) |

## i3 Keybindings

`$mod` = Alt

### Windows

| Key | Action |
|-----|--------|
| `$mod+Return` | Open terminal (kitty) |
| `$mod+Shift+q` | Kill focused window |
| `$mod+f` | Toggle fullscreen |
| `$mod+Shift+Space` | Toggle floating |
| `$mod+Space` | Switch focus: tiled / floating |
| `$mod+a` | Focus parent container |

### Navigation

| Key | Action |
|-----|--------|
| `$mod+h/j/k/l` | Focus left / down / up / right |
| `$mod+Shift+h/j/k/l` | Move window left / down / up / right |
| `$mod+1`–`0` | Switch to workspace 1–10 |
| `$mod+Shift+1`–`0` | Move window to workspace 1–10 |

### Layout

| Key | Action |
|-----|--------|
| `$mod+v` | Split vertical |
| `$mod+Shift+v` | Split horizontal |
| `$mod+s` | Stacking layout |
| `$mod+w` | Tabbed layout |
| `$mod+e` | Toggle split layout |
| `$mod+r` | Enter resize mode (h/j/k/l to resize, Esc to exit) |

### Launchers & Utilities

| Key | Action |
|-----|--------|
| `$mod+d` | App launcher (rofi) |
| `$mod+Shift+p` | Power menu (rofi) |
| `$mod+p` | Display layout menu (rofi) |
| `$mod+Shift+/` | Keybindings hint (rofi) |
| `$mod+Escape` | Lock screen |
| `Print` | Screenshot — interactive (flameshot gui) |
| `Shift+Print` | Screenshot — full screen to ~/Pictures |
| `Ctrl+Print` | Screenshot — selection to clipboard |

### Media & Hardware

| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up (+5%) |
| `XF86AudioLowerVolume` | Volume down (-5%) |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86MonBrightnessUp` | Brightness up (+10%) |
| `XF86MonBrightnessDown` | Brightness down (-10%) |

### Session

| Key | Action |
|-----|--------|
| `$mod+Shift+c` | Reload i3 config |
| `$mod+Shift+r` | Restart i3 in-place |
| `$mod+Shift+e` | Exit i3 (with confirmation) |

## Shell Aliases

### File browsing

| Alias | Command |
|-------|---------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first` |
| `la` | `eza -a --icons --group-directories-first` |
| `tree` | `eza --tree --icons` |

### Tool replacements

| Alias | Command |
|-------|---------|
| `cat` | `bat` |
| `grep` | `rg` (ripgrep) |
| `find` | `fd` |
| `cd` | `zoxide` (auto-initialized) |

### Git

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git log --oneline --graph` |
| `gd` | `git diff` |
| `lg` | `lazygit` |

## Install

### Dependencies

```bash
# Core packages (Fedora 43)
sudo dnf install stow kitty rofi polybar picom bat fd-find btop zsh papirus-icon-theme-dark flameshot

# lazygit (COPR)
sudo dnf copr enable atim/lazygit -y && sudo dnf install lazygit
```

> dunst and ripgrep ship with Fedora 43 — no need to install them.

### Binary downloads

eza, yazi, zoxide, and starship aren't in the Fedora repos. Download them to `~/.local/bin/`:

```bash
# eza — https://github.com/eza-community/eza/releases
# extract and place the binary in ~/.local/bin/

# yazi — https://github.com/sxyazi/yazi/releases
# extract and place the yazi binary in ~/.local/bin/

# zoxide — https://github.com/ajlj/zoxide/releases
# extract and place the zoxide binary in ~/.local/bin/

# starship
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin/
```

### Font

Download [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases) and install:

```bash
unzip JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono/
fc-cache -fv
```

### GTK theme & cursors

- **Theme:** Download `catppuccin-macchiato-blue-standard+default` from [catppuccin/gtk](https://github.com/catppuccin/gtk/releases) → extract to `~/.themes/`
- **Cursors:** Download `catppuccin-macchiato-dark-cursors` from [catppuccin/cursors](https://github.com/catppuccin/cursors/releases) → extract to `~/.icons/`

### Deploy

```bash
cd ~/dotfiles

# Stow all packages
for dir in */; do stow "$dir"; done

# Set zsh as default shell
chsh -s $(which zsh)
```
