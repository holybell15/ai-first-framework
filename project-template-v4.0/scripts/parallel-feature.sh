#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# parallel-feature.sh — Feature 開發生命週期管理
# 所有 git 操作都封裝在此腳本中，使用者不需要碰 git 指令。
#
# Feature:
#   bash scripts/parallel-feature.sh start F07              ← 建立 Feature
#   bash scripts/parallel-feature.sh start F02 integration  ← 建立（串接模式）
#   bash scripts/parallel-feature.sh status                 ← 查看所有狀態
#   bash scripts/parallel-feature.sh push F07               ← 推送到 remote
#   bash scripts/parallel-feature.sh sync F07               ← 同步 develop 最新
#   bash scripts/parallel-feature.sh merge F07              ← merge → develop
#   bash scripts/parallel-feature.sh merge F07 --push       ← merge → develop + push
#   bash scripts/parallel-feature.sh drop F07               ← 放棄
#
# Release:
#   bash scripts/parallel-feature.sh release start v1.2     ← 從 develop 切 release
#   bash scripts/parallel-feature.sh release finish v1.2    ← → main + tag + 回寫 develop
#
# Hotfix:
#   bash scripts/parallel-feature.sh hotfix start bug-456   ← 從 main 切 hotfix
#   bash scripts/parallel-feature.sh hotfix finish bug-456  ← → main + develop + tag
#
# 全域 flag：
#   -y, --yes    跳過互動確認（CI / Claude Code 使用）
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ─── 解析全域 flag ───
AUTO_YES=false
ARGS=()
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
    *)        ARGS+=("$arg") ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

# 確認提示（AUTO_YES=true 時自動通過）
confirm_prompt() {
  local message="$1"
  if [ "$AUTO_YES" = true ]; then
    echo "${message} (自動確認 -y)"
    return 0
  fi
  echo "${message} (y/N)"
  read -r confirm
  [ "$confirm" = "y" ]
}

# 確認是 git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ 此目錄不是 git repo。請先執行："
  echo "   git init && git add -A && git commit -m 'chore: initial commit'"
  exit 1
fi

MAIN_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WORKTREES_ROOT="${MAIN_DIR}/.worktrees"

# ─── 分支偵測 ───
detect_main_branch() {
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    echo "master"
  else
    echo "main"
  fi
}

MAIN_BRANCH=$(detect_main_branch)
DEVELOP_BRANCH="develop"

# 確保 develop 分支存在
ensure_develop() {
  if ! git show-ref --verify --quiet "refs/heads/${DEVELOP_BRANCH}" 2>/dev/null; then
    echo "📁 建立 ${DEVELOP_BRANCH} 分支（從 ${MAIN_BRANCH}）..."
    git branch "${DEVELOP_BRANCH}" "${MAIN_BRANCH}"
    if has_remote; then
      git push -u origin "${DEVELOP_BRANCH}" 2>/dev/null || true
    fi
  fi
}

# 檢查是否有設定 remote
has_remote() {
  git remote | grep -q . 2>/dev/null
}

# ─── Track 配置 ───
get_track() {
  echo "track-a"
}

# ─── 工具函數 ───
feature_vars() {
  FEATURE_ID=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  FEATURE_LOWER=$(echo "$FEATURE_ID" | tr '[:upper:]' '[:lower:]')
  TRACK=$(get_track "$FEATURE_ID")
  BRANCH="${TRACK}/${FEATURE_LOWER}"
  WORKTREE_DIR="${WORKTREES_ROOT}/${FEATURE_LOWER}"
}

print_help() {
  cat <<'EOF'
Feature 開發生命週期管理

Feature:
  start <FXX> [integration]   建立開發環境（從 develop 分支）
  split <FXX>                 拆為 BE/FE 並行 worktree（v4.1）
  status                      查看所有 Feature / Release / Hotfix 狀態
  push  <FXX>                 推送 feature branch 到 remote
  sync  <FXX>                 同步 develop 最新進度（rebase）
  merge <FXX> [--push]        完成 → merge 到 develop → 清理
  merge-specialist <FXX> <backend|frontend>  merge 單邊 specialist（v4.1）
  drop  <FXX>                 放棄 → 清理

Release（每兩週）:
  release start <vX.Y>        從 develop 切出 release 分支
  release finish <vX.Y>       → main + tag + 回寫 develop + 清理

Hotfix（緊急）:
  hotfix start <name>         從 main 切出 hotfix 分支
  hotfix finish <name>        → main + develop + tag + 清理

全域 flag：
  -y, --yes                   跳過互動確認（CI / Claude Code 使用）

範例：
  bash scripts/parallel-feature.sh start F07
  bash scripts/parallel-feature.sh -y merge F07 --push
  bash scripts/parallel-feature.sh release start v1.2
  bash scripts/parallel-feature.sh -y release finish v1.2
  bash scripts/parallel-feature.sh hotfix start bug-456
  bash scripts/parallel-feature.sh -y hotfix finish bug-456
EOF
}

# ════════════════════════════════════════════════════════════
# 子命令：status
# ════════════════════════════════════════════════════════════
cmd_status() {
  echo ""
  echo "═══════════════════════════════════════"
  echo "  開發狀態總覽"
  echo "═══════════════════════════════════════"
  echo ""

  # remote 狀態
  if has_remote; then
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
    echo "  🌐 Remote: ${remote_url}"
  else
    echo "  📍 純本地（無 remote）"
  fi

  # 分支狀態
  echo ""
  echo "── 主要分支 ──"
  local main_hash=$(git rev-parse --short "${MAIN_BRANCH}" 2>/dev/null || echo "?")
  local dev_hash=$(git rev-parse --short "${DEVELOP_BRANCH}" 2>/dev/null || echo "?")
  echo "  🏷️  ${MAIN_BRANCH} (prod):  ${main_hash}"
  echo "  🔧 ${DEVELOP_BRANCH} (dev): ${dev_hash}"

  # develop 領先 main 多少
  if git show-ref --verify --quiet "refs/heads/${DEVELOP_BRANCH}" 2>/dev/null; then
    local dev_ahead=$(git rev-list --count "${MAIN_BRANCH}..${DEVELOP_BRANCH}" 2>/dev/null || echo "0")
    [ "$dev_ahead" -gt 0 ] && echo "     develop 領先 ${MAIN_BRANCH} ${dev_ahead} 個 commits"
  fi

  # Release 分支
  local release_branches=$(git branch --list "release/*" 2>/dev/null | tr -d ' *')
  if [ -n "$release_branches" ]; then
    echo ""
    echo "── Release ──"
    for rb in $release_branches; do
      local rh=$(git rev-parse --short "$rb" 2>/dev/null || echo "?")
      echo "  📦 ${rb} (${rh})"
    done
  fi

  # Hotfix 分支
  local hotfix_branches=$(git branch --list "hotfix/*" 2>/dev/null | tr -d ' *')
  if [ -n "$hotfix_branches" ]; then
    echo ""
    echo "── Hotfix ──"
    for hb in $hotfix_branches; do
      local hh=$(git rev-parse --short "$hb" 2>/dev/null || echo "?")
      echo "  🚑 ${hb} (${hh})"
    done
  fi

  echo ""

  # Feature worktrees
  local found=false
  if [ -d "$WORKTREES_ROOT" ]; then
    for wt_dir in "${WORKTREES_ROOT}"/*/; do
      [ -d "$wt_dir" ] || continue
      found=true

      if [ "$found" = true ] && [ "$(echo "$wt_dir" | grep -c '/')" -gt 0 ]; then
        # 只在第一個 feature 前印標題
        if [ "$(basename "$wt_dir")" = "$(ls "${WORKTREES_ROOT}" | head -1)" ]; then
          echo "── Feature Worktrees ──"
        fi
      fi

      local wt_name=$(basename "$wt_dir")
      local feature=$(echo "$wt_name" | tr '[:lower:]' '[:upper:]')
      local branch=$(cd "$wt_dir" && git branch --show-current 2>/dev/null || echo "?")
      local commits=$(cd "$MAIN_DIR" && git log --oneline "${DEVELOP_BRANCH}..${branch}" 2>/dev/null | wc -l | tr -d ' ')

      echo "  ── ${feature} ──"
      echo "    📂 ${wt_dir}"
      echo "    🌿 ${branch} (${commits} commits ahead of develop)"

      # remote 同步狀態
      if has_remote; then
        if git show-ref --verify --quiet "refs/remotes/origin/${branch}" 2>/dev/null; then
          local local_hash=$(cd "$wt_dir" && git rev-parse HEAD 2>/dev/null)
          local remote_hash=$(git rev-parse "origin/${branch}" 2>/dev/null || echo "")
          if [ "$local_hash" = "$remote_hash" ]; then
            echo "    🌐 Remote: 已同步"
          else
            local ahead=$(cd "$wt_dir" && git rev-list --count "origin/${branch}..HEAD" 2>/dev/null || echo "?")
            local behind=$(cd "$wt_dir" && git rev-list --count "HEAD..origin/${branch}" 2>/dev/null || echo "?")
            echo "    🌐 Remote: ↑${ahead} ↓${behind}"
          fi
        else
          echo "    🌐 Remote: 未推送"
        fi
      fi

      if [ -d "${wt_dir}/.gates" ]; then
        for gate_dir in "${wt_dir}"/.gates/*/; do
          [ -d "$gate_dir" ] || continue
          if [ -f "${gate_dir}/.integration" ]; then
            echo -n "    🔒 Integration Gate: "
            local g0="❌" g1="❌" g2="❌"
            [ -f "${gate_dir}/gate0-spec.confirmed" ] && g0="✅"
            [ -f "${gate_dir}/gate1-arch.confirmed" ] && g1="✅"
            [ -f "${gate_dir}/gate2-contract.confirmed" ] && g2="✅"
            echo "G0${g0} G1${g1} G2${g2}"
          else
            echo -n "    🔒 Build Grounding: "
            [ -f "${gate_dir}/build-grounded.confirmed" ] && echo "✅ confirmed" || echo "❌ not confirmed"
          fi
        done
      fi

      [ -f "${wt_dir}/.tests-dirty" ] && echo "    🔴 測試未跑" || echo "    ✅ 測試 clean"
      [ -f "${wt_dir}/.playwright-required" ] && echo "    🎭 Playwright 未跑"

      local dirty=$(cd "$wt_dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      [ "$dirty" -gt 0 ] && echo "    ⚠️  ${dirty} 個未 commit 的變更"

      echo ""
    done
  fi

  if [ "$found" = false ]; then
    echo "── Feature Worktrees ──"
    echo "  沒有進行中的 Feature worktree。"
    echo "  建立: bash scripts/parallel-feature.sh start F07"
    echo ""
  fi
}

# ════════════════════════════════════════════════════════════
# 子命令：start
# ════════════════════════════════════════════════════════════
cmd_start() {
  local fid="${1:-}"
  local mode="${2:-standard}"

  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID: bash scripts/parallel-feature.sh start F07"
    exit 1
  fi

  feature_vars "$fid"
  ensure_develop

  echo ""
  echo "🚀 建立開發環境：${FEATURE_ID}"
  echo ""

  if [ -d "$WORKTREE_DIR" ]; then
    echo "⚠️ 已存在: ${WORKTREE_DIR}"
    echo "   查看狀態: bash scripts/parallel-feature.sh status"
    echo "   重建需先: bash scripts/parallel-feature.sh drop ${FEATURE_ID}"
    exit 1
  fi

  # 確保 .worktrees 目錄存在 + gitignore
  mkdir -p "$WORKTREES_ROOT"
  if [ -f "${MAIN_DIR}/.gitignore" ]; then
    grep -qxF '.worktrees/' "${MAIN_DIR}/.gitignore" || echo '.worktrees/' >> "${MAIN_DIR}/.gitignore"
  else
    echo '.worktrees/' > "${MAIN_DIR}/.gitignore"
  fi

  cd "$MAIN_DIR"
  if has_remote; then
    echo "📡 同步 remote..."
    git fetch origin 2>/dev/null || true
    # 更新 develop
    git branch -f "${DEVELOP_BRANCH}" "origin/${DEVELOP_BRANCH}" 2>/dev/null || true
  fi

  # 從 develop 建立 worktree
  echo "📁 建立 worktree + branch（從 ${DEVELOP_BRANCH}）..."
  git worktree add "$WORKTREE_DIR" -b "$BRANCH" "${DEVELOP_BRANCH}" 2>/dev/null || \
    git worktree add "$WORKTREE_DIR" "$BRANCH"
  echo "   ✅ ${WORKTREE_DIR} → ${BRANCH}"

  cd "$WORKTREE_DIR"
  mkdir -p ".gates/${FEATURE_ID}"
  touch ".gates/${FEATURE_ID}/.enabled"

  if [ "$mode" = "integration" ]; then
    touch ".gates/${FEATURE_ID}/.integration"
    echo "   🔒 Gate: External Integration 模式"
  else
    echo "   🔒 Gate: Build Grounding 模式"
  fi

  [ -f "${MAIN_DIR}/.env" ] && cp "${MAIN_DIR}/.env" .env 2>/dev/null && echo "   📋 .env 已複製" || true

  if [ -f "package.json" ]; then
    echo "   📦 安裝依賴..."
    npm install --prefer-offline 2>/dev/null && echo "   ✅ npm install" || echo "   ⚠️ npm install 失敗"
  fi

  echo ""
  echo "════════════════════════════════════════════"
  echo "✅ ${FEATURE_ID} 開發環境就緒"
  echo "════════════════════════════════════════════"
  echo ""
  echo "下一步：開新 Terminal 執行"
  echo ""
  echo "  cd ${WORKTREE_DIR} && claude"
  echo ""
}

# ════════════════════════════════════════════════════════════
# 子命令：push
# ════════════════════════════════════════════════════════════
cmd_push() {
  local fid="${1:-}"
  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID: bash scripts/parallel-feature.sh push F07"
    exit 1
  fi

  feature_vars "$fid"

  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "❌ Worktree 不存在: ${WORKTREE_DIR}"
    exit 1
  fi

  if ! has_remote; then
    echo "❌ 沒有設定 remote。請先執行："
    echo "   git remote add origin <repo-url>"
    exit 1
  fi

  if cd "$WORKTREE_DIR" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "⚠️  有未 commit 的變更："
    git status --short
    echo ""
    if ! confirm_prompt "未 commit 的變更不會被推送。繼續？"; then
      echo "取消"
      exit 0
    fi
  fi

  cd "$WORKTREE_DIR"

  echo ""
  echo "📡 推送 ${FEATURE_ID} → origin/${BRANCH}"
  echo ""

  if git push -u origin "${BRANCH}" 2>&1; then
    echo ""
    echo "✅ 推送成功"

    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if echo "$remote_url" | grep -qE "github\.com|gitlab\.com|bitbucket\.org|dev\.azure\.com"; then
      echo ""
      echo "建立 PR："
      echo "  gh pr create --base ${DEVELOP_BRANCH} --head ${BRANCH}"
    fi
  else
    echo "❌ 推送失敗"
    exit 1
  fi

  echo ""
}

# ════════════════════════════════════════════════════════════
# 子命令：sync
# ════════════════════════════════════════════════════════════
cmd_sync() {
  local fid="${1:-}"
  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID: bash scripts/parallel-feature.sh sync F07"
    exit 1
  fi

  feature_vars "$fid"

  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "❌ Worktree 不存在: ${WORKTREE_DIR}"
    exit 1
  fi

  if cd "$WORKTREE_DIR" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "❌ 有未 commit 的變更，請先 commit 或 stash 後再 sync："
    git status --short
    exit 1
  fi

  echo ""
  echo "🔄 同步 ${DEVELOP_BRANCH} → ${FEATURE_ID}"
  echo ""

  cd "$MAIN_DIR"
  if has_remote; then
    echo "📡 拉取 remote 最新..."
    git fetch origin 2>/dev/null || true
    git branch -f "${DEVELOP_BRANCH}" "origin/${DEVELOP_BRANCH}" 2>/dev/null || true
  fi

  cd "$WORKTREE_DIR"

  local before_hash
  before_hash=$(git rev-parse HEAD)

  echo "🔀 Rebase onto ${DEVELOP_BRANCH}..."
  if git rebase "${DEVELOP_BRANCH}" 2>&1; then
    local after_hash
    after_hash=$(git rev-parse HEAD)
    if [ "$before_hash" = "$after_hash" ]; then
      echo ""
      echo "✅ 已是最新，無需同步"
    else
      local synced=$(git rev-list --count "${before_hash}..HEAD" 2>/dev/null || echo "?")
      echo ""
      echo "✅ 同步完成（納入 ${synced} 個來自 ${DEVELOP_BRANCH} 的 commits）"
    fi
  else
    echo ""
    echo "⚠️  Rebase 有衝突！"
    echo ""
    echo "選項："
    echo "  (1) 解完衝突後: git add <file> && git rebase --continue"
    echo "  (2) 放棄 rebase: git rebase --abort"
    exit 1
  fi

  echo ""
}

# ════════════════════════════════════════════════════════════
# 子命令：merge（→ develop）
# ════════════════════════════════════════════════════════════
cmd_merge() {
  local fid="${1:-}"
  local do_push=false

  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID: bash scripts/parallel-feature.sh merge F07"
    exit 1
  fi

  shift
  for arg in "$@"; do
    [ "$arg" = "--push" ] && do_push=true
  done

  feature_vars "$fid"
  ensure_develop

  echo ""
  echo "🔀 準備 Merge ${FEATURE_ID} → ${DEVELOP_BRANCH}"
  echo ""

  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "❌ Worktree 不存在: ${WORKTREE_DIR}"
    exit 1
  fi

  if cd "$WORKTREE_DIR" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "❌ 有未 commit 的變更："
    git status --short
    exit 1
  fi

  local gate_dir="${WORKTREE_DIR}/.gates/${FEATURE_ID}"
  if [ -d "$gate_dir" ]; then
    if [ -f "${gate_dir}/.integration" ]; then
      for gate in gate0-spec gate1-arch; do
        [ ! -f "${gate_dir}/${gate}.confirmed" ] && echo "❌ ${gate} 未通過" && exit 1
      done
      echo "  ✅ Integration Gate 通過"
    else
      [ ! -f "${gate_dir}/build-grounded.confirmed" ] && echo "❌ Build Grounding 未通過" && exit 1
      echo "  ✅ Build Grounding 通過"
    fi
  fi

  [ -f "${WORKTREE_DIR}/.tests-dirty" ] && echo "❌ 測試未跑" && exit 1
  echo "  ✅ 測試通過"
  [ -f "${WORKTREE_DIR}/.playwright-required" ] && echo "❌ Playwright 未跑" && exit 1

  # 同步 develop 最新
  cd "$MAIN_DIR"
  if has_remote; then
    echo "  📡 同步 remote..."
    git fetch origin 2>/dev/null || true
  fi

  # 切到 develop 做 merge（用 detached worktree 避免 checkout 衝突）
  local tmp_merge_dir="${WORKTREES_ROOT}/.merge-tmp"
  git worktree add "$tmp_merge_dir" "${DEVELOP_BRANCH}" 2>/dev/null || {
    # develop 可能被其他 worktree 佔用，嘗試直接在 main dir 操作
    rm -rf "$tmp_merge_dir" 2>/dev/null
    git worktree prune 2>/dev/null
    git worktree add "$tmp_merge_dir" "${DEVELOP_BRANCH}" 2>/dev/null || {
      echo "❌ 無法切換到 ${DEVELOP_BRANCH}，請確認沒有其他 worktree 佔用"
      exit 1
    }
  }

  cd "$tmp_merge_dir"

  if has_remote; then
    git pull --ff-only origin "${DEVELOP_BRANCH}" 2>/dev/null || true
  fi

  echo ""
  echo "── commits ──"
  git log --oneline "${DEVELOP_BRANCH}..${BRANCH}" 2>/dev/null || echo "(無)"
  echo ""

  local count=$(git log --oneline "${DEVELOP_BRANCH}..${BRANCH}" 2>/dev/null | wc -l | tr -d ' ')
  if ! confirm_prompt "共 ${count} 個 commits → ${DEVELOP_BRANCH}。確認？"; then
    cd "$MAIN_DIR"
    git worktree remove "$tmp_merge_dir" --force 2>/dev/null || true
    echo "取消"
    exit 0
  fi

  if git merge "${BRANCH}" --no-ff -m "feat(${FEATURE_LOWER}): merge ${FEATURE_ID} into ${DEVELOP_BRANCH}"; then
    echo "✅ Merge 成功"
  else
    echo "⚠️ 有衝突！在 ${tmp_merge_dir} 解完後 git add + git commit。"
    echo "   解完後手動清理: git worktree remove ${tmp_merge_dir}"
    exit 1
  fi

  # push develop
  if [ "$do_push" = true ] && has_remote; then
    echo "📡 推送 ${DEVELOP_BRANCH} → remote..."
    git push origin "${DEVELOP_BRANCH}" 2>&1 && echo "✅ 推送成功" || echo "⚠️ 推送失敗"
  fi

  # 清理 merge worktree
  cd "$MAIN_DIR"
  git worktree remove "$tmp_merge_dir" --force 2>/dev/null || true

  # 刪除 remote feature branch
  if has_remote && git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}" 2>/dev/null; then
    git push origin --delete "${BRANCH}" 2>/dev/null && echo "  🗑️  Remote feature branch 已刪除" || true
  fi

  # 刪除 feature worktree + branch
  git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
  git worktree prune
  git branch -d "$BRANCH" 2>/dev/null || true

  echo ""
  echo "✅ ${FEATURE_ID} 完成（merged into ${DEVELOP_BRANCH} + 已清理）"
  echo ""
}

# ════════════════════════════════════════════════════════════
# 子命令：drop
# ════════════════════════════════════════════════════════════
cmd_drop() {
  local fid="${1:-}"
  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID"
    exit 1
  fi

  feature_vars "$fid"

  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "❌ Worktree 不存在: ${WORKTREE_DIR}"
    exit 1
  fi

  local commits=$(cd "$MAIN_DIR" && git log --oneline "${DEVELOP_BRANCH}..${BRANCH}" 2>/dev/null | wc -l | tr -d ' ')
  if ! confirm_prompt "⚠️  放棄 ${FEATURE_ID}（${commits} commits 將丟棄）。確認？"; then
    echo "取消"
    exit 0
  fi

  cd "$MAIN_DIR"

  if has_remote && git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}" 2>/dev/null; then
    echo "🗑️  刪除 remote branch..."
    git push origin --delete "${BRANCH}" 2>/dev/null || true
  fi

  git worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
  git worktree prune
  git branch -D "$BRANCH" 2>/dev/null || true

  echo "✅ ${FEATURE_ID} 已清理"
}

# ════════════════════════════════════════════════════════════
# 子命令：release
# ════════════════════════════════════════════════════════════
cmd_release() {
  local subcmd="${1:-}"
  local version="${2:-}"

  if [ -z "$subcmd" ] || [ -z "$version" ]; then
    echo "用法："
    echo "  bash scripts/parallel-feature.sh release start v1.2"
    echo "  bash scripts/parallel-feature.sh release finish v1.2"
    exit 1
  fi

  local RELEASE_BRANCH="release/${version}"

  case "$subcmd" in
    start)
      ensure_develop
      echo ""
      echo "📦 建立 Release: ${version}"
      echo ""

      if git show-ref --verify --quiet "refs/heads/${RELEASE_BRANCH}" 2>/dev/null; then
        echo "⚠️ ${RELEASE_BRANCH} 已存在"
        exit 1
      fi

      cd "$MAIN_DIR"
      if has_remote; then
        echo "📡 同步 remote..."
        git fetch origin 2>/dev/null || true
      fi

      # 從 develop 切出 release branch（用 worktree）
      local release_dir="${WORKTREES_ROOT}/${version}"
      mkdir -p "$WORKTREES_ROOT"
      git worktree add "$release_dir" -b "$RELEASE_BRANCH" "${DEVELOP_BRANCH}" 2>/dev/null || {
        echo "❌ 建立 release worktree 失敗"
        exit 1
      }

      if has_remote; then
        cd "$release_dir"
        git push -u origin "${RELEASE_BRANCH}" 2>/dev/null || true
      fi

      echo ""
      echo "════════════════════════════════════════════"
      echo "✅ Release ${version} 就緒"
      echo "════════════════════════════════════════════"
      echo ""
      echo "  📂 ${release_dir}"
      echo "  🌿 ${RELEASE_BRANCH}"
      echo ""
      echo "在此分支上做 QA bug fix，完成後執行："
      echo "  bash scripts/parallel-feature.sh release finish ${version}"
      echo ""
      ;;

    finish)
      if ! git show-ref --verify --quiet "refs/heads/${RELEASE_BRANCH}" 2>/dev/null; then
        echo "❌ ${RELEASE_BRANCH} 不存在"
        exit 1
      fi

      echo ""
      echo "🚀 完成 Release: ${version}"
      echo ""

      local release_dir="${WORKTREES_ROOT}/${version}"

      # 檢查未 commit 變更
      if [ -d "$release_dir" ]; then
        if cd "$release_dir" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
          echo "❌ Release worktree 有未 commit 的變更"
          git status --short
          exit 1
        fi
      fi

      cd "$MAIN_DIR"

      local commits=$(git log --oneline "${MAIN_BRANCH}..${RELEASE_BRANCH}" 2>/dev/null | wc -l | tr -d ' ')
      if ! confirm_prompt "Release ${version}（${commits} commits）→ ${MAIN_BRANCH} + tag。確認？"; then
        echo "取消"
        exit 0
      fi

      # Merge release → main（用 temp worktree）
      local tmp_main="${WORKTREES_ROOT}/.release-main-tmp"
      git worktree add "$tmp_main" "${MAIN_BRANCH}" 2>/dev/null || {
        rm -rf "$tmp_main" 2>/dev/null; git worktree prune 2>/dev/null
        git worktree add "$tmp_main" "${MAIN_BRANCH}"
      }

      cd "$tmp_main"
      if git merge "${RELEASE_BRANCH}" --no-ff -m "release: ${version}"; then
        echo "✅ Release → ${MAIN_BRANCH} merge 成功"
        git tag -a "${version}" -m "Release ${version}" 2>/dev/null && echo "🏷️  Tag ${version} 已建立" || echo "⚠️ Tag 已存在"

        if has_remote; then
          echo "📡 推送 ${MAIN_BRANCH} + tag..."
          git push origin "${MAIN_BRANCH}" 2>&1 || true
          git push origin "${version}" 2>&1 || true
        fi
      else
        echo "⚠️ Merge 有衝突！在 ${tmp_main} 解完後 git add + git commit。"
        exit 1
      fi

      # 回寫 release → develop
      cd "$MAIN_DIR"
      git worktree remove "$tmp_main" --force 2>/dev/null || true

      local tmp_dev="${WORKTREES_ROOT}/.release-dev-tmp"
      git worktree add "$tmp_dev" "${DEVELOP_BRANCH}" 2>/dev/null || {
        rm -rf "$tmp_dev" 2>/dev/null; git worktree prune 2>/dev/null
        git worktree add "$tmp_dev" "${DEVELOP_BRANCH}"
      }

      cd "$tmp_dev"
      if git merge "${RELEASE_BRANCH}" --no-ff -m "merge: release ${version} back into ${DEVELOP_BRANCH}"; then
        echo "✅ Release → ${DEVELOP_BRANCH} 回寫成功"
        if has_remote; then
          git push origin "${DEVELOP_BRANCH}" 2>&1 || true
        fi
      else
        echo "⚠️ 回寫 develop 有衝突，請手動解決: cd ${tmp_dev}"
        exit 1
      fi

      # 清理
      cd "$MAIN_DIR"
      git worktree remove "$tmp_dev" --force 2>/dev/null || true
      [ -d "$release_dir" ] && git worktree remove "$release_dir" --force 2>/dev/null || true
      git worktree prune
      git branch -d "${RELEASE_BRANCH}" 2>/dev/null || true

      if has_remote; then
        git push origin --delete "${RELEASE_BRANCH}" 2>/dev/null || true
      fi

      echo ""
      echo "════════════════════════════════════════════"
      echo "✅ Release ${version} 完成"
      echo "════════════════════════════════════════════"
      echo "  ${MAIN_BRANCH}: merged + tagged ${version}"
      echo "  ${DEVELOP_BRANCH}: 已回寫"
      echo "  ${RELEASE_BRANCH}: 已清理"
      echo ""
      ;;

    *)
      echo "❌ 未知 release 子命令: ${subcmd}"
      echo "   用法: release start|finish <vX.Y>"
      exit 1
      ;;
  esac
}

# ════════════════════════════════════════════════════════════
# 子命令：hotfix
# ════════════════════════════════════════════════════════════
cmd_hotfix() {
  local subcmd="${1:-}"
  local name="${2:-}"

  if [ -z "$subcmd" ] || [ -z "$name" ]; then
    echo "用法："
    echo "  bash scripts/parallel-feature.sh hotfix start bug-456"
    echo "  bash scripts/parallel-feature.sh hotfix finish bug-456"
    exit 1
  fi

  local HOTFIX_BRANCH="hotfix/${name}"

  case "$subcmd" in
    start)
      echo ""
      echo "🚑 建立 Hotfix: ${name}"
      echo ""

      if git show-ref --verify --quiet "refs/heads/${HOTFIX_BRANCH}" 2>/dev/null; then
        echo "⚠️ ${HOTFIX_BRANCH} 已存在"
        exit 1
      fi

      cd "$MAIN_DIR"
      if has_remote; then
        echo "📡 同步 remote..."
        git fetch origin 2>/dev/null || true
      fi

      # 從 main 切出 hotfix（用 worktree）
      local hotfix_dir="${WORKTREES_ROOT}/${name}"
      mkdir -p "$WORKTREES_ROOT"
      git worktree add "$hotfix_dir" -b "$HOTFIX_BRANCH" "${MAIN_BRANCH}" 2>/dev/null || {
        echo "❌ 建立 hotfix worktree 失敗"
        exit 1
      }

      if has_remote; then
        cd "$hotfix_dir"
        git push -u origin "${HOTFIX_BRANCH}" 2>/dev/null || true
      fi

      # v4.1: 自動建立 Debug Grounding Gate
      cd "$hotfix_dir"
      local gate_id
      gate_id=$(echo "$name" | tr '[:lower:]' '[:upper:]')
      mkdir -p ".gates/HOTFIX-${gate_id}"
      touch ".gates/HOTFIX-${gate_id}/.enabled"
      touch ".gates/HOTFIX-${gate_id}/.debug"
      echo "   🔒 Debug Grounding Gate 已啟用"
      echo "      如果包含 UI bug → 額外執行:"
      echo "      touch ${hotfix_dir}/.gates/HOTFIX-${gate_id}/.ui-bug"

      echo ""
      echo "════════════════════════════════════════════"
      echo "✅ Hotfix ${name} 就緒"
      echo "════════════════════════════════════════════"
      echo ""
      echo "  📂 ${hotfix_dir}"
      echo "  🌿 ${HOTFIX_BRANCH}（從 ${MAIN_BRANCH} 切出）"
      echo "  🔒 Debug Gate: .gates/HOTFIX-${gate_id}/"
      echo ""
      echo "⚠️  改 code 前必須先收集證據："
      echo "  1. SSH 到 248 看 log"
      echo "  2. 列出根因假設"
      echo "  3. echo \"confirmed \$(date -u +%Y-%m-%dT%H:%M:%SZ)\" > .gates/HOTFIX-${gate_id}/debug-evidence.confirmed"
      echo ""
      echo "修完後執行："
      echo "  bash scripts/parallel-feature.sh hotfix finish ${name}"
      echo ""
      ;;

    finish)
      if ! git show-ref --verify --quiet "refs/heads/${HOTFIX_BRANCH}" 2>/dev/null; then
        echo "❌ ${HOTFIX_BRANCH} 不存在"
        exit 1
      fi

      echo ""
      echo "🚑 完成 Hotfix: ${name}"
      echo ""

      local hotfix_dir="${WORKTREES_ROOT}/${name}"

      if [ -d "$hotfix_dir" ]; then
        if cd "$hotfix_dir" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
          echo "❌ Hotfix worktree 有未 commit 的變更"
          git status --short
          exit 1
        fi
      fi

      cd "$MAIN_DIR"

      local commits=$(git log --oneline "${MAIN_BRANCH}..${HOTFIX_BRANCH}" 2>/dev/null | wc -l | tr -d ' ')
      if ! confirm_prompt "Hotfix ${name}（${commits} commits）→ ${MAIN_BRANCH} + ${DEVELOP_BRANCH}。確認？"; then
        echo "取消"
        exit 0
      fi

      # 自動產生 patch tag
      local latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
      local hotfix_tag="${latest_tag}.hotfix-${name}"

      # Merge hotfix → main
      local tmp_main="${WORKTREES_ROOT}/.hotfix-main-tmp"
      git worktree add "$tmp_main" "${MAIN_BRANCH}" 2>/dev/null || {
        rm -rf "$tmp_main" 2>/dev/null; git worktree prune 2>/dev/null
        git worktree add "$tmp_main" "${MAIN_BRANCH}"
      }

      cd "$tmp_main"
      if git merge "${HOTFIX_BRANCH}" --no-ff -m "hotfix: ${name}"; then
        echo "✅ Hotfix → ${MAIN_BRANCH} merge 成功"
        git tag -a "${hotfix_tag}" -m "Hotfix: ${name}" 2>/dev/null && echo "🏷️  Tag ${hotfix_tag}" || true

        if has_remote; then
          echo "📡 推送 ${MAIN_BRANCH} + tag..."
          git push origin "${MAIN_BRANCH}" 2>&1 || true
          git push origin "${hotfix_tag}" 2>&1 || true
        fi
      else
        echo "⚠️ Merge 有衝突！在 ${tmp_main} 解完。"
        exit 1
      fi

      # Merge hotfix → develop
      cd "$MAIN_DIR"
      git worktree remove "$tmp_main" --force 2>/dev/null || true

      local tmp_dev="${WORKTREES_ROOT}/.hotfix-dev-tmp"
      git worktree add "$tmp_dev" "${DEVELOP_BRANCH}" 2>/dev/null || {
        rm -rf "$tmp_dev" 2>/dev/null; git worktree prune 2>/dev/null
        git worktree add "$tmp_dev" "${DEVELOP_BRANCH}"
      }

      cd "$tmp_dev"
      if git merge "${HOTFIX_BRANCH}" --no-ff -m "merge: hotfix ${name} into ${DEVELOP_BRANCH}"; then
        echo "✅ Hotfix → ${DEVELOP_BRANCH} merge 成功"
        if has_remote; then
          git push origin "${DEVELOP_BRANCH}" 2>&1 || true
        fi
      else
        echo "⚠️ 回寫 develop 有衝突，請手動解決: cd ${tmp_dev}"
        exit 1
      fi

      # 清理
      cd "$MAIN_DIR"
      git worktree remove "$tmp_dev" --force 2>/dev/null || true
      [ -d "$hotfix_dir" ] && git worktree remove "$hotfix_dir" --force 2>/dev/null || true
      git worktree prune
      git branch -d "${HOTFIX_BRANCH}" 2>/dev/null || true

      if has_remote; then
        git push origin --delete "${HOTFIX_BRANCH}" 2>/dev/null || true
      fi

      echo ""
      echo "════════════════════════════════════════════"
      echo "✅ Hotfix ${name} 完成"
      echo "════════════════════════════════════════════"
      echo "  ${MAIN_BRANCH}: merged + tagged ${hotfix_tag}"
      echo "  ${DEVELOP_BRANCH}: 已回寫"
      echo "  ${HOTFIX_BRANCH}: 已清理"
      echo ""
      ;;

    *)
      echo "❌ 未知 hotfix 子命令: ${subcmd}"
      echo "   用法: hotfix start|finish <name>"
      exit 1
      ;;
  esac
}

# ════════════════════════════════════════════════════════════
# 子命令：split（v4.1 — Specialist 並行）
# 將一個 Feature ���為 backend + frontend 兩個 worktree
# ════════════════════════════════════════════════════════════
cmd_split() {
  local fid="${1:-}"

  if [ -z "$fid" ]; then
    echo "❌ 請指定 Feature ID: bash scripts/parallel-feature.sh split F03"
    exit 1
  fi

  feature_vars "$fid"
  ensure_develop

  local be_dir="${WORKTREES_ROOT}/${FEATURE_LOWER}-be"
  local fe_dir="${WORKTREES_ROOT}/${FEATURE_LOWER}-fe"
  local be_branch="${TRACK}/${FEATURE_LOWER}-be"
  local fe_branch="${TRACK}/${FEATURE_LOWER}-fe"
  local coord_dir="${MAIN_DIR}/.coordination/${FEATURE_LOWER}"

  # 檢查是否已存在整體 worktree
  if [ -d "$WORKTREE_DIR" ]; then
    echo "⚠️  已存在整體 worktree: ${WORKTREE_DIR}"
    echo "   split 與整體 worktree 互斥。"
    echo "   請先: bash scripts/parallel-feature.sh drop ${FEATURE_ID}"
    exit 1
  fi

  if [ -d "$be_dir" ] || [ -d "$fe_dir" ]; then
    echo "⚠️  已存在 specialist worktree:"
    [ -d "$be_dir" ] && echo "   Backend:  ${be_dir}"
    [ -d "$fe_dir" ] && echo "   Frontend: ${fe_dir}"
    exit 1
  fi

  echo ""
  echo "🔀 Split ${FEATURE_ID} → Backend + Frontend"
  echo ""

  mkdir -p "$WORKTREES_ROOT"
  if [ -f "${MAIN_DIR}/.gitignore" ]; then
    grep -qxF '.worktrees/' "${MAIN_DIR}/.gitignore" || echo '.worktrees/' >> "${MAIN_DIR}/.gitignore"
    grep -qxF '.coordination/' "${MAIN_DIR}/.gitignore" || echo '.coordination/' >> "${MAIN_DIR}/.gitignore"
  fi

  cd "$MAIN_DIR"
  if has_remote; then
    echo "📡 同步 remote..."
    git fetch origin 2>/dev/null || true
    git branch -f "${DEVELOP_BRANCH}" "origin/${DEVELOP_BRANCH}" 2>/dev/null || true
  fi

  # Backend worktree
  echo "📁 建立 Backend worktree..."
  git worktree add "$be_dir" -b "$be_branch" "${DEVELOP_BRANCH}" 2>/dev/null || \
    git worktree add "$be_dir" "$be_branch"
  cd "$be_dir"
  mkdir -p ".gates/${FEATURE_ID}" && touch ".gates/${FEATURE_ID}/.enabled"
  [ -f "${MAIN_DIR}/.env" ] && cp "${MAIN_DIR}/.env" .env 2>/dev/null || true
  [ -f "package.json" ] && npm install --prefer-offline 2>/dev/null || true
  echo "   ✅ ${be_dir} → ${be_branch}"

  # Frontend worktree
  cd "$MAIN_DIR"
  echo "📁 建立 Frontend worktree..."
  git worktree add "$fe_dir" -b "$fe_branch" "${DEVELOP_BRANCH}" 2>/dev/null || \
    git worktree add "$fe_dir" "$fe_branch"
  cd "$fe_dir"
  mkdir -p ".gates/${FEATURE_ID}" && touch ".gates/${FEATURE_ID}/.enabled"
  [ -f "${MAIN_DIR}/.env" ] && cp "${MAIN_DIR}/.env" .env 2>/dev/null || true
  [ -f "package.json" ] && npm install --prefer-offline 2>/dev/null || true
  echo "   ✅ ${fe_dir} → ${fe_branch}"

  # Coordination 目錄
  echo "📋 建立 coordination..."
  mkdir -p "$coord_dir"
  touch "${coord_dir}/signals.jsonl"

  cat > "${coord_dir}/sync-points.yaml" <<EOSYNC
# Sync Points — ${FEATURE_ID}
# Backend 完成 endpoint 後發 ENDPOINT_READY signal
endpoints: []
shared_types: []
EOSYNC

  cat > "${coord_dir}/ownership.yaml" <<EOOWN
feature: ${FEATURE_ID}
created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
backend:
  worktree: ${be_dir}
  write_allowed:
    - "src/main/java/**"
    - "src/test/java/**"
    - "src/backend/**"
    - "server/**"
    - "database/**"
  read_only:
    - "src/frontend/**"
    - "src/shared/**"
frontend:
  worktree: ${fe_dir}
  write_allowed:
    - "src/frontend/**"
    - "src/components/**"
    - "src/views/**"
    - "src/composables/**"
    - "src/stores/**"
    - "tests/e2e/**"
  read_only:
    - "src/main/java/**"
    - "src/shared/**"
shared:
  coordination_required:
    - "src/shared/**"
    - "contracts/**"
EOOWN

  echo "   ✅ coordination: ${coord_dir}"
  echo ""
  echo "════════════════════════════════════════════"
  echo "✅ ${FEATURE_ID} Specialist Split 完成"
  echo "════════════════════════════════════════════"
  echo ""
  echo "  Backend:  ${be_dir}"
  echo "  Frontend: ${fe_dir}"
  echo "  協調:     ${coord_dir}"
  echo ""
  echo "下一步：開兩個 Terminal"
  echo ""
  echo "  cd ${be_dir} && claude    # Backend Agent"
  echo "  cd ${fe_dir} && claude    # Frontend Agent"
  echo ""
}

# ════════════════════════════════════════════════════════════
# 子命令：merge-specialist（v4.1）
# merge 單邊 specialist worktree → develop
# ════════════════════════════════════════════════════════════
cmd_merge_specialist() {
  local fid="${1:-}"
  local side="${2:-}"

  if [ -z "$fid" ] || [ -z "$side" ]; then
    echo "❌ 用法: bash scripts/parallel-feature.sh merge-specialist F03 backend"
    exit 1
  fi

  if [ "$side" != "backend" ] && [ "$side" != "frontend" ]; then
    echo "❌ side 必須是 backend 或 frontend"
    exit 1
  fi

  feature_vars "$fid"
  ensure_develop

  local side_short
  [ "$side" = "backend" ] && side_short="be" || side_short="fe"
  local side_dir="${WORKTREES_ROOT}/${FEATURE_LOWER}-${side_short}"
  local side_branch="${TRACK}/${FEATURE_LOWER}-${side_short}"

  if [ ! -d "$side_dir" ]; then
    echo "❌ Worktree 不存在: ${side_dir}"
    exit 1
  fi

  echo ""
  echo "🔀 Merge ${FEATURE_ID}-${side_short} → ${DEVELOP_BRANCH}"
  echo ""

  if cd "$side_dir" && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "❌ 有未 commit 的變更："
    git status --short
    exit 1
  fi

  [ -f "${side_dir}/.tests-dirty" ] && echo "❌ 測試未跑" && exit 1
  echo "  ✅ 測試通過"

  cd "$MAIN_DIR"
  if has_remote; then
    git fetch origin 2>/dev/null || true
  fi

  local tmp_merge_dir="${WORKTREES_ROOT}/.merge-specialist-tmp"
  rm -rf "$tmp_merge_dir" 2>/dev/null
  git worktree prune 2>/dev/null
  git worktree add "$tmp_merge_dir" "${DEVELOP_BRANCH}" 2>/dev/null || {
    echo "❌ 無法切換到 ${DEVELOP_BRANCH}"
    exit 1
  }

  cd "$tmp_merge_dir"
  if has_remote; then
    git pull --ff-only origin "${DEVELOP_BRANCH}" 2>/dev/null || true
  fi

  echo ""
  echo "── ${side} commits ──"
  git log --oneline "${DEVELOP_BRANCH}..${side_branch}" 2>/dev/null || echo "(無)"
  echo ""

  if ! confirm_prompt "確認 merge ${FEATURE_ID}-${side_short} → ${DEVELOP_BRANCH}？"; then
    cd "$MAIN_DIR"
    git worktree remove "$tmp_merge_dir" --force 2>/dev/null
    git worktree prune
    echo "取消"
    exit 0
  fi

  if git merge --no-ff "${side_branch}" -m "merge: ${FEATURE_ID}-${side_short} → ${DEVELOP_BRANCH}" 2>&1; then
    echo ""
    echo "✅ Merge 成功"
  else
    echo ""
    echo "⚠️  Merge 有衝突！在此目錄解決："
    echo "   cd ${tmp_merge_dir}"
    echo "   解完: git add <file> && git commit"
    exit 1
  fi

  cd "$MAIN_DIR"
  git fetch . "${DEVELOP_BRANCH}:${DEVELOP_BRANCH}" 2>/dev/null || true

  git worktree remove "$tmp_merge_dir" --force 2>/dev/null
  git worktree prune

  if confirm_prompt "清理 ${side} worktree（${side_dir}）？"; then
    git worktree remove "$side_dir" --force 2>/dev/null
    git worktree prune
    git branch -d "$side_branch" 2>/dev/null || true
    echo "  ✅ ${side} worktree 已清理"
  fi

  # 記錄 signal
  local coord_dir="${MAIN_DIR}/.coordination/${FEATURE_LOWER}"
  if [ -d "$coord_dir" ]; then
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"from\":\"orchestrator\",\"type\":\"SPECIALIST_MERGED\",\"data\":{\"side\":\"${side}\"}}" >> "${coord_dir}/signals.jsonl"
  fi

  # 提示另一邊
  local other_short
  [ "$side_short" = "be" ] && other_short="fe" || other_short="be"
  local other_dir="${WORKTREES_ROOT}/${FEATURE_LOWER}-${other_short}"

  echo ""
  if [ -d "$other_dir" ]; then
    echo "📌 另一邊（${other_short}）尚未 merge："
    echo "   bash scripts/parallel-feature.sh merge-specialist ${FEATURE_ID} $([ "$other_short" = "be" ] && echo backend || echo frontend)"
  else
    echo "✅ 兩邊都已 merge → 跑整合測試"
  fi
  echo ""
}

# ════════════════════════════════════════════════════════════
# 主入口
# ════════════════════════════════════════════════════════════
CMD="${1:-}"

case "$CMD" in
  start)   shift; cmd_start "$@" ;;
  split)   shift; cmd_split "$@" ;;
  status)  cmd_status ;;
  push)    shift; cmd_push "$@" ;;
  sync)    shift; cmd_sync "$@" ;;
  merge)   shift; cmd_merge "$@" ;;
  merge-specialist) shift; cmd_merge_specialist "$@" ;;
  drop)    shift; cmd_drop "$@" ;;
  release) shift; cmd_release "$@" ;;
  hotfix)  shift; cmd_hotfix "$@" ;;
  --help|-h|help|"") print_help ;;
  *)       echo "❌ 未知命令: ${CMD}"; print_help; exit 1 ;;
esac
