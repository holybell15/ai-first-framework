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

  DEPLOY_VERIFY_FILE=".deploy-verify-required"

  if [ "$IS_PROD" = true ]; then
    # 標記 dirty
    echo "$FILE_PATH $(date +%Y-%m-%dT%H:%M:%S)" >> "$DIRTY_FILE"
    echo "🔴 test-on-change: production code 已修改（$(basename "$FILE_PATH")）。必須跑測試才能繼續。"

    # ── v4.1: Debug 模式 → 額外標記 deploy-verify-required ──
    # 有 .debug gate 存在 = 正在做 hotfix → 改完必須自己部署驗證
    if ls .gates/*/.debug 1>/dev/null 2>&1; then
      echo "$FILE_PATH $(date +%Y-%m-%dT%H:%M:%S)" >> "$DEPLOY_VERIFY_FILE"
      echo "🚀 test-on-change: Debug 模式 — 改完後你必須自己部署到目標環境並驗證。不要等人幫你測。"
    fi

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

  HEALING_FILE=".healing-required"

  if [ "$IS_UNIT_TEST" = true ]; then
    # 檢查是否通過（簡單啟發式：沒有 FAIL/FAILED/ERROR 關鍵字）
    if echo "$TOOL_OUTPUT" | grep -qiE "FAIL|FAILED|ERROR|BROKEN"; then
      echo "🔴 test-on-change: 測試有失敗項目。.tests-dirty 保持標記。修完再跑。"

      # ── v4.1: Self-Healing 強制觸發 ──
      # 測試失敗 → 建立 .healing-required → AI 下次改 code 前被攔截
      ATTEMPT=$(cat "$HEALING_FILE" 2>/dev/null | grep -c "attempt" || echo "0")
      NEXT_ATTEMPT=$((ATTEMPT + 1))
      if [ "$NEXT_ATTEMPT" -le 3 ]; then
        echo "attempt:${NEXT_ATTEMPT} ts:$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$HEALING_FILE"
        echo "🔧 test-on-change: Self-Healing Attempt ${NEXT_ATTEMPT}/3 已記錄。請遵循 self-healing-build skill 修復。"
      else
        echo "🚨 test-on-change: Self-Healing 3 次嘗試已用完。必須產出 Escalation Report 升級給人。"
      fi
    else
      # 清除 dirty 標記 + healing 標記
      rm -f "$DIRTY_FILE"
      rm -f "$HEALING_FILE"
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

  # ── v4.1: 偵測部署 + 驗證行為 → 清除 .deploy-verify-required ──
  DEPLOY_VERIFY_FILE=".deploy-verify-required"
  if [ -f "$DEPLOY_VERIFY_FILE" ]; then
    IS_DEPLOY_OR_VERIFY=false
    case "$COMMAND" in
      *deploy*|*scp*|*rsync*|*docker*push*|*kubectl*apply*)
        IS_DEPLOY_OR_VERIFY=true
        ;;
    esac

    # SSH 到目標環境做驗證也算
    IS_REMOTE_VERIFY=false
    case "$COMMAND" in
      *ssh*grep*|*ssh*curl*|*ssh*health*|*ssh*log*|*ssh*tail*)
        IS_REMOTE_VERIFY=true
        ;;
    esac

    # curl 打 API smoke test 也算
    IS_SMOKE_TEST=false
    case "$COMMAND" in
      *curl*api*|*curl*health*|*curl*actuator*)
        IS_SMOKE_TEST=true
        ;;
    esac

    if [ "$IS_DEPLOY_OR_VERIFY" = true ]; then
      echo "📡 test-on-change: 偵測到部署行為。"
    fi

    if [ "$IS_REMOTE_VERIFY" = true ] || [ "$IS_SMOKE_TEST" = true ]; then
      # 驗證行為 → 檢查結果
      if echo "$TOOL_OUTPUT" | grep -qiE "ERROR|FAIL|500|502|503|Connection refused"; then
        echo "🔴 test-on-change: 部署驗證有問題。.deploy-verify-required 保持。繼續修復。"
      else
        rm -f "$DEPLOY_VERIFY_FILE"
        echo "✅ test-on-change: 部署驗證通過。.deploy-verify-required 已清除。"
      fi
    fi
  fi

  exit 0
fi

exit 0
