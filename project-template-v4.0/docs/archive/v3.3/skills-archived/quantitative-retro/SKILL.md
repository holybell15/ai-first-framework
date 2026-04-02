---
name: quantitative-retro
description: >
  量化回顧分析，用 git 統計產出數據驅動的 Retro 報告。

  遇到「做回顧」、「retrospective」、「retro」、「L1/L2/L3 回顧」、「Gate 通過後」、
  「專案完成後」或「出貨指標」時觸發。

  **為什麼？** 傳統回顧只有定性討論（「覺得這次還行」），缺乏數據支撐。
  量化指標讓團隊看到真實的出貨效率、品質趨勢、工作熱點，做出有依據的改善決策。

  靈感來源：gstack /retro — per-person breakdown、shipping streak、test health trends
---

# Quantitative Retro Skill：數據驅動回顧

## 觸發時機

| 時機 | 回顧層級 | 範圍 |
|------|---------|------|
| Gate 通過後 | L1 輕量 | 單一 Gate 的交付品質 |
| Feature 上線後（P06 完成） | L2 模組 | 整個 Feature 從 P01→P06 |
| Sprint / 季度結束 | L3 專案 | 跨 Feature 全局分析 |

---

## Step 1 — Git 統計自動收集

> 每次 Retro 自動執行以下 git 指令，產出原始數據。

### 1.1 基本統計

```bash
# 指定時間範圍的 commit 統計（替換日期）
git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --oneline | wc -l

# LOC 變化（新增/刪除）
git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --shortstat --pretty="" | \
  awk '{ins+=$1; del+=$2} END {print "新增:", ins, "刪除:", del, "淨變化:", ins-del}'

# 每人 commit 數
git shortlog -sn --after="YYYY-MM-DD" --before="YYYY-MM-DD"
```

### 1.2 Commit 類型分布

```bash
# Conventional Commits 類型統計
git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --oneline | \
  grep -oE "^[a-f0-9]+ (feat|fix|docs|test|refactor|chore|hotfix|style|perf)" | \
  awk '{print $2}' | sort | uniq -c | sort -rn
```

### 1.3 修改熱點分析（Hotspot）

```bash
# 最常被修改的檔案 Top 10
git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --name-only --pretty="" | \
  sort | uniq -c | sort -rn | head -20
```

### 1.4 測試健康度

```bash
# 測試相關 commit 佔比
TOTAL=$(git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --oneline | wc -l)
TESTS=$(git log --after="YYYY-MM-DD" --before="YYYY-MM-DD" --oneline | grep -ciE "test|spec|e2e" )
echo "測試 commit 佔比: $TESTS / $TOTAL"
```

---

## Step 2 — 量化指標計算

### 2.1 出貨指標面板

```
📊 Retro 量化指標 — [Feature/Sprint 名稱]
期間：YYYY-MM-DD → YYYY-MM-DD

┌─────────────────────────────────────────┐
│ 📦 出貨指標                              │
│   Commit 總數：          [N]             │
│   LOC 淨變化：           +[N] / -[N]     │
│   Feature Lead Time：    [N] 天          │
│   Shipping Streak：      [N] 天連續出貨   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ 🧪 品質指標                              │
│   測試 commit 佔比：     [N]%            │
│   Gate Return Rate：     [N]%            │
│   Bug Density：          [N] bugs/feature│
│   QA Health Score：      [N]/100         │
│   Scope Change 次數：    [N]             │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ 🔥 修改熱點 Top 5                        │
│   1. [檔案路徑]  ([N] 次修改)            │
│   2. [檔案路徑]  ([N] 次修改)            │
│   3. [檔案路徑]  ([N] 次修改)            │
│   4. [檔案路徑]  ([N] 次修改)            │
│   5. [檔案路徑]  ([N] 次修改)            │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ 📝 Commit 類型分布                       │
│   feat:     [N] ([%])                    │
│   fix:      [N] ([%])                    │
│   test:     [N] ([%])                    │
│   docs:     [N] ([%])                    │
│   refactor: [N] ([%])                    │
│   hotfix:   [N] ([%])                    │
│   other:    [N] ([%])                    │
└─────────────────────────────────────────┘
```

### 2.2 趨勢比較（L2/L3 層級）

```
📈 趨勢比較
                 上次        本次        變化
Lead Time:       12 天       9 天        ↓ -3 天 🟢
Gate Return:     25%         15%         ↓ -10% 🟢
Bug Density:     3.2         4.8         ↑ +1.6 🔴
Test Ratio:      18%         25%         ↑ +7%  🟢
Health Score:    78          85          ↑ +7   🟢
```

### 2.3 健康基準對照

| 指標 | 健康 🟢 | 待改善 🟡 | 警報 🔴 |
|------|---------|----------|---------|
| Feature Lead Time（M 規模） | ≤ 10 天 | 11-15 天 | > 15 天 |
| Gate Return Rate | ≤ 20% | 21-30% | > 30% |
| Bug Density | ≤ 5/feature | 6-10 | > 10 |
| Test Commit 佔比 | ≥ 20% | 10-19% | < 10% |
| QA Health Score | ≥ 90 | 70-89 | < 70 |

---

## Step 3 — 定性回顧（搭配數據）

> 數據是起點，不是終點。每個異常指標都需要根因討論。

### 回顧三問（每個層級都問）

1. **What went well?** — 哪些指標改善了？為什麼？能否制度化？
2. **What didn't go well?** — 哪些指標惡化了？根因是什麼？
3. **What will we change?** — 具體改善行動（≤ 3 項，附負責人和截止日）

### 熱點分析解讀

修改熱點 Top 5 的解讀策略：
- **同一檔案被改 > 10 次** → 可能需要重構拆分
- **測試檔案是熱點** → 好事！代表測試在跟進
- **config/env 檔案是熱點** → 環境管理可能有問題
- **spec/doc 檔案是熱點** → 可能需求不穩定

---

## Step 4 — 產出報告

### 報告位置

```
07_Retrospectives/F##-RETRO.md        （L2 模組回顧）
07_Retrospectives/Sprint-RETRO-N.md   （L3 Sprint 回顧）
```

### 報告結構

```markdown
# Retro 報告 — [名稱]
日期：YYYY-MM-DD | 層級：L[1/2/3] | 範圍：[Feature/Sprint]

## 量化指標面板
（Step 2 的完整面板貼入）

## 趨勢比較
（與上次 Retro 比較，僅 L2/L3）

## 定性回顧
### What went well?
### What didn't go well?
### What will we change?

## 改善行動追蹤
| # | 行動項目 | 負責人 | 截止日 | 狀態 |
|---|---------|--------|--------|------|

## 缺陷回寫記錄
（從 DL-01~04 彙整，標記回寫到哪個框架機制）
```

---

## 與現有框架整合

| 機制 | 整合方式 |
|------|---------|
| `retro` slash command | 觸發本 skill，自動執行 git 統計 |
| Gate 通過後 | gate-reviewer agent 完成後觸發 L1 |
| P06 完成後 | pipeline-orchestrator 觸發 L2 |
| CLAUDE.md KPI | 本 skill 產出的指標直接對應 Framework KPI 定義 |
| 缺陷回寫流程 | Step 3 的改善行動對應 CLAUDE.md 缺陷回寫機制 |
| Friction Log | 讀取 `memory/friction_log.md` 作為定性回顧輸入 |
| Skill Analytics | 讀取 `memory/analytics.jsonl` 計算 Skill 使用統計 |

---

## Friction Logging（框架摩擦點記錄）

> 靈感來源：gstack contributor mode — 被動收集框架改善建議。

### 機制

任何 Agent 在工作過程中遇到摩擦（流程不順、文件不清楚、skill 不好用），
可在交接摘要中附加一行 friction log：

```markdown
<!-- FRICTION: [skill/步驟] | [什麼卡住了] | [改善建議] -->
```

Pipeline-orchestrator 收到交接摘要時，自動提取 `<!-- FRICTION:` 行，
追加到 `memory/friction_log.md`。

### memory/friction_log.md 格式

```markdown
# Friction Log — 框架摩擦點記錄

> 被動收集，每次 Retro 時作為改善輸入。

| 日期 | Agent | Skill/步驟 | 摩擦描述 | 建議 |
|------|-------|-----------|---------|------|
| 2026-03-25 | Backend | info-ship Step 3 | 測試框架偵測失敗（用 bun test 不是 npm test）| 支援 bun test 偵測 |
| 2026-03-25 | QA | webapp-testing | 截圖比對在 dark mode 下永遠 fail | 加入 theme 參數 |
```

### Retro 整合

L2/L3 Retro 時，quantitative-retro 自動讀取 friction_log.md：

```
📋 Friction Log 摘要（本期 [N] 條）
  最常出現的摩擦點：
    1. [skill X] — [N] 次被回報
    2. [步驟 Y] — [N] 次被回報
  建議優先改善：[skill X]
```

---

## Skill Usage Analytics（使用統計）

> 靈感來源：gstack skill-usage.jsonl — 追蹤哪些 skill 被用最多、哪些失敗最多。

### 機制

每次 skill 被呼叫時，追加一行到 `memory/analytics.jsonl`：

```jsonl
{"ts":"2026-03-25T14:30:00Z","skill":"info-ship","agent":"Backend","feature":"F02","duration_s":180,"outcome":"success"}
{"ts":"2026-03-25T14:35:00Z","skill":"systematic-debugging","agent":"Frontend","feature":"F02","duration_s":600,"outcome":"blocked"}
{"ts":"2026-03-25T15:00:00Z","skill":"webapp-testing","agent":"QA","feature":"F02","duration_s":300,"outcome":"success"}
```

### 欄位定義

| 欄位 | 型別 | 說明 |
|------|------|------|
| `ts` | ISO 8601 | 呼叫時間 |
| `skill` | string | skill 名稱 |
| `agent` | string | 呼叫的 Agent |
| `feature` | string | F## 代碼 |
| `duration_s` | number | 執行秒數（估算） |
| `outcome` | string | `success` / `blocked` / `skipped` |

### Retro 整合

L3 Retro 時，quantitative-retro 讀取 analytics.jsonl 產出：

```
📊 Skill Usage 統計（本期）
  最常使用 Top 5：
    1. webapp-testing     — 23 次（成功 21, blocked 2）
    2. info-ship          — 12 次（成功 12）
    3. forced-thinking    — 45 次（成功 45）
    4. systematic-debugging — 8 次（成功 5, blocked 3）
    5. quality-gates      — 6 次（成功 5, blocked 1）

  失敗率最高：
    1. systematic-debugging — 37.5% blocked
    → 建議：檢查 Bug Pattern 資料庫是否需要擴充

  平均執行時間：
    1. info-ship — 3.2 min
    2. webapp-testing — 5.1 min
    3. quality-gates — 12.3 min
```

### 容量管理

- `analytics.jsonl` 超過 500 行 → 舊資料移至 `05_Archive/analytics_YYYY-MM.jsonl`
- `friction_log.md` 超過 100 行 → 已處理的條目移至 `05_Archive/`

---

## Per-Person Breakdown（團隊模式，L3 層級）

> 僅在 5+ 人團隊且 L3 回顧時使用。1-2 人模式跳過。

```
👤 Per-Person 統計
                  Commits   LOC+    LOC-    Tests   feat%   fix%
王小明（Backend）    45      +2,100  -800     12     60%     20%
李大華（Frontend）   38      +1,800  -500      8     55%     25%
張美麗（QA）         22       +900   -200     18     10%     70%
```

**使用原則**：
- 這是「理解工作分布」的工具，不是「評比績效」的工具
- 不公開排名、不做 LOC 競賽
- 關注異常：某人 fix% 過高 → 可能承擔了過多 debug 工作
