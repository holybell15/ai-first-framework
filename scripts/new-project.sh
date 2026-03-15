#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# AI-First Framework — new-project.sh
# Usage: ./scripts/new-project.sh <ProjectName> [output-dir] [ErrorPrefix]
#
# Creates a new project folder from the project-template,
# replacing all placeholders with actual values.
#
# Arguments:
#   ProjectName   — Project name (e.g. MyProduct)
#   output-dir    — Where to create the project (default: current dir)
#   ErrorPrefix   — 4-6 char error code prefix (default: derived from name)
#                   e.g. "AICC" → error codes become AICC-B001
# ──────────────────────────────────────────────────────────────

set -e

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$FRAMEWORK_DIR/project-template"

# ── Args ──────────────────────────────────────────────────────
PROJECT_NAME="${1:-}"
OUTPUT_BASE="${2:-$(pwd)}"
ERROR_PREFIX="${3:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 <ProjectName> [output-directory] [ErrorPrefix]"
  echo "Example: $0 MyProduct ~/Projects MYP"
  exit 1
fi

# Derive error prefix from project name if not provided
# Take first 4 uppercase alphanumeric characters
if [ -z "$ERROR_PREFIX" ]; then
  ERROR_PREFIX=$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9' | cut -c1-4)
fi

TARGET="$OUTPUT_BASE/$PROJECT_NAME"

if [ -d "$TARGET" ]; then
  echo "❌ Directory already exists: $TARGET"
  exit 1
fi

# ── Copy template ──────────────────────────────────────────────
echo "🚀 Creating AI-First project: $PROJECT_NAME"
echo "   → $TARGET"
echo "   Error Code Prefix: $ERROR_PREFIX"
echo ""

cp -r "$TEMPLATE_DIR" "$TARGET"

# ── Replace placeholders ───────────────────────────────────────
echo "🔧 Replacing placeholders..."

# macOS uses BSD sed, Linux uses GNU sed — handle both
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

# Find all text files and replace all placeholders
while IFS= read -r -d '' file; do
  replace_in_file "$file" "\[專案名稱\]" "$PROJECT_NAME"
  replace_in_file "$file" "\[產品名稱\]" "$PROJECT_NAME"
  replace_in_file "$file" "\[PREFIX\]"   "$ERROR_PREFIX"
done < <(find "$TARGET" -type f \( \
  -name "*.md" -o \
  -name "*.html" -o \
  -name "*.yaml" -o \
  -name "*.yml" -o \
  -name "*.json" -o \
  -name "*.example" \
\) -print0)

echo "   ✅ Placeholders replaced (專案名稱 → $PROJECT_NAME, PREFIX → $ERROR_PREFIX)"

# ── Set up initial memory ──────────────────────────────────────
TODAY=$(date +%Y-%m-%d)
FW_VERSION=$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null || echo "2.3.0")

cat > "$TARGET/memory/last_task.md" << EOF
## $TODAY — Project Initialized

- **專案**: $PROJECT_NAME
- **錯誤碼前綴**: $ERROR_PREFIX（用於 \`10_Standards/API/Error_Code_Standard_v1.0.md\`）
- **完成**: 使用 AI-First Framework v$FW_VERSION 初始化專案
- **待續**:
  1. 完成 CLAUDE.md 產品概覽表格
  2. 更新 \`memory/product.md\` 填入技術棧
  3. 在 \`context-seeds/\` 各 SEED 替換 \`[佔位符]\`
  4. 確認 \`10_Standards/DB/enum_registry.yaml\` 的範例 ENUM 是否適用，不適用則清空
  5. 建立 \`.env\` 從 \`.env.example\` 複製（\`cp .env.example .env\`）
  6. 在 MASTER_INDEX.md 登記第一個 F-code，再執行 Pipeline: 需求訪談
EOF

# ── Add CODEOWNERS stub ────────────────────────────────────────
mkdir -p "$TARGET/.github"
cat > "$TARGET/.github/CODEOWNERS" << EOF
# CODEOWNERS — $PROJECT_NAME
# Gate 3 D16-D20 驗收要求此檔案存在
# 格式：<path-pattern> <@github-username or @team>

# 全域預設 Owner（至少一人）
*                   @project-owner

# 合規文件需雙人 Review
/04_Compliance/     @project-owner @security-reviewer

# 資料庫 Schema 需 DBA 參與
/contracts/         @dba-owner
/03_System_Design/  @architect-owner

# CI/CD 配置需 DevOps 參與
/.github/           @devops-owner
EOF

echo "   ✅ .github/CODEOWNERS created"

# ── Initialize git ─────────────────────────────────────────────
if command -v git &> /dev/null; then
  cd "$TARGET"
  git init -q
  git add .
  git commit -q -m "feat: initialize $PROJECT_NAME with AI-First Framework v$FW_VERSION"
  echo "   ✅ Git repository initialized"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "✅ Project created successfully!"
echo ""
echo "📁 Location     : $TARGET"
echo "🔖 Error Prefix : $ERROR_PREFIX (e.g. ${ERROR_PREFIX}-B001)"
echo ""
echo "📋 Next steps:"
echo ""
echo "   1. cd \"$TARGET\""
echo "   2. cp .env.example .env  (填入真實密鑰，禁止 commit)"
echo "   3. Open with Cowork or Claude Code"
echo "   4. Complete CLAUDE.md 產品概覽表格"
echo "   5. Update memory/product.md 技術棧"
echo "   6. Update 10_Standards/DB/enum_registry.yaml（清除範例 ENUM，填入專案 ENUM）"
echo "   7. Fill in TEAM.md — 分配團隊成員到各 Agent 角色"
echo "   8. Register first F-code in MASTER_INDEX.md"
echo "   9. Say: 執行 Pipeline: 需求訪談"
echo ""
echo "──────────────────────────────────────────────────────────"
