#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Skill / Seed 品質驗證腳本（Tier 1 — 靜態驗證）
# 用途：CI 中確保所有 SKILL.md / SEED 檔案格式正確、無飄移
# 靈感來源：gstack skill-docs.yml CI 驗證
# ─────────────────────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
SKILLS_DIR="${1:-project-template/context-skills}"
SEEDS_DIR="${2:-project-template/context-seeds}"

echo "═══════════════════════════════════════"
echo " Skill / Seed 靜態品質驗證（Tier 1）"
echo "═══════════════════════════════════════"
echo ""

# ─── Tier 1-A：SKILL.md 格式驗證 ───
echo "▌ Tier 1-A：SKILL.md 格式驗證"
echo "─────────────────────────────"

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    echo -e "  ${RED}✗${NC} $skill_name — 缺少 SKILL.md"
    ((ERRORS++))
    continue
  fi

  # 檢查 frontmatter 存在
  if ! head -1 "$skill_file" | grep -q "^---"; then
    echo -e "  ${RED}✗${NC} $skill_name — 缺少 YAML frontmatter（必須以 --- 開頭）"
    ((ERRORS++))
    continue
  fi

  # 檢查必要欄位：name, description
  if ! grep -q "^name:" "$skill_file"; then
    echo -e "  ${RED}✗${NC} $skill_name — frontmatter 缺少 'name' 欄位"
    ((ERRORS++))
  fi

  if ! grep -q "^description:" "$skill_file"; then
    echo -e "  ${RED}✗${NC} $skill_name — frontmatter 缺少 'description' 欄位"
    ((ERRORS++))
  fi

  # 檢查內容不為空（至少 10 行）
  line_count=$(wc -l < "$skill_file" | tr -d ' ')
  if [ "$line_count" -lt 10 ]; then
    echo -e "  ${YELLOW}⚠${NC} $skill_name — 內容過短（$line_count 行，建議 ≥ 20 行）"
    ((WARNINGS++))
  else
    echo -e "  ${GREEN}✓${NC} $skill_name — OK（$line_count 行）"
  fi

  # 檢查 UTF-8 編碼
  if file "$skill_file" | grep -qv "UTF-8\|ASCII"; then
    echo -e "  ${YELLOW}⚠${NC} $skill_name — 非 UTF-8 編碼"
    ((WARNINGS++))
  fi
done

echo ""

# ─── Tier 1-B：SEED 檔案驗證 ───
echo "▌ Tier 1-B：SEED 檔案格式驗證"
echo "─────────────────────────────"

EXPECTED_SEEDS=("SEED_Interviewer" "SEED_PM" "SEED_UX" "SEED_Architect" "SEED_DBA" "SEED_Backend" "SEED_Frontend" "SEED_QA" "SEED_Security" "SEED_DevOps" "SEED_Review")

for seed_name in "${EXPECTED_SEEDS[@]}"; do
  seed_file="$SEEDS_DIR/${seed_name}.md"

  if [ ! -f "$seed_file" ]; then
    echo -e "  ${RED}✗${NC} $seed_name — 檔案不存在"
    ((ERRORS++))
    continue
  fi

  # 檢查是否包含種子提示詞區塊
  if ! grep -q "種子提示詞\|## 種子" "$seed_file"; then
    echo -e "  ${YELLOW}⚠${NC} $seed_name — 找不到「種子提示詞」區塊"
    ((WARNINGS++))
  fi

  # 檢查是否有未替換的佔位符提示
  if ! grep -q "\[.*佔位符\|placeholder\|使用前請將" "$seed_file"; then
    echo -e "  ${YELLOW}⚠${NC} $seed_name — 缺少佔位符替換提示（可能是已客製化版本）"
    ((WARNINGS++))
  fi

  line_count=$(wc -l < "$seed_file" | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} $seed_name — OK（$line_count 行）"
done

echo ""

# ─── Tier 1-C：交叉引用驗證 ───
echo "▌ Tier 1-C：Skill 交叉引用驗證"
echo "─────────────────────────────"

# 檢查 SEED 中引用的 skill 路徑是否存在
for seed_file in "$SEEDS_DIR"/SEED_*.md; do
  seed_name=$(basename "$seed_file" .md)
  # 找出所有 context-skills/xxx/ 引用
  referenced_skills=$(grep -oE "context-skills/[a-zA-Z0-9_-]+/" "$seed_file" 2>/dev/null | sort -u || true)

  for ref in $referenced_skills; do
    ref_path="$SKILLS_DIR/../$ref"
    if [ ! -d "${ref_path%/}" ] && [ ! -d "project-template/$ref" ]; then
      # Try relative to skills dir
      skill_subdir=$(echo "$ref" | sed 's|context-skills/||' | sed 's|/||')
      if [ ! -d "$SKILLS_DIR/$skill_subdir" ]; then
        echo -e "  ${YELLOW}⚠${NC} $seed_name 引用了 $ref 但目錄不存在"
        ((WARNINGS++))
      fi
    fi
  done
done

echo -e "  ${GREEN}✓${NC} 交叉引用掃描完成"
echo ""

# ─── Tier 1-D：Manifest 一致性 ───
echo "▌ Tier 1-D：Manifest 一致性"
echo "─────────────────────────────"

MANIFEST="$SEEDS_DIR/_MANIFEST.md"
if [ -f "$MANIFEST" ]; then
  for seed_name in "${EXPECTED_SEEDS[@]}"; do
    if ! grep -q "$seed_name" "$MANIFEST"; then
      echo -e "  ${YELLOW}⚠${NC} $seed_name 不在 _MANIFEST.md 中"
      ((WARNINGS++))
    fi
  done
  echo -e "  ${GREEN}✓${NC} Manifest 檢查完成"
else
  echo -e "  ${YELLOW}⚠${NC} _MANIFEST.md 不存在"
  ((WARNINGS++))
fi

echo ""

# ─── 結果彙總 ───
echo "═══════════════════════════════════════"
echo " 驗證結果"
echo "═══════════════════════════════════════"
echo ""
echo "  Skills 掃描：$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ') 個"
echo "  Seeds 掃描：${#EXPECTED_SEEDS[@]} 個"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  echo -e "  ${RED}✗ $ERRORS 個錯誤${NC} / ${YELLOW}$WARNINGS 個警告${NC}"
  echo ""
  echo "  CI 結果：❌ FAIL"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo -e "  ${GREEN}0 個錯誤${NC} / ${YELLOW}$WARNINGS 個警告${NC}"
  echo ""
  echo "  CI 結果：✅ PASS（有警告）"
  exit 0
else
  echo -e "  ${GREEN}✓ 全部通過，0 個錯誤，0 個警告${NC}"
  echo ""
  echo "  CI 結果：✅ PASS"
  exit 0
fi
