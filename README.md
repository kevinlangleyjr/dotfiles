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
| [`.zshrc`](.zshrc)                                      | Example zsh entrypoint (Oh My Zsh, Powerlevel10k, nvm); **not** linked by the installer |

The installer **does not** overwrite `~/.zshrc`. It prints the snippets you should add so `~/.common_env` loads and `~/bin` / `~/.local/bin` are on `PATH`. You can copy ideas from the repo’s `.zshrc` or symlink it yourself if this machine should match the repo exactly.

## Requirements

- **Git** (clone / install)
- **zsh** (configs assume zsh)
- Optional: whatever your `~/.zshrc` references (e.g. [Oh My Zsh](https://ohmyz.sh/), [nvm](https://github.com/nvm-sh/nvm), editors used in aliases)

## Install

### Option A: Clone, then run the script

```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

If the repo already lives somewhere else, run `./install.sh` from that clone; the script detects the git root and uses it.

### Option B: One-liner (remote script)

Replace the URL with your **raw** `install.sh` and set **`REPO_URL`** to the same dotfiles repo you want cloned under `~/.dotfiles`:

```bash
curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/install.sh | REPO_URL='https://github.com/<you>/<repo>.git' bash -s
```

If `~/.dotfiles` already exists and is a git checkout, the script skips cloning.

### Environment variables

| Variable   | Meaning                                                                                                   |
| ---------- | --------------------------------------------------------------------------------------------------------- |
| `DOTFILES` | Directory to use as the dotfiles repo (default: git root when running from disk, otherwise `~/.dotfiles`) |
| `REPO_URL` | Git URL to clone when `DOTFILES` has no `.git` directory (required in that case)                          |

## What the installer links

Symlinks are created in `$HOME` pointing at the repo:

- `.gitconfig`
- `.gitignore_global`
- `.common_env`
- `.macos_env` on Darwin, or `.linux_env` on Linux

After it runs, follow the printed instructions to wire **`~/.common_env`** and **PATH** into `~/.zshrc`, then restart the shell or `source ~/.zshrc`.

## Platform-specific env

`.common_env` sources `~/.macos_env` or `~/.linux_env` based on `uname`. Keep machine-specific or sensitive values there and treat them like any secret-bearing file: avoid committing real secrets, or use a private branch / template file if you share the repo publicly.

## License

If you open-source this repo, add a license file; otherwise this is personal configuration.
