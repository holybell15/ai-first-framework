---
name: using-git-worktrees
description: >
  Use this skill at the start of every P04 feature implementation, and whenever creating a new branch
  for isolated development. Trigger on: "我要開始做這個功能", "P04 開始了", "開一個 branch",
  "開始實作 F01", "新功能隔離開發", "我要做 hotfix". Worktrees prevent the common problem of
  accidentally working on the wrong branch, and let you switch between features without stashing.
  If the user is about to start implementing any feature in P04 or creating a fix branch, proactively
  suggest using a worktree.
source: obra/superpowers (adapted for AI-First workflow)
---

# Using Git Worktrees Skill

## 為什麼用 Worktree 而不是 checkout？

`git checkout feature-branch` 會切換當前工作目錄 — 危險且容易出錯。
Worktree 讓每個 feature 有**自己的目錄**：主線和 feature 同時存在，不互相干擾。

```
project/                    ← main branch（不動）
../feature-F01-login/       ← F01 worktree（你在這裡開發）
../feature-F02-ticket/      ← F02 worktree（另一個人或另一個 session）
```

---

## Step 1 — 建立 Worktree

```bash
# 命名格式: feature/{F碼}-{簡述} 或 fix/{BUG-ID}-{簡述}
git worktree add ../feature-F01-login feature/F01-login
git worktree list  # 確認已建立
```

```bash
cd ../feature-F01-login
git branch --show-current  # 必須看到 feature/F01-login
```

---

## Step 2 — 建立基準線（必做）

```bash
./mvnw test && npm run test   # 確認 main 的測試在此 branch 也能通過
echo "Baseline: X passed" > .worktree-baseline
```

**基準失敗 → 不開始開發。回 main 修好再開 worktree。**
（不能在壞掉的基礎上開發，否則 finishing 時無法區分哪些問題是你造成的）

---

## Step 3 — 開發（搭配 TDD）

```bash
# 每次開始前確認你在對的目錄
pwd && git branch --show-current
```

正常走 `test-driven-development` skill 的 RED→GREEN→REFACTOR。
定期 commit，保持 commit 粒度小。

---

## Step 4 — 完成（交給 finishing-a-development-branch）

開發完成後切換到 `finishing-a-development-branch` skill 走標準收尾流程。

---

## 管理指令

```bash
# 查看所有 worktrees
git worktree list

# 刪除已合併的 worktree
git worktree remove ../feature-F01-login

# 清理殭屍 worktree（目錄已刪但 git 還記得）
git worktree prune
```

---

## Pipeline 對應

| 情境 | Worktree 前綴 |
|------|-------------|
| P04 Feature 實作 | `feature/{F碼}-{名稱}` |
| Hotfix | `fix/{BUG-ID}-{描述}` |
| G4-ENG 修正後重提 | `fix/g4eng-{F碼}` |
| Gate 3 Block 修正 | `fix/gate3-{描述}` |

---

## Conductor 並行工作區（Lifecycle Hooks）

> 靈感來源：gstack conductor.json — 管理多個 Claude Code session 在不同 worktree 並行。
> 自動化 setup / archive lifecycle，減少手動操作。

### conductor.json 配置

在專案根目錄建立 `conductor.json`，定義 worktree lifecycle hook：

```json
{
  "version": "1.0",
  "description": "AI-First Framework 並行工作區配置",

  "hooks": {
    "setup": {
      "description": "Worktree 建立後自動執行",
      "commands": [
        "npm install --prefer-offline 2>/dev/null || true",
        "cp ../.env .env 2>/dev/null || true",
        "echo '✅ Worktree 環境已準備'"
      ]
    },
    "archive": {
      "description": "Worktree 完成後自動清理",
      "commands": [
        "git stash list | head -5",
        "echo '📦 正在歸檔 worktree...'",
        "git worktree remove --force . 2>/dev/null || echo '⚠️ 請手動清理'"
      ]
    }
  },

  "defaults": {
    "base_branch": "main",
    "worktree_root": "..",
    "auto_install": true,
    "auto_baseline": true
  },

  "parallel_rules": {
    "max_concurrent": 3,
    "conflict_detection": true,
    "shared_files_warning": [
      "TASKS.md",
      "memory/STATE.md",
      "memory/decisions.md",
      "MASTER_INDEX.md"
    ]
  }
}
```

### 自動化 Setup（Worktree 建立時）

建立 worktree 後自動執行 setup hook：

```bash
#!/usr/bin/env bash
# scripts/worktree-setup.sh — Worktree 建立後自動執行
set -euo pipefail

WORKTREE_PATH="$1"
FEATURE_NAME="$2"

echo "🔧 設定 Worktree 環境：$FEATURE_NAME"

cd "$WORKTREE_PATH"

# 1. 安裝依賴
if [ -f "package.json" ]; then
  npm install --prefer-offline 2>/dev/null || echo "⚠️ npm install 失敗，請手動執行"
fi

if [ -f "pom.xml" ]; then
  ./mvnw dependency:resolve -q 2>/dev/null || echo "⚠️ Maven resolve 失敗"
fi

# 2. 複製環境變數
MAIN_DIR=$(git worktree list | head -1 | awk '{print $1}')
if [ -f "$MAIN_DIR/.env" ]; then
  cp "$MAIN_DIR/.env" .env
  echo "✅ .env 已從 main worktree 複製"
fi

# 3. 建立基準線
echo "🧪 執行基準線測試..."
if npm test 2>/dev/null; then
  echo "✅ 基準線測試通過" > .worktree-baseline
else
  echo "⚠️ 基準線測試失敗 — 請先修復 main 的問題" > .worktree-baseline
fi

# 4. 記錄 worktree 資訊
cat > .worktree-info.json <<EOF
{
  "feature": "$FEATURE_NAME",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "base_branch": "$(git log --oneline -1 main 2>/dev/null | cut -d' ' -f1)",
  "baseline_status": "$(cat .worktree-baseline 2>/dev/null | head -1)"
}
EOF

echo "✅ Worktree 環境準備完成"
```

### 自動化 Archive（Worktree 完成時）

Feature merge 或 abandon 後執行：

```bash
#!/usr/bin/env bash
# scripts/worktree-archive.sh — Worktree 完成後清理
set -euo pipefail

WORKTREE_PATH="$1"
ACTION="${2:-merged}"  # merged / abandoned

echo "📦 歸檔 Worktree：$WORKTREE_PATH"

cd "$WORKTREE_PATH"

# 1. 檢查是否有未 commit 的變更
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️ 發現未 commit 的變更："
  git status --short
  echo ""
  echo "選項："
  echo "  (1) git stash 保存後繼續歸檔"
  echo "  (2) 取消歸檔"
  read -r choice
  if [ "$choice" = "1" ]; then
    git stash push -m "worktree-archive-$(date +%Y%m%d)"
  else
    echo "❌ 歸檔取消"
    exit 1
  fi
fi

# 2. 記錄歸檔資訊
FEATURE_NAME=$(cat .worktree-info.json 2>/dev/null | grep -o '"feature": "[^"]*"' | cut -d'"' -f4 || basename "$WORKTREE_PATH")
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | $ACTION | $FEATURE_NAME | $(git log --oneline -1)" >> \
  "$(git worktree list | head -1 | awk '{print $1}')/memory/worktree_log.md"

# 3. 回到 main worktree
MAIN_DIR=$(git worktree list | head -1 | awk '{print $1}')
cd "$MAIN_DIR"

# 4. 移除 worktree
git worktree remove "$WORKTREE_PATH" 2>/dev/null || \
  echo "⚠️ 無法自動移除，請手動執行：git worktree remove $WORKTREE_PATH"

# 5. 清理殭屍 worktree
git worktree prune

echo "✅ Worktree 歸檔完成"
```

### 並行衝突偵測

多個 worktree 同時工作時，自動偵測共享檔案衝突：

```bash
#!/usr/bin/env bash
# scripts/worktree-conflict-check.sh — 並行衝突偵測
SHARED_FILES=("TASKS.md" "memory/STATE.md" "memory/decisions.md" "MASTER_INDEX.md")

echo "🔍 檢查並行 worktree 衝突..."

for wt in $(git worktree list --porcelain | grep "^worktree " | sed 's/worktree //'); do
  for file in "${SHARED_FILES[@]}"; do
    if cd "$wt" && git diff --name-only 2>/dev/null | grep -q "$file"; then
      echo "⚠️ 衝突風險：$wt 修改了共享檔案 $file"
    fi
  done
done
```

### 快捷指令

```bash
# 建立 worktree + 自動 setup
git worktree add ../feature-F05-chat feature/F05-chat && \
  bash scripts/worktree-setup.sh ../feature-F05-chat F05-chat

# 歸檔 worktree（merge 後）
bash scripts/worktree-archive.sh ../feature-F05-chat merged

# 查看所有活躍 worktree
git worktree list

# 衝突偵測
bash scripts/worktree-conflict-check.sh
```
