# start_jdtls.sh 簡化設計

## 目標

將 `bin/start_jdtls.sh` 簡化為只支援 arm64 macOS 的執行環境。

## 非目標

- 非 arm64 macOS 平台不在本次支援範圍內
- 其他平台上的失敗行為不特別處理，這是刻意收斂支援範圍，不視為 regression

## 變更範圍

- 移除 `uname` 的 OS/architecture 偵測
- 移除 `CONFIG_BASE` 的多平台 `case` 判斷
- 移除 writable fallback 與複製設定目錄的邏輯
- 直接將 JDTLS configuration 固定為 `"$DIR/config_mac_arm"`

## 保留項目

- `LAUNCHER`、`LOMBOK_JAR`、workspace hash 與 `JAVA_BIN` 選擇邏輯保持不變
- `-configuration` 以外的 JVM / JDTLS 啟動參數保持不變

## 錯誤處理

- 不新增額外防呆或 fallback
- `"$DIR/config_mac_arm"` 必須由既有安裝流程提供，且必須是 JDTLS 可直接使用的 configuration 目錄
- 若 `"$DIR/config_mac_arm"` 不存在、不可直接使用，或因此導致 JDTLS 啟動失敗，視為可接受失敗，交由現有安裝流程保證前提成立

## 驗證

- 以下 runtime smoke test 以前提 `"$DIR/config_mac_arm"` 與其中 `config.ini` 已由既有安裝流程正確提供為準；若此前提不成立，視為環境或安裝問題，不視為本次 script 簡化 regression
- 檢查腳本語法無誤
- 確認 `-configuration` 參數改為 `"$DIR/config_mac_arm"`
- 確認不再出現 OS/architecture 判斷與 writable fallback
- 在 arm64 macOS 上，於任一測試 workspace 實際執行一次腳本
- 確認程序不會因 `config_mac_arm`、`config.ini`，或 configuration 目錄 writable 問題而立即失敗
- 確認程序在 5 秒觀察期間內持續存活
