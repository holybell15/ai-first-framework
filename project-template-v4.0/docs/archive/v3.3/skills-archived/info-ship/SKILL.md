---
name: info-ship
description: >
  一鍵 Pre-Merge 自動化：測試 → Review → 版本號 → CHANGELOG → PR。

  遇到「功能做完了」、「準備 merge」、「ship it」、「info-ship」、「可以合併了嗎」、
  「提 PR」或 P04 完成後觸發。

  **為什麼？** 從「程式碼寫完」到「PR 建立」之間有 10 個手動步驟。
  這個 skill 把它們串成一條指令，不漏步、不忘事。

  靈感來源：gstack /ship — test + review + version bump + changelog + bisectable commits + PR

  **Pipeline 整合**：P04 最後一個 Agent 完成後，pipeline-orchestrator 自動觸發。
---

# info-ship Skill：一鍵 Pre-Merge 自動化

## 為什麼不只用 finishing-a-development-branch？

`finishing-a-development-branch` 是 checklist（你自己勾）。
`info-ship` 是 pipeline（自動執行每一步）。

差異：
- finishing = 「確認這些事做了」
- info-ship = 「自動做這些事 + 回報結果」

兩者搭配：先跑 info-ship 自動化步驟，有問題時 fallback 到 finishing checklist 手動處理。

---

## 執行流程（10 步）

### Step 1 — Pre-flight 環境檢查

```bash
# 確認在正確的 branch
git branch --show-current
# 確認 worktree 狀態乾淨（或提示 commit）
git status --porcelain
# 確認 base branch 是最新的
git fetch origin main && git log --oneline HEAD..origin/main | wc -l
```

**阻塞條件**：
- 有未 commit 的變更 → 提示 commit 或 stash
- base branch 有新 commit → 自動 merge（有衝突則停止）

### Step 2 — Diff 範圍分類（gstack-diff-scope）

```bash
# 分析本次變更的範圍
git diff --name-only main...HEAD
```

自動分類：

| 類別 | 匹配規則 | 影響 |
|------|---------|------|
| `FRONTEND` | `src/components/`, `*.vue`, `*.tsx`, `*.css` | 需要 UI Review |
| `BACKEND` | `src/api/`, `src/services/`, `*.java`, `*.ts`（非前端） | 需要 API Review |
| `DATABASE` | `*.sql`, `migration/`, `schema/` | 需要 DBA Review |
| `TESTS` | `tests/`, `*.test.*`, `*.spec.*` | 測試覆蓋率檢查 |
| `DOCS` | `*.md`, `02_Specifications/`, `03_System_Design/` | 輕量 Review |
| `CONFIG` | `*.json`, `*.yaml`, `*.env*`, `Dockerfile` | 安全掃描 |

**輸出**：`📋 本次變更：BACKEND(65%) + TESTS(25%) + DOCS(10%)`
→ 後續步驟根據分類智慧路由（純 DOCS 跳過測試、純 TESTS 跳過安全掃描）

### Step 3 — 測試執行

```bash
# 自動偵測測試框架
npm test 2>/dev/null || ./mvnw test 2>/dev/null || pytest 2>/dev/null

# 區分失敗來源
# 如果 main 也有同樣的失敗 → 標記 [PRE-EXISTING]，不阻塞
# 如果只有本 branch 失敗 → 標記 [IN-BRANCH]，阻塞
```

**阻塞條件**：有 `[IN-BRANCH]` 測試失敗 → 停止，修好再跑

### Step 4 — 測試覆蓋率審計

針對 diff 中的每個新/修改函數：
- 有對應測試 → ✅
- 無測試 → ⚠️ 列出，建議補充
- 核心路徑無測試 → 🔴 阻塞

### Step 5 — Pre-Landing Code Review

**Pass 1 — Critical（自動修復）**：
- formatting / lint 問題 → 自動修正 + commit
- 未使用的 import → 自動移除
- console.log / print 殘留 → 自動移除

**Pass 2 — Informational（回報但不阻塞）**：
- 命名建議
- 複雜度警告
- 潛在效能問題

**Pass 3 — Adversarial（diff > 500 行自動觸發）**：
- 假設挑戰
- 邊界案例探索
- 安全漏洞掃描

### Step 6 — TODOS.md 自動偵測

```bash
# 掃描 diff 中是否有 TODO 完成
git diff main...HEAD | grep -E "^\-.*TODO|^\-.*FIXME"
# → 自動標記為已完成
```

### Step 7 — 版本號決策

```
📊 版本號建議

目前版本：v1.2.3
本次變更：BACKEND(65%) + TESTS(25%) + DOCS(10%)

建議版本號：
  (A) v1.2.4 — PATCH（bug fix / 小改動）  ← 推薦
  (B) v1.3.0 — MINOR（新功能 / API 新增）
  (C) v2.0.0 — MAJOR（breaking change）

請選擇：
```

**自動判斷邏輯**：
- diff 含 `BREAKING CHANGE` → 建議 MAJOR
- diff 含新 API endpoint / 新功能 → 建議 MINOR
- 其餘 → 建議 PATCH

### Step 8 — CHANGELOG 自動生成

從 commit messages 自動生成 CHANGELOG 條目：

```markdown
## [v1.2.4] — 2026-03-25

### Added
- F02 來電彈屏功能（#PR-123）

### Fixed
- 修正 CRM 查詢逾時問題

### Changed
- API response 欄位重新命名（`caller_info` → `contact_info`）
```

**規則**：
- 用「使用者視角」的語言，不是 commit message 原文
- feat → Added, fix → Fixed, refactor → Changed
- 不含 chore/test/docs 類型（除非影響使用者）

### Step 9 — Bisectable Commit 整理

檢查 commit history：
- 每個 commit 是否是單一邏輯變更 → ✅
- 有 `wip`、`temp`、`fixup` commit → ⚠️ 建議 squash
- 所有 commit message 符合 Conventional Commits → ✅

### Step 10 — PR 建立

```bash
gh pr create \
  --title "feat(F02): 來電彈屏功能" \
  --body "$(cat <<'EOF'
## Summary
- 實作來電彈屏 Prototype + API + 前端元件
- Health Score: 85/100

## Review Readiness
- [x] 測試通過（12/12）
- [x] 覆蓋率審計完成
- [x] Pre-landing review 完成
- [ ] Adversarial review（diff > 500 行，已自動觸發）

## Test Plan
- 功能測試：TC-01~TC-08
- 回歸測試：無新失敗
- 截圖報告：08_Test_Reports/F02-QA-Report.html

## Files Changed
- BACKEND: 8 files (+420/-120)
- TESTS: 4 files (+280/-0)
- DOCS: 2 files (+40/-10)
EOF
)"
```

---

## Review Readiness Dashboard

每次 info-ship 完成後顯示：

```
╔══════════════════════════════════════════╗
║  📋 Review Readiness Dashboard          ║
╠══════════════════════════════════════════╣
║  Tests          ✅ 12/12 passed         ║
║  Coverage       ✅ 新增程式碼 85% 覆蓋   ║
║  Critical Fix   ✅ 3 issues auto-fixed   ║
║  Adversarial    ⏳ 進行中（diff 680 行）  ║
║  CHANGELOG      ✅ 已生成               ║
║  Version        ✅ v1.2.4 (PATCH)       ║
║  PR             ✅ #123 已建立           ║
╠══════════════════════════════════════════╣
║  📊 Diff Scope: BE 65% | TEST 25%      ║
║  ⏱️ 總耗時: 3m 42s                      ║
╚══════════════════════════════════════════╝
```

---

## Pipeline 整合

| 觸發時機 | 行為 |
|---------|------|
| P04 QA 完成後 | pipeline-orchestrator 自動提示：「P04 完成，執行 `/info-ship` 還是手動提 PR？」 |
| Gate 3 通過後 | 如果 PR 尚未建立，自動建議執行 |
| 手動觸發 | 任何時候說「info-ship」或「準備 merge」|

---

## 與 finishing-a-development-branch 的關係

```
info-ship 自動執行 10 步
  ↓ 任何步驟失敗
  ↓ fallback
finishing-a-development-branch 手動 checklist
  ↓ 修好問題
  ↓ 重跑
info-ship 從失敗步驟繼續
```
