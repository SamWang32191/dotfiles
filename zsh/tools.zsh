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
# Eagerly load SDKMAN completion so aliases like `sdj` get TAB completion
# without triggering the lazy-load first.
export SDKMAN_CANDIDATES_DIR="${SDKMAN_DIR}/candidates"
if [[ -r "$SDKMAN_DIR/contrib/completion/bash/sdk" ]]; then
  autoload -U bashcompinit
  bashcompinit
  source "$SDKMAN_DIR/contrib/completion/bash/sdk"
fi

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

_gh_repo_clone_relative_path() {
  local repo="$1"
  local rel

  case "$repo" in
    git@github.com:*)
      rel="${repo#git@github.com:}"
      ;;
    ssh://git@github.com/*)
      rel="${repo#ssh://git@github.com/}"
      ;;
    https://github.com/*|http://github.com/*)
      rel="${repo#*://github.com/}"
      ;;
    github.com/*)
      rel="${repo#github.com/}"
      ;;
    *)
      rel="$repo"
      ;;
  esac

  rel="${rel%.git}"
  rel="${rel#/}"
  printf '%s\n' "$rel"
}

_gh_repo_clone_conflict_example_path() {
  local repo="$1"
  local requested_directory="${2:-}"
  local base_path

  if [[ -n "$requested_directory" ]]; then
    base_path="$requested_directory"
  else
    base_path="$(_gh_repo_clone_relative_path "$repo")"
  fi

  printf '%s-worktree2\n' "$base_path"
}

_gh_repo_clone_conflict_error() {
  local repo="$1"
  local target="$2"
  local requested_directory="${3:-}"
  local example_path

  example_path="$(_gh_repo_clone_conflict_example_path "$repo" "$requested_directory")"

  printf 'gh repo clone: 目標目錄已存在: %s\n' "$target" >&2
  printf '若要 clone 到其他路徑，請指定第二個參數，例如：gh repo clone %s %s\n' "$repo" "$example_path" >&2
}

gh() {
  local -a original_args
  original_args=("$@")

  if [[ "$1" != "repo" || "$2" != "clone" ]]; then
    command gh "${original_args[@]}"
    return
  fi

  local clone_root="${GH_REPO_CLONE_ROOT:-$HOME/code/github.com}"
  local -a before_gitflags gitflags clone_opts positionals
  local repo directory target arg
  local expect_flag_value=""
  local in_gitflags=0

  shift 2
  for arg in "$@"; do
    if (( in_gitflags )); then
      gitflags+=("$arg")
      continue
    fi

    if [[ "$arg" == "--" ]]; then
      in_gitflags=1
      continue
    fi

    before_gitflags+=("$arg")
  done

  local i
  for (( i = 1; i <= ${#before_gitflags[@]}; i++ )); do
    arg="${before_gitflags[i]}"

    if [[ -n "$expect_flag_value" ]]; then
      clone_opts+=("$arg")
      expect_flag_value=""
      continue
    fi

    case "$arg" in
      -u|--upstream-remote-name)
        clone_opts+=("$arg")
        expect_flag_value=1
        ;;
      -u=*|--upstream-remote-name=*|--no-upstream|--help)
        clone_opts+=("$arg")
        ;;
      -*)
        command gh "${original_args[@]}"
        return
        ;;
      *)
        positionals+=("$arg")
        ;;
    esac
  done

  if [[ -n "$expect_flag_value" || ${#positionals[@]} -eq 0 || ${#positionals[@]} -gt 2 ]]; then
    command gh "${original_args[@]}"
    return
  fi

  repo="${positionals[1]}"

  if (( ${#positionals[@]} == 2 )); then
    directory="${positionals[2]}"
    case "$directory" in
      /*|~|~/*|~*/*|./*|../*|.|..)
        command gh "${original_args[@]}"
        return
        ;;
      *)
        target="$clone_root/$directory"
        ;;
    esac
  else
    target="$clone_root/$(_gh_repo_clone_relative_path "$repo")"
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    _gh_repo_clone_conflict_error "$repo" "$target" "$directory"
    return 1
  fi

  mkdir -p "${target:h}" || return

  if (( ${#gitflags[@]} > 0 )); then
    command gh repo clone "${clone_opts[@]}" "$repo" "$target" -- "${gitflags[@]}"
    return
  fi

  command gh repo clone "${clone_opts[@]}" "$repo" "$target"
}
