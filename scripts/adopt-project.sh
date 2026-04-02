#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# AI-First Framework — adopt-project.sh
# Usage: ./scripts/adopt-project.sh <ProjectPath> [ErrorPrefix]
#
# 將 AI-First Framework 導入「已存在」的舊專案。
# 與 new-project.sh 的差異：
#   - 不複製整個 template（避免覆蓋現有程式碼）
#   - 只補入缺少的框架文件（memory/, 10_Standards/, context-seeds/ 等）
#   - 不覆蓋已存在的文件
#   - 執行完成後提示運行 Pipeline: 舊專案接入
#
# Arguments:
#   ProjectPath  — 已存在的專案路徑（絕對或相對）
#   ErrorPrefix  — 4-6 char 錯誤碼前綴（預設從資料夾名稱推導）
# ──────────────────────────────────────────────────────────────

set -e

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$FRAMEWORK_DIR/project-template"

# ── Args ──────────────────────────────────────────────────────
PROJECT_PATH="${1:-}"
ERROR_PREFIX="${2:-}"

if [ -z "$PROJECT_PATH" ]; then
  echo "Usage: $0 <ProjectPath> [ErrorPrefix]"
  echo "Example: $0 ~/Projects/MyLegacyApp MYL"
  exit 1
fi

# Resolve to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "❌ Directory does not exist: $PROJECT_PATH"
  exit 1
fi

# Derive error prefix if not provided
if [ -z "$ERROR_PREFIX" ]; then
  ERROR_PREFIX=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-4)
fi

echo "🔄 Adopting AI-First Framework into existing project: $PROJECT_NAME"
echo "   Path: $PROJECT_PATH"
echo "   Error Code Prefix: $ERROR_PREFIX"
echo ""

# ── Helper: copy file only if target does NOT exist ────────────
copy_if_missing() {
  local src="$1"
  local dst="$2"
  local label="${3:-$(basename "$dst")}"

  if [ -e "$dst" ]; then
    echo "   ⏭️  Skip (already exists): $label"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "   ✅ Added: $label"
  fi
}

# ── Helper: copy only missing files from a directory tree ─────
copy_tree_missing_files() {
  local src_dir="$1"
  local dst_dir="$2"
  local label="$3"
  local added=0
  local skipped=0

  mkdir -p "$dst_dir"

  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$src_dir/}"
    local dst_file="$dst_dir/$rel_path"

    mkdir -p "$(dirname "$dst_file")"

    if [ -e "$dst_file" ]; then
      skipped=$((skipped + 1))
    else
      cp "$src_file" "$dst_file"
      replace_placeholders "$dst_file"
      added=$((added + 1))
    fi
  done < <(find "$src_dir" -type f -print0)

  echo "   ✅ Synced: $label (added $added, skipped $skipped existing files)"
}

# ── Replace placeholders in a file ────────────────────────────
replace_in_file() {
  local file="$1"
  local from="$2"
  local to="$3"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|${from}|${to}|g" "$file"
  else
    sed -i "s|${from}|${to}|g" "$file"
  fi
}

replace_placeholders() {
  local file="$1"
  replace_in_file "$file" "\[專案名稱\]" "$PROJECT_NAME"
  replace_in_file "$file" "\[產品名稱\]" "$PROJECT_NAME"
  replace_in_file "$file" "\[PREFIX\]"   "$ERROR_PREFIX"
}

# ──────────────────────────────────────────────────────────────
# Step 1: Framework 核心文件（memory/, context-seeds/）
# ──────────────────────────────────────────────────────────────
echo "📁 Step 1 — Framework memory & seeds..."

# memory/ — copy each file individually to avoid overwriting user data
MEMORY_FILES=(
  "workflow_rules.md"
  "decisions.md"
  "glossary.md"
  "product.md"
  "STATE.md"
  "TECH_DEBT.md"
  "hotfix_log.md"
  "token_budget.md"
  "gate_baseline.yaml"
  "smoke_tests.md"
  "dashboard.md"
)

mkdir -p "$PROJECT_PATH/memory"
mkdir -p "$PROJECT_PATH/memory/context"
mkdir -p "$PROJECT_PATH/memory/people"
mkdir -p "$PROJECT_PATH/memory/projects"
mkdir -p "$PROJECT_PATH/memory/knowledge_base"

for f in "${MEMORY_FILES[@]}"; do
  src="$TEMPLATE_DIR/memory/$f"
  dst="$PROJECT_PATH/memory/$f"
  if [ -f "$src" ]; then
    if [ ! -f "$dst" ]; then
      cp "$src" "$dst"
      replace_placeholders "$dst"
      echo "   ✅ Added: memory/$f"
    else
      echo "   ⏭️  Skip (exists): memory/$f"
    fi
  fi
done

copy_if_missing "$TEMPLATE_DIR/memory/context/company.md" \
  "$PROJECT_PATH/memory/context/company.md" "memory/context/company.md"
copy_if_missing "$TEMPLATE_DIR/memory/knowledge_base/KB-AH_hallucination_patterns.md" \
  "$PROJECT_PATH/memory/knowledge_base/KB-AH_hallucination_patterns.md" "memory/KB-AH..."

# ──────────────────────────────────────────────────────────────
# Step 2: 10_Standards/（三域技術標準）
# ──────────────────────────────────────────────────────────────
echo ""
echo "📐 Step 2 — 10_Standards/ (三域技術標準)..."

copy_tree_missing_files "$TEMPLATE_DIR/10_Standards" \
  "$PROJECT_PATH/10_Standards" "10_Standards/"

# ──────────────────────────────────────────────────────────────
# Step 3: context-seeds/ 和 context-skills/
# ──────────────────────────────────────────────────────────────
echo ""
echo "🌱 Step 3 — context-seeds/ + context-skills/..."

copy_tree_missing_files "$TEMPLATE_DIR/context-seeds" \
  "$PROJECT_PATH/context-seeds" "context-seeds/"

copy_tree_missing_files "$TEMPLATE_DIR/context-skills" \
  "$PROJECT_PATH/context-skills" "context-skills/"

copy_tree_missing_files "$TEMPLATE_DIR/scripts" \
  "$PROJECT_PATH/scripts" "scripts/"

# ──────────────────────────────────────────────────────────────
# Step 4: contracts/, CLAUDE.md, TASKS.md, MASTER_INDEX.md
# ──────────────────────────────────────────────────────────────
echo ""
echo "📋 Step 4 — contracts/ + root files..."

copy_tree_missing_files "$TEMPLATE_DIR/contracts" \
  "$PROJECT_PATH/contracts" "contracts/"

copy_if_missing "$TEMPLATE_DIR/CLAUDE.md" "$PROJECT_PATH/CLAUDE.md" "CLAUDE.md"
if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
  replace_placeholders "$PROJECT_PATH/CLAUDE.md"
fi

copy_if_missing "$TEMPLATE_DIR/PROJECT_DASHBOARD.html" "$PROJECT_PATH/PROJECT_DASHBOARD.html" "PROJECT_DASHBOARD.html"
copy_if_missing "$TEMPLATE_DIR/PROJECT_DASHBOARD.data.js" "$PROJECT_PATH/PROJECT_DASHBOARD.data.js" "PROJECT_DASHBOARD.data.js"

copy_if_missing "$TEMPLATE_DIR/TASKS.md" "$PROJECT_PATH/TASKS.md" "TASKS.md"
copy_if_missing "$TEMPLATE_DIR/MASTER_INDEX.md" "$PROJECT_PATH/MASTER_INDEX.md" "MASTER_INDEX.md"
copy_if_missing "$TEMPLATE_DIR/TEAM.md" "$PROJECT_PATH/TEAM.md" "TEAM.md"
copy_if_missing "$TEMPLATE_DIR/START_HERE.md" "$PROJECT_PATH/START_HERE.md" "START_HERE.md"

if [ -f "$PROJECT_PATH/MASTER_INDEX.md" ]; then
  replace_placeholders "$PROJECT_PATH/MASTER_INDEX.md"
fi
if [ -f "$PROJECT_PATH/PROJECT_DASHBOARD.html" ]; then
  replace_placeholders "$PROJECT_PATH/PROJECT_DASHBOARD.html"
fi
if [ -f "$PROJECT_PATH/PROJECT_DASHBOARD.data.js" ]; then
  replace_placeholders "$PROJECT_PATH/PROJECT_DASHBOARD.data.js"
fi

# ──────────────────────────────────────────────────────────────
# Step 5: .env.example + .github/ (CODEOWNERS + CI)
# ──────────────────────────────────────────────────────────────
echo ""
echo "⚙️  Step 5 — .env.example + .github/..."

copy_if_missing "$TEMPLATE_DIR/.env.example" \
  "$PROJECT_PATH/.env.example" ".env.example"

mkdir -p "$PROJECT_PATH/.github/workflows"
copy_if_missing "$TEMPLATE_DIR/.github/CODEOWNERS" \
  "$PROJECT_PATH/.github/CODEOWNERS" ".github/CODEOWNERS"
copy_if_missing "$TEMPLATE_DIR/.github/workflows/ci.yml" \
  "$PROJECT_PATH/.github/workflows/ci.yml" ".github/workflows/ci.yml"

# ──────────────────────────────────────────────────────────────
# Step 6: 資料夾結構（02~09 若缺少則建立 .gitkeep）
# ──────────────────────────────────────────────────────────────
echo ""
echo "📂 Step 6 — Project folder structure..."

FOLDERS=(
  "01_Product_Prototype"
  "02_Specifications"
  "03_System_Design"
  "04_Compliance"
  "05_Archive"
  "06_Interview_Records"
  "07_Retrospectives"
  "08_Test_Reports"
  "09_Release_Records"
)

for folder in "${FOLDERS[@]}"; do
  if [ ! -d "$PROJECT_PATH/$folder" ]; then
    mkdir -p "$PROJECT_PATH/$folder"
    touch "$PROJECT_PATH/$folder/.gitkeep"
    echo "   ✅ Added: $folder/"
  else
    echo "   ⏭️  Skip (exists): $folder/"
  fi
done

# ──────────────────────────────────────────────────────────────
# Step 7: memory/adoption_gap_report.md（建立初始 GAP 報告）
# ──────────────────────────────────────────────────────────────
echo ""
echo "🧭 Step 7 — Creating memory/adoption_gap_report.md..."

ADOPTION_GAP_REPORT="$PROJECT_PATH/memory/adoption_gap_report.md"

if [ ! -f "$ADOPTION_GAP_REPORT" ]; then
  cat > "$ADOPTION_GAP_REPORT" << EOF
# Adoption Gap Report — $PROJECT_NAME

> 舊專案接入的初始盤點。先標出差距，再決定哪些要現在補、哪些排到後續。

## Environment Snapshot

- Production branch: [待確認]
- Deploy method: [待確認]
- CI status: [待確認]
- Automated tests: [待確認]
- Staging / preview environment: [待確認]

## Gaps

### Now
- [ ] 確認 production branch 與部署流程
- [ ] 建立第一版 codebase snapshot
- [ ] 確認第一個要接入的功能或修復

### Next
- [ ] 補齊缺少的 standards 對映
- [ ] 補齊 CI / smoke checks
- [ ] 補技術債與決策記錄

### Later
- [ ] legacy feature F-code 盤點
- [ ] 完整 ADR 補記
- [ ] 完整 Gate / compliance 接軌

## Notes

- 本報告允許先不完整，重點是讓接入工作可持續推進。
- 建議 Lite 接入先完成 Now，再決定是否升級到 Standard 接入。
EOF
  echo "   ✅ Added: memory/adoption_gap_report.md"
else
  echo "   ⏭️  Skip (exists): memory/adoption_gap_report.md"
fi

# ──────────────────────────────────────────────────────────────
# Step 8: memory/last_task.md（記錄接入時間點）
# ──────────────────────────────────────────────────────────────
echo ""
echo "📝 Step 8 — Recording adoption in memory/last_task.md..."

TODAY=$(date +%Y-%m-%d)
FW_VERSION=$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null || echo "2.3.0")

# Prepend to last_task.md (keep existing content if any)
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
## $TODAY — AI-First Framework 接入完成

- **專案**: $PROJECT_NAME（舊專案接入）
- **框架版本**: AI-First Framework v$FW_VERSION
- **錯誤碼前綴**: $ERROR_PREFIX
- **下一步**: 說「執行 Pipeline: 舊專案接入」開始雙軌接入流程
  Lite 接入：現況盤點 → baseline 建立 → codebase 掃描 → GAP 報告 → 選第一個接入功能
  Standard 接入：map-codebase → F-code 分配 → ADR 補記 → 技術債登記 → GAP 評估 → CI 整合 → 接入宣告
- **初始 GAP**: memory/adoption_gap_report.md

EOF

if [ -f "$PROJECT_PATH/memory/last_task.md" ]; then
  cat "$PROJECT_PATH/memory/last_task.md" >> "$TEMP_FILE"
fi
mv "$TEMP_FILE" "$PROJECT_PATH/memory/last_task.md"

echo "   ✅ memory/last_task.md updated"

# ──────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────
echo ""
echo "✅ AI-First Framework adopted successfully!"
echo ""
echo "📁 Project : $PROJECT_PATH"
echo "🔖 Prefix  : $ERROR_PREFIX"
echo ""
echo "📋 接下來在 Claude Code / Cowork 中說："
echo ""
echo "   「執行 Pipeline: 舊專案接入」"
echo ""
echo "   這會啟動雙軌接入流程："
echo "   Lite 接入：現況盤點 → baseline 建立 → codebase 掃描 → GAP 報告 → 第一個接入功能"
echo "   Standard 接入：map-codebase → F-code 分配 → ADR 補記 → 技術債登記 → GAP 評估 → CI 整合 → 接入宣告"
echo ""
echo "   接入完成後，新功能走 Pipeline: 需求訪談，"
echo "   修改舊 code 走 §4 四步修改法，緊急問題走 執行 Hotfix:。"
echo ""
echo "──────────────────────────────────────────────────────────"
