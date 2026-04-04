#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# test-on-change.sh — PostToolUse hook：Dirty Flag 機制
# 用途：
#   1. production code 變更後 → 建立 .tests-dirty（強制跑測試）
#   2. 前端 code 變更後 → 額外建立 .playwright-required
#   3. 偵測到測試執行 → 清除對應標記
# 配置：.claude/settings.json → hooks.PostToolUse
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
TOOL_NAME=$(echo "$INPUT" | grep -oE '"tool_name"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

DIRTY_FILE=".tests-dirty"
PLAYWRIGHT_FILE=".playwright-required"

# ════════════════════════════════════════════════════
# Case 1: Write/Edit → 檢查是否為 production code
# ════════════════════════════════════════════════════
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$FILE_PATH" ] && exit 0

  # 白名單：非 production code 不標記
  case "$FILE_PATH" in
    */test/*|*/tests/*|*/__tests__/*|*Test.java|*.spec.ts|*.test.ts)
      exit 0  # 測試檔案不觸發 dirty
      ;;
    */memory/*|*/TASKS.md|*task_plan.md|*findings.md|*progress.md)
      exit 0  # 追蹤檔案
      ;;
    */.gates/*|*/contracts/*|*/fixtures/*)
      exit 0  # Gate/Contract 產出物
      ;;
    */scripts/*|*/deploy*|*/.claude/*)
      exit 0  # 腳本和配置
      ;;
    */02_Specifications/*|*/03_System_Design/*|*/01_Product_Prototype/*)
      exit 0  # 規格文件
      ;;
    */CLAUDE.md|*/project-config.yaml|*/DESIGN.md|*/context-skills/*|*/context-roles/*)
      exit 0  # 框架配置
      ;;
    */.plan-history/*)
      exit 0  # Plan 備份
      ;;
  esac

  # 判斷是否為 production code
  IS_PROD=false
  case "$FILE_PATH" in
    */src/main/*) IS_PROD=true ;;  # Java backend
    */src/*.vue|*/src/*.ts|*/src/*.tsx|*/src/*.js|*/src/*.jsx)
      # 前端 source（排除已在白名單的 test）
      IS_PROD=true
      ;;
    *.java)
      # Java 檔案（排除已在白名單的 test）
      IS_PROD=true
      ;;
  esac

  if [ "$IS_PROD" = true ]; then
    # 標記 dirty
    echo "$FILE_PATH $(date +%Y-%m-%dT%H:%M:%S)" >> "$DIRTY_FILE"
    echo "🔴 test-on-change: production code 已修改（$(basename "$FILE_PATH")）。必須跑測試才能繼續。"

    # 前端 code 額外標記 playwright-required
    case "$FILE_PATH" in
      *.vue|*.ts|*.tsx|*.js|*.jsx)
        if ! echo "$FILE_PATH" | grep -qE '/src/main/'; then
          # 不是 Java backend 的 .java → 是前端
          echo "$FILE_PATH $(date +%Y-%m-%dT%H:%M:%S)" >> "$PLAYWRIGHT_FILE"
          echo "🎭 test-on-change: 前端 code 已修改。完成前必須跑 Playwright E2E。"
        fi
        ;;
    esac
  fi

  exit 0
fi

# ════════════════════════════════════════════════════
# Case 2: Bash → 偵測是否為測試執行
# ════════════════════════════════════════════════════
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | grep -oE '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
  [ -z "$COMMAND" ] && exit 0

  # 偵測 unit test 執行
  IS_UNIT_TEST=false
  case "$COMMAND" in
    *mvnw\ test*|*maven\ test*|*gradle\ test*|*npm\ run\ test*|*npm\ test*|*vitest*|*jest*|*pytest*|*cargo\ test*)
      IS_UNIT_TEST=true
      ;;
  esac

  # 偵測 Playwright 執行
  IS_PLAYWRIGHT=false
  case "$COMMAND" in
    *playwright*|*npx\ playwright*|*npm\ run\ e2e*|*npm\ run\ test:e2e*)
      IS_PLAYWRIGHT=true
      ;;
  esac

  # 從工具輸出偵測測試結果
  TOOL_OUTPUT=$(echo "$INPUT" | grep -oE '"stdout"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//' || true)

  if [ "$IS_UNIT_TEST" = true ]; then
    # 檢查是否通過（簡單啟發式：沒有 FAIL/FAILED/ERROR 關鍵字）
    if echo "$TOOL_OUTPUT" | grep -qiE "FAIL|FAILED|ERROR|BROKEN"; then
      echo "🔴 test-on-change: 測試有失敗項目。.tests-dirty 保持標記。修完再跑。"
    else
      # 清除 dirty 標記
      rm -f "$DIRTY_FILE"
      echo "✅ test-on-change: 單元測試通過。.tests-dirty 已清除。"
    fi
  fi

  if [ "$IS_PLAYWRIGHT" = true ]; then
    if echo "$TOOL_OUTPUT" | grep -qiE "FAIL|FAILED|ERROR|BROKEN"; then
      echo "🔴 test-on-change: Playwright 有失敗項目。.playwright-required 保持標記。"
    else
      rm -f "$PLAYWRIGHT_FILE"
      echo "✅ test-on-change: Playwright E2E 通過。.playwright-required 已清除。"
    fi
  fi

  exit 0
fi

exit 0
