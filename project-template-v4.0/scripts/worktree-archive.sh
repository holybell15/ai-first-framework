#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# worktree-archive.sh — Worktree 完成後清理與歸檔
# 用法：bash scripts/worktree-archive.sh <worktree-path> [merged|abandoned]
# ─────────────────────────────────────────────────────────────
set -euo pipefail

WORKTREE_PATH="${1:?用法: worktree-archive.sh <worktree-path> [merged|abandoned]}"
ACTION="${2:-merged}"
MAIN_DIR=$(git worktree list | head -1 | awk '{print $1}')

echo "📦 歸檔 Worktree：$WORKTREE_PATH（$ACTION）"

# 1. 檢查是否有未 commit 的變更
if cd "$WORKTREE_PATH" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo ""
  echo "⚠️ 發現未 commit 的變更："
  git status --short
  echo ""
  echo "自動 stash 保存..."
  git stash push -m "worktree-archive-$(date +%Y%m%d)" 2>/dev/null || true
fi

# 2. 記錄歸檔資訊
FEATURE_NAME="unknown"
if [ -f "$WORKTREE_PATH/.worktree-info.json" ]; then
  FEATURE_NAME=$(grep -o '"feature": "[^"]*"' "$WORKTREE_PATH/.worktree-info.json" | cut -d'"' -f4 || basename "$WORKTREE_PATH")
fi

LAST_COMMIT=$(cd "$WORKTREE_PATH" && git log --oneline -1 2>/dev/null || echo "N/A")

# 寫入歸檔日誌
ARCHIVE_LOG="$MAIN_DIR/memory/worktree_log.md"
if [ ! -f "$ARCHIVE_LOG" ]; then
  cat > "$ARCHIVE_LOG" <<'HEADER'
# Worktree 歸檔日誌

| 時間 | 動作 | Feature | 最後 Commit |
|------|------|---------|------------|
HEADER
fi

echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | $ACTION | $FEATURE_NAME | $LAST_COMMIT |" >> "$ARCHIVE_LOG"

# 3. 回到 main worktree 並移除
cd "$MAIN_DIR"
git worktree remove "$WORKTREE_PATH" 2>/dev/null || \
  echo "⚠️ 無法自動移除，請手動執行：git worktree remove $WORKTREE_PATH"

# 4. 清理殭屍 worktree
git worktree prune 2>/dev/null

echo "✅ Worktree 歸檔完成（$ACTION）"
