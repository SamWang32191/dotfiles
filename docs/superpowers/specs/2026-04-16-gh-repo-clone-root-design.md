# gh repo clone 根目錄包裝設計

## 目標

讓 `gh repo clone` 在未指定目標目錄時，預設 clone 到 `~/code/github.com/<owner>/<repo>`；若指定第二個參數且該參數不是絕對路徑或 `./`、`../` 類型路徑，則將其視為相對於 `~/code/github.com` 的路徑。

## 非目標

- 不修改 GitHub CLI 本身的設定或安裝方式
- 不自動為已存在的 clone 目錄改名
- 不改寫非 `gh repo clone` 的其他 `gh` 子命令

## 行為規則

- `gh repo clone softleader/kapok` -> `~/code/github.com/softleader/kapok`
- `gh repo clone softleader/kapok softleader/kapok-worktree2` -> `~/code/github.com/softleader/kapok-worktree2`
- `gh repo clone softleader/kapok /tmp/kapok` 保留 GitHub CLI 原本行為
- `gh repo clone softleader/kapok ./kapok`、`../kapok` 保留 GitHub CLI 原本行為
- 若目標父目錄不存在，wrapper 先建立父目錄
- 若目標目錄已存在，wrapper 在呼叫 `gh` 前直接失敗，並提示如何用第二個參數指定其他路徑

## 實作方式

- 在 `zsh` 載入鏈中加入 `gh()` shell function，僅攔截 `repo clone`
- function 內部使用 `command gh` 呼叫真正的 GitHub CLI，避免遞迴
- 僅辨識目前 `gh repo clone` 官方支援的 clone 旗標：`--no-upstream`、`-u`、`--upstream-remote-name`
- 若出現未知旗標或無法安全判讀的參數形態，直接回退到原始 `gh repo clone` 行為

## 驗證

- 用非互動 `zsh` 啟動並 source 設定檔
- 以暫時的 fake `gh` 可執行檔驗證 wrapper 實際轉發出去的參數
- 覆蓋以下情境：
  - 無第二個參數
  - 使用根目錄相對路徑作為第二個參數
  - 使用絕對路徑作為第二個參數
  - 目標目錄已存在時的提示訊息
  - 使用 `--no-upstream`
  - 使用 `--` 後續 git clone flags
