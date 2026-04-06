#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# debug-gate-auto.sh — PostToolUse hook：偵測到錯誤時自動啟用 Debug Gate
#
# 問題：AI 看到錯誤就直接改 code，跳過分析和讀文件
# 解法：偵測到錯誤信號 → 自動建立 .gates/DEBUG/ → gate-checkpoint.sh 攔截寫入
#       AI 必須完成分析 + 產出 Debug Evidence → 建立 checkpoint → 才能改 code
#
# === 觸發信號 ===
# 1. Bash 輸出包含 ERROR / Exception / FAIL / 500 / Connection refused
# 2. 測試失敗（exit code != 0 的測試指令）
# 3. 部署後驗證失敗
#
# === Debug Gate 流程 ===
#   錯誤偵測 → .gates/DEBUG/.enabled + .debug 自動建立
#     → AI 想寫 src/ code → gate-checkpoint.sh 攔截
#     → 必須先：
#       1. 讀 log / error 分析問題（Phase 1）
#       2. 讀相關 source code + 文件（Phase 2）
#       3. 產出分析報告 → echo "confirmed ..." > .gates/DEBUG/debug-evidence.confirmed
#     → checkpoint 存在後才能寫 code
#     → 寫 code 後 test-on-change.sh 強制跑測試
#     → 測試通過 → .gates/DEBUG/ 自動清除
#
# === 手動清除（誤判時）===
#   rm -rf .gates/DEBUG
#
# 配置：.claude/settings.json → hooks.PostToolUse（matcher: Bash）
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
TOOL_NAME=$(echo "$INPUT" | grep -oE '"tool_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

GATE_DIR=".gates/DEBUG"

# ════════════════════════════════════════════════════
# 只處理 Bash 工具的輸出
# ════════════════════════════════════════════════════
[ "$TOOL_NAME" != "Bash" ] && exit 0

# 如果 Debug Gate 已存在，檢查是否可以清除（測試通過了）
if [ -d "$GATE_DIR" ]; then
  COMMAND=$(echo "$INPUT" | grep -oE '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

  IS_TEST=false
  case "$COMMAND" in
    *mvnw\ test*|*maven\ test*|*gradle\ test*|*npm\ run\ test*|*npm\ test*|*vitest*|*jest*|*pytest*|*cargo\ test*|*playwright*)
      IS_TEST=true ;;
  esac

  if [ "$IS_TEST" = true ]; then
    # 從 stdout 檢查測試結果
    STDOUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('stdout', ''))
except:
    pass
" 2>/dev/null || true)

    if echo "$STDOUT" | grep -qiE "FAIL|FAILED|ERROR|BROKEN"; then
      echo "🔴 debug-gate-auto: 測試仍有失敗。Debug Gate 保持。繼續走 Debug 流程。" >&2
    else
      # 測試全過 → 清除 Debug Gate
      rm -rf "$GATE_DIR"
      echo "✅ debug-gate-auto: 測試通過。Debug Gate 已清除。" >&2
    fi
  fi

  exit 0
fi

# ════════════════════════════════════════════════════
# Debug Gate 不存在 → 偵測是否有錯誤信號
# ════════════════════════════════════════════════════
COMMAND=$(echo "$INPUT" | grep -oE '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$COMMAND" ] && exit 0

# 白名單：這些指令的錯誤不觸發 debug gate
case "$COMMAND" in
  *git\ status*|*git\ log*|*git\ diff*|*ls*|*cat*|*head*|*tail*|*grep*|*find*|*echo*|*mkdir*|*touch*|*rm*|*cp*|*mv*)
    exit 0 ;;
  *install*|*npm\ i\ *|*pip\ install*|*brew\ *|*apt\ *)
    exit 0 ;;  # 安裝指令
  *ssh*|*scp*|*rsync*)
    exit 0 ;;  # 遠端操作（錯誤由 deploy-verify 處理）
esac

# 取得 stdout
STDOUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('stdout', ''))
except:
    pass
" 2>/dev/null || true)

# 取得 exit code
EXIT_CODE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('exit_code', 0))
except:
    print(0)
" 2>/dev/null || echo "0")

# ─── 偵測錯誤信號 ───
HAS_ERROR=false
ERROR_SIGNAL=""

# 信號 1：測試指令失敗
IS_TEST=false
case "$COMMAND" in
  *mvnw\ test*|*maven\ test*|*gradle\ test*|*npm\ run\ test*|*npm\ test*|*vitest*|*jest*|*pytest*|*cargo\ test*|*playwright*)
    IS_TEST=true ;;
esac

if [ "$IS_TEST" = true ] && [ "${EXIT_CODE:-0}" != "0" ]; then
  HAS_ERROR=true
  ERROR_SIGNAL="測試指令失敗 (exit code: $EXIT_CODE)"
fi

# 信號 2：編譯/build 失敗
IS_BUILD=false
case "$COMMAND" in
  *mvnw\ compile*|*mvnw\ package*|*gradle\ build*|*npm\ run\ build*|*tsc*|*vite\ build*)
    IS_BUILD=true ;;
esac

if [ "$IS_BUILD" = true ] && [ "${EXIT_CODE:-0}" != "0" ]; then
  HAS_ERROR=true
  ERROR_SIGNAL="編譯/Build 失敗 (exit code: $EXIT_CODE)"
fi

# 信號 3：輸出包含嚴重錯誤關鍵字（只在測試/build 指令）
if [ "$IS_TEST" = true ] || [ "$IS_BUILD" = true ]; then
  if echo "$STDOUT" | grep -qiE "Exception|FATAL|BUILD FAILURE|compilation error|Cannot find module"; then
    HAS_ERROR=true
    ERROR_SIGNAL="${ERROR_SIGNAL:+$ERROR_SIGNAL + }輸出包含嚴重錯誤關鍵字"
  fi
fi

# 信號 4：啟動服務失敗
IS_START=false
case "$COMMAND" in
  *mvnw\ spring-boot:run*|*npm\ run\ dev*|*npm\ start*|*node\ *)
    IS_START=true ;;
esac

if [ "$IS_START" = true ] && [ "${EXIT_CODE:-0}" != "0" ]; then
  HAS_ERROR=true
  ERROR_SIGNAL="服務啟動失敗 (exit code: $EXIT_CODE)"
fi

# ═══════════════════════════════════════════════════════════════
# 啟用 Debug Gate
# ═══════════════════════════════════════════════════════════════
if [ "$HAS_ERROR" = true ]; then
  mkdir -p "$GATE_DIR"
  touch "$GATE_DIR/.enabled" "$GATE_DIR/.debug"
  echo "$ERROR_SIGNAL" > "$GATE_DIR/.error-signal"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $COMMAND" > "$GATE_DIR/.trigger-command"

  cat >&2 <<DEBUG_GATE

╔══════════════════════════════════════════════════════════════╗
║  🔍 DEBUG GATE 已自動啟用 — 偵測到錯誤                       ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  信號: $(printf '%-52s' "$ERROR_SIGNAL") ║
║                                                              ║
║  你現在不能直接改 code。必須先完成分析：                       ║
║                                                              ║
║  Step 1: 分析錯誤                                            ║
║    └─ 讀 error log，描述 SYMPTOM / EXPECTED / ACTUAL          ║
║                                                              ║
║  Step 2: 讀相關 source code + 文件                            ║
║    └─ 用 Read 工具讀檔案，不要靠記憶                          ║
║                                                              ║
║  Step 3: 產出分析報告，建立 checkpoint：                      ║
║    echo "confirmed \$(date)" > .gates/DEBUG/debug-evidence.confirmed ║
║                                                              ║
║  之後才能改 code → 改完自己跑測試 → 測試通過自動清除 Gate    ║
║                                                              ║
║  誤判？手動清除: rm -rf .gates/DEBUG                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
DEBUG_GATE
fi

exit 0
