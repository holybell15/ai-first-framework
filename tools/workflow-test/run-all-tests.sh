#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# 三層工作流測試 — 一鍵執行
# Tier 1: 結構驗證（run_tests.py）
# Tier 2: 流程模擬（workflow-simulation.py）
# Tier 3: A/B 品質比對（workflow-ab-test.py）
#
# 用法:
#   bash run-all-tests.sh           # Tier 1 + 2（不用 LLM）
#   bash run-all-tests.sh --all     # Tier 1 + 2 + 3（需要 claude CLI）
#   bash run-all-tests.sh --tier 2  # 只跑 Tier 2
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIER="${1:---default}"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "╔══════════════════════════════════════════════════╗"
echo "║  AI-First Framework — 工作流品質測試            ║"
echo "║  $(date)                              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─── Tier 1：結構驗證 ───
if [ "$TIER" = "--default" ] || [ "$TIER" = "--all" ] || [ "$TIER" = "--tier" -a "${2:-}" = "1" ]; then
  echo "━━━ Tier 1: 結構驗證 ━━━"
  python3 "$SCRIPT_DIR/run_tests.py" 2>&1 | tail -20
  echo ""
fi

# ─── Tier 2：流程模擬 ───
if [ "$TIER" = "--default" ] || [ "$TIER" = "--all" ] || [ "$TIER" = "--tier" -a "${2:-}" = "2" ]; then
  echo "━━━ Tier 2: 流程模擬 ━━━"
  python3 "$SCRIPT_DIR/workflow-simulation.py" --output "$RESULTS_DIR/tier2_${TIMESTAMP}.json"
  echo ""
fi

# ─── Tier 3：A/B 品質比對 ───
if [ "$TIER" = "--all" ] || [ "$TIER" = "--tier" -a "${2:-}" = "3" ]; then
  echo "━━━ Tier 3: A/B 品質比對 ━━━"
  if command -v claude &>/dev/null; then
    python3 "$SCRIPT_DIR/workflow-ab-test.py" --output "$RESULTS_DIR/tier3_${TIMESTAMP}.json"
  else
    echo "⚠️ claude CLI 未安裝，跳過 Tier 3"
    echo "   安裝：npm install -g @anthropic-ai/claude-code"
  fi
  echo ""
fi

# ─── Master Report ───
echo "━━━ Master Report ━━━"
python3 "$SCRIPT_DIR/generate-master-report.py" --open

echo "╔══════════════════════════════════════════════════╗"
echo "║  測試完成                                       ║"
echo "║  結果目錄：$RESULTS_DIR"
echo "║  Master Report：$RESULTS_DIR/master-report.html ║"
echo "╚══════════════════════════════════════════════════╝"
