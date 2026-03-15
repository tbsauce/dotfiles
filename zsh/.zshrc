# ── Zsh Options ──
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_SILENT
setopt CORRECT

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# ── Completion ──
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── PATH ──
typeset -U path
path=(~/.npm-global/bin ~/.local/bin ~/bin $path)
export PATH

# ── Aliases ──
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias tree='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias lg='lazygit'

# ── FZF — Catppuccin Macchiato ──
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--color=selected-bg:#494d64 \
--multi"

# Use fd for fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ── Zoxide ──
eval "$(zoxide init zsh --cmd cd)"

# ── Source extra configs ──
if [ -d ~/.zshrc.d ]; then
    for rc in ~/.zshrc.d/*; do
        [ -f "$rc" ] && source "$rc"
    done
fi

# ── Plugins ──
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Starship prompt (must be last) ──
eval "$(starship init zsh)"
