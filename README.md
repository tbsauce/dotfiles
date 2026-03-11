# dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), themed with **Catppuccin Macchiato** across the board. Built for Fedora 43 on i3.

![Catppuccin Macchiato](https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png)

## Stow Packages

| Package | Tool | Notes |
|---------|------|-------|
| `bat` | [bat](https://github.com/sharkdp/bat) | Catppuccin theme, line numbers |
| `btop` | [btop](https://github.com/aristocratos/btop) | Catppuccin theme, vim keys |
| `dunst` | [dunst](https://github.com/dunst-project/dunst) | Notification daemon, Catppuccin colors |
| `fzf` | [fzf](https://github.com/junegunn/fzf) | fd integration, Catppuccin colors |
| `git` | [git](https://git-scm.com/) | SSH signing, nvim as editor |
| `gtk` | GTK 3 | Catppuccin theme, Papirus-Dark icons, Catppuccin cursors |
| `i3` | [i3](https://i3wm.org/) | Gaps, vim-style keybindings, Catppuccin colors |
| `kitty` | [kitty](https://sw.kovidgoyal.net/kitty/) | JetBrainsMono NF 11pt, 0.95 opacity, Catppuccin |
| `lazygit` | [lazygit](https://github.com/jesseduffield/lazygit) | Catppuccin theme |
| `nvim` | [Neovim](https://neovim.io/) | Full Lua config |
| `picom` | [picom](https://github.com/yshui/picom) | Shadows, fading, blur, rounded corners (8px) |
| `polybar` | [polybar](https://github.com/polybar/polybar) | i3 workspaces, audio, backlight, battery, wifi, date |
| `rofi` | [rofi](https://github.com/davatorium/rofi) | App launcher, Catppuccin theme, 600x360 |
| `starship` | [starship](https://starship.rs/) | Prompt with git/dir/duration, Catppuccin palette |
| `tmux` | [tmux](https://github.com/tmux/tmux) | 256color, vim keys, mouse, Catppuccin status bar |
| `yazi` | [yazi](https://github.com/sxyazi/yazi) | Terminal file manager, Catppuccin theme |
| `zsh` | [zsh](https://www.zsh.org/) | Aliases, history, PATH, env vars |

## Install

### Dependencies

```bash
# Core packages (Fedora 43)
sudo dnf install stow kitty rofi polybar picom bat fd-find btop zsh papirus-icon-theme-dark

# lazygit (COPR)
sudo dnf copr enable atim/lazygit -y && sudo dnf install lazygit
```

> dunst and ripgrep ship with Fedora 43 — no need to install them.

### Binary downloads

eza, yazi, and starship aren't in the Fedora repos. Download them to `~/.local/bin/`:

```bash
# eza — download the latest tarball from https://github.com/eza-community/eza/releases
# extract and place the binary in ~/.local/bin/

# yazi — download the latest zip from https://github.com/sxyazi/yazi/releases
# extract and place the yazi binary in ~/.local/bin/

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

## i3 Keybindings

`$mod` = Alt

| Key | Action |
|-----|--------|
| `$mod+Return` | kitty |
| `$mod+d` | rofi |
| `$mod+Shift+q` | kill window |
| `$mod+h/j/k/l` | focus left/down/up/right |
| `$mod+Shift+h/j/k/l` | move window |
| `$mod+1`–`0` | switch workspace |
| `$mod+Shift+1`–`0` | move to workspace |
| `$mod+f` | fullscreen |
| `$mod+v` | vertical split |
| `$mod+Shift+v` | horizontal split |
| `$mod+s/w/e` | stacking / tabbed / split layout |
| `$mod+r` | resize mode |
| `$mod+Shift+c` | reload config |
| `$mod+Shift+r` | restart i3 |
| `Print` | screenshot (flameshot) |
| `Shift+Print` | area screenshot |
| `Ctrl+Print` | current window screenshot |

Volume, brightness, and media keys are also bound.

## Shell Aliases

```bash
ls  → eza --icons --group-directories-first
ll  → eza -la --icons --group-directories-first
la  → eza -a --icons --group-directories-first
tree → eza --tree --icons
cat → bat
grep → rg
find → fd

# git
gs → git status    ga → git add     gc → git commit
gp → git push      gl → git log     gd → git diff
lg → lazygit
```
