---
name: finishing-a-development-branch
description: >
  Use this skill when a feature is complete and ready to merge or submit for review. Trigger on:
  "功能做完了", "我完成了 F01", "準備合併", "這個 branch 做完了", "可以 merge 了嗎",
  "準備提 PR", "Gate 3 前要確認什麼". This is the checklist that prevents "I thought it was done"
  problems — missed tests, hardcoded secrets, STATE.md not updated. If someone says they're done
  with a feature, always run through this skill before proceeding.
source: obra/superpowers (adapted for AI-First workflow)
---

# Finishing a Development Branch Skill

## 為什麼要有標準收尾流程？

沒有 checklist 的「完成」不算完成。這個流程防止：
- 測試在主線上壞掉（你在 worktree 裡看到 pass，但沒跑全套）
- Hardcoded 密碼/key 被 merge 進去
- STATE.md 沒更新，下個 session 的人不知道現在在哪裡

---

## Step 1 — 測試驗證

```bash
./mvnw test && npm run test
cat .worktree-baseline    # 比較：現在的數字應該 >= 基準線
```

**未全過 → 不進 Step 2。修好再來。**

---

## Step 2 — 自我 Code Review

在請 Review Agent 審查前，先自己過一遍：

```
代碼品質
- [ ] 符合專案 coding style（縮排/命名/結構）
- [ ] 無 TODO/FIXME 殘留（或有明確 issue 追蹤）
- [ ] 函數/變數命名自我說明

安全
- [ ] 無 hardcoded 密碼、API key、token
- [ ] 無 console.log 或 print 含敏感資訊

業務邏輯
- [ ] 所有 AC 都有對應測試 + 實作
- [ ] 邊界條件有處理（null、空陣列、最大值）
- [ ] 多租戶 tenant_id 正確隔離（若適用）

API 合約
- [ ] API response 格式與 F##-API.md 規格一致
- [ ] 錯誤碼與 Spec 定義一致

TDD 證據
- [ ] 每個 AC 都有 DSV 聲明
```

---

## Step 3 — Bisectable Commit 整理（強制）

> 靈感來源：gstack bisectable history — 每個 commit 是單一邏輯變更，`git bisect` 才能用。

```bash
git log --oneline main..HEAD    # 確認 commit 清單合理
```

### Bisectable 規則

| 規則 | 說明 | 檢查 |
|------|------|------|
| 一個 commit = 一個邏輯變更 | 功能、修復、重構分開 commit | `git log --oneline` 每行描述獨立 |
| 不混合 refactor 和 feature | 重新命名和新功能分開 | diff 中不同時有 rename + 新增程式碼 |
| 每個 commit 可獨立編譯通過 | 不能有「一半完成」的 commit | 理論上任一 commit checkout 都能 build |
| Commit message 符合 Conventional Commits | `feat:` / `fix:` / `refactor:` / `test:` / `docs:` | 格式正確 |

### 整理指令

```bash
# 檢查是否有 wip/temp/fixup commit
git log --oneline main..HEAD | grep -iE "wip|temp|fixup|todo"

# 如有 → 考慮 interactive rebase squash（僅在提 PR 前）
# 如無 → Step 4
```

### QA Bug Fix Commit 規範

QA 階段每個 bug fix **必須**獨立 commit，格式：
```
fix(qa): TC-{ID} {一句話描述}

Root cause: {根因}
Regression: tests/{test-file}:{line}
Found by QA on {date}
```

---

## Step 4 — 決策

| 選項 | 適用情境 |
|------|---------|
| **Merge to main** | 小修改、已完整自我 review、無需第三方確認 |
| **Create PR / Review Request** | 需要 Review Agent 正式審查（Gate 流程）|
| **Keep branch** | 未完成，待續 |
| **Discard** | 實驗性質，結論是不做 |

---

## Step 5 — 執行 Merge 或 PR

```bash
# 直接 merge
git checkout main
git merge --no-ff feature/F01-login -m "feat: F01 用戶登入"
git worktree remove ../feature-F01-login

# 或建 PR
git push origin feature/F01-login
# → 由 requesting-code-review skill 接手
```

---

## Step 6 — 更新追蹤文件

完成後必須更新：

1. **TASKS.md** — 標記此任務完成，寫簡短交接摘要
2. **memory/STATE.md** — 更新 current_focus + next_action（§38）
3. **Dashboard** — 觸發 update-dashboard skill，新增 pipelineLog 記錄
