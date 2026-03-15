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
