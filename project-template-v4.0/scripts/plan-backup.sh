#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# plan-backup.sh — PreToolUse hook：覆寫 TASKS.md / task_plan.md 前自動備份
# 用途：保留計畫演變歷史，commit/PR 產出時可回溯完整脈絡
# 配置：寫入 .claude/settings.json 的 hooks.PreToolUse（matcher: Write, Edit）
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

# ─── 只攔截需要備份的檔案 ───
BASENAME=$(basename "$FILE_PATH")
case "$BASENAME" in
  TASKS.md|task_plan.md|progress.md|findings.md)
    ;;
  *)
    exit 0  # 非追蹤檔案，放行
    ;;
esac

# ─── 原檔不存在就不備份（新建場景）───
[ ! -f "$FILE_PATH" ] && exit 0

# ─── 建立備份目錄 ───
BACKUP_DIR=".plan-history"
mkdir -p "$BACKUP_DIR"

# ─── 備份：檔名_時間戳.md ───
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="${BASENAME%.md}_${TIMESTAMP}.md"
cp "$FILE_PATH" "${BACKUP_DIR}/${BACKUP_NAME}"

# ─── 更新 index ───
INDEX_FILE="${BACKUP_DIR}/INDEX.md"
if [ ! -f "$INDEX_FILE" ]; then
  cat > "$INDEX_FILE" << 'HEADER'
# Plan History Index

> 自動產生。每次 TASKS.md / task_plan.md / progress.md / findings.md 被覆寫前，
> 舊版會備份到此目錄。commit/PR 產出時參考此歷史。

| 時間 | 檔案 | 備份 |
|------|------|------|
HEADER
fi

echo "| $(date +%Y-%m-%d\ %H:%M:%S) | ${BASENAME} | [${BACKUP_NAME}](${BACKUP_NAME}) |" >> "$INDEX_FILE"

# ─── 清理：保留最近 30 個備份 ───
FILE_COUNT=$(ls -1 "$BACKUP_DIR"/*.md 2>/dev/null | grep -v INDEX.md | wc -l)
if [ "$FILE_COUNT" -gt 30 ]; then
  ls -1t "$BACKUP_DIR"/*.md | grep -v INDEX.md | tail -n +31 | xargs rm -f
fi

exit 0  # 放行（備份完成，不阻擋寫入）
