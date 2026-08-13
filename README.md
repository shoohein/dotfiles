# dotfiles

[![Check](https://github.com/shoohein/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/shoohein/dotfiles/actions/workflows/check.yml)

Manages dotfiles using [chezmoi](https://www.chezmoi.io/).

## Setup

[Install chezmoi](https://www.chezmoi.io/install) and run the following command:

```console
chezmoi init --apply https://github.com/shoohein/dotfiles.git
```

## Operations

> **Concepts**
>
> - **Destination:** Actual files on your system (e.g., `~/.bashrc`).
> - **Source state:** Files managed inside chezmoi.
> - **Rule:** Always use `chezmoi edit`. If you edit a destination file directly, use `chezmoi re-add`.

### Sync & Apply

| Command                             | Description                                    |
| :---------------------------------- | :--------------------------------------------- |
| `chezmoi update`                    | Pull and apply latest remote changes.          |
| `chezmoi status`                    | Show pending changes (Source vs. Destination). |
| `chezmoi diff`                      | Show exact differences.                        |
| `chezmoi apply`                     | Apply source state to destination.             |
| `chezmoi apply --refresh-externals` | Apply and force-update external repositories.  |

### Add & Edit

| Command               | Description                                                       |
| :-------------------- | :---------------------------------------------------------------- |
| `chezmoi add <file>`  | Add file/directory to source state.                               |
| `chezmoi edit <file>` | Edit managed file in `$EDITOR`. (use `--apply` to apply on save). |

### Status & Maintenance

| Command                     | Description                                                                 |
| :-------------------------- | :-------------------------------------------------------------------------- |
| `chezmoi managed/unmanaged` | List managed/unmanaged files.                                               |
| `chezmoi re-add <file>`     | **[Recovery]** Update source state from directly modified destination file. |
| `chezmoi forget <file>`     | Remove from source state (keeps destination file intact).                   |
| `chezmoi chattr +x <file>`  | Mark as executable in source state.                                         |
| `chezmoi doctor`            | Check for configuration problems.                                           |

### Git Operations

| Command                | Description                                                        |
| :--------------------- | :----------------------------------------------------------------- |
| `chezmoi cd`           | Open shell in source directory.                                    |
| `chezmoi git -- <cmd>` | Run git in source dir (e.g., `chezmoi git -- commit -m "update"`). |

## Dev Containers

`dvim` starts the Dev Container for the current Git repository and opens Neovim in
the corresponding directory. `dsh` opens an interactive shell in the same location.

```console
dvim
dvim README.md
dsh
```

Both commands require the Dev Container CLI. `dvim` installs its fixed Neovim
version on first use in glibc-based `amd64` and `arm64` containers.

`dvim` and `dsh` use the Git root as the Dev Container workspace. Run them from
the repository or one of its subdirectories.
