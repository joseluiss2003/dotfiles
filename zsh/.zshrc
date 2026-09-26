# Environment
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export MANPAGER="less -R"

# History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit
if [[ -z "${ZDOTDIR:-}" || ! -d "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --decorate --graph -20'
alias gd='git diff'

# System
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true'
alias ports='ss -tulpn'
alias ipinfo='ip -br addr'

# Quick helpers
mkcd() {
    [[ -n "$1" ]] || return 1
    mkdir -p -- "$1" && cd -- "$1"
}

extract() {
    [[ -f "$1" ]] || return 1
    case "$1" in
        *.tar.gz|*.tgz) tar xzf "$1" ;;
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.xz) tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.tar) tar xf "$1" ;;
        *.zip) unzip "$1" ;;
        *.7z) 7z x "$1" ;;
        *) echo "Formato no soportado: $1"; return 1 ;;
    esac
}

# Matugen-generated Starship configuration
export STARSHIP_CONFIG="$HOME/.config/matugen/generated/starship.toml"

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
