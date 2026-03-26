# start_jdtls.sh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 `bin/start_jdtls.sh` 收斂為只支援 arm64 macOS，固定使用 `"$DIR/config_mac_arm"`，並移除所有 OS/architecture 判斷與 writable fallback。

**Architecture:** 實作只修改單一 shell script。保留 launcher、workspace hash、Java runtime 選擇與 JVM/JDTLS 啟動參數；僅把 configuration 選擇邏輯替換成固定常數，讓腳本直接把 `-configuration` 指向安裝流程提供的 `config_mac_arm`。

**Tech Stack:** POSIX shell、JDTLS、macOS arm64

---

## File Structure

- Modify: `bin/start_jdtls.sh`
  - 保留既有 JDTLS 啟動流程
  - 移除 `uname`/`case` 平台判斷與 writable fallback
  - 新增固定 `CONFIG="$DIR/config_mac_arm"`
- Verify against: `docs/superpowers/specs/2026-03-26-start-jdtls-design.md`
  - 確認實作完整覆蓋 spec 的變更範圍、非目標與驗證要求

### Task 1: 固定 JDTLS configuration 並移除 fallback

**Files:**
- Modify: `bin/start_jdtls.sh:13-46`
- Verify: `docs/superpowers/specs/2026-03-26-start-jdtls-design.md:12-37`

- [ ] **Step 1: 先寫出預期修改內容**

將 `bin/start_jdtls.sh` 的 configuration 區塊改成以下內容：

```sh
CONFIG="$DIR/config_mac_arm"
```

並保留後續 Java 與 `exec` 區塊不變，讓結尾維持：

```sh
exec "$JAVA_BIN" \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dosgi.checkConfiguration=true \
  -Dosgi.sharedConfiguration.area.readOnly=true \
  -Xms1G -Xmx2G \
  -XX:+TieredCompilation \
  -XX:TieredStopAtLevel=1 \
  --add-modules=ALL-SYSTEM \
  --add-exports java.base/jdk.internal.misc=ALL-UNNAMED \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED \
  --add-opens java.base/java.io=ALL-UNNAMED \
  --add-opens java.base/java.nio=ALL-UNNAMED \
  --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
  --add-opens java.compiler/javax.annotation.processing=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.element=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.type=ALL-UNNAMED \
  --add-opens java.compiler/javax.lang.model.util=ALL-UNNAMED \
  --add-opens java.compiler/javax.tools=ALL-UNNAMED \
  -javaagent:"$LOMBOK_JAR" \
  -jar "$LAUNCHER" \
  -configuration "$CONFIG" \
  -data "$WORKSPACE"
```

- [ ] **Step 2: 編輯腳本，移除平台判斷與 writable fallback**

把下列整段刪掉：

```sh
# Detect OS and architecture
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

case "$OS_TYPE" in
  Darwin)
    if [ "$ARCH_TYPE" = "arm64" ] && [ -d "$DIR/config_mac_arm" ]; then
      CONFIG_BASE="$DIR/config_mac_arm"
    else
      CONFIG_BASE="$DIR/config_mac"
    fi
    ;;
  Linux)
    if [ "$ARCH_TYPE" = "aarch64" ] && [ -d "$DIR/config_linux_arm" ]; then
      CONFIG_BASE="$DIR/config_linux_arm"
    else
      CONFIG_BASE="$DIR/config_linux"
    fi
    ;;
  *)
    CONFIG_BASE="$DIR/config_linux"
    ;;
esac

# Prefer a writable configuration directory to avoid JDTLS warnings.
if [ -w "$CONFIG_BASE" ]; then
  CONFIG="$CONFIG_BASE"
else
  CONFIG="$HOME/.cache/jdtls/$(basename "$CONFIG_BASE")"
  if [ ! -d "$CONFIG" ] || [ ! -f "$CONFIG/config.ini" ]; then
    mkdir -p "$CONFIG"
    cp -R "$CONFIG_BASE"/. "$CONFIG"/
  fi
fi
```

改成：

```sh
CONFIG="$DIR/config_mac_arm"
```

- [ ] **Step 3: 檢查 shell 語法**

Run: `sh -n bin/start_jdtls.sh`

Expected: 無輸出且 exit code 為 0。

- [ ] **Step 4: 靜態確認腳本符合 spec**

Run: `rg -n 'CONFIG="\$DIR/config_mac_arm"' bin/start_jdtls.sh`

Then run: `! rg -n 'uname|ARCH_TYPE|OS_TYPE|CONFIG_BASE|mkdir -p "\$CONFIG"|cp -R "\$CONFIG_BASE"' bin/start_jdtls.sh`

Expected:
- 第一個指令找到 `CONFIG="$DIR/config_mac_arm"`
- 第二個指令 exit code 為 0，代表找不到 `uname`、`ARCH_TYPE`、`OS_TYPE`、`CONFIG_BASE`
- 第二個指令 exit code 為 0，代表也找不到 fallback 的 `mkdir -p "$CONFIG"` 與 `cp -R "$CONFIG_BASE"/. "$CONFIG"/`

- [ ] **Step 5: 在 arm64 macOS 做 runtime smoke test**

本 smoke test 以前提 `"$DIR/config_mac_arm"` 與其中 `config.ini` 已由既有安裝流程正確提供為準；若此前提不成立，視為環境或安裝問題，不視為本次 script 簡化 regression。

Run:

```bash
tmpdir=$(mktemp -d)
( cd "$tmpdir" && /Users/samwang/dotfiles/bin/start_jdtls.sh ) &
pid=$!
sleep 5
kill -0 "$pid"
status=$?
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
exit "$status"
```

Expected:
- 程序不會因 `config_mac_arm`、`config.ini`，或 configuration writable 問題立即退出
- `sleep 5` 後 `kill -0 "$pid"` 回傳 0，代表程序在 5 秒觀察期間內持續存活

- [ ] **Step 6: 檢查 diff 僅包含預期縮減**

Run: `git diff -- bin/start_jdtls.sh`

Expected:
- 只看到 configuration 選擇區塊被刪除並以 `CONFIG="$DIR/config_mac_arm"` 取代
- `JAVA_BIN` 選擇與 `exec "$JAVA_BIN"` 參數區塊未被意外改動

- [ ] **Step 7: Commit**

```bash
git add bin/start_jdtls.sh docs/superpowers/specs/2026-03-26-start-jdtls-design.md docs/superpowers/plans/2026-03-26-start-jdtls.md
git commit -m "refactor: simplify jdtls config selection"
```

Expected: 產生一個只包含 spec/plan/script 調整的 commit。
