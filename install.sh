#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles_backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
BACKUP_CREATED=0

ensure_backup_dir() {
  if [ "$BACKUP_CREATED" -eq 0 ]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=1
    echo "Backup directory: $BACKUP_DIR"
  fi
}

backup_target_path() {
  local dst="$1"
  local rel

  case "$dst" in
    "$HOME"/*)
      rel="${dst#$HOME/}"
      ;;
    *)
      rel="$(basename "$dst")"
      ;;
  esac

  printf '%s/%s\n' "$BACKUP_DIR" "$rel"
}

link_file() {
  local src_rel="$1"
  local dst="$2"
  local src="$DOTFILES_DIR/$src_rel"

  if [ ! -e "$src" ]; then
    echo "Missing source: $src" >&2
    return 1
  fi

  if [ -L "$dst" ] && [ "$dst" -ef "$src" ]; then
    echo "[SKIP] Already linked: $dst -> $src"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup_path
    backup_path="$(backup_target_path "$dst")"

    ensure_backup_dir
    mkdir -p "$(dirname "$backup_path")"
    mv "$dst" "$backup_path"
    echo "[BACKUP] $dst -> $backup_path"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "[LINK] $dst -> $src"
}

echo "Installing dotfiles from: $DOTFILES_DIR"

# Task 2 docs (.gitignore, README.md, AGENTS.md) are repo-local only.
# Intentionally no mapping for ~/.myenv (secret file).

declare -a LINK_MAPPINGS=(
  "zsh/zprofile|$HOME/.zprofile"
  "zsh/zshrc|$HOME/.zshrc"
  "zsh/path.zsh|$HOME/.zsh/path.zsh"
  "zsh/omz.zsh|$HOME/.zsh/omz.zsh"
  "zsh/tools.zsh|$HOME/.zsh/tools.zsh"
  "shell/myalias|$HOME/.myalias"
  "shell/myenv.example|$HOME/.myenv.example"
  "git/gitconfig|$HOME/.gitconfig"
  "git/gitignore_global|$HOME/.gitignore_global"
  "ssh/config|$HOME/.ssh/config"
  "tools/npmrc|$HOME/.npmrc"
  "tools/testcontainers.properties|$HOME/.testcontainers.properties"
  "config/btop/btop.conf|$HOME/.config/btop/btop.conf"
  "config/macmon.json|$HOME/.config/macmon.json"
  "config/ghostty/config|$HOME/.config/ghostty/config"
  "config/opencode/opencode.json|$HOME/.config/opencode/opencode.json"
  "config/opencode/oh-my-opencode.json|$HOME/.config/opencode/oh-my-opencode.json"
  "bin/start_jdtls.sh|$HOME/.bin/start_jdtls.sh"
)

for mapping in "${LINK_MAPPINGS[@]}"; do
  IFS='|' read -r src_rel dst <<< "$mapping"
  link_file "$src_rel" "$dst"
done

echo
echo "Next steps:"
echo "- brew bundle --file=~/dotfiles/brew/Brewfile"
echo "- copy ~/.myenv.example -> ~/.myenv"
echo "- exec zsh"
