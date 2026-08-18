#!/usr/bin/env bash
# Dotfiles installer
#
# Environment:
#   DOTFILES              Target directory (default: repo root when run from disk, else ~/.dotfiles)
#   REPO_URL              Override clone URL (default: SSH — requires GitHub SSH keys; set when you fork)
#   INSTALL_GIT_DOTFILES  yes/no — link .gitconfig and .gitignore_global (skips prompt when set)
#
# Flags:  --git           link Git config files (non-interactive)
#         --no-git        skip Git config files (non-interactive)
#         --no-bootstrap  skip the Brewfile / linux-packages.txt step
#
# Local:     ./install.sh [--git|--no-git] [--no-bootstrap]
# Remote:    curl -fsSL https://raw.githubusercontent.com/kevinlangleyjr/dotfiles/main/install.sh | bash -s
DEFAULT_REPO_URL='git@github.com:kevinlangleyjr/dotfiles.git'
set -euo pipefail

BOOTSTRAP=yes

for _arg in "$@"; do
	case "$_arg" in
		--git) INSTALL_GIT_DOTFILES=yes ;;
		--no-git) INSTALL_GIT_DOTFILES=no ;;
		--no-bootstrap) BOOTSTRAP=no ;;
	esac
done

want_git_dotfiles() {
	local reply
	case "${INSTALL_GIT_DOTFILES:-}" in
		[yY] | [yY][eE][sS] | 1 | true) return 0 ;;
		[nN] | [nN][oO] | 0 | false) return 1 ;;
	esac
	if [[ ! -r /dev/tty ]]; then
		return 0
	fi
	read -r -p "Link Git config (.gitconfig) and ~/.gitignore_global? [Y/n] " reply </dev/tty || reply=y
	case "${reply:-y}" in
		[nN] | [nN][oO]) return 1 ;;
		*) return 0 ;;
	esac
}

# If a dotfile already exists and is not already our symlink, move it aside as <name>.old
move_existing_to_old() {
	local home_path=$1
	local repo_path=$2
	local name
	name=$(basename "$home_path")

	if [[ -L "$home_path" ]]; then
		local cur
		cur=$(readlink "$home_path")
		if [[ "$cur" == "$repo_path" ]]; then
			return 0
		fi
	fi
	if [[ ! -e "$home_path" && ! -L "$home_path" ]]; then
		return 0
	fi
	local bak="${home_path}.old"
	if [[ -e "$bak" || -L "$bak" ]]; then
		mv -f "$bak" "${bak}.bak"
		echo "install: existing ${name}.old moved to ${name}.old.bak" >&2
	fi
	mv "$home_path" "$bak"
	echo "install: previous ${name} moved to ${name}.old" >&2
}

# Clone a git repo into a target dir unless it's already a checkout. Errors
# clearly when the target exists but isn't a git repo, since `git clone` would
# otherwise fail cryptically and abort the script under `set -e`.
clone_if_absent() {
	local dir=$1 url=$2 label=$3
	if [[ -d "$dir/.git" ]]; then
		echo "install: $label already present at $dir" >&2
		return 0
	fi
	if [[ -e "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
		echo "install: $dir exists but is not a $label checkout; remove it and re-run." >&2
		exit 1
	fi
	mkdir -p "$(dirname "$dir")"
	git clone "$url" "$dir"
}

resolve_dotfiles_dir() {
	if [[ -n "${DOTFILES:-}" ]]; then
		printf '%s' "$DOTFILES"
		return
	fi
	local src="${BASH_SOURCE[0]:-}"
	if [[ -n "$src" && "$src" != "-" ]]; then
		local dir
		dir="$(cd "$(dirname "$src")" && pwd)"
		if git -C "$dir" rev-parse --show-toplevel &>/dev/null; then
			git -C "$dir" rev-parse --show-toplevel
			return
		fi
	fi
	printf '%s' "$HOME/.dotfiles"
}

DOTFILES_DIR="$(resolve_dotfiles_dir)"

REPO_URL="${REPO_URL:-$DEFAULT_REPO_URL}"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
	if [[ -e "$DOTFILES_DIR" ]] && [[ ! -d "$DOTFILES_DIR/.git" ]]; then
		echo "install: $DOTFILES_DIR exists but is not a git clone; remove it or set DOTFILES." >&2
		exit 1
	fi
	git clone "$REPO_URL" "$DOTFILES_DIR"
fi

if want_git_dotfiles; then
	move_existing_to_old "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
	move_existing_to_old "$HOME/.gitignore_global" "$DOTFILES_DIR/.gitignore_global"
	move_existing_to_old "$HOME/.gitconfig-agilebits" "$DOTFILES_DIR/.gitconfig-agilebits"
	ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
	ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
	ln -sf "$DOTFILES_DIR/.gitconfig-agilebits" "$HOME/.gitconfig-agilebits"

	# Select the commit-signing profile for this host and expose it as
	# ~/.gitconfig-os (git can't branch on OS/host, so we decide here). On Linux
	# the presence of 1Password's op-ssh-sign distinguishes a desktop/laptop from
	# a headless server that must fall back to the native ssh-keygen signer.
	case "$(uname -s)" in
		Darwin) git_os_profile=".gitconfig-os-macos" ;;
		Linux)
			if [[ -x /opt/1Password/op-ssh-sign ]]; then
				git_os_profile=".gitconfig-os-linux"
			else
				git_os_profile=".gitconfig-os-linux-server"
			fi
			;;
		*) git_os_profile="" ;;
	esac
	if [[ -n "$git_os_profile" ]]; then
		# ~/.gitconfig-os is fully install-managed: re-point it without backup
		# churn when it already points inside the dotfiles dir.
		if [[ -L "$HOME/.gitconfig-os" && "$(readlink "$HOME/.gitconfig-os")" == "$DOTFILES_DIR/"* ]]; then
			rm -f "$HOME/.gitconfig-os"
		else
			move_existing_to_old "$HOME/.gitconfig-os" "$DOTFILES_DIR/$git_os_profile"
		fi
		ln -sf "$DOTFILES_DIR/$git_os_profile" "$HOME/.gitconfig-os"
		echo "install: git signing profile -> $git_os_profile" >&2
	else
		echo "install: unknown OS $(uname -s); skipped ~/.gitconfig-os signing profile" >&2
	fi
else
	echo "install: skipped ~/.gitconfig, ~/.gitignore_global, ~/.gitconfig-agilebits, ~/.gitconfig-os" >&2
fi

move_existing_to_old "$HOME/.zshrc" "$DOTFILES_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

move_existing_to_old "$HOME/.common_env" "$DOTFILES_DIR/.common_env"
ln -sf "$DOTFILES_DIR/.common_env" "$HOME/.common_env"

SLATEWAVE_OMP_DIR="$HOME/.config/oh-my-posh/slatewave-omp"
SLATEWAVE_OMP_URL="${SLATEWAVE_OMP_URL:-git@github.com:kevinlangleyjr/slatewave-omp.git}"
clone_if_absent "$SLATEWAVE_OMP_DIR" "$SLATEWAVE_OMP_URL" "slatewave-omp"

DELTA_SLATEWAVE_DIR="$HOME/.config/delta-slatewave"
DELTA_SLATEWAVE_URL="${DELTA_SLATEWAVE_URL:-ssh://git@github.com/kevinlangleyjr/delta-slatewave.git}"
clone_if_absent "$DELTA_SLATEWAVE_DIR" "$DELTA_SLATEWAVE_URL" "delta-slatewave"

case "$(uname -s)" in
	Darwin) ln -sf "$DOTFILES_DIR/.macos_env" "$HOME/.macos_env" ;;
	Linux) ln -sf "$DOTFILES_DIR/.linux_env" "$HOME/.linux_env" ;;
	*)
		echo "install: unsupported OS: $(uname -s)" >&2
		exit 1
		;;
esac

# Seed ~/.zshrc.local from the example if it doesn't exist yet.
if [[ ! -e "$HOME/.zshrc.local" ]]; then
	cp "$DOTFILES_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
	echo "install: created ~/.zshrc.local from template — edit it to set per-machine values" >&2
fi

# Symlink bin/ scripts into ~/.local/bin so they land on PATH (the .zshrc
# already adds ~/.local/bin when it exists).
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR"/bin/*; do
	[[ -f "$script" && -x "$script" ]] || continue
	ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Install Neovim (Linux) from the official self-contained tarball, which ships
# the binary together with its runtime (share/nvim/runtime). Copying just the
# nvim binary breaks it: without the runtime it can't find vim.uri/syntax.vim
# and aborts at startup. macOS installs nvim via the Brewfile instead.
install_neovim_linux() {
	local min_major=0 min_minor=11 have_ver
	if command -v nvim >/dev/null 2>&1; then
		have_ver=$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9]*\.[0-9]*\).*/\1/p')
		if [[ -n "$have_ver" ]]; then
			local maj=${have_ver%%.*} min=${have_ver##*.}
			# Skip only when it's already OUR install (the runtime tree exists) and
			# new enough. A bare copied binary reports a version but has no runtime,
			# so it fails this check and gets reinstalled.
			if (( maj > min_major || (maj == min_major && min >= min_minor) )) \
				&& [[ -d "$HOME/.local/nvim/share/nvim/runtime" ]]; then
				echo "install: neovim $have_ver already installed" >&2
				return 0
			fi
		fi
	fi
	local tarch
	case "$(uname -m)" in
		x86_64) tarch=x86_64 ;;
		aarch64 | arm64) tarch=arm64 ;;
		*) echo "install: unsupported arch $(uname -m); skipping neovim" >&2; return 0 ;;
	esac
	local url="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${tarch}.tar.gz"
	local tmp
	tmp=$(mktemp -d)
	echo "install: installing neovim (stable) to ~/.local/nvim..." >&2
	if curl -fL --retry 3 -o "$tmp/nvim.tar.gz" "$url" && tar xzf "$tmp/nvim.tar.gz" -C "$tmp"; then
		rm -rf "$HOME/.local/nvim"
		mv "$tmp/nvim-linux-${tarch}" "$HOME/.local/nvim"
		ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
		echo "install: neovim -> $("$HOME/.local/bin/nvim" --version | head -1)" >&2
	else
		echo "install: neovim download failed; skipping" >&2
	fi
	rm -rf "$tmp"
}
if [[ "$(uname -s)" == Linux ]]; then
	install_neovim_linux
fi

# Bootstrap external tools the shell config expects (oh-my-posh, zoxide, etc).
if [[ "$BOOTSTRAP" == "yes" ]]; then
	case "$(uname -s)" in
		Darwin)
			if command -v brew >/dev/null 2>&1; then
				echo "install: running brew bundle..." >&2
				brew bundle --file="$DOTFILES_DIR/Brewfile"
			else
				echo "install: Homebrew not found; skipping Brewfile. Install brew from https://brew.sh and re-run." >&2
			fi
			;;
		Linux)
			echo "install: Linux bootstrap is advisory only. Recommended packages:" >&2
			grep -v '^\s*#' "$DOTFILES_DIR/linux-packages.txt" | grep -v '^\s*$' | sed 's/^/  - /' >&2
			echo "install: install them with your package manager, e.g. sudo apt install <pkg>..." >&2
			;;
	esac
fi

cat <<'EOF'

Dotfiles linked. Restart the shell or run: source ~/.zshrc

If you had a customized ~/.zshrc, it's been preserved at ~/.zshrc.old.
EOF
