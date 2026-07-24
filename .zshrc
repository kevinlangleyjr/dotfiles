# Keep $path (and therefore $PATH) deduplicated. Anything that prepends
# or appends from here on — this file, .common_env, .macos_env, ~/.1P,
# ~/.zshrc.local — gets a free dedup on assignment.
typeset -U path PATH

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
	PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes ~/.local/bin if it exists
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
	PATH="$HOME/.local/bin:$PATH"
fi

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# yarn: the `yarn` command comes via corepack on the node bin dir (added below).
# These are only the classic `yarn global` bin dirs — add them if they exist so
# a missing/empty dir never lands on PATH.
[ -d "$HOME/.config/yarn/global/node_modules/.bin" ] && PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"
[ -d "$HOME/.yarn/bin" ] && PATH="$HOME/.yarn/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
# pnpm >=9 installs global binaries into $PNPM_HOME/bin, so both must be on PATH.
for pnpm_dir in "$PNPM_HOME" "$PNPM_HOME/bin"; do
	if [ -d "$pnpm_dir" ]; then
		case ":$PATH:" in
			*":$pnpm_dir:"*) ;;
			*) export PATH="$pnpm_dir:$PATH" ;;
		esac
	fi
done
unset pnpm_dir
# pnpm end

if [ -f ~/.common_env ]; then
	. ~/.common_env
fi

# nvm without the ~300ms startup cost: eagerly put the `default` node version's
# bin on PATH (cheap — no nvm.sh source) so node/npm/npx are real binaries that
# work everywhere, including non-interactive shells and captured shell snapshots.
# Only the `nvm` command itself lazy-sources the full machinery on first use.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
	if [ -f "$NVM_DIR/alias/default" ]; then
		_nvm_default="$(command cat "$NVM_DIR/alias/default")"
		# Expand a partial alias (e.g. "24") to the newest matching install.
		_nvm_ver="$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null \
			| grep -E "^v${_nvm_default#v}([.]|$)" | sort -V | tail -1)"
		if [ -n "$_nvm_ver" ] && [ -d "$NVM_DIR/versions/node/$_nvm_ver/bin" ]; then
			PATH="$NVM_DIR/versions/node/$_nvm_ver/bin:$PATH"
		fi
		unset _nvm_default _nvm_ver
	fi

	# Lazy-load full nvm only when `nvm` itself is invoked.
	nvm() {
		unset -f nvm
		\. "$NVM_DIR/nvm.sh"
		[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
		nvm "$@"
	}
fi

# zoxide (frecent directory jumping); guarded so headless hosts don't error.
if command -v zoxide >/dev/null 2>&1; then
	eval "$(zoxide init zsh)"
fi

# direnv hook — auto-loads/unloads .envrc files when changing directories.
if command -v direnv >/dev/null 2>&1; then
	eval "$(direnv hook zsh)"
fi

if command -v fastfetch >/dev/null 2>&1; then
	fastfetch
fi

# slatewave prompt; guarded so headless hosts without oh-my-posh don't error.
if command -v oh-my-posh >/dev/null 2>&1; then
	eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/slatewave.omp.yml)"
fi

export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"