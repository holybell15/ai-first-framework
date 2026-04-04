---
name: finishing-a-development-branch
description: >
  Use this skill when a feature is complete and ready to merge or submit for review. Trigger on:
  "功能做完了", "我完成了 F01", "準備合併", "這個 branch 做完了", "可以 merge 了嗎",
  "準備提 PR", "Gate 前要確認什麼". This is the checklist that prevents "I thought it was done"
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
# 跑全套測試
./mvnw test && npm run test
```

**未全過 → 不進 Step 2。修好再來。**

---

## Step 2 — 回溯完整開發脈絡（commit/PR 上下文）

在寫 commit message 或 PR description 之前，先回溯整個開發過程：

```
必讀檔案（依序）：
1. .plan-history/INDEX.md          ← Plan 演變歷史（如果存在）
2. src/[feature-id]/findings.md    ← 過程觀察、決策依據、踩過的坑
3. src/[feature-id]/progress.md    ← Phase 摘要、測試結果
4. TASKS.md                        ← 任務狀態與交接摘要
```

**為什麼？** Context 壓縮後早期的嘗試、失敗、決策原因都會遺失。
如果只看最後的 diff，commit message 只會描述「改了什麼」，不會描述「為什麼這樣改」。

**Commit message 必須包含：**
- **What**: 改了什麼（從 diff 看）
- **Why**: 為什麼這樣改（從 findings.md 看）
- **Context**: 過程中嘗試過但放棄的方案（從 .plan-history 看）

**PR description 必須包含：**
- Summary: 功能摘要（從 progress.md Phase Log 整理）
- Key decisions: 關鍵決策及原因（從 findings.md Decisions Made 整理）
- Test plan: 測試覆蓋（從 progress.md Test Results 整理）

---

## Step 3 — 自我 Code Review

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
- [ ] API response 格式與 Tech Spec 規格一致
- [ ] 錯誤碼與 Spec 定義一致

TDD 證據
- [ ] 每個 AC 都有 DSV 聲明
```

---

## Step 4 — Bisectable Commit 整理（強制）

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
# 如無 → Step 5
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

## Step 5 — 決策

| 選項 | 適用情境 |
|------|---------|
| **Merge to main** | 小修改、已完整自我 review、無需第三方確認 |
| **Create PR / Review Request** | 需要 Review Agent 正式審查（Gate 流程）|
| **Keep branch** | 未完成，待續 |
| **Discard** | 實驗性質，結論是不做 |

---

## Step 6 — 執行 Merge 或 PR

**統一使用 `parallel-feature.sh`，不手動執行 git 指令。**
**在 Claude Code 內執行時加 `-y` 跳過互動確認。**

```bash
# 直接 merge（腳本會檢查 gate、dirty flag、未 commit 變更）
bash scripts/parallel-feature.sh -y merge F01

# merge 後同時推送 main 到 remote
bash scripts/parallel-feature.sh -y merge F01 --push

# 或建 PR（先 push feature branch，再由 requesting-code-review skill 接手）
bash scripts/parallel-feature.sh -y push F01
# → 由 requesting-code-review skill 接手

# 放棄
bash scripts/parallel-feature.sh -y drop F01
```

---

## Step 7 — 更新追蹤文件

完成後必須更新：

1. **TASKS.md** — 標記此任務完成，寫簡短交接摘要
2. **memory/STATE.md** — 更新 current_focus + next_action
3. **Dashboard** — 觸發 update-dashboard skill，新增 pipelineLog 記錄
