# eza
alias ll='eza -lah --git --icons=auto --group-directories-first'
alias lt='eza --tree --level=2 --icons=auto'

# Git
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gr='git rebase --continue'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias lg='lazygit'

# Docker
alias di='docker image'
alias dct='docker container'
alias dv='docker volume'
alias dn='docker network'
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
