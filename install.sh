#!/usr/bin/env bash
# Dotfiles installer
#
# Environment:
#   DOTFILES   Target directory (default: repo root when run from disk, else ~/.dotfiles)
#   REPO_URL   Override clone URL (default: SSH — requires GitHub SSH keys; set when you fork)
#
# Local:     ./install.sh
# Remote:    curl -fsSL https://raw.githubusercontent.com/kevinlangleyjr/dotfiles/main/install.sh | bash -s
DEFAULT_REPO_URL='git@github.com:kevinlangleyjr/dotfiles.git'
set -euo pipefail

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

ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
ln -sf "$DOTFILES_DIR/.common_env" "$HOME/.common_env"

case "$(uname -s)" in
	Darwin) ln -sf "$DOTFILES_DIR/.macos_env" "$HOME/.macos_env" ;;
	Linux) ln -sf "$DOTFILES_DIR/.linux_env" "$HOME/.linux_env" ;;
	*)
		echo "install: unsupported OS: $(uname -s)" >&2
		exit 1
		;;
esac

cat <<'EOF'

Dotfiles linked. Add the following to your ~/.zshrc (if not already present).

--- common env (~/.common_env) ---
if [ -f ~/.common_env ]; then
	. ~/.common_env
fi

--- PATH (~/bin and ~/.local/bin) ---
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
	PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes ~/.local/bin if it exists
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
	PATH="$HOME/.local/bin:$PATH"
fi

Then restart the shell or run: source ~/.zshrc
EOF
