#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# freeze-hook.sh — Freeze Mode 目錄鎖定 Hook
# 用途：PreToolUse hook，攔截 Edit/Write 超出允許 scope 的操作
# 配置：寫入 .claude/settings.json 的 hooks.PreToolUse（matcher: Edit/Write）
# 傳回非零 exit code = 攔截操作
# ─────────────────────────────────────────────────────────────
set -uo pipefail

SCOPE_FILE=".claude-freeze-scope"

# 如果沒有 scope file → Freeze 未啟用，全部放行
[ ! -f "$SCOPE_FILE" ] && exit 0

INPUT="${1:-}"
ALLOWED_DIR=$(head -1 "$SCOPE_FILE" 2>/dev/null)

# 如果 scope file 為空或讀取失敗，放行
[ -z "$ALLOWED_DIR" ] && exit 0

# 從工具輸入中提取檔案路徑
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

# 無法提取路徑，放行（保守策略）
[ -z "$FILE_PATH" ] && exit 0

# ─── 永遠允許的路徑（白名單）───
case "$FILE_PATH" in
  */memory/*)     exit 0 ;;  # memory/ 目錄（STATE.md、decisions.md 等）
  */TASKS.md)     exit 0 ;;  # 任務追蹤
  */.worktree-*)  exit 0 ;;  # worktree 資訊檔
  */test-results/*) exit 0 ;; # 測試結果
  */08_Test_Reports/*) exit 0 ;; # 測試報告
  */07_Retrospectives/*) exit 0 ;; # 回顧報告
esac

# ─── 檢查是否在允許範圍內 ───
# 支援多行 scope（每行一個允許目錄）
while IFS= read -r scope_dir; do
  [ -z "$scope_dir" ] && continue
  case "$FILE_PATH" in
    ${scope_dir}*) exit 0 ;;  # 在 scope 內，放行
  esac
done < "$SCOPE_FILE"

# ─── 不在 scope 內 → 攔截 ───
cat <<EOF
🔒 FREEZE MODE — 目錄鎖定攔截

嘗試修改：$FILE_PATH
允許範圍：$(cat "$SCOPE_FILE" | tr '\n' ', ')

此檔案不在 Freeze 允許範圍內。

選項：
  • 說「暫時解鎖 $FILE_PATH」— 僅本次操作放行
  • 說「擴大範圍到 [目錄]」— 新增允許目錄
  • 說「解除目錄鎖定」— 移除 Freeze Mode

詳見：context-skills/destructive-guard/SKILL.md
EOF
exit 2
