# Dotfiles (Symlink Mode)

`~/dotfiles` 是設定檔唯一來源；生效檔案由 `install.sh` symlink 到 `$HOME`。

## Repository Layout

- `zsh/`
- `git/`
- `ssh/`
- `tools/`
- `config/btop/`
- `config/codex/`
- `config/ghostty/`
- `config/opencode/`
- `brew/`
- `bin/`

## Workflow

1. 修改 `~/dotfiles` 內檔案。
2. 執行 `bash ~/dotfiles/install.sh`（建立或更新 symlink）。
3. 檢查變更後再進行 commit/push。

## Security Rules

- 不追蹤 secrets（例如 `.myenv`、SSH 私鑰）。
- 不追蹤 shell history、快取與 app runtime/auth 狀態。
- 只納入可在新機重建的設定內容。
