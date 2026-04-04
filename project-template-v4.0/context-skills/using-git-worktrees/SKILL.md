---
name: using-git-worktrees
description: >
  Use this skill at the start of every Build phase feature implementation, and whenever creating a new branch
  for isolated development. Trigger on: "我要開始做這個功能", "Build 開始了", "開一個 branch",
  "開始實作 F01", "新功能隔離開發", "我要做 hotfix". Worktrees prevent the common problem of
  accidentally working on the wrong branch, and let you switch between features without stashing.
  If the user is about to start implementing any feature in Build or creating a fix branch, proactively
  suggest using a worktree.
source: obra/superpowers (adapted for AI-First workflow)
---

# Using Git Worktrees Skill

## 前提條件

專案必須是 git repo。如果還不是，先執行：

```bash
git init && git add -A && git commit -m "chore: initial commit"
```

## 為什麼用 Worktree 而不是 checkout？

`git checkout feature-branch` 會切換當前工作目錄 — 危險且容易出錯。
Worktree 讓每個 feature 有**自己的目錄**：主線和 feature 同時存在，不互相干擾。

```
project/                          ← main branch（不動）
├── .worktrees/f01/               ← F01 worktree（你在這裡開發）
└── .worktrees/f02/               ← F02 worktree（另一個 session）
```

---

## 唯一工具：`parallel-feature.sh`

**所有 worktree 操作統一使用此腳本，禁止手動執行 `git worktree` 指令。**

```bash
# 建立（一般模式）
bash scripts/parallel-feature.sh start F03

# 建立（外部串接模式 — 啟用 5-Gate）
bash scripts/parallel-feature.sh start F02 integration

# 查看所有 Feature 狀態
bash scripts/parallel-feature.sh status

# 推送 feature branch 到 remote（備份 / 準備 PR）
bash scripts/parallel-feature.sh push F03

# 同步 main 最新進度到 feature branch（rebase）
bash scripts/parallel-feature.sh sync F03

# 完成 → merge 到 main → 清理
bash scripts/parallel-feature.sh merge F03

# 完成 → merge → 推送 main → 清理
bash scripts/parallel-feature.sh merge F03 --push

# 放棄 → 清理（不 merge）
bash scripts/parallel-feature.sh drop F02
```

### 在 Claude Code 內執行

有互動確認的指令加 `-y` 跳過確認：

```bash
bash scripts/parallel-feature.sh -y merge F03 --push
bash scripts/parallel-feature.sh -y drop F02
```

### 腳本自動處理

- 建立 `.worktrees/f##/` 目錄 + `track-a/f##` branch
- 設定 `.gates/F##/` gate 目錄
- 複製 `.env`、安裝 `npm install`
- `.gitignore` 自動加入 `.worktrees/`
- Merge 前檢查 gate 狀態、dirty flag、未 commit 變更

---

## Step 1 — 建立 Worktree

```bash
bash scripts/parallel-feature.sh start F03
```

腳本完成後，開新 Terminal：

```bash
cd .worktrees/f03 && claude
```

確認環境正確：

```bash
pwd                        # 應為 .worktrees/f03
git branch --show-current  # 應為 track-a/f03
```

---

## Step 2 — 開發（搭配 TDD）

```bash
# 每次開始前確認你在對的目錄
pwd && git branch --show-current
```

正常走 `test-driven-development` skill 的 RED→GREEN→REFACTOR。
定期 commit，保持 commit 粒度小。

---

## Step 3 — 完成（交給 finishing-a-development-branch）

開發完成後切換到 `finishing-a-development-branch` skill 走標準收尾流程。
最終 merge 使用：

```bash
bash scripts/parallel-feature.sh merge F03
```

---

## 管理指令

```bash
# 查看所有 worktree 狀態（含 gate、dirty flag）
bash scripts/parallel-feature.sh status

# 放棄某個 Feature
bash scripts/parallel-feature.sh drop F02
```

---

## Pipeline 對應

| 情境 | 指令 |
|------|------|
| Build Feature 實作 | `bash scripts/parallel-feature.sh start F##` |
| 外部串接 Feature | `bash scripts/parallel-feature.sh start F## integration` |
| Hotfix | `bash scripts/parallel-feature.sh start HOTFIX01` |
| 完成 merge | `bash scripts/parallel-feature.sh merge F##` |

---

## 並行規則

- 多個 Feature 同時 Build 時，**每個 Feature 必須在獨立 worktree 中開發**
- 原因：Hook 強制執行機制（`.tests-dirty`、`.gates/`）是目錄級的
- 單人單 Feature 開發也建議用 worktree（保持 main 乾淨）

---

## 並行衝突注意

多個 worktree 同時工作時，注意共享檔案衝突風險：

- `TASKS.md`
- `memory/STATE.md`
- `memory/decisions.md`

修改這些檔案前先 pull main 的最新版。
