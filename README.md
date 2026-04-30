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
| [`.zshrc`](.zshrc)                                      | Example zsh entrypoint (oh-my-posh + slatewave theme, zoxide, nvm); **not** linked by the installer |
| [`.zshrc.local.example`](.zshrc.local.example)          | Template for per-machine values (e.g. `CLAUDE_1P_DEV_ENV_ID`); copy to `~/.zshrc.local`              |

The installer **does not** overwrite `~/.zshrc`. It prints the snippets you should add so `~/.common_env` loads and `~/bin` / `~/.local/bin` are on `PATH`. You can copy ideas from the repo’s `.zshrc` or symlink it yourself if this machine should match the repo exactly.

## Requirements

- **Git** (clone / install)
- **zsh** (configs assume zsh)
- Optional: whatever your `~/.zshrc` references (e.g. [Oh My Zsh](https://ohmyz.sh/), [nvm](https://github.com/nvm-sh/nvm), editors used in aliases)

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

## What the installer links

Symlinks are created in `$HOME` pointing at the repo:

- **Optional (prompt or `INSTALL_GIT_DOTFILES` / `--git` / `--no-git`):** `.gitconfig`, `.gitignore_global` — existing files are moved to `.gitconfig.old` / `.gitignore_global.old` (and a prior `.old` is shifted to `.old.bak`) before linking, unless the home file is already a symlink to this repo’s copy
- **Always:** `.common_env`
- **Always (OS-specific):** `.macos_env` on Darwin, or `.linux_env` on Linux

After it runs, follow the printed instructions to wire **`~/.common_env`** and **PATH** into `~/.zshrc`, then restart the shell or `source ~/.zshrc`.

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
