---
name: planning-with-tasks
description: >
  Track and record task progress across a feature's lifecycle using three persistent landing points:
  TASKS.md (status), findings.md (process observations), progress.md (phase summary).
  Distinct from writing-plans (plan decomposition before a task) — this skill is for During-task tracking.
  Trigger: any multi-step implementation task, specialist handoff, or feature build cycle.
user-invocable: true
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Planning with Tasks

> **Purpose**: During-task tracking & recording. Not plan decomposition.
> Use `writing-plans` before starting. Use this skill *while executing*.

---

## Core Concept: Three Landing Points

每個進行中的 feature 有三個固定的記錄位置：

| Landing Point | 位置 | 用途 | 更新時機 |
|---|---|---|---|
| **TASKS.md** | `TASKS.md`（專案根目錄） | Task 狀態追蹤 | 每次 Task 狀態變更 |
| **findings.md** | `src/[feature-id]/findings.md` | 過程觀察、發現、決策依據 | 每次有新發現 |
| **progress.md** | `src/[feature-id]/progress.md` | Phase 完成摘要、測試結果 | 每個 Phase 結束 |

---

## Path Convention（RR-1 Fixed）

### Feature 目錄結構

```
src/
└── [feature-id]/          ← 例如: src/F-001-auth/
    ├── findings.md        ← 過程觀察（本技能管理）
    ├── progress.md        ← Phase 摘要（本技能管理）
    └── [實作檔案...]
```

### Feature ID 格式

```
F-[三位數]-[簡短描述]
```

**範例：**
- `F-001-user-auth`
- `F-002-payment-gateway`
- `F-015-report-export`

### 路徑範例

```
src/F-001-user-auth/findings.md
src/F-001-user-auth/progress.md
```

> ⚠️ **不要** 把 findings.md / progress.md 放在專案根目錄。
> 根目錄只有 TASKS.md。每個 feature 有自己的子目錄。

---

## 啟動（Feature 開始時）

### Step 1：建立 feature 目錄

```bash
mkdir -p src/[feature-id]
```

### Step 2：初始化 findings.md

```markdown
# Findings — [feature-id]

**Feature**: [feature 描述]
**Started**: [YYYY-MM-DD]
**Specialist**: [角色名稱]

---

## Observations

<!-- 每次觀察/發現都加一條，格式如下 -->

### [YYYY-MM-DD HH:MM] [標題]
- **Context**: [發生什麼情況]
- **Finding**: [觀察到什麼]
- **Impact**: [對 feature 的影響]
- **Action**: [採取或建議的行動]

---

## DRIFT_SIGNAL Log

<!-- 如果有送出 DRIFT_SIGNAL，在此記錄 -->

| 時間 | 類型 | 摘要 | 結果 |
|------|------|------|------|
|      |      |      |      |

---

## Decisions Made

<!-- 本 feature 範圍內的技術決策 -->

| 決策 | 原因 | 日期 |
|------|------|------|
|      |      |      |
```

### Step 3：初始化 progress.md

```markdown
# Progress — [feature-id]

**Feature**: [feature 描述]
**Target**: [Gate / Milestone]
**Started**: [YYYY-MM-DD]

---

## Phase Log

| Phase | 描述 | 狀態 | 完成時間 | 備註 |
|-------|------|------|----------|------|
| P1    |      | 🔄   |          |      |
| P2    |      | ⏳   |          |      |

**狀態符號**: ✅ 完成 | 🔄 進行中 | ⏳ 待開始 | ❌ 失敗

---

## Test Results

| 測試類型 | 結果 | 時間 | 備註 |
|----------|------|------|------|
|          |      |      |      |

---

## Handoff Notes

<!-- 交接給下一個 Agent 時填寫 -->

**下一個角色**:
**交接摘要**:
**待確認事項**:
```

### Step 4：在 TASKS.md 標記 In Progress

```markdown
## In Progress

- [ ] [feature-id]: [feature 描述]
  - **Assigned**: [角色]
  - **Started**: [YYYY-MM-DD]
  - **Target Gate**: [Gate name]
  - **Files**: `src/[feature-id]/`
```

---

## 執行中規則

### 規則 1：2-Action Rule
> 每完成 2 個工具呼叫，把關鍵發現寫進 `findings.md`。

### 規則 2：Phase 完成後更新 progress.md
每個 Phase 結束立即更新：
```markdown
| P1 | 實作核心邏輯 | ✅ | 2025-01-15 14:30 | 無阻礙 |
```

### 規則 3：TASKS.md 狀態同步
Task 狀態只有三個值：`⏳ 待開始` → `🔄 進行中` → `✅ 完成`

不要讓 TASKS.md 與實際狀態落差超過 1 個 Phase。

### 規則 4：DRIFT 時先記錄再回報

發現 scope/design/test 偏移，先在 findings.md 記錄：
```markdown
### [時間] DRIFT 偵測
- **Context**: 原設計假設 X，但實際發現 Y
- **Finding**: 這會影響 [相關功能]
- **Impact**: 中/高 — 需要 Task-Master 決策
- **Action**: 送出 DRIFT_SIGNAL
```
然後再送 DRIFT_SIGNAL 給 Task-Master。

---

## 完成（Feature Done 時）

### Step 1：標記 TASKS.md

```markdown
## Completed

- [x] [feature-id]: [feature 描述]
  - **Completed**: [YYYY-MM-DD]
  - **Gate Passed**: [Gate name]
```

### Step 2：Archive feature 目錄

Feature 完成後，將整個目錄歸檔：

```bash
# 建立 archive 目錄
mkdir -p docs/archive/[feature-id]

# 移動 findings 和 progress（保留原始碼在 src/）
mv src/[feature-id]/findings.md docs/archive/[feature-id]/
mv src/[feature-id]/progress.md docs/archive/[feature-id]/
```

**Archive 目錄結構：**

```
docs/
└── archive/
    ├── F-001-user-auth/
    │   ├── findings.md    ← 過程觀察歸檔
    │   └── progress.md    ← Phase 摘要歸檔
    └── F-002-payment-gateway/
        ├── findings.md
        └── progress.md
```

### Step 3：在 archive 加入封存標記

在 `docs/archive/[feature-id]/findings.md` 頂部加入：

```markdown
> **[ARCHIVED]** Feature 完成日期：[YYYY-MM-DD] | Gate 通過：[Gate name]
> 此檔案為唯讀歷史記錄，不應再修改。
```

---

## 生命週期總覽

```
Feature 開始
    ↓
建立 src/[feature-id]/findings.md + progress.md
    ↓
執行中：持續更新兩個檔案
    ↓
Feature 完成（Gate 通過）
    ↓
Archive：mv → docs/archive/[feature-id]/
    ↓
src/[feature-id]/ 只留實作程式碼
```

---

## DRIFT_SIGNAL 格式（快速參考）

```
DRIFT_SIGNAL
TYPE: scope | design | test
SEVERITY: low | medium | high
FEATURE: [feature-id]
SUMMARY: [一句話說明偏移]
EVIDENCE: [findings.md 中的具體觀察]
RECOMMENDATION: [建議做法]
```

---

## Anti-Patterns

| ❌ 不要這樣 | ✅ 改這樣做 |
|---|---|
| 把 findings.md 放在根目錄 | 放在 `src/[feature-id]/findings.md` |
| feature 完成後不 archive | 執行 mv 到 `docs/archive/[feature-id]/` |
| 只更新 TASKS.md，不更新 progress.md | 兩個都要同步 |
| DRIFT 直接口頭回報 | 先記 findings.md，再送 DRIFT_SIGNAL |
| 一個 findings.md 跨多個 feature | 每個 feature 獨立目錄 |
