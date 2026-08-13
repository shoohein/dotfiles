#!/usr/bin/env bash

# Host-side orchestration layer for Dev Container workspace commands.
# Do not use container $HOME or container-side absolute paths here.

set -euo pipefail

readonly devcontainer_dotfiles_repository='https://github.com/shoohein/dotfiles.git'
readonly devcontainer_dotfiles_install_command='install.sh'

devcontainer_require_commands() {
  if ! command -v devcontainer > /dev/null 2>&1; then
    printf '%s\n' 'devcontainer: required command not found: devcontainer' >&2
    return 1
  fi
}

devcontainer_workspace_root() {
  local workspace

  if command -v git > /dev/null 2>&1 && workspace="$(git rev-parse --show-toplevel 2> /dev/null)"; then
    printf '%s\n' "$workspace"
    return
  fi

  pwd -P
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
      printf '%s\n' 'devcontainer: current directory is outside the workspace.' >&2
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

devcontainer_run() {
  local operation workspace workdir

  operation="$1"
  workspace="$2"
  workdir="$3"
  shift 3

  # shellcheck disable=SC2016
  exec devcontainer exec --workspace-folder "$workspace" \
    /bin/sh -c '
      ep="$HOME/.local/lib/devcontainer/entrypoint.sh"
      if [ ! -x "$ep" ]; then
        printf "%s\n" "devcontainer: entrypoint not found in container ($ep)." >&2
        printf "%s\n" "devcontainer: the dotfiles may not be installed, or the container image is outdated." >&2
        printf "%s\n" "devcontainer: recreate the container so the dotfiles install command can provision the entrypoint." >&2
        exit 1
      fi
      exec "$ep" "$@"
    ' sh \
    "$operation" "$workdir" "$@"
}
