# Dotfiles

Personal shell and Git configuration for **macOS** and **Linux**, managed as a git repo and installed with a small symlink script.

## What’s in here

| File                                                    | Purpose                                                                                 |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [`install.sh`](install.sh)                              | Clones (if needed) and symlinks configs into `$HOME`                                    |
| [`.common_env`](.common_env)                            | Shared zsh aliases, options, and functions (sourced from `~/.zshrc`)                    |
| [`.macos_env`](.macos_env) / [`.linux_env`](.linux_env) | Per-OS environment (e.g. tool-specific IDs); sourced by `.common_env`                   |
| [`.gitconfig`](.gitconfig)                              | Default Git identity + global config; uses `includeIf` to load `.gitconfig-agilebits` for 1P repo paths |
| [`.gitconfig-agilebits`](.gitconfig-agilebits)          | Work identity overrides — applied via `includeIf` for `~/Development/1P/` and `~/go/src/go.1password.io/` |
| [`.gitignore_global`](.gitignore_global)                | Patterns ignored by Git everywhere (`core.excludesFile`)                                |
| [`.zshrc`](.zshrc)                                      | Zsh entrypoint (oh-my-posh + slatewave theme, zoxide, lazy nvm). Linked by the installer; an existing `~/.zshrc` is moved to `~/.zshrc.old` first |
| [`.zshrc.local.example`](.zshrc.local.example)          | Template for per-machine values (e.g. `CLAUDE_1P_DEV_ENV_ID`); copy to `~/.zshrc.local`              |
| [`bin/`](bin/)                                          | Standalone helper scripts (`killport`, `dotfiles-update`); installer symlinks each into `~/.local/bin` |
| [`Brewfile`](Brewfile)                                  | macOS dependencies — installed by `install.sh` via `brew bundle` (skip with `--no-bootstrap`)         |
| [`linux-packages.txt`](linux-packages.txt)              | Linux package list, advisory only — `install.sh` prints it but doesn't run apt for you               |

## Tools the shell expects

These are pulled in by `Brewfile` on macOS (or `linux-packages.txt` on Linux). The shell config gracefully no-ops the optional ones, but the experience assumes they're present.

| Tool                                       | What it's for                                                |
| ------------------------------------------ | ------------------------------------------------------------ |
| [oh-my-posh](https://ohmyposh.dev/)        | Prompt rendering engine; uses the `slatewave` theme          |
| [zoxide](https://github.com/ajeetdsouza/zoxide)        | Frecency-ranked `cd`. Backs the `j` / `s` / `d` / `p` aliases. |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info splash on shell launch                          |
| [lsd](https://github.com/lsd-rs/lsd)       | Modern `ls`; backs `ll`                                      |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Faster `grep`; backs the global `\|G` alias              |
| [git-delta](https://github.com/dandavison/delta) | Git diff pager (configured in `.gitconfig`)            |
| `figlet`, `lolcat`                         | Banner / rainbow text helpers (`label`, `title`, `hero`, `morning`) |
| [nvm](https://github.com/nvm-sh/nvm)       | Node version manager — lazy-loaded; install separately       |

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
| `INSTALL_GIT_DOTFILES` | `yes` / `no` — whether to link `~/.gitconfig`, `~/.gitignore_global`, and `~/.gitconfig-agilebits`. When unset and your terminal is interactive, the script **asks**; when stdin isn’t a TTY (e.g. some CI), it defaults to **yes** so existing one-liners keep working. |

You can also pass **`--no-git`** or **`--git`** to `install.sh` instead of using the variable.

## What the installer does

Symlinks created in `$HOME` pointing at the repo:

- **Optional (prompt or `INSTALL_GIT_DOTFILES` / `--git` / `--no-git`):** `.gitconfig`, `.gitignore_global`, `.gitconfig-agilebits` — any pre-existing file is moved to `.<name>.old` (and a prior `.old` is shifted to `.old.bak`) before linking, unless it's already a symlink to this repo's copy
- **Always:** `.zshrc`, `.common_env`
- **Always (OS-specific):** `.macos_env` on Darwin, `.linux_env` on Linux

Plus:

- Each executable in `bin/` symlinked into `~/.local/bin/`
- `~/.zshrc.local` seeded from `.zshrc.local.example` if it doesn't exist
- The `slatewave-omp` oh-my-posh theme cloned to `~/.config/oh-my-posh/slatewave-omp` if missing
- macOS: `brew bundle` against the repo's `Brewfile` (unless `--no-bootstrap`)
- Linux: prints the `linux-packages.txt` advisory list (unless `--no-bootstrap`)

After it runs, restart the shell or `source ~/.zshrc`.

## Helper scripts

`bin/` contains standalone scripts; the installer symlinks each into `~/.local/bin/`, which `.zshrc` puts on `PATH`.

| Command                  | What it does                                                                                                              |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| `killport <port>`        | Kills any process listening on the given TCP port. Requires `sudo`.                                                       |
| `dotfiles-update`        | `cd $DOTFILES_DIR && git pull`. `DOTFILES_DIR` defaults to `~/.dotfiles`.                                                  |
| `bak <path>`             | Copies a file or directory to `<path>.bak.YYYY-MM-DD-HHMMSS` in place. Prints the new path.                                |
| `whichall <cmd>`         | Lists every executable matching `<cmd>` across `$PATH`, not just the first. Useful for PATH conflicts (brew vs nvm, etc.). |
| `portcheck <port>`       | Read-only counterpart to `killport`: prints what's listening on a TCP port (no `sudo` needed for your own processes).      |
| `git-cleanup`            | Fetches with `--prune`, then prompts to delete (a) local branches whose upstream is gone and (b) local branches fully merged into the default branch. |

`.common_env` keeps `killPort` / `updateDotfiles` aliases pointed at these for muscle-memory continuity.

## Platform-specific env

`.common_env` sources `~/.macos_env` or `~/.linux_env` based on `uname`. These hold OS-specific behavior (PATH bits, key bindings, OS-only commands). On macOS, `.macos_env` additionally sources `~/.1P` for 1Password-managed env (work-only; not part of this repo).

## Per-machine values (`~/.zshrc.local`)

After the OS env file, `.common_env` sources `~/.zshrc.local` if it exists. This file is **machine-local and gitignored** — put per-machine env vars, tokens, or one-off PATH bits here so they never get committed.

```bash
cp .zshrc.local.example ~/.zshrc.local
# edit ~/.zshrc.local and fill in values
```

At minimum, set `CLAUDE_1P_DEV_ENV_ID` (get the value from your local 1P setup).

## Troubleshooting

- **Shell startup feels slow.** Profile with `time zsh -i -c exit`. The biggest contributors are usually `fastfetch` and the `nvm` lazy-load on first node invocation. The `compinit` cache rebuilds every 24h — `rm ~/.zcompdump*` forces a rebuild.
- **`killport: command not found`.** `~/.local/bin` isn't on `PATH`. The `.zshrc` only adds it if the directory exists — re-run `./install.sh` to create it and link the bin scripts.
- **Wrong git identity in a commit.** `git config --local user.email` overrides any `includeIf`. Check the local repo with `git config --show-origin user.email` to see which file is winning.
- **`oh-my-posh: command not found` on first launch.** Brewfile didn't run, or the Brewfile bootstrap was skipped. Run `./install.sh` (or `brew bundle --file=~/.dotfiles/Brewfile` directly).

## License

If you open-source this repo, add a license file; otherwise this is personal configuration.
