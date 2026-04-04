---
name: parallel-feature
description: >
  一鍵建立 Feature 平行開發環境。自動處理 worktree 建立、gate 設定、環境複製。
  觸發詞: "parallel", "並行開發", "同時做兩個 Feature", "開 worktree",
  "平行啟動", "我要同時做 F02 和 F03"
user-invocable: true
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Parallel Feature Skill

## 簡介

多個 Feature 同時 Build 時，Hook 機制（`.tests-dirty`、`.gates/`）是目錄級的，
共用目錄會互相干擾。此 skill 用 git worktree 自動建立隔離環境。

**單 Feature 開發不需要此 skill。**

---

## 快速指令

所有操作統一使用 `parallel-feature.sh`：

```bash
# 建立（一般模式 — Build Grounding）
bash scripts/parallel-feature.sh start F03

# 建立（外部串接模式 — Integration 5-Gate）
bash scripts/parallel-feature.sh start F02 integration

# 查看所有 Feature 狀態
bash scripts/parallel-feature.sh status

# 推送 feature branch 到 remote（備份 / PR）
bash scripts/parallel-feature.sh push F03

# 同步 main 最新進度（rebase）
bash scripts/parallel-feature.sh sync F03

# 完成 → merge → 清理
bash scripts/parallel-feature.sh merge F03

# 完成 → merge → 推送 main → 清理
bash scripts/parallel-feature.sh merge F03 --push

# 放棄 → 清理
bash scripts/parallel-feature.sh drop F02
```

腳本會自動：
1. 建立 git worktree（`.worktrees/f##/`）
2. 建立對應 branch（`track-a/f##`）
3. 設定 `.gates/F##/` 目錄和模式
4. 複製 `.env` 等環境檔案
5. 安裝依賴
6. 輸出下一步指令

### 在 Claude Code 內執行

所有有互動確認的指令加 `-y` 跳過確認，讓 Claude Code 的 Bash 工具可以直接執行：

```bash
bash scripts/parallel-feature.sh -y merge F03 --push
bash scripts/parallel-feature.sh -y drop F02
```

不需要確認的指令（`start`、`status`、`sync`）直接執行即可。

---

## 完整流程範例

### 同時開發 F02（CTI 串接）和 F03（客戶資料）

**Step 1：在 main 目錄建立環境**

```bash
bash scripts/parallel-feature.sh start F02 integration
bash scripts/parallel-feature.sh start F03
```

**Step 2：開兩個 Terminal，各自啟動 Claude Code**

```bash
# Terminal 1
cd .worktrees/f02 && claude

# Terminal 2
cd .worktrees/f03 && claude
```

**Step 3：各自開發**

Terminal 1 的 AI 走 external-integration 5-Gate。
Terminal 2 的 AI 走 Build Grounding。
兩邊互不干擾。

**Step 4：完成後 merge**

```bash
# 先 merge 先完成的
bash scripts/parallel-feature.sh merge F03

# 再 merge 另一個（可能需要解衝突）
bash scripts/parallel-feature.sh merge F02
```

---

## Track 分配

腳本預設使用 `track-a`。多 Track 專案可在 `parallel-feature.sh` 的 `get_track()` 函數中自訂邏輯。

---

## 注意事項

| 情境 | 做法 |
|------|------|
| 只做一個 Feature | 不需要 worktree，直接在 main 開發 |
| 兩個 Feature 同時 Build | **必須**用此 skill 建立隔離環境 |
| 一個 Build + 一個 Discover/Plan | 不需要 worktree（Discover/Plan 不寫 code） |
| Merge 後開下一個 Feature | 從最新 main 建新 worktree |
| Merge 有衝突 | 在 main 解完衝突，讓 Review Agent 審查 |
