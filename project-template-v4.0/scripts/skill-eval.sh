#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Skill E2E 評估腳本（Tier 2 + Tier 3）
# 用途：用 LLM 評估 Skill 品質（清晰度/完整度/可操作性）
# 靈感來源：gstack eval 三層測試架構
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SKILLS_DIR="${1:-project-template/context-skills}"
EVAL_OUTPUT="${2:-project-template/scripts/eval-results}"
THRESHOLD="${3:-4}"  # LLM 評分閾值（滿分 5）

mkdir -p "$EVAL_OUTPUT"

echo "═══════════════════════════════════════"
echo " Skill 品質評估（Tier 2 + Tier 3）"
echo "═══════════════════════════════════════"
echo ""

# ─── Tier 2：結構完整性深度檢查 ───
echo "▌ Tier 2：結構完整性深度檢查"
echo "─────────────────────────────"

TIER2_PASS=0
TIER2_FAIL=0

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  [ ! -f "$skill_file" ] && continue

  issues=""

  # 檢查是否有「為什麼」段落（動機說明）
  if ! grep -qiE "為什麼|why|目的|purpose" "$skill_file"; then
    issues="${issues}  - 缺少動機說明（為什麼需要此 skill）\n"
  fi

  # 檢查是否有步驟/流程（Step / 步驟 / 流程）
  if ! grep -qiE "step|步驟|流程|執行|how to" "$skill_file"; then
    issues="${issues}  - 缺少執行步驟\n"
  fi

  # 檢查是否有與現有框架的整合說明
  if ! grep -qiE "整合|integration|搭配|與.*skill|pipeline" "$skill_file"; then
    issues="${issues}  - 缺少框架整合說明\n"
  fi

  if [ -z "$issues" ]; then
    echo "  ✓ $skill_name — 結構完整"
    ((TIER2_PASS++))
  else
    echo "  ⚠ $skill_name — 結構不完整："
    echo -e "$issues"
    ((TIER2_FAIL++))
  fi
done

echo ""
echo "  Tier 2 結果：$TIER2_PASS 通過 / $TIER2_FAIL 需改善"
echo ""

# ─── Tier 3：LLM-as-Judge 評估（需要 claude CLI）───
echo "▌ Tier 3：LLM-as-Judge 評估"
echo "─────────────────────────────"
echo ""

# 檢查 claude CLI 是否可用
if ! command -v claude &>/dev/null; then
  echo "  ⚠ claude CLI 未安裝，跳過 Tier 3 評估"
  echo "  安裝方式：npm install -g @anthropic-ai/claude-code"
  echo ""
  echo "  若要手動執行 Tier 3，對每個 SKILL.md 執行："
  echo "  claude -p '請評估以下 SKILL.md 的品質...'"
  exit 0
fi

EVAL_PROMPT='請評估以下 SKILL.md 文件的品質，針對三個維度各給 1-5 分：

1. **清晰度 (Clarity)**：讀者能否快速理解這個 skill 是做什麼的？觸發條件明確嗎？
2. **完整度 (Completeness)**：步驟是否完整？是否涵蓋了常見情境和邊界案例？
3. **可操作性 (Actionability)**：Agent 讀完後能否直接執行？還是需要猜測很多細節？

輸出格式（JSON，不要其他文字）：
{"clarity": N, "completeness": N, "actionability": N, "avg": N.N, "summary": "一句話評語"}

SKILL.md 內容：
'

TIER3_PASS=0
TIER3_FAIL=0
RESULTS="[]"

echo "  評估中（每個 skill 約 10-15 秒）..."
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  [ ! -f "$skill_file" ] && continue

  content=$(cat "$skill_file")
  result=$(claude -p "${EVAL_PROMPT}${content}" --model haiku 2>/dev/null || echo '{"error": "eval failed"}')

  # 嘗試解析平均分
  avg=$(echo "$result" | grep -oE '"avg":\s*[0-9.]+' | grep -oE '[0-9.]+' || echo "0")

  if [ "$(echo "$avg >= $THRESHOLD" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    echo "  ✓ $skill_name — 平均 $avg/5"
    ((TIER3_PASS++))
  else
    echo "  ✗ $skill_name — 平均 $avg/5（低於閾值 $THRESHOLD）"
    ((TIER3_FAIL++))
  fi

  # 儲存詳細結果
  echo "{\"skill\": \"$skill_name\", \"result\": $result}" >> "$EVAL_OUTPUT/tier3-results.jsonl"
done

echo ""
echo "  Tier 3 結果：$TIER3_PASS 通過 / $TIER3_FAIL 低於閾值"
echo "  詳細結果：$EVAL_OUTPUT/tier3-results.jsonl"
echo ""

# ─── 總結 ───
echo "═══════════════════════════════════════"
echo " 評估總結"
echo "═══════════════════════════════════════"
echo "  Tier 1（靜態）：另行執行 validate-skills.sh"
echo "  Tier 2（結構）：$TIER2_PASS 通過 / $TIER2_FAIL 需改善"
echo "  Tier 3（LLM）：$TIER3_PASS 通過 / $TIER3_FAIL 低於閾值"
