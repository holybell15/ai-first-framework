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

# ─── 情境 A-1：Self-Healing 未完成就想改 code（v4.1）───
HEALING_FILE=".healing-required"
if [ -f "$HEALING_FILE" ]; then
  IS_PROD=false
  case "$FILE_PATH" in
    */src/main/*) IS_PROD=true ;;
    *.java) IS_PROD=true ;;
    */src/*.vue|*/src/*.ts|*/src/*.tsx|*/src/*.js|*/src/*.jsx) IS_PROD=true ;;
  esac

  if [ "$IS_PROD" = true ]; then
    ATTEMPT_COUNT=$(grep -c "attempt" "$HEALING_FILE" 2>/dev/null || echo "0")
    if [ "$ATTEMPT_COUNT" -ge 3 ]; then
      cat <<EOF
⛔ SELF-HEALING EXHAUSTED — 3 次自動修復都失敗了

已嘗試記錄：
$(cat "$HEALING_FILE")

必須產出 Escalation Report 升級給人（見 self-healing-build skill）：
1. 列出 3 次嘗試的方法和失敗原因
2. 提供 AI 的判斷和建議
3. 列出可以繼續的獨立 AC

產出報告後，人工介入修復，或執行：
  rm .healing-required    （人工確認後清除）
EOF
      exit 2
    else
      NEXT=$((ATTEMPT_COUNT + 1))
      cat <<EOF
⛔ SELF-HEALING REQUIRED — 測試失敗，請先自動修復（Attempt ${NEXT}/3）

上次失敗記錄：
$(tail -1 "$HEALING_FILE")

請遵循 self-healing-build skill：
$(if [ "$NEXT" -eq 1 ]; then echo "  → Attempt 1: Quick Fix（比對 Known Bug Pattern，修 typo/import/型別）"; elif [ "$NEXT" -eq 2 ]; then echo "  → Attempt 2: Root Cause Analysis（觸發 systematic-debugging Phase 1+2）"; else echo "  → Attempt 3: Alternative Strategy（換實作方式或檢查測試本身）"; fi)

修復後重跑測試。測試通過 → .healing-required 自動清除。
EOF
      exit 2
    fi
  fi
fi

# ─── 情境 A-1b：Debug 模式 — 改了 code 但沒自己部署驗證（v4.1）───
DEPLOY_VERIFY_FILE=".deploy-verify-required"
if [ -f "$DEPLOY_VERIFY_FILE" ]; then
  IS_PROD=false
  case "$FILE_PATH" in
    */src/main/*) IS_PROD=true ;;
    *.java) IS_PROD=true ;;
    */src/*.vue|*/src/*.ts|*/src/*.tsx|*/src/*.js|*/src/*.jsx) IS_PROD=true ;;
  esac

  if [ "$IS_PROD" = true ]; then
    CHANGED_COUNT=$(wc -l < "$DEPLOY_VERIFY_FILE" 2>/dev/null | tr -d ' ')
    cat <<EOF
⛔ DEPLOY-VERIFY GATE — 你改了 code 但還沒自己部署驗證

已修改 ${CHANGED_COUNT} 個檔案但尚未部署驗證：
$(cat "$DEPLOY_VERIFY_FILE")

你必須自己完成以下步驟（不要等人幫你測）：

  1. 部署到目標環境：
     bash scripts/deploy.sh
     （或你的專案部署指令）

  2. 等 Backend 啟動後，SSH 驗證：
     ssh user@host "grep -E 'ERROR|Started' /path/to/app.log | tail -20"

  3. 打真實 API 確認修復：
     curl -s http://host:port/api/v1/xxx | head -5

  4. 前端問題 → 檢查瀏覽器 Console

部署驗證通過後 .deploy-verify-required 會自動清除。
驗證失敗 → 繼續修復 → 再部署驗證。不要只改 code 不驗證。
EOF
    exit 2
  fi
fi

# ─── 情境 A-2：想寫 production code 但測試未跑 ───
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

  if [ -f "$DEPLOY_VERIFY_FILE" ]; then
    DV_COUNT=$(wc -l < "$DEPLOY_VERIFY_FILE" 2>/dev/null | tr -d ' ')
    BLOCKERS="${BLOCKERS}
❌ 部署驗證未完成（${DV_COUNT} 個檔案已修改但未在目標環境驗證）
   → 執行: bash scripts/deploy.sh → SSH 驗證 → curl 打 API"
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
