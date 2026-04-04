---
name: self-healing-build
description: >
  **AI 自動修復迴圈 — 測試失敗時 AI 自己分析、修復、重跑，3 次失敗才升級給人。**

  Triggered by: TDD GREEN phase 失敗、`npm test` / `./mvnw test` 回傳非零、Playwright 失敗、
  任何 Build 階段的測試不通過。當 test-driven-development skill 的 GREEN phase 失敗時自動接管。

  取代舊模式：AI 寫壞 → 人看 error → 人指導 → AI 修 → 人再看（每次失敗都需要人）
  新模式：AI 寫壞 → AI 自動分析 + 修復 → 連續 3 次失敗才升級（人只處理頑固問題）

source: AI-First Framework v4.1 — Autonomous Build Optimization
---

# Self-Healing Build Loop

## 為什麼需要這個？

F01-F08 的實戰數據顯示：**Build 階段 55-65% 的時間花在人工 debug 迴圈**。
根本原因不是「測試太多」，而是「每次測試失敗都需要人介入」。

Self-Healing Loop 讓 AI 在升級給人之前，先自己嘗試修復。

---

## 核心流程

```
┌─────────────────────────────────────────────────┐
│              Self-Healing Build Loop              │
│                                                   │
│  ① Generate Code（TDD GREEN phase）              │
│       ↓                                           │
│  ② Run Tests                                     │
│       ├── ✅ PASS → 繼續下一個 AC                │
│       └── ❌ FAIL → 進入 Self-Healing            │
│                ↓                                  │
│  ③ Attempt 1: Quick Fix                          │
│     - 讀 error message + stack trace             │
│     - 比對 Known Bug Patterns                    │
│     - 執行最小修復                               │
│     - 重跑測試                                   │
│       ├── ✅ PASS → 記錄 pattern → 繼續          │
│       └── ❌ FAIL ↓                              │
│                                                   │
│  ④ Attempt 2: Root Cause Analysis                │
│     - 觸發 systematic-debugging Phase 1+2        │
│     - 生成 ≤3 假設，逐一驗證                     │
│     - 找到根因後修復                             │
│     - 重跑測試                                   │
│       ├── ✅ PASS → 記錄 pattern → 繼續          │
│       └── ❌ FAIL ↓                              │
│                                                   │
│  ⑤ Attempt 3: Alternative Strategy              │
│     - 換一個實作策略（不同演算法/不同 API 用法） │
│     - 或退回檢查測試本身是否寫錯                 │
│     - 重跑測試                                   │
│       ├── ✅ PASS → 記錄 pattern → 繼續          │
│       └── ❌ FAIL ↓                              │
│                                                   │
│  ⑥ 🚨 ESCALATE to Human                         │
│     - 產出結構化升級報告                         │
│     - 鎖定修改範圍（Freeze Mode）                │
│     - 等待人工介入                               │
└─────────────────────────────────────────────────┘
```

---

## Attempt 1: Quick Fix（< 2 分鐘）

**目標**：解決「手指滑了」等級的問題 — typo、import 遺漏、型別不匹配。

### 執行步驟

1. **讀取完整 error output**（不要只看最後一行）
2. **比對 Known Bug Patterns**：

| Pattern | 簽名 | 自動修復 |
|---------|------|---------|
| `IMPORT-01` | `Cannot find module` / `未解析的引用` | 補 import |
| `TYPE-01` | `Type 'X' is not assignable to type 'Y'` | 修正型別 |
| `NULL-01` | `Cannot read property of null/undefined` | 加 null check 或修正資料流 |
| `SYNTAX-01` | `Unexpected token` / `SyntaxError` | 修正語法 |
| `API-01` | `404 Not Found` / `405 Method Not Allowed` | 修正 route path 或 method |
| `ASSERT-01` | `Expected X but received Y` | 檢查 X 和 Y 的差異，修正邏輯 |

3. **執行最小修復**（只改導致 error 的那一行或那個區塊）
4. **重跑失敗的測試**（不是全套，只跑失敗的那個）

### 判定

- ✅ 測試通過 → 記錄到 `healing-log.md` → 回到 TDD 流程
- ❌ 仍失敗 → 進入 Attempt 2

---

## Attempt 2: Root Cause Analysis（< 5 分鐘）

**目標**：問題不是 typo，需要理解根因。

### 執行步驟

1. **觸發 systematic-debugging skill 的 Phase 1**：
   - 精確描述 SYMPTOM vs EXPECTED vs ACTUAL
   - 收集環境資訊（Node 版本、DB 狀態、mock 設定）

2. **觸發 Phase 2**：
   - 列出 ≤3 假設（排序：最可能 → 最不可能）
   - 每個假設設計一個驗證測試
   - 依序驗證，找到根因即停

3. **根因修復**：
   - 只修根因，不重構周邊 code
   - 修復後重跑測試

4. **Sibling Check**（Phase 3c）：
   - 搜尋相同 pattern 是否在其他檔案出現
   - 一併修復

### 判定

- ✅ 測試通過 → 記錄根因到 `healing-log.md` + pattern library → 回到 TDD
- ❌ 仍失敗 → 進入 Attempt 3

---

## Attempt 3: Alternative Strategy（< 5 分鐘）

**目標**：前兩次都失敗，可能是實作方向錯誤或測試本身有問題。

### 執行步驟

1. **先檢查測試是否正確**：
   - 重讀 AC 原文
   - 測試的期望值是否真的符合 AC？
   - 測試的 setup/mock 是否正確反映 production path？

2. **如果測試正確 → 換實作策略**：
   - 回顧 Tech Spec，是否有替代實作方式
   - 檢查 pattern library 是否有類似功能的已驗證實作
   - 用不同的演算法或 API 重新實作

3. **如果測試有問題 → 修正測試**（僅限明確的測試 bug，不是降低標準）：
   - 記錄「測試修正原因」
   - 修正後重跑

### 判定

- ✅ 測試通過 → 記錄到 `healing-log.md` → 回到 TDD
- ❌ 仍失敗 → 升級給人

---

## Escalation Report（升級報告格式）

3 次嘗試都失敗後，產出以下報告：

```markdown
## 🚨 Self-Healing Escalation Report

**Feature**: [Feature ID] — [名稱]
**AC**: [AC-ID] — [描述]
**測試**: [測試檔案:行數] — [測試名稱]

### 症狀
[精確描述 error — SYMPTOM / EXPECTED / ACTUAL]

### 嘗試記錄

**Attempt 1 (Quick Fix)**:
- 判斷：[pattern ID 或「無匹配 pattern」]
- 修復：[做了什麼]
- 結果：[仍失敗，error 變成 X]

**Attempt 2 (Root Cause)**:
- H1: [假設] → [驗證結果]
- H2: [假設] → [驗證結果]
- H3: [假設] → [驗證結果]
- 根因判斷：[找到但修不了 / 三個都排除]

**Attempt 3 (Alternative)**:
- 測試檢查：[測試正確 / 測試有 bug（已修正但仍失敗）]
- 替代策略：[嘗試了什麼]
- 結果：[仍失敗，最終 error]

### 建議
[AI 的判斷：可能需要 Architect 介入 / 可能是 Tech Spec 設計問題 / 可能需要人工確認需求]

### 影響範圍
- 阻塞的後續 AC：[列表]
- 可以繼續的獨立 AC：[列表]
```

---

## Healing Log（自癒記錄）

每次成功自癒後，記錄到 `healing-log.md`（working directory）：

```markdown
| 時間 | Feature | AC | Attempt | Pattern | 根因 | 修復方式 |
|------|---------|-----|---------|---------|------|---------|
| 2026-04-05T10:30Z | F03 | AC-2 | 1 | IMPORT-01 | 缺少 import | 補 import |
| 2026-04-05T11:15Z | F03 | AC-5 | 2 | — | race condition | 加 await |
```

**Healing Log 的用途**：
- 累積 Known Bug Patterns（反饋到 Attempt 1 的 pattern 表）
- 識別重複出現的問題類型 → 改進 Tech Spec 或 code generation 策略
- Gate Review 時作為品質證據

---

## 與其他 Skill 的整合

| Skill | 整合方式 |
|-------|---------|
| `test-driven-development` | GREEN phase 失敗時自動觸發 self-healing-build |
| `systematic-debugging` | Attempt 2 調用 Phase 1+2 |
| `gate-check` | Healing Log 作為 Build Gate 的品質證據 |
| `pattern-library` | 成功修復的 pattern 回饋到 pattern library |
| `verification-before-completion` | 驗證所有 AC 都通過（含自癒的） |

---

## 設定參數

```yaml
# project-config.yaml
self_healing:
  max_attempts: 3                    # 最多嘗試次數
  attempt1_timeout_sec: 120          # Quick Fix 上限
  attempt2_timeout_sec: 300          # Root Cause 上限
  attempt3_timeout_sec: 300          # Alternative 上限
  auto_freeze_on_escalate: true      # 升級時自動鎖定
  log_file: "healing-log.md"         # 記錄檔
  pattern_feedback: true             # 成功修復自動回饋 pattern library
```

---

## 禁止事項

1. **不可降低測試標準來讓測試通過**（刪 assertion / 放寬 threshold）
2. **不可跳過 Attempt 直接升級**（每次都要走完該走的步驟）
3. **不可在 Attempt 3 之後繼續嘗試**（你已經證明你不了解問題）
4. **不可修改不相關的 code**（Attempt 的修復範圍限定在失敗的 AC 相關檔案）
5. **不可隱瞞失敗記錄**（所有 attempt 都要記錄在 healing-log.md）
