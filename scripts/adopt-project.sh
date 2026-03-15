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

# ── Helper: copy directory, skipping existing files ────────────
copy_dir_if_missing() {
  local src_dir="$1"
  local dst_dir="$2"
  local label="$3"

  if [ -d "$dst_dir" ]; then
    echo "   ⏭️  Skip dir (already exists): $label"
  else
    cp -r "$src_dir" "$dst_dir"
    echo "   ✅ Added dir: $label"
  fi
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

if [ ! -d "$PROJECT_PATH/10_Standards" ]; then
  cp -r "$TEMPLATE_DIR/10_Standards" "$PROJECT_PATH/10_Standards"
  # Replace placeholders in all standards files
  while IFS= read -r -d '' file; do
    replace_placeholders "$file"
  done < <(find "$PROJECT_PATH/10_Standards" -type f \( -name "*.md" -o -name "*.yaml" \) -print0)
  echo "   ✅ Added: 10_Standards/ (API / DB / UI 三域標準)"
else
  echo "   ⏭️  Skip (exists): 10_Standards/"
fi

# ──────────────────────────────────────────────────────────────
# Step 3: context-seeds/ 和 context-skills/
# ──────────────────────────────────────────────────────────────
echo ""
echo "🌱 Step 3 — context-seeds/ + context-skills/..."

copy_dir_if_missing "$TEMPLATE_DIR/context-seeds" \
  "$PROJECT_PATH/context-seeds" "context-seeds/"

copy_dir_if_missing "$TEMPLATE_DIR/context-skills" \
  "$PROJECT_PATH/context-skills" "context-skills/"

# ──────────────────────────────────────────────────────────────
# Step 4: contracts/, CLAUDE.md, TASKS.md, MASTER_INDEX.md
# ──────────────────────────────────────────────────────────────
echo ""
echo "📋 Step 4 — contracts/ + root files..."

if [ ! -d "$PROJECT_PATH/contracts" ]; then
  mkdir -p "$PROJECT_PATH/contracts"
  cp "$TEMPLATE_DIR/contracts/README.md" "$PROJECT_PATH/contracts/README.md"
  replace_placeholders "$PROJECT_PATH/contracts/README.md"
  echo "   ✅ Added: contracts/"
else
  echo "   ⏭️  Skip (exists): contracts/"
fi

copy_if_missing "$TEMPLATE_DIR/CLAUDE.md" "$PROJECT_PATH/CLAUDE.md" "CLAUDE.md"
if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
  replace_placeholders "$PROJECT_PATH/CLAUDE.md"
fi

copy_if_missing "$TEMPLATE_DIR/TASKS.md" "$PROJECT_PATH/TASKS.md" "TASKS.md"
copy_if_missing "$TEMPLATE_DIR/MASTER_INDEX.md" "$PROJECT_PATH/MASTER_INDEX.md" "MASTER_INDEX.md"
copy_if_missing "$TEMPLATE_DIR/TEAM.md" "$PROJECT_PATH/TEAM.md" "TEAM.md"

if [ -f "$PROJECT_PATH/MASTER_INDEX.md" ]; then
  replace_placeholders "$PROJECT_PATH/MASTER_INDEX.md"
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
# Step 7: memory/last_task.md（記錄接入時間點）
# ──────────────────────────────────────────────────────────────
echo ""
echo "📝 Step 7 — Recording adoption in memory/last_task.md..."

TODAY=$(date +%Y-%m-%d)
FW_VERSION=$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null || echo "2.3.0")

# Prepend to last_task.md (keep existing content if any)
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOF
## $TODAY — AI-First Framework 接入完成

- **專案**: $PROJECT_NAME（舊專案接入）
- **框架版本**: AI-First Framework v$FW_VERSION
- **錯誤碼前綴**: $ERROR_PREFIX
- **下一步**: 說「執行 Pipeline: 舊專案接入」開始 7-Stage 接入流程
  Stage 1: map-codebase（技術全景掃描）
  Stage 2: F-code 分配
  Stage 3: ADR 補記
  Stage 4: 技術債登記
  Stage 5: GAP 評估
  Stage 6: CI 整合
  Stage 7: 接入宣告 commit

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
echo "   這會啟動 7 個 Stage 的接入流程（約 1~2 天）："
echo "   1. 技術全景掃描（map-codebase §41）"
echo "   2. Feature 盤點 + F-code 分配"
echo "   3. 架構決策補記（ADR）"
echo "   4. 技術債顯性登記"
echo "   5. 標準差距評估（GAP Report）"
echo "   6. 環境 + CI 整合"
echo "   7. 接入宣告 commit"
echo ""
echo "   接入完成後，新功能走 Pipeline: 需求訪談，"
echo "   修改舊 code 走 §4 四步修改法，緊急問題走 執行 Hotfix:。"
echo ""
echo "──────────────────────────────────────────────────────────"
