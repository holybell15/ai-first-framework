#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# AI-First Framework — new-project.sh
# Usage: ./scripts/new-project.sh <ProjectName> [output-dir]
#
# Creates a new project folder from the project-template,
# replacing all [專案名稱] placeholders with the actual name.
# ──────────────────────────────────────────────────────────────

set -e

FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$FRAMEWORK_DIR/project-template"

# ── Args ──────────────────────────────────────────────────────
PROJECT_NAME="${1:-}"
OUTPUT_BASE="${2:-$(pwd)}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: $0 <ProjectName> [output-directory]"
  echo "Example: $0 MyProduct ~/Projects"
  exit 1
fi

TARGET="$OUTPUT_BASE/$PROJECT_NAME"

if [ -d "$TARGET" ]; then
  echo "❌ Directory already exists: $TARGET"
  exit 1
fi

# ── Copy template ──────────────────────────────────────────────
echo "🚀 Creating AI-First project: $PROJECT_NAME"
echo "   → $TARGET"
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

# Find all text files and replace placeholders
while IFS= read -r -d '' file; do
  replace_in_file "$file" "\[專案名稱\]" "$PROJECT_NAME"
  replace_in_file "$file" "\[產品名稱\]" "$PROJECT_NAME"
done < <(find "$TARGET" -type f \( -name "*.md" -o -name "*.html" -o -name "*.yaml" -o -name "*.json" \) -print0)

echo "   ✅ Placeholders replaced in all .md / .html files"

# ── Set up initial memory ──────────────────────────────────────
TODAY=$(date +%Y-%m-%d)

cat > "$TARGET/memory/last_task.md" << EOF
## $TODAY — Project Initialized
- **專案**: $PROJECT_NAME
- **完成**: 使用 AI-First Framework v$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null || echo "2.3.0") 初始化專案
- **待續**: 完成 CLAUDE.md 設定（替換佔位符），然後執行 Pipeline: 需求訪談
EOF

# ── Initialize git ─────────────────────────────────────────────
if command -v git &> /dev/null; then
  cd "$TARGET"
  git init -q
  git add .
  git commit -q -m "feat: initialize $PROJECT_NAME with AI-First Framework v$(cat "$FRAMEWORK_DIR/VERSION" 2>/dev/null || echo "2.3.0")"
  echo "   ✅ Git repository initialized"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "✅ Project created successfully!"
echo ""
echo "📁 Location:  $TARGET"
echo "📋 Next steps:"
echo ""
echo "   1. Open $TARGET with Cowork or Claude Code"
echo "   2. Complete CLAUDE.md setup (fill in Product Overview table)"
echo "   3. Update memory/product.md with your tech stack"
echo "   4. Say: 執行 Pipeline: 需求訪談"
echo ""
echo "──────────────────────────────────────────────────────────"
