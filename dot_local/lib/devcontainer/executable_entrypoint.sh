#!/usr/bin/env bash

# Container-side dispatcher for Dev Container workspace commands.
# Invoked by the host-side common.sh with positional arguments:
#   $1: operation (shell | nvim)
#   $2: workdir (relative to the workspace, or '.')
#   $3+: operation arguments

set -euo pipefail

if [ "$#" -lt 2 ]; then
  printf '%s\n' 'usage: entrypoint.sh <shell|nvim> <workdir> [--] [args...]' >&2
  exit 2
fi

readonly operation="$1"
readonly workdir="$2"
shift 2

case "$operation" in
  shell)
    cd "$workdir"
    if [ -n "${SHELL:-}" ] && [ -x "$SHELL" ]; then
      exec "$SHELL" -i
    elif [ -x /bin/bash ]; then
      exec /bin/bash -i
    else
      exec /bin/sh -i
    fi
    ;;
  nvim)
    readonly nvim_bootstrap="${HOME}/.local/lib/devcontainer/nvim-bootstrap.sh"
    if [ ! -x "$nvim_bootstrap" ]; then
      printf '%s\n' "devcontainer: nvim-bootstrap not found in container (${nvim_bootstrap})." >&2
      printf '%s\n' 'devcontainer: recreate the container so the dotfiles install command can provision it.' >&2
      exit 1
    fi

    if [ "${1:-}" = '--' ]; then
      shift
    fi

    cd "$workdir"
    nvim_binary="$("$nvim_bootstrap")"
    exec "$nvim_binary" "$@"
    ;;
  *)
    printf '%s\n' "devcontainer: unknown operation: ${operation}" >&2
    exit 2
    ;;
esac
