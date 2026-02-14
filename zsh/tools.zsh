# Open in tmux popup if on tmux, otherwise use --height mode
export FZF_DEFAULT_OPTS="--style full"
export FZF_CTRL_T_OPTS="--preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"
# Set up fzf key bindings and fuzzy completion (cached)
if command -v fzf >/dev/null 2>&1; then
  FZF_ZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-zsh-init.zsh"
  FZF_BIN="$(command -v fzf)"
  if [[ ! -s "$FZF_ZSH_CACHE" || "$FZF_BIN" -nt "$FZF_ZSH_CACHE" ]]; then
    fzf --zsh >| "$FZF_ZSH_CACHE"
  fi
  source "$FZF_ZSH_CACHE"
  unset FZF_BIN FZF_ZSH_CACHE
fi

# SDKMAN: keep current candidates on PATH, lazy-load full init on first `sdk` usage.
export SDKMAN_DIR="${HOME}/.sdkman"
if [[ -r "$SDKMAN_DIR/var/candidates" ]]; then
  for _sdkman_name in ${(s:,:)$(<"$SDKMAN_DIR/var/candidates")}; do
    _sdkman_candidate_bin="$SDKMAN_DIR/candidates/${_sdkman_name}/current/bin"
    if [[ -d "$_sdkman_candidate_bin" ]]; then
      # Always move candidate bin to the front. This avoids accidentally
      # hitting system stubs like /usr/bin/java when the candidate bin is
      # already present later in PATH.
      path=("$_sdkman_candidate_bin" ${path:#"$_sdkman_candidate_bin"})
    fi
  done
  unhash java 2>/dev/null || true
  unset _sdkman_name _sdkman_candidate_bin
fi
sdk() {
  unset -f sdk
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# 1Password Cli completions
if command -v op >/dev/null 2>&1; then
  OP_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/op-completion.zsh"
  OP_BIN="$(command -v op)"
  if [[ ! -s "$OP_COMPLETION_CACHE" || "$OP_BIN" -nt "$OP_COMPLETION_CACHE" ]]; then
    op completion zsh >| "$OP_COMPLETION_CACHE"
  fi
  source "$OP_COMPLETION_CACHE"
  compdef _op op
  unset OP_BIN OP_COMPLETION_CACHE
fi

###-begin-opencode-completions-###
#
# yargs command completion script
#
# Installation: opencode completion >> ~/.zshrc
#    or opencode completion >> ~/.zprofile on OSX.
#
_opencode_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'\n' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
  IFS=$si
  if [[ ${#reply} -gt 0 ]]; then
    _describe 'values' reply
  else
    _default
  fi
}
if [[ "'${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
  _opencode_yargs_completions "$@"
else
  compdef _opencode_yargs_completions opencode
fi
###-end-opencode-completions-###
