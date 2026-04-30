# Dotfiles

Personal shell and Git configuration for **macOS** and **Linux**, managed as a git repo and installed with a small symlink script.

## What’s in here

| File                                                    | Purpose                                                                                 |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [`install.sh`](install.sh)                              | Clones (if needed) and symlinks configs into `$HOME`                                    |
| [`.common_env`](.common_env)                            | Shared zsh aliases, options, and functions (sourced from `~/.zshrc`)                    |
| [`.macos_env`](.macos_env) / [`.linux_env`](.linux_env) | Per-OS environment (e.g. tool-specific IDs); sourced by `.common_env`                   |
| [`.gitconfig`](.gitconfig)                              | Git user name, default branch, global ignore file path                                  |
| [`.gitignore_global`](.gitignore_global)                | Patterns ignored by Git everywhere (`core.excludesFile`)                                |
| [`.zshrc`](.zshrc)                                      | Zsh entrypoint (oh-my-posh + slatewave theme, zoxide, lazy nvm). Linked by the installer; an existing `~/.zshrc` is moved to `~/.zshrc.old` first |
| [`.zshrc.local.example`](.zshrc.local.example)          | Template for per-machine values (e.g. `CLAUDE_1P_DEV_ENV_ID`); copy to `~/.zshrc.local`              |
| [`bin/`](bin/)                                          | Standalone helper scripts (`killport`, `dotfiles-update`); installer symlinks each into `~/.local/bin` |
| [`Brewfile`](Brewfile)                                  | macOS dependencies — installed by `install.sh` via `brew bundle` (skip with `--no-bootstrap`)         |
| [`linux-packages.txt`](linux-packages.txt)              | Linux package list, advisory only — `install.sh` prints it but doesn't run apt for you               |

## Requirements

- **Git** (clone / install)
- **zsh** (configs assume zsh)
- **Homebrew** on macOS so `install.sh` can run `brew bundle`. On Linux, install the packages from `linux-packages.txt` manually.

## Install

### Option A: Clone, then run the script

```bash
git clone git@github.com:kevinlangleyjr/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

If the repo already lives somewhere else, run `./install.sh` from that clone; the script detects the git root and uses it.

### Option B: One-liner (remote script)

Uses the default clone URL baked into `install.sh` (SSH). You need [GitHub SSH access](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) for a fresh clone; otherwise set `REPO_URL` to an HTTPS URL. Forks can override with **`REPO_URL`**.

```bash
curl -fsSL https://raw.githubusercontent.com/kevinlangleyjr/dotfiles/main/install.sh | bash -s
```

If `~/.dotfiles` already exists and is a git checkout, the script skips cloning.

### Environment variables

| Variable               | Meaning                                                                                                                                                                                                                                       |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DOTFILES`             | Directory to use as the dotfiles repo (default: git root when running from disk, otherwise `~/.dotfiles`)                                                                                                                                     |
| `REPO_URL`             | Git URL to clone when `DOTFILES` has no `.git` directory (defaults to `git@github.com:kevinlangleyjr/dotfiles.git`; override if you use HTTPS or a fork)                                                                                      |
| `INSTALL_GIT_DOTFILES` | `yes` / `no` — whether to link `~/.gitconfig` and `~/.gitignore_global`. When unset and your terminal is interactive, the script **asks**; when stdin isn’t a TTY (e.g. some CI), it defaults to **yes** so existing one-liners keep working. |

You can also pass **`--no-git`** or **`--git`** to `install.sh` instead of using the variable.

## What the installer does

Symlinks created in `$HOME` pointing at the repo:

- **Optional (prompt or `INSTALL_GIT_DOTFILES` / `--git` / `--no-git`):** `.gitconfig`, `.gitignore_global` — any pre-existing file is moved to `.<name>.old` (and a prior `.old` is shifted to `.old.bak`) before linking, unless it's already a symlink to this repo's copy
- **Always:** `.zshrc`, `.common_env`
- **Always (OS-specific):** `.macos_env` on Darwin, `.linux_env` on Linux

Plus:

- Each executable in `bin/` symlinked into `~/.local/bin/`
- `~/.zshrc.local` seeded from `.zshrc.local.example` if it doesn't exist
- The `slatewave-omp` oh-my-posh theme cloned to `~/.config/oh-my-posh/slatewave-omp` if missing
- macOS: `brew bundle` against the repo's `Brewfile` (unless `--no-bootstrap`)
- Linux: prints the `linux-packages.txt` advisory list (unless `--no-bootstrap`)

After it runs, restart the shell or `source ~/.zshrc`.

## Platform-specific env

`.common_env` sources `~/.macos_env` or `~/.linux_env` based on `uname`. These hold OS-specific behavior (PATH bits, key bindings, OS-only commands). On macOS, `.macos_env` additionally sources `~/.1P` for 1Password-managed env (work-only; not part of this repo).

## Per-machine values (`~/.zshrc.local`)

After the OS env file, `.common_env` sources `~/.zshrc.local` if it exists. This file is **machine-local and gitignored** — put per-machine env vars, tokens, or one-off PATH bits here so they never get committed.

```bash
cp .zshrc.local.example ~/.zshrc.local
# edit ~/.zshrc.local and fill in values
```

At minimum, set `CLAUDE_1P_DEV_ENV_ID` (get the value from your local 1P setup).

## License

If you open-source this repo, add a license file; otherwise this is personal configuration.
