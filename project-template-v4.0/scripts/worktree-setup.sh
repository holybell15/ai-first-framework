#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# worktree-setup.sh — Worktree 建立後自動 setup
# 用法：bash scripts/worktree-setup.sh <worktree-path> <feature-name>
# ─────────────────────────────────────────────────────────────
set -euo pipefail

WORKTREE_PATH="${1:?用法: worktree-setup.sh <worktree-path> <feature-name>}"
FEATURE_NAME="${2:?用法: worktree-setup.sh <worktree-path> <feature-name>}"
MAIN_DIR=$(git worktree list | head -1 | awk '{print $1}')

echo "🔧 設定 Worktree 環境：$FEATURE_NAME"
echo "   路徑：$WORKTREE_PATH"
echo "   主線：$MAIN_DIR"
echo ""

cd "$WORKTREE_PATH"

# 1. 安裝依賴（靜默模式）
if [ -f "package.json" ]; then
  echo "📦 安裝 npm 依賴..."
  npm install --prefer-offline 2>/dev/null && echo "  ✅ npm install 完成" || echo "  ⚠️ npm install 失敗，請手動執行"
fi

if [ -f "pom.xml" ]; then
  echo "📦 解析 Maven 依賴..."
  ./mvnw dependency:resolve -q 2>/dev/null && echo "  ✅ Maven resolve 完成" || echo "  ⚠️ Maven resolve 失敗"
fi

# 2. 複製環境變數
if [ -f "$MAIN_DIR/.env" ]; then
  cp "$MAIN_DIR/.env" .env
  echo "✅ .env 已從 main worktree 複製"
fi

# 3. 記錄 worktree 資訊
cat > .worktree-info.json <<EOF
{
  "feature": "$FEATURE_NAME",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "base_commit": "$(git log --oneline -1 HEAD | cut -d' ' -f1)",
  "main_branch": "main"
}
EOF

echo ""
echo "✅ Worktree 環境準備完成"
echo "   cd $WORKTREE_PATH && git branch --show-current"
