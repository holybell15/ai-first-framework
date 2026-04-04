#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# findings-reminder.sh — PostToolUse hook：定期提醒更新 findings.md
# 用途：防止 AI 在長 session 中忘記記錄過程觀察，導致 context 壓縮後遺失
# 配置：寫入 .claude/settings.json 的 hooks.PostToolUse
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
TOOL_NAME=$(echo "$INPUT" | grep -oE '"tool_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

# ─── 只計數「有意義的」工具呼叫 ───
case "$TOOL_NAME" in
  Write|Edit|Bash|NotebookEdit)
    ;;
  *)
    exit 0  # Read/Glob/Grep 等查詢類不計數
    ;;
esac

# ─── 計數器 ───
COUNTER_FILE=".findings-counter"
THRESHOLD=10  # 每 10 次有意義的操作提醒一次

if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
else
  COUNT=0
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# ─── 達到閾值 → 提醒 ───
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  # 重置計數器
  echo "0" > "$COUNTER_FILE"

  # 找到目前進行中的 feature findings.md
  FINDINGS=$(find src/ -name "findings.md" -newer "$COUNTER_FILE" 2>/dev/null | head -1)

  if [ -n "$FINDINGS" ]; then
    LAST_MOD=$(stat -f "%Sm" -t "%H:%M" "$FINDINGS" 2>/dev/null || stat -c "%y" "$FINDINGS" 2>/dev/null | cut -d' ' -f2 | cut -d':' -f1,2)
    echo "📝 findings-reminder: 已執行 ${THRESHOLD} 次操作。findings.md 上次更新：${LAST_MOD}。如果有新發現或決策，請更新 ${FINDINGS}"
  else
    echo "📝 findings-reminder: 已執行 ${THRESHOLD} 次操作。請確認是否有值得記錄到 findings.md 的觀察或決策。"
  fi
fi

exit 0
