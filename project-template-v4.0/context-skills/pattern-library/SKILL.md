---
name: pattern-library
description: >
  **已驗證的 Code Pattern 管理 — 存取、複用、累積。**

  Triggered by: Build 階段開始實作前（查詢已有 pattern）、TDD cycle 通過後（回饋新 pattern）、
  self-healing-build 成功修復後（記錄修復 pattern）、「有沒有類似的實作可以參考」、「這個功能之前做過嗎」。

  解決問題：每個 Feature 都從零生成 code，沒有累積可複用的「已驗證模式」，
  導致相同類型的功能每次都要重新 debug。

source: AI-First Framework v4.1 — Autonomous Build Optimization
---

# Code Pattern Library

## 為什麼需要 Pattern Library？

F01-F08 經驗：**相似功能（CRUD、搜尋、權限檢查）每次都從零生成，每次都踩相同的坑。**

Pattern Library 不是文件庫，是**已通過測試的、可直接複用的 code 片段 + 使用說明**。

---

## Pattern 目錄結構

```
verified-patterns/
├── README.md                          ← 索引 + 使用說明
├── backend/
│   ├── crud-standard.md               ← 標準 CRUD（Controller + Service + Repo）
│   ├── search-with-pagination.md      ← 分頁搜尋
│   ├── auth-rbac-guard.md             ← RBAC 權限檢查
│   ├── file-upload.md                 ← 檔案上傳
│   ├── event-publish.md               ← 事件發佈
│   └── multi-tenant-query.md          ← 多租戶查詢隔離
├── frontend/
│   ├── form-with-validation.md        ← 表單 + 驗證
│   ├── data-table.md                  ← 資料表格（排序 + 分頁 + 篩選）
│   ├── modal-confirm.md               ← Modal 確認對話框
│   ├── composable-api-call.md         ← API 呼叫 composable
│   └── permission-guard.md            ← 前端權限守衛
├── testing/
│   ├── api-integration-test.md        ← API 整合測試模板
│   ├── playwright-page-object.md      ← Playwright Page Object
│   └── mock-external-service.md       ← 外部服務 Mock
└── healing/
    └── common-fixes.md                ← 自癒迴圈累積的常見修復
```

---

## Pattern 格式

每個 pattern 檔案的固定結構：

```markdown
# Pattern: [名稱]

> 狀態：✅ Verified | 來源：F[XX] | 最後驗證：[日期]
> 適用：[技術棧，例如 Spring Boot + Vue 3]

## 何時使用

[1-2 句話描述適用場景]

## 前置條件

- [依賴的 library / 設定 / 共用元件]

## Code（可直接複製修改）

### [層級 1，例如 Controller]

```java
// 📋 複製後需修改的部分用 [PLACEHOLDER] 標記
@RestController
@RequestMapping("/api/v1/[RESOURCE]")
public class [Resource]Controller {
    // ...
}
```

### [層級 2，例如 Service]

```java
// ...
```

### [層級 3，例如 Test]

```java
// 對應的測試也一起提供
@Test
void should[Action]() {
    // ...
}
```

## 使用步驟

1. 複製 code 到對應目錄
2. 將 [PLACEHOLDER] 替換為實際值
3. 跑測試確認

## 已知陷阱

| 陷阱 | 解法 |
|------|------|
| [從 self-healing 累積的常見問題] | [修復方式] |

## 變更歷史

| 日期 | Feature | 變更 |
|------|---------|------|
| [日期] | F[XX] | 初版 |
| [日期] | F[YY] | 加入 [改進] |
```

---

## 使用流程

### Build 開始前 — 查詢 Pattern

```
TDD RED phase 開始前
  ↓
讀取 Tech Spec 的 AC
  ↓
比對 pattern library：這個 AC 的實作類型有沒有已驗證的 pattern？
  ├── ✅ 有 → 複製 pattern，替換 placeholder，進入 GREEN phase
  └── ❌ 沒有 → 從零實作（正常 TDD 流程）
```

### Build 完成後 — 回饋 Pattern

```
TDD cycle 全部通過
  ↓
判斷：這次實作中有沒有可複用的模式？
  ├── ✅ 有 → 抽取 pattern → 加入 verified-patterns/
  └── ❌ 沒有（太特殊）→ 不做
```

### Self-Healing 成功後 — 累積修復知識

```
self-healing-build 成功修復
  ↓
修復的根因是通用的嗎？
  ├── ✅ 是（例如「多租戶查詢忘記加 tenant_id」）
  │   → 更新對應 pattern 的「已知陷阱」
  │   → 更新 healing/common-fixes.md
  └── ❌ 否（例如「這個 API 的 response 格式特殊」）
      → 只記在 healing-log.md
```

---

## Pattern 品質規則

| 規則 | 說明 |
|------|------|
| **必須附帶測試** | 沒有測試的 pattern 不入庫 |
| **必須有來源 Feature** | 標記是從哪個 Feature 驗證過的 |
| **Placeholder 明確標記** | 用 `[PLACEHOLDER]` 格式，不能有 hardcode 的業務值 |
| **一個 pattern 一個職責** | 不要把 CRUD + 搜尋 + 權限放在同一個 pattern |
| **定期清理** | 超過 3 個 Feature 沒人用的 pattern → 移到 archive |

---

## 與其他 Skill 的整合

| Skill | 整合方式 |
|-------|---------|
| `test-driven-development` | RED phase 前查詢 pattern；全通過後回饋 pattern |
| `self-healing-build` | 成功修復 → 更新 pattern 的已知陷阱 |
| `ground` | Build Grounding 時列出可用的 pattern |
| `gate-check` | Pattern 使用率作為 Build 效率指標 |

---

## Pattern 索引（README.md 格式）

`verified-patterns/README.md` 維護索引：

```markdown
# Verified Pattern Library

> 最後更新：[日期] | Pattern 數量：[N]

## Backend

| Pattern | 適用場景 | 來源 | 使用次數 |
|---------|---------|------|---------|
| [crud-standard](backend/crud-standard.md) | 標準 CRUD 操作 | F01 | 5 |
| [search-with-pagination](backend/search-with-pagination.md) | 分頁搜尋 | F02 | 3 |

## Frontend

| Pattern | 適用場景 | 來源 | 使用次數 |
|---------|---------|------|---------|
| [form-with-validation](frontend/form-with-validation.md) | 表單 + 驗證 | F01 | 4 |

## Testing

| Pattern | 適用場景 | 來源 | 使用次數 |
|---------|---------|------|---------|
| [api-integration-test](testing/api-integration-test.md) | API 整合測試 | F01 | 6 |
```

---

## 初始化

專案首次使用時：

```bash
mkdir -p verified-patterns/{backend,frontend,testing,healing}
touch verified-patterns/README.md
```

Pattern 在第一個 Feature 完成後開始累積。不要在 Build 開始前「預寫」pattern — 那是猜測，不是驗證。
