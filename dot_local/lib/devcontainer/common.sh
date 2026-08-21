#!/usr/bin/env bash

# Host-side orchestration layer for Dev Container workspace commands.
# Do not use container $HOME or container-side absolute paths here.

set -euo pipefail

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
