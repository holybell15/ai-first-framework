#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# install-skills.sh — 將 project-template/context-skills/ 內的
# framework skills 連結到 ~/.claude/skills/
#
# 用法:
#   bash scripts/install-skills.sh           # 安裝所有框架 skills
#   bash scripts/install-skills.sh --dry-run # 只顯示，不執行
# ─────────────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$REPO_DIR/project-template/context-skills"
DST_DIR="$HOME/.claude/skills"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Skills 由 project-template 管理，安裝到 ~/.claude/skills/
FRAMEWORK_SKILLS=(
  "slice-cycle"
  "forced-thinking"
  "destructive-guard"
  "info-canary"
  "info-doc-sync"
  "info-ship"
  "quantitative-retro"
  "execution-trace"
)

echo "╔══════════════════════════════════════════════════╗"
echo "║  AI-First Framework — Skills 安裝工具           ║"
if $DRY_RUN; then
echo "║  模式：DRY RUN（只顯示，不執行）                ║"
fi
echo "╚══════════════════════════════════════════════════╝"
echo ""

mkdir -p "$DST_DIR"

installed=0
skipped=0
failed=0

for skill in "${FRAMEWORK_SKILLS[@]}"; do
  src="$SRC_DIR/$skill"
  dst="$DST_DIR/$skill"

  if [ ! -d "$src" ]; then
    echo "  ⚠️  SKIP  $skill — 來源目錄不存在: $src"
    ((skipped++)) || true
    continue
  fi

  if [ -L "$dst" ]; then
    # 已是 symlink — 確認指向正確
    current_target="$(readlink "$dst")"
    if [ "$current_target" = "$src" ]; then
      echo "  ✅ OK    $skill — 已連結（正確）"
      ((skipped++)) || true
      continue
    else
      echo "  🔄 UPDATE $skill — 重新連結 ($current_target → $src)"
      if ! $DRY_RUN; then
        rm "$dst"
        ln -s "$src" "$dst"
      fi
      ((installed++)) || true
    fi
  elif [ -d "$dst" ]; then
    echo "  ⚠️  SKIP  $skill — 目標已存在且非 symlink（手動管理中，跳過）"
    ((skipped++)) || true
  else
    echo "  🔗 LINK  $skill"
    if ! $DRY_RUN; then
      ln -s "$src" "$dst"
    fi
    ((installed++)) || true
  fi
done

echo ""
echo "────────────────────────────────────────────────"
if $DRY_RUN; then
  echo "  DRY RUN 完成 — 以上為預覽，未實際執行"
else
  echo "  安裝完成：$installed 個連結 / $skipped 個跳過 / $failed 個失敗"
fi
echo "────────────────────────────────────────────────"
echo ""
echo "  安裝後可執行驗證："
echo "  python3 tools/workflow-test/run_tests.py"
