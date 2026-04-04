#!/usr/bin/env bash
# ─────────���───────────────────────────────────────────────────
# test-lint.sh — PreToolUse hook：跑 Playwright 前自動檢查測試品質
# 用途：攔截已知的效率殺手，在跑測試前就擋住
# 配置：.claude/settings.json → hooks.PreToolUse（matcher: Bash）
# ─────────────────────────���───────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
COMMAND=$(echo "$INPUT" | grep -oE '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$COMMAND" ] && exit 0

# 只���截 Playwright 執行指令
case "$COMMAND" in
  *playwright*test*|*npm*run*e2e*|*npm*run*test:e2e*)
    ;;
  *)
    exit 0  # 非 Playwright 指令，放行
    ;;
esac

ERRORS=""
WARNINGS=""

# ─── 檢查 1：waitForTimeout ───
TIMEOUT_FILES=$(grep -rl "waitForTimeout" tests/ 2>/dev/null || true)
if [ -n "$TIMEOUT_FILES" ]; then
  TIMEOUT_COUNT=$(grep -r "waitForTimeout" tests/ 2>/dev/null | wc -l | tr -d ' ')
  ERRORS="${ERRORS}
❌ 發現 ${TIMEOUT_COUNT} 處 waitForTimeout（效率殺手）
   檔案：
$(echo "$TIMEOUT_FILES" | sed 's/^/     /')
   修正：改用 waitForSelector / waitForResponse / expect"
fi

# ─── 檢查 2：beforeEach 登入 ───
LOGIN_IN_BEFORE=$(grep -rl "beforeEach.*\(.*page\)" tests/e2e/ 2>/dev/null | while read -r f; do
  grep -l "login\|fill.*password\|fill.*帳號\|fill.*密碼\|click.*登入\|click.*submit" "$f" 2>/dev/null
done || true)
if [ -n "$LOGIN_IN_BEFORE" ]; then
  ERRORS="${ERRORS}
❌ ��測到 beforeEach 中有登入操作（每個 test 重複登入）
   檔案：
$(echo "$LOGIN_IN_BEFORE" | sed 's/^/     /')
   修正：用 storageState 共用 session（見 webapp-testing skill）"
fi

# ─── 檢查 3：auth.setup.ts 存在 ───
if [ -d "tests/e2e" ] && [ ! -f "tests/auth.setup.ts" ] && [ ! -f "tests/e2e/auth.setup.ts" ]; then
  # 檢查 playwright.config 有沒有設定 storageState
  HAS_STORAGE=$(grep -l "storageState" playwright.config.* 2>/dev/null || true)
  if [ -z "$HAS_STORAGE" ]; then
    WARNINGS="${WARNINGS}
⚠️ 沒有 auth.setup.ts 且 playwright.config 沒有 storageState
   這代表每個 test 可能都在重新登入"
  fi
fi

# ─── 檢查 4：背景執行 ───
case "$COMMAND" in
  *\&|*nohup*|*run_in_background*)
    ERRORS="${ERRORS}
❌ Playwright 不能背景執行（看不到輸出、佔用資源）
   修正：移除 & 或 nohup，前台直接跑"
    ;;
esac

# ─���─ 輸出結果 ───
if [ -n "$ERRORS" ]; then
  cat <<EOF
⛔ TEST LINT — Playwright 測試品質檢查未通過

${ERRORS}
${WARNINGS}

修完以上問題再跑測試。不要跳過。
EOF
  exit 2
fi

if [ -n "$WARNINGS" ]; then
  echo "⚠️ test-lint:${WARNINGS}"
fi

exit 0
