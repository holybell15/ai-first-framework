#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# test-before-continue.sh — PreToolUse hook：測試未跑時阻擋繼續
# 用途：
#   1. .tests-dirty 存在 → 阻擋寫入 production code（必須先跑測試）
#   2. .tests-dirty 存在 → 阻擋標記任務完成（TASKS.md / progress.md）
#   3. .playwright-required 存在 → 阻擋標記完成（前端必須跑 Playwright）
# 配置：.claude/settings.json → hooks.PreToolUse（matcher: Write, Edit）
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

DIRTY_FILE=".tests-dirty"
PLAYWRIGHT_FILE=".playwright-required"

# ─── 沒有 dirty 標記 → 全部放行 ───
[ ! -f "$DIRTY_FILE" ] && [ ! -f "$PLAYWRIGHT_FILE" ] && exit 0

# ─── 永遠放行的路徑 ───
case "$FILE_PATH" in
  */test/*|*/tests/*|*/__tests__/*|*Test.java|*.spec.ts|*.test.ts)
    exit 0  # 測試檔案永遠放行（要讓 AI 能修 test）
    ;;
  */.gates/*|*/.tests-dirty|*/.playwright-required|*/.findings-counter)
    exit 0  # Hook 自身的標記檔
    ;;
  */contracts/*|*/fixtures/*|*/tools/mock-*)
    exit 0  # Contract/Mock 產出物
    ;;
  */memory/*|*/.plan-history/*)
    exit 0  # 追蹤和備份
    ;;
  */scripts/*|*/.claude/*|*/context-skills/*|*/context-roles/*)
    exit 0  # 框架配置
    ;;
  */02_Specifications/*|*/03_System_Design/*|*/01_Product_Prototype/*)
    exit 0  # 規格文件
    ;;
  */CLAUDE.md|*/project-config.yaml|*/DESIGN.md)
    exit 0  # 框架配置
    ;;
esac

# ─── 情境 A：想寫 production code 但測試未跑 ───
if [ -f "$DIRTY_FILE" ]; then
  IS_PROD=false
  case "$FILE_PATH" in
    */src/main/*) IS_PROD=true ;;
    *.java) IS_PROD=true ;;
    */src/*.vue|*/src/*.ts|*/src/*.tsx|*/src/*.js|*/src/*.jsx) IS_PROD=true ;;
  esac

  if [ "$IS_PROD" = true ]; then
    CHANGED_COUNT=$(wc -l < "$DIRTY_FILE" 2>/dev/null | tr -d ' ')
    LAST_CHANGED=$(tail -1 "$DIRTY_FILE" 2>/dev/null)
    cat <<EOF
⛔ TEST GATE — 測試未跑，不能繼續修改 production code

已修改 ${CHANGED_COUNT} 個檔案但尚未測試：
$(cat "$DIRTY_FILE")

必須先執行：
  後端: ./mvnw test
  前端: npm run test
  (測試通過後 .tests-dirty 會自動清除)

不要跳過測試。改了 code 就要驗證。
EOF
    exit 2
  fi
fi

# ─── 情境 B：想標記完成但測試未跑 ───
BASENAME=$(basename "$FILE_PATH")
IS_COMPLETION=false
case "$BASENAME" in
  TASKS.md|progress.md)
    IS_COMPLETION=true
    ;;
esac

if [ "$IS_COMPLETION" = true ]; then
  BLOCKERS=""

  if [ -f "$DIRTY_FILE" ]; then
    CHANGED_COUNT=$(wc -l < "$DIRTY_FILE" 2>/dev/null | tr -d ' ')
    BLOCKERS="${BLOCKERS}
❌ 單元測試未跑（${CHANGED_COUNT} 個檔案已修改未測試）
   → 執行: ./mvnw test 或 npm run test"
  fi

  if [ -f "$PLAYWRIGHT_FILE" ]; then
    PW_COUNT=$(wc -l < "$PLAYWRIGHT_FILE" 2>/dev/null | tr -d ' ')
    BLOCKERS="${BLOCKERS}
❌ Playwright E2E 未跑（${PW_COUNT} 個前端檔案已修改）
   → 執行: npx playwright test"
  fi

  if [ -n "$BLOCKERS" ]; then
    cat <<EOF
⛔ TEST GATE — 不能標記完成，以下測試未通過：
${BLOCKERS}

跑完測試、全部通過後才能更新 ${BASENAME}。
EOF
    exit 2
  fi
fi

exit 0
