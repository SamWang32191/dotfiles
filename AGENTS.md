# AGENTS.md

## Scope

本檔適用於 `/Users/samwang/dotfiles`（symlink 模式 dotfiles repo）。

## Goals

- 管理可重建的個人設定檔。
- 透過 `install.sh` 將 repo 內容 symlink 到 `$HOME`。
- 避免 secrets 與 runtime state 進入版本控制。

## Allowed Changes

- 可修改並追蹤：`zsh/`, `git/`, `ssh/`, `tools/`, `config/`, `brew/`, `bin/`。
- 可新增模板檔（例如 `*.example`）。

## Never Track Secrets Or Runtime State

- Secrets: `.myenv`, `ssh/id_*`, `*.pem`, `*.key`。
- History/cache/state: `.zsh_history`, `.bash_history`, `.zcompdump*`, `.DS_Store`。
- Auto-generated/local files: `.yarnrc`, `.nuxtrc`, `.stCommitMsg`, `.gitflow_export`。
- App runtime/auth state: `config/gcloud/`, `config/gh/`, `config/op/`, `config/1Password/`, `config/configstore/`。

## Workflow

```bash
git -C "$HOME/dotfiles" status
git -C "$HOME/dotfiles" diff
git -C "$HOME/dotfiles" add <path>
git -C "$HOME/dotfiles" diff --cached
```
