set fish_greeting

# ==============================================
# Environment Variables
# ==============================================
set -gx MISE_IGNORED_CONFIG_PATHS $HOME/dev/dotfiles

# ==============================================
# PATH Configuration
# ==============================================
fish_add_path -m $HOME/.local/bin

fish_config theme choose "Catppuccin Mocha"

alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --group-directories-first"
alias cat="bat --theme=\"Catppuccin Mocha\" -pp"

mise activate fish | source
starship init fish | source
zoxide init fish | source
