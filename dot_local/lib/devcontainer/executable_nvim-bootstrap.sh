#!/usr/bin/env bash

# Container-side Neovim provisioning for the dvim command.
# Installs a fixed Neovim version on first use and prints the binary path
# to stdout. Errors go to stderr. Takes no arguments.

set -euo pipefail

readonly nvim_version='0.12.4'
readonly nvim_sha256_x86_64='012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628'
readonly nvim_sha256_arm64='ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f'

bootstrap_temporary_directory=''
bootstrap_lock_directory=''

bootstrap_cleanup() {
  if [ -n "${bootstrap_temporary_directory:-}" ]; then
    rm -rf -- "$bootstrap_temporary_directory"
  fi
  if [ -n "${bootstrap_lock_directory:-}" ]; then
    rm -rf -- "$bootstrap_lock_directory"
  fi
}
trap bootstrap_cleanup EXIT

bootstrap_require_command() {
  local command="$1"

  if ! command -v "$command" > /dev/null 2>&1; then
    printf '%s\n' "devcontainer: required command not found: ${command}" >&2
    exit 1
  fi
}

bootstrap_is_healthy() {
  local binary="$1"

  [ -x "$binary" ] &&
    "$binary" --clean --headless \
      '+lua assert(require("vim.uri"))' \
      '+lua assert(vim.fn.filereadable(vim.env.VIMRUNTIME .. "/syntax/syntax.vim") == 1)' \
      '+qa'
}

bootstrap_acquire_lock() {
  local lock_directory="$1"
  local lock_pid
  local attempts=0
  local maximum_attempts=60

  while ! mkdir "$lock_directory" 2> /dev/null; do
    if [ -r "${lock_directory}/pid" ]; then
      lock_pid="$(< "${lock_directory}/pid")"
      if ! kill -0 "$lock_pid" 2> /dev/null; then
        rm -rf "$lock_directory"
        continue
      fi
    fi

    if [ "$attempts" -ge "$maximum_attempts" ]; then
      printf '%s\n' "devcontainer: timed out waiting for Neovim installation: ${lock_directory}" >&2
      exit 1
    fi

    attempts=$((attempts + 1))
    sleep 1
  done

  printf '%s\n' "$$" > "${lock_directory}/pid"
  bootstrap_lock_directory="$lock_directory"
}

bootstrap_install() {
  local architecture archive_architecture checksum download_url
  local install_root nvim_directory nvim_binary lock_directory

  for command in curl getconf mktemp sha256sum tar uname; do
    bootstrap_require_command "$command"
  done

  if ! getconf GNU_LIBC_VERSION 2> /dev/null | grep -q '^glibc '; then
    printf '%s\n' 'devcontainer: Neovim tarballs are supported only on glibc-based containers.' >&2
    exit 1
  fi

  architecture="$(uname -m)"
  case "$architecture" in
    x86_64)
      archive_architecture='x86_64'
      checksum="$nvim_sha256_x86_64"
      ;;
    aarch64)
      archive_architecture='arm64'
      checksum="$nvim_sha256_arm64"
      ;;
    *)
      printf '%s\n' "devcontainer: unsupported architecture: ${architecture}" >&2
      exit 1
      ;;
  esac

  install_root="${HOME}/.local/opt"
  nvim_directory="${install_root}/nvim-${nvim_version}"
  nvim_binary="${nvim_directory}/bin/nvim"
  lock_directory="${install_root}/.nvim-${nvim_version}.lock"

  mkdir -p "$install_root"
  if [ ! -w "$install_root" ]; then
    printf '%s\n' "devcontainer: installation directory is not writable: ${install_root}" >&2
    exit 1
  fi

  if bootstrap_is_healthy "$nvim_binary"; then
    printf '%s\n' "$nvim_binary"
    return
  fi

  bootstrap_acquire_lock "$lock_directory"

  bootstrap_temporary_directory="$(mktemp -d "${install_root}/.nvim-${nvim_version}.tmp.XXXXXX")"

  if bootstrap_is_healthy "$nvim_binary"; then
    printf '%s\n' "$nvim_binary"
    return
  fi

  download_url="https://github.com/neovim/neovim/releases/download/v${nvim_version}/nvim-linux-${archive_architecture}.tar.gz"
  curl --fail --location --show-error --silent "$download_url" --output "${bootstrap_temporary_directory}/nvim.tar.gz"
  printf '%s  %s\n' "$checksum" "${bootstrap_temporary_directory}/nvim.tar.gz" | sha256sum --check --status -

  tar --extract --gzip --file "${bootstrap_temporary_directory}/nvim.tar.gz" --directory "$bootstrap_temporary_directory"
  mv "${bootstrap_temporary_directory}/nvim-linux-${archive_architecture}" "${bootstrap_temporary_directory}/nvim"

  if ! bootstrap_is_healthy "${bootstrap_temporary_directory}/nvim/bin/nvim"; then
    printf '%s\n' 'devcontainer: downloaded Neovim failed its runtime verification.' >&2
    exit 1
  fi

  rm -rf "$nvim_directory"
  mv "${bootstrap_temporary_directory}/nvim" "$nvim_directory"

  rm -rf -- "$bootstrap_temporary_directory" "$bootstrap_lock_directory"
  bootstrap_temporary_directory=''
  bootstrap_lock_directory=''
  printf '%s\n' "$nvim_binary"
}

bootstrap_install
