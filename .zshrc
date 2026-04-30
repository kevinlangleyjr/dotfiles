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
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ -d "$PNPM_HOME" ]; then
	case ":$PATH:" in
		*":$PNPM_HOME:"*) ;;
		*) export PATH="$PNPM_HOME:$PATH" ;;
	esac
fi
# pnpm end

if [ -f ~/.common_env ]; then
	. ~/.common_env
fi

# Lazy-load nvm: defer the ~300ms nvm.sh source until first nvm/node/npm/npx call.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
	_load_nvm() {
		unset -f nvm node npm npx _load_nvm
		\. "$NVM_DIR/nvm.sh"
		[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
	}
	nvm()  { _load_nvm; nvm "$@"; }
	node() { _load_nvm; node "$@"; }
	npm()  { _load_nvm; npm "$@"; }
	npx()  { _load_nvm; npx "$@"; }
fi

eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/slatewave-omp/slatewave.omp.yml)"

eval "$(zoxide init zsh)"

# direnv hook — auto-loads/unloads .envrc files when changing directories.
if command -v direnv >/dev/null 2>&1; then
	eval "$(direnv hook zsh)"
fi

if command -v fastfetch >/dev/null 2>&1; then
	fastfetch
fi
