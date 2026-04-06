#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# arch-guard-hook.sh — PreToolUse hook：偵測架構級變更並強制攔截
#
# 問題：AI 會把「改架構」包裝成「修 bug」或「對齊參考」繞過所有 Gate
# 解法：自動偵測架構變更信號，無論 AI 怎麼描述任務都會被攔
#
# === 偵測信號 ===
# 1. 刪除/替換核心服務檔案（service, store, composable, api client）
# 2. 新增外部 SDK/library 檔案（.min.js, vendor/, sdk）
# 3. 變更 package.json / build.gradle 依賴
# 4. 大量修改 import/require 語句（通訊層替換信號）
# 5. 刪除整個目錄結構（rm -rf src/services/ 等）
#
# === 啟用方式 ===
# 預設啟用（不需要任何額外檔案）
# 豁免方式：建立 .arch-approved 檔案
#   echo "APPROVED: 2026-04-06 遷移到 Uni4cc SDK — by Alex" > .arch-approved
#
# === 配置 ===
# 寫入 .claude/settings.json 的 hooks.PreToolUse（matcher: Write|Edit）
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"

# ─── 豁免檢查 ───
# 如果有 .arch-approved 檔案，表示人已確認這次架構變更
if [ -f ".arch-approved" ]; then
  exit 0
fi

# ─── 解析 TOOL_INPUT ───
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

# ─── 白名單：這些路徑不檢查 ───
case "$FILE_PATH" in
  */test/*|*/tests/*|*/__tests__/*|*Test.java|*.spec.ts|*.test.ts)
    exit 0 ;;
  */memory/*|*/TASKS.md|*task_plan.md|*findings.md|*progress.md)
    exit 0 ;;
  */.gates/*|*/.arch-approved)
    exit 0 ;;
  */02_Specifications/*|*/03_System_Design/*|*/01_Product_Prototype/*)
    exit 0 ;;
  */scripts/*|*.md|*.json|*.yaml|*.yml)
    # 設定檔另外檢查 package.json
    if [[ "$FILE_PATH" != *"package.json"* ]] && [[ "$FILE_PATH" != *"build.gradle"* ]]; then
      exit 0
    fi
    ;;
esac

# ─── 取得 old_string / new_string / content ───
OLD_STRING=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('old_string', ''))
except:
    pass
" 2>/dev/null || true)

NEW_STRING=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('new_string', d.get('content', '')))
except:
    pass
" 2>/dev/null || true)

BLOCKED=false
REASON=""

# ═══════════════════════════════════════════════════════════════
# 信號 1：新增外部 SDK / vendor 檔案
# ═══════════════════════════════════════════════════════════════
if [[ "$FILE_PATH" =~ \.(min\.js|min\.css)$ ]] || \
   [[ "$FILE_PATH" =~ (vendor|sdk|lib)/ ]] && [[ "$FILE_PATH" =~ \.(js|ts|css)$ ]]; then
  BLOCKED=true
  REASON="新增外部 SDK/vendor 檔案: $FILE_PATH"
fi

# ═══════════════════════════════════════════════════════════════
# 信號 2：package.json / build.gradle 依賴變更
# ═══════════════════════════════════════════════════════════════
if [[ "$FILE_PATH" == *"package.json"* ]] || [[ "$FILE_PATH" == *"build.gradle"* ]]; then
  # 檢查是否有新增 dependencies
  if echo "$NEW_STRING" | grep -qiE '"dependencies"|"devDependencies"|implementation |compile '; then
    # 如果舊的也有 dependencies，可能只是版本更新 — 檢查是否新增了不同的套件名
    if [ -n "$OLD_STRING" ]; then
      OLD_DEPS=$(echo "$OLD_STRING" | grep -oE '"[a-z@][a-z0-9@/_-]+"' | sort -u)
      NEW_DEPS=$(echo "$NEW_STRING" | grep -oE '"[a-z@][a-z0-9@/_-]+"' | sort -u)
      ADDED_DEPS=$(comm -13 <(echo "$OLD_DEPS") <(echo "$NEW_DEPS") 2>/dev/null || true)
      if [ -n "$ADDED_DEPS" ]; then
        BLOCKED=true
        REASON="package.json 新增依賴: $ADDED_DEPS"
      fi
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 信號 3：刪除核心服務/通訊層檔案（old_string 很大但 new_string 幾乎為空）
# ═══════════════════════════════════════════════════════════════
if [ -n "$OLD_STRING" ] && [ ${#OLD_STRING} -gt 500 ]; then
  if [ -z "$NEW_STRING" ] || [ ${#NEW_STRING} -lt 50 ]; then
    # 整個檔案被清空 — 檢查是不是核心檔案
    if [[ "$FILE_PATH" =~ (service|store|composable|api|client|adapter|provider|gateway|connector|handler) ]]; then
      BLOCKED=true
      REASON="清空核心服務檔案: $FILE_PATH (${#OLD_STRING} chars → ${#NEW_STRING} chars)"
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 信號 4：大量替換 import 語句（通訊層替換信號）
# ═══════════════════════════════════════════════════════════════
if [ -n "$OLD_STRING" ] && [ -n "$NEW_STRING" ]; then
  OLD_IMPORTS=$(echo "$OLD_STRING" | grep -cE "^import |^from |require\(" 2>/dev/null || true)
  OLD_IMPORTS=${OLD_IMPORTS:-0}; OLD_IMPORTS=$(echo "$OLD_IMPORTS" | tr -d '[:space:]')
  NEW_IMPORTS=$(echo "$NEW_STRING" | grep -cE "^import |^from |require\(" 2>/dev/null || true)
  NEW_IMPORTS=${NEW_IMPORTS:-0}; NEW_IMPORTS=$(echo "$NEW_IMPORTS" | tr -d '[:space:]')

  # 如果 import 變化 >= 3 行且來源完全不同
  if [ "${OLD_IMPORTS:-0}" -ge 3 ] 2>/dev/null && [ "${NEW_IMPORTS:-0}" -ge 3 ] 2>/dev/null; then
    OLD_SOURCES=$(echo "$OLD_STRING" | grep -oE "from ['\"][^'\"]+['\"]|require\(['\"][^'\"]+['\"]\)" | sort -u)
    NEW_SOURCES=$(echo "$NEW_STRING" | grep -oE "from ['\"][^'\"]+['\"]|require\(['\"][^'\"]+['\"]\)" | sort -u)
    if [ "$OLD_SOURCES" != "$NEW_SOURCES" ]; then
      REMOVED_SOURCES=$(comm -23 <(echo "$OLD_SOURCES") <(echo "$NEW_SOURCES") 2>/dev/null | wc -l | tr -d ' ')
      if [ "$REMOVED_SOURCES" -ge 3 ]; then
        BLOCKED=true
        REASON="大量替換 import 來源 (移除 ${REMOVED_SOURCES} 個): 可能是通訊層/架構替換"
      fi
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 信號 5：Write 整個新檔案且包含 SDK 初始化模式
# ═══════════════════════════════════════════════════════════════
if [ -z "$OLD_STRING" ] && [ -n "$NEW_STRING" ] && [ ${#NEW_STRING} -gt 200 ]; then
  # 新建檔案且包含 SDK 初始化關鍵字
  if echo "$NEW_STRING" | grep -qiE "sdk\.init|SDK\.create|new SDK|initSDK|sdkInitData"; then
    if [[ "$FILE_PATH" =~ (service|store|composable|plugin|provider|adapter) ]]; then
      BLOCKED=true
      REASON="新建含 SDK 初始化的核心檔案: $FILE_PATH"
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 信號 6：替換整個通訊方式（REST→SDK, WebSocket→SDK 等）
# ═══════════════════════════════════════════════════════════════
if [ -n "$OLD_STRING" ] && [ -n "$NEW_STRING" ]; then
  # 舊的用 REST/fetch/axios，新的用 SDK
  OLD_HAS_REST=$(echo "$OLD_STRING" | grep -cE "fetch\(|axios\.|\.get\(|\.post\(|\.put\(|\.delete\(|sendCommand|WebSocket|EventSource" 2>/dev/null || true)
  OLD_HAS_REST=$(echo "${OLD_HAS_REST:-0}" | tr -d '[:space:]')
  NEW_HAS_SDK=$(echo "$NEW_STRING" | grep -cE "sdk\.|SDK\.|\.acceptCall|\.hangupCall|\.makeCall|\.init\(|addEventListener" 2>/dev/null || true)
  NEW_HAS_SDK=$(echo "${NEW_HAS_SDK:-0}" | tr -d '[:space:]')

  if [ "${OLD_HAS_REST:-0}" -ge 2 ] 2>/dev/null && [ "${NEW_HAS_SDK:-0}" -ge 2 ] 2>/dev/null; then
    BLOCKED=true
    REASON="通訊層替換: REST/WebSocket API (${OLD_HAS_REST} calls) → SDK pattern (${NEW_HAS_SDK} calls)"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 結果輸出
# ═══════════════════════════════════════════════════════════════
if [ "$BLOCKED" = true ]; then
  cat >&2 <<BLOCK_MSG

⛔ ARCHITECTURE GUARD — 偵測到架構級變更，已攔截

  檔案: $FILE_PATH
  信號: $REASON

  ──────────────────────────────────────────────────
  這不是普通的 code 修改，而是架構級變更。
  架構變更必須經過人工確認才能執行。
  ──────────────────────────────────────────────────

  如果這次變更是經過討論並同意的，請執行：

    echo "APPROVED: $(date +%Y-%m-%d) [變更描述] — by [你的名字]" > .arch-approved

  完成後重新執行即可。
  ⚠️ 變更完成後請刪除 .arch-approved 避免後續誤用。

BLOCK_MSG
  exit 2
fi

exit 0
