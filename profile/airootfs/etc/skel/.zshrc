export EDITOR="code --wait"
export VISUAL="code --wait"
export BROWSER="google-chrome-stable"

autoload -Uz compinit && compinit
eval "$(starship init zsh)"

alias ll='ls -alF --color=auto'
alias update='sudo pacman -Syu'
alias ahmedshell='pwsh'

printf '\033[1;36mWelcome to Lumarchy!\033[0m  SUPER+E opens VS Code.\n'
