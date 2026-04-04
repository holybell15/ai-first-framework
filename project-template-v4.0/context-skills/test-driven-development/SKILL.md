---
name: test-driven-development
description: >
  Use this skill when writing any new feature, fixing a bug, or implementing any AC (Acceptance Criterion)
  during P04 실作開發. Also trigger when the user says "我要開始實作這個功能", "怎麼確保 code 正確",
  "先寫測試還是先寫程式", "幫我實作這個 API", "Backend 開始開發", "Frontend 實作元件".
  TDD prevents the all-too-common scenario of writing code that "seems to work" but breaks edge cases,
  regresses later, or doesn't actually satisfy the AC. Even if the user doesn't say "TDD" — if they're
  about to implement something, suggest this approach.
source: obra/superpowers (adapted for AI-First workflow)
---

# Test-Driven Development (TDD) Skill

## 為什麼先寫測試？

不是規矩，是保護機制。先寫測試讓你：
1. **確認你理解需求** — 測試通不過才發現需求根本沒想清楚
2. **有安全網重構** — REFACTOR 階段改 code 不怕壞掉，測試會告訴你
3. **產出 DSV 證據** — Gate 3 需要的稽核日誌，TDD 自然生成

## 核心原則
**絕不跳過任何步驟。每一步都必須看到對應的測試狀態。未見 RED 就進 GREEN，等於沒做 TDD。**

---

## 執行流程

### Phase 1 — RED（先寫一個失敗的測試）

根據 User Story 的某一條 AC，寫出**剛好一個**最小測試：

```
# 好的 RED 測試特徵：
✅ 只測一件事
✅ 名稱說明期望行為：test_create_ticket_returns_ticket_id
✅ 執行後看到 FAIL / RED（不是 Error）
✅ Error 訊息清楚說明缺少什麼
```

```bash
./mvnw test -Dtest=TicketServiceTest#shouldReturnTicketId
# 必須看到: FAILED — AssertionError 或 NoSuchMethodError
```

測試意外通過 → 測試沒寫對（可能在測試已存在的行為），重寫。

`Commit: test: [RED] add failing test for [AC-ID] — [描述]`

> 每次只寫一個測試。5 個 AC → 5 輪 RED/GREEN/REFACTOR。

---

### Phase 2 — GREEN（最少程式碼讓測試通過）

目標：讓測試從 RED 變 GREEN，**用最笨的方式就好**：

```java
// 允許 hardcode：
public String createTicket() {
    return "TICKET-001";  // 先讓測試通過，之後 REFACTOR
}
```

```bash
./mvnw test -Dtest=TicketServiceTest#shouldReturnTicketId
# 必須看到: PASSED / GREEN
```

失敗 → 修 implementation，**不改測試**（改測試等於改需求）。

`Commit: feat: [GREEN] implement [AC-ID] — [描述]`

> 不要過度設計。GREEN 的唯一目標是讓這一個測試通過。

---

### Phase 3 — REFACTOR（清理，不加功能）

現在有安全網了，清理 code：

```
移除重複 → 改善命名 → 提取方法 → 整理結構
```

```bash
./mvnw test    # 全部測試，不只這一個
# 必須全部 PASS。有測試壞掉 → 撤銷重構重來
```

`Commit: refactor: clean up [描述]`

> REFACTOR 時不加新功能。加新功能 = 下一個 RED 測試。

---

回到 Phase 1，下一個 AC。

---

## 測試檔案位置

```
後端: src/test/java/{domain}/...Test.java
前端: src/__tests__/{component}.spec.ts
E2E:  tests/e2e/{flow}.spec.ts
```

---

## DSV 聲明（每個 TDD cycle 後記錄）

```
DSV: TDD cycle for [AC-ID] [AC描述]
- RED:      [測試檔案路徑:行數]  — 測試名稱
- GREEN:    [實作檔案路徑:行數]  — 實作方式
- REFACTOR: [修改摘要]
- 測試結果: [X passed / Y total]
```

---

## GREEN 失敗 → Self-Healing Build（v4.1 強制）

**GREEN phase 測試失敗時，不要直接問人怎麼修。必須先走 self-healing-build 流程。**

```
GREEN phase → 跑測試 → ❌ 失敗
  ↓
  ⚠️ .healing-required 已由 test-on-change.sh 自動建立
  ↓
  強制觸發 self-healing-build skill：
    Attempt 1: Quick Fix（比對 Known Bug Pattern）
    Attempt 2: Root Cause（systematic-debugging Phase 1+2）
    Attempt 3: Alternative Strategy
  ↓
  ✅ 測試通過 → .healing-required 自動清除 → 回到 TDD 繼續
  ❌ 3 次都失敗 → 產出 Escalation Report → 升級給人
```

**禁止**：
- 跳過 self-healing 直接問人「這個怎麼修」
- 改測試讓它通過（除非 Attempt 3 確認測試本身有 bug）
- 在 .healing-required 存在時繼續寫新 code（Hook 會攔截）

---

## 常見錯誤 → 正確做法

| 錯誤 | 正確做法 |
|------|---------|
| 先寫 code 再補測試 | 先寫 RED 測試 |
| 一次寫 5 個測試再實作 | 一次只做一個 RED/GREEN/REFACTOR |
| GREEN 失敗時改測試 | 改 implementation，不動測試 |
| REFACTOR 時加新功能 | 加功能 = 新的 RED 測試 |
| 跳過 REFACTOR「之後再清」 | 三步缺一不可，現在清 |
| 只跑這個測試 | REFACTOR 後跑全套測試 |
