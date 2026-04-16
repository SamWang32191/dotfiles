# gh repo clone 根目錄包裝 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `gh repo clone` 預設落在 `~/code/github.com` 下，並保留 `owner/repo` 路徑層級。

**Architecture:** 在 `zsh/tools.zsh` 加入一層薄的 `gh()` wrapper，只在 `repo clone` 時解析參數並重寫目標目錄，其餘命令全部交回真正的 `gh`。驗證採用 fake `gh` binary 的非互動 smoke test。

**Tech Stack:** zsh、GitHub CLI、shell smoke test

---

## File Structure

- Modify: `zsh/tools.zsh`
  - 新增 `gh repo clone` 包裝與路徑解析 helper
- Create: `docs/superpowers/specs/2026-04-16-gh-repo-clone-root-design.md`
  - 記錄行為規則與非目標
- Create: `docs/superpowers/plans/2026-04-16-gh-repo-clone-root.md`
  - 記錄實作與驗證步驟

### Task 1: 加入 gh repo clone wrapper

**Files:**
- Modify: `zsh/tools.zsh`
- Verify: `docs/superpowers/specs/2026-04-16-gh-repo-clone-root-design.md`

- [ ] **Step 1: 在 `zsh/tools.zsh` 新增 helper**

加入一個將 repo 參數轉成 clone 相對路徑的 helper，支援 `OWNER/REPO`、`https://github.com/OWNER/REPO` 與 `git@github.com:OWNER/REPO.git` 形式。

- [ ] **Step 2: 實作 `gh()` wrapper**

只攔截 `gh repo clone`，辨識 `--no-upstream`、`-u`、`--upstream-remote-name`，在安全可判讀的情況下重寫目標目錄，其他情況直接 fallback 到原始 `gh`。

- [ ] **Step 3: 確保會先建立父目錄**

在 wrapper 內對重寫後的目標目錄執行 `mkdir -p "${target:h}"`，避免 `owner/` 目錄不存在時 clone 失敗。

### Task 2: 驗證 wrapper 行為

**Files:**
- Create: `bin/test_gh_repo_clone_wrapper.sh`
- Verify: `zsh/tools.zsh`

- [ ] **Step 1: 準備 fake `gh` binary**

建立暫時目錄，放一個只會印出收到參數的 `gh` 腳本，並把它放到 `PATH` 最前面。

- [ ] **Step 2: 驗證預設 clone 路徑**

Run: `zsh -fc 'HOME=/tmp/... PATH="/tmp/...:$PATH" source .../zsh/tools.zsh; gh repo clone softleader/kapok'`

Expected: fake `gh` 收到 `repo clone softleader/kapok /tmp/.../code/github.com/softleader/kapok`

- [ ] **Step 3: 驗證第二個參數的根目錄相對路徑**

Run: `... gh repo clone softleader/kapok softleader/kapok-worktree2`

Expected: fake `gh` 收到 `... /tmp/.../code/github.com/softleader/kapok-worktree2`

- [ ] **Step 4: 驗證絕對路徑保留原行為**

Run: `... gh repo clone softleader/kapok /tmp/kapok`

Expected: fake `gh` 收到原始的 `/tmp/kapok`

- [ ] **Step 5: 驗證 clone flags 與 git flags 保留**

Run: `... gh repo clone --no-upstream softleader/kapok -- --depth=1`

Expected: fake `gh` 收到 `repo clone --no-upstream softleader/kapok /tmp/.../code/github.com/softleader/kapok -- --depth=1`

- [ ] **Step 6: 驗證目標已存在時的自訂錯誤**

先建立 `/tmp/.../code/github.com/softleader/agent-skills`，再執行：

Run: `... gh repo clone softleader/agent-skills`

Expected:
- wrapper 直接以非 0 exit 結束
- fake `gh` 不會被呼叫
- stderr 會包含既有目標路徑
- stderr 會包含可直接複製的替代指令，例如 `gh repo clone softleader/agent-skills softleader/agent-skills-worktree2`
