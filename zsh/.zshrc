export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

autoload -Uz compinit
compinit

export STARSHIP_CONFIG="$HOME/.config/matugen/generated/starship.toml"

eval "$(starship init zsh)"
