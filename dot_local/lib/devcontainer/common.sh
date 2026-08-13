#!/usr/bin/env bash

# Shared host-side helpers for commands that enter a Dev Container.

readonly devcontainer_dotfiles_repository='https://github.com/shoohein/dotfiles.git'
readonly devcontainer_dotfiles_install_command='install.sh'

devcontainer_require_commands() {
  local command

  for command in devcontainer git; do
    if ! command -v "$command" > /dev/null 2>&1; then
      printf '%s\n' "devcontainer: required command not found: ${command}" >&2
      return 1
    fi
  done
}

devcontainer_workspace_root() {
  if ! git rev-parse --show-toplevel; then
    printf '%s\n' 'devcontainer: run this command inside a Git repository.' >&2
    return 1
  fi
}

devcontainer_workdir() {
  local workspace="$1"
  local current_directory

  workspace="$(cd "$workspace" && pwd -P)"
  current_directory="$(pwd -P)"

  if [ "$current_directory" = "$workspace" ]; then
    printf '%s\n' .
    return
  fi

  case "$current_directory" in
    "$workspace"/*)
      printf '%s\n' "${current_directory#"${workspace}"/}"
      ;;
    *)
      printf '%s\n' 'devcontainer: current directory is outside the Git workspace.' >&2
      return 1
      ;;
  esac
}

devcontainer_up() {
  local workspace="$1"

  devcontainer up \
    --workspace-folder "$workspace" \
    --dotfiles-repository "$devcontainer_dotfiles_repository" \
    --dotfiles-install-command "$devcontainer_dotfiles_install_command" \
    > /dev/null
}

devcontainer_exec() {
  local workspace="$1"
  shift

  devcontainer exec --workspace-folder "$workspace" "$@"
}
