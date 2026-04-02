#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# auto-state-update.sh — PostToolUse hook：Agent 產出文件後自動更新 STATE.md
# 用途：每次 Write/Edit 操作後，檢查是否為 Pipeline 產出物，自動更新追蹤狀態
# 配置：寫入 .claude/settings.json 的 hooks.PostToolUse
# ─────────────────────────────────────────────────────────────
set -uo pipefail

# 從工具輸入中提取檔案路徑
INPUT="${1:-}"
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

# ─── 偵測是否為 Pipeline 產出物 ───
STATE_FILE="memory/STATE.md"
[ ! -f "$STATE_FILE" ] && exit 0

case "$FILE_PATH" in
  */02_Specifications/RFP_Brief_*)
    echo "[auto-state] 偵測到 RFP Brief 產出 → Interviewer 階段進行中"
    ;;
  */02_Specifications/US_F*)
    echo "[auto-state] 偵測到 User Story 產出 → PM 階段進行中"
    ;;
  */01_Product_Prototype/*)
    echo "[auto-state] 偵測到 Prototype 產出 → UX 階段進行中"
    ;;
  */03_System_Design/*ARCH*)
    echo "[auto-state] 偵測到架構文件產出 → Architect 階段進行中"
    ;;
  */03_System_Design/*DB*)
    echo "[auto-state] 偵測到 DB Schema 產出 → DBA 階段進行中"
    ;;
  */02_Specifications/*API*)
    echo "[auto-state] 偵測到 API Spec 產出 → Backend 階段進行中"
    ;;
  */08_Test_Reports/*)
    echo "[auto-state] 偵測到測試報告產出 → QA 階段進行中"
    ;;
  */04_Compliance/*)
    echo "[auto-state] 偵測到合規文件產出 → Security 階段進行中"
    ;;
  */07_Retrospectives/*)
    echo "[auto-state] 偵測到 Gate Review 產出 → Review 階段進行中"
    ;;
  *)
    exit 0  # 非 Pipeline 產出，忽略
    ;;
esac

# 更新 STATE.md 的 updated 時間
if [ -f "$STATE_FILE" ]; then
  # 用 sed 更新 last_activity 行（如果存在的話）
  sed -i.bak "s/^last_activity:.*/last_activity: $(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$STATE_FILE" 2>/dev/null || true
  rm -f "${STATE_FILE}.bak"
fi

exit 0
