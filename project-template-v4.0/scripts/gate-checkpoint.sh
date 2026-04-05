#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# gate-checkpoint.sh — PreToolUse hook：Gate 未通過時阻擋寫入 production code
# 用途：強制執行流程紀律。Gate checkpoint file 不存在 = 不能寫 production code
# 配置：寫入 .claude/settings.json 的 hooks.PreToolUse（matcher: Write, Edit）
#
# === 兩種 Gate 模式 ===
#
# 模式 A：Build Grounding Gate（所有 Feature 通用）
#   .gates/<feature>/.enabled + 無 .integration 標記
#   必須通過：build-grounded.confirmed
#   用途：確保 AI 讀了 RS + Prototype + Tech Spec 才能寫 code
#
# 模式 B：External Integration Gate（外部系統串接 Feature）
#   .gates/<feature>/.enabled + .gates/<feature>/.integration 標記
#   必須通過：gate0-spec → gate1-arch → gate2-contract（警告）
#   用途：確保 AI 讀了外部 Spec + 確認架構 + Contract Test
#
# === 啟用方式 ===
#   一般 Feature：  mkdir -p .gates/F03 && touch .gates/F03/.enabled
#   串接 Feature：  mkdir -p .gates/F02 && touch .gates/F02/.enabled .gates/F02/.integration
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="${1:-}"
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

# ─── 白名單：永遠放行的路徑 ───
case "$FILE_PATH" in
  */test/*|*/tests/*|*/__tests__/*|*Test.java|*.spec.ts|*.test.ts)
    exit 0  # 測試檔案永遠放行（TDD RED 階段需要）
    ;;
  */memory/*|*/TASKS.md|*task_plan.md|*findings.md|*progress.md)
    exit 0  # 追蹤檔案永遠放行
    ;;
  */.gates/*)
    exit 0  # Gate checkpoint file 本身放行
    ;;
  */contracts/*|*/fixtures/*)
    exit 0  # Contract fixture 放行
    ;;
  */tools/mock-*|*/mock-server/*)
    exit 0  # Mock server 放行
    ;;
  */scripts/*|*/deploy*)
    exit 0  # 部署腳本放行
    ;;
  */02_Specifications/*|*/03_System_Design/*|*/01_Product_Prototype/*)
    exit 0  # 規格文件放行（Discover/Plan 階段）
    ;;
  */CLAUDE.md|*/project-config.yaml|*/DESIGN.md)
    exit 0  # 框架配置放行
    ;;
  */context-skills/*|*/context-roles/*)
    exit 0  # Skill/Role 定義放行
    ;;
  */.plan-history/*)
    exit 0  # Plan 備份放行
    ;;
esac

# ─── 判斷是否為 production code ───
IS_PROD_CODE=false
case "$FILE_PATH" in
  */src/main/*|*/src/*)
    IS_PROD_CODE=true
    ;;
esac

[ "$IS_PROD_CODE" = false ] && exit 0

# ─── 查找啟用的 Feature ───
GATES_DIR=".gates"
[ ! -d "$GATES_DIR" ] && exit 0

ENABLED_FEATURES=""
for enabled_file in "$GATES_DIR"/*/.enabled; do
  [ -f "$enabled_file" ] || continue
  FEATURE_DIR=$(dirname "$enabled_file")
  FEATURE_ID=$(basename "$FEATURE_DIR")
  ENABLED_FEATURES="$ENABLED_FEATURES $FEATURE_ID"
done

[ -z "$ENABLED_FEATURES" ] && exit 0

# ─── 對每個啟用的 Feature 檢查 Gate ───
for FEATURE_ID in $ENABLED_FEATURES; do
  FEATURE_GATE_DIR="${GATES_DIR}/${FEATURE_ID}"

  # ════════════════════════════════════════
  # 模式 C：Debug Grounding Gate（Hotfix / Bug Fix）
  # ════════════════════════════════════════
  if [ -f "${FEATURE_GATE_DIR}/.debug" ]; then

    # Gate D1: 證據收集 — 讀了真實 log 才能改 code
    if [ ! -f "${FEATURE_GATE_DIR}/debug-evidence.confirmed" ]; then
      cat <<EOF
⛔ DEBUG GROUNDING GATE — 阻擋寫入 production code

Feature: ${FEATURE_ID}（Debug / Hotfix 模式）
目標檔案: ${FILE_PATH}

❌ 證據收集未完成 — 你還沒看 log 就想改 code

必須先完成（systematic-debugging → 部署環境模式）：
1. SSH 到目標環境，grep 相關 log：
   ssh user@host "grep -E 'ERROR|WARN|異常關鍵字' /path/to/app.log | tail -50"
2. 如果是前端問題 → 打開瀏覽器 Console，截取/複製完整 error
3. 收集完整 error stack trace + 環境資訊
4. 精確描述 SYMPTOM / EXPECTED / ACTUAL（不是「不能用」）
5. 列出 ≤3 個根因假設（排序：最可能 → 最不可能）
6. 產出 Debug Evidence Report 後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/debug-evidence.confirmed

⚠️ 禁止靠猜測改 code。沒有 log 證據的修復 = 瞎猜。
EOF
      exit 2
    fi

    # Gate D2: UI 問題 → 必須讀 Prototype（僅 UI 相關 bug）
    if [ -f "${FEATURE_GATE_DIR}/.ui-bug" ] && [ ! -f "${FEATURE_GATE_DIR}/debug-prototype.confirmed" ]; then
      cat <<EOF
⛔ DEBUG PROTOTYPE GATE — 阻擋寫入前端 code

Feature: ${FEATURE_ID}（UI Bug 修復模式）
目標檔案: ${FILE_PATH}

✅ 證據收集已完成
❌ Prototype 比對未完成 — 你還沒看 Prototype 就想改 CSS/HTML

必須先完成：
1. 讀取 Prototype HTML（用 Read 工具，不是靠記憶）
2. 逐行比對：Prototype 的佈局 vs 目前 248 上的實際畫面
3. 列出差異清單：
   | UI 元素 | Prototype | 目前 248 | 差異 |
   |---------|-----------|---------|------|
4. 確認後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/debug-prototype.confirmed

⚠️ 禁止靠記憶描述 Prototype。必須實際讀取 HTML 檔案。
EOF
      exit 2
    fi

    # Debug gate 通過 → 放行
    exit 0

  # ════════════════════════════════════════
  # 模式 B：External Integration Gate
  # ════════════════════════════════════════
  elif [ -f "${FEATURE_GATE_DIR}/.integration" ]; then

    # Gate 0: 讀 Spec + 介面契約摘要
    if [ ! -f "${FEATURE_GATE_DIR}/gate0-spec.confirmed" ]; then
      cat <<EOF
⛔ GATE CHECKPOINT — 阻擋寫入 production code

Feature: ${FEATURE_ID}（外部系統串接模式）
目標檔案: ${FILE_PATH}

❌ Gate 0（讀 Spec + 介面契約摘要）未通過

必須先完成：
1. 讀取外部系統 Spec 文件
2. 產出介面契約摘要
3. 用戶確認後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/gate0-spec.confirmed

詳見：context-skills/external-integration/SKILL.md → Gate 0
EOF
      exit 2
    fi

    # Gate 1: 架構確認
    if [ ! -f "${FEATURE_GATE_DIR}/gate1-arch.confirmed" ]; then
      cat <<EOF
⛔ GATE CHECKPOINT — 阻擋寫入 production code

Feature: ${FEATURE_ID}（外部系統串接模式）
目標檔案: ${FILE_PATH}

✅ Gate 0（Spec 確認）已通過
❌ Gate 1（架構設計確認）未通過

必須先完成：
1. 回答架構問題 + 元件職責表
2. 用戶確認後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/gate1-arch.confirmed

詳見：context-skills/external-integration/SKILL.md → Gate 1
EOF
      exit 2
    fi

    # Gate 2: Contract Test（警告不阻擋）
    if [ ! -f "${FEATURE_GATE_DIR}/gate2-contract.confirmed" ]; then
      echo "⚠️ gate-checkpoint: ${FEATURE_ID} Gate 2（Contract Test）尚未確認。請確保 Fixture + Test 全綠後建立 checkpoint。"
    fi

  # ════════════════════════════════════════
  # 模式 A：Build Grounding Gate（通用）
  # ════════════════════════════════════════
  else

    if [ ! -f "${FEATURE_GATE_DIR}/build-grounded.confirmed" ]; then
      cat <<EOF
⛔ BUILD GROUNDING GATE — 阻擋寫入 production code

Feature: ${FEATURE_ID}
目標檔案: ${FILE_PATH}

❌ Build Grounding 未通過 — 你還沒讀 spec 就想寫 code

必須先完成（ground skill → Build Grounding 流程）：
1. 讀 RS_${FEATURE_ID} → 列出所有 AC
2. 讀 Prototype HTML → 描述看到的 UI 佈局和元件（不是靠記憶）
3. 讀 Tech Spec TS_${FEATURE_ID} → 列出 API / Schema / 元件清單
4. 產出 Build Checklist：每條 AC → 對應的實作項目
5. 用戶確認 Checklist 後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/build-grounded.confirmed

⚠️ 禁止靠記憶描述 UI。必須用 Read 工具實際讀取 Prototype HTML 檔案。
EOF
      exit 2
    fi

    # ── v4.1: Pattern Check Gate ──
    # Build Grounding 通過後，寫 code 前必須查 Pattern Library
    if [ ! -f "${FEATURE_GATE_DIR}/pattern-checked.confirmed" ]; then
      cat <<EOF
⛔ PATTERN CHECK GATE — 阻擋寫入 production code

Feature: ${FEATURE_ID}
目標檔案: ${FILE_PATH}

✅ Build Grounding 已通過
❌ Pattern Library 未查詢 — 可能在重複造輪子

必須先完成（pattern-library skill）：
1. 讀取 verified-patterns/README.md 查看有無可複用的 pattern
2. 對照 Build Checklist 的每個實作項目，標記：
   - ✅ 有 pattern 可用 → 記錄 pattern 名稱
   - ❌ 無 pattern → 標記「從零實作」
3. 產出 Pattern Check Log 後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/pattern-checked.confirmed

查完就好，不是每個 AC 都一定要有 pattern。重點是先查再寫。
EOF
      exit 2
    fi

    # ── v4.1: Contract Defined Gate ──
    # Pattern Check 通過後，有 API endpoint 的 Feature 必須有 Contract YAML
    if [ ! -f "${FEATURE_GATE_DIR}/contract-defined.confirmed" ]; then
      # 檢查這個 Feature 是否有 API（有的 Feature 可能純前端 UI 不需要）
      CONTRACT_FILES=$(ls contracts/${FEATURE_ID}-*.yaml 2>/dev/null | wc -l | tr -d ' ')
      if [ "$CONTRACT_FILES" -gt 0 ]; then
        # 已有 contract 檔案 → 自動通過（但還沒有 confirmed 標記）
        echo "⚠️ gate-checkpoint: 已找到 ${CONTRACT_FILES} 個 Contract YAML，但尚未確認。請驗證後建立 checkpoint。"
      fi
      cat <<EOF
⛔ CONTRACT DEFINED GATE — 阻擋寫入 production code

Feature: ${FEATURE_ID}
目標檔案: ${FILE_PATH}

✅ Build Grounding 已通過
✅ Pattern Check 已通過
❌ API Contract 未定義 — 前後端會各自發明 DTO 欄位名

必須先完成（validate-contract skill）：
1. 對照 Tech Spec §2.5 的 Shared DTO 定義
2. 為每個 API endpoint 建立 Contract YAML：
   contracts/${FEATURE_ID}-[endpoint].yaml（模板：contracts/TEMPLATE_API_Contract.yaml）
3. Contract YAML 定義 response 結構（欄位名 = 前後端共用 SSOT）
4. 確認後建立 checkpoint：
   echo "confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${FEATURE_GATE_DIR}/contract-defined.confirmed

如果本 Feature 沒有 API endpoint（純 UI），直接建立 checkpoint 標記跳過。
EOF
      exit 2
    fi

  fi
done

exit 0
