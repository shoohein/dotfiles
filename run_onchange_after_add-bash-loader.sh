#!/usr/bin/env bash
set -Eeuo pipefail

bashrc="$HOME/.bashrc"
touch "$bashrc" "$HOME/.bashrc.local"

remove_range() {
  local begin="$1" end="$2"
  sed -i.bak -e "\\|^${begin}\$|,\\|^${end}\$|d" "$bashrc" && rm -f "$bashrc.bak"
}

update_block() {
  local name="$1" block="$2"
  local start="# >>> chezmoi: ${name} >>>"
  local end="# <<< chezmoi: ${name} <<<"
  remove_range "$start" "$end"
  # Remove trailing blank lines so the separator below stays stable
  while [[ -s "$bashrc" ]] && [[ -z "$(tail -n 1 "$bashrc")" ]]; do
    sed -i.bak '$d' "$bashrc" && rm -f "$bashrc.bak"
  done
  if [[ -s "$bashrc" ]]; then
    printf '\n' >>"$bashrc"
  fi
  printf '%s\n%s\n%s\n' "$start" "$block" "$end" >>"$bashrc"
}

# Remove blocks written by the previous needle-based loader (idempotent)
# shellcheck disable=SC2016
remove_range '# User-managed shell configuration' '  source "$HOME/.config/bash/aliases.bash"'
# shellcheck disable=SC2016
remove_range '# Local shell configuration (not managed by chezmoi)' '  source "$HOME/.bashrc.local"'

# shellcheck disable=SC2016
update_block bash '# User-managed shell configuration
[[ -f "$HOME/.config/bash/tools.bash" ]] &&
  source "$HOME/.config/bash/tools.bash"

[[ -f "$HOME/.config/bash/aliases.bash" ]] &&
  source "$HOME/.config/bash/aliases.bash"

# Local shell configuration (not managed by chezmoi)
[[ -f "$HOME/.bashrc.local" ]] &&
  source "$HOME/.bashrc.local"'
