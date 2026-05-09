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
	move_existing_to_old "$HOME/.gitconfig-os-linux" "$DOTFILES_DIR/.gitconfig-os-linux"
	move_existing_to_old "$HOME/.gitconfig-os-macos" "$DOTFILES_DIR/.gitconfig-os-macos"
	ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
	ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
	ln -sf "$DOTFILES_DIR/.gitconfig-agilebits" "$HOME/.gitconfig-agilebits"
	ln -sf "$DOTFILES_DIR/.gitconfig-os-linux" "$HOME/.gitconfig-os-linux"
	ln -sf "$DOTFILES_DIR/.gitconfig-os-macos" "$HOME/.gitconfig-os-macos"
else
	echo "install: skipped ~/.gitconfig, ~/.gitignore_global, ~/.gitconfig-agilebits, ~/.gitconfig-os-{linux,macos}" >&2
fi

move_existing_to_old "$HOME/.zshrc" "$DOTFILES_DIR/.zshrc"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

ln -sf "$DOTFILES_DIR/.common_env" "$HOME/.common_env"

SLATEWAVE_OMP_DIR="$HOME/.config/oh-my-posh/slatewave-omp"
SLATEWAVE_OMP_URL="${SLATEWAVE_OMP_URL:-git@github.com:kevinlangleyjr/slatewave-omp.git}"
if [[ ! -d "$SLATEWAVE_OMP_DIR/.git" ]]; then
	mkdir -p "$(dirname "$SLATEWAVE_OMP_DIR")"
	git clone "$SLATEWAVE_OMP_URL" "$SLATEWAVE_OMP_DIR"
else
	echo "install: slatewave-omp already present at $SLATEWAVE_OMP_DIR" >&2
fi

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
