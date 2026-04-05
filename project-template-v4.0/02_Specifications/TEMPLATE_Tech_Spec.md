# Tech Spec — [Feature ID]: [Feature 名稱]

> 版本：v0.1 | 狀態：Draft → Review → **Baselined**
> 對應 RS：`RS_[FXX]_[名稱]_v[X.X].md`
> 對應 AC：`[FXX]_AC_v[X.X].md`

---

## 1. 概述

### 1.1 目的
本文件定義 [Feature ID] 的技術實作方案，作為 Build 階段的技術基準。
所有 Agent 在 Build 時必須遵循此文件的設計。

### 1.2 範圍
- **包含**：[本 Feature 涵蓋的技術實作]
- **排除**：[明確不在本 Feature 中的事項]

### 1.3 Scope Baseline 追溯
| REQ 功能編號 | REQ 描述 | 本文件對應章節 |
|-------------|----------|---------------|
| F[XX]-[YY] | [需求描述] | §[章節號] |

---

## 2. API 設計

### 2.1 端點清單

| Method | Path | 說明 | 對應 REQ |
|--------|------|------|---------|
| POST | `/api/v1/[resource]` | [說明] | F[XX]-[YY] |
| GET | `/api/v1/[resource]` | [說明] | F[XX]-[YY] |

### 2.2 Request / Response 規格

#### [API 名稱]

**Request:**
```json
{
  "field": "type — 說明（必填/選填）"
}
```

**Response (200):**
```json
{
  "field": "type — 說明"
}
```

**Error Responses:**
| HTTP Status | Error Code | 說明 |
|-------------|-----------|------|
| 400 | INVALID_INPUT | [說明] |
| 401 | UNAUTHORIZED | [說明] |

### 2.3 Executable Contract（OpenAPI Snippet）

> **目的**：減少「自然語言 → code」的語義落差。AI 從 contract 生成 code，一次通過率顯著提升。
> 只需寫關鍵 endpoint，不需完整 OpenAPI spec。

```yaml
# OpenAPI 3.0 snippet — 關鍵 endpoint
paths:
  /api/v1/[resource]:
    post:
      summary: "[說明]"
      operationId: "[operationId]"
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [field1, field2]
              properties:
                field1:
                  type: string
                  description: "[說明]"
                  minLength: 1
                  maxLength: 200
                field2:
                  type: integer
                  description: "[說明]"
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/StandardResponse'
        '400':
          description: 驗證失敗
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ErrorResponse'
```

> **使用方式**：Backend Agent 讀取此 snippet 生成 Controller + Validation；QA Agent 從 schema 自動生成邊界測試。

### 2.4 認證與授權
- 認證方式：[JWT / Session / OAuth2 / 依專案決策]
- 授權模型：[RBAC / ABAC / 說明角色權限]

### 2.5 Shared DTO / Response Schema（v4.1 — 前後端共用 SSOT）

> **目的**：前後端必須從同一份 DTO 定義開發。禁止各自發明欄位名。
> **教訓**：後端返回 `callType, durationSec`（DB 欄位），前端期望 `interactionType, talkDurationSec`（UI 欄位），合併後全炸。
> **Contract 檔案**：`contracts/F[XX]-[endpoint].yaml`（SSOT，兩邊都從這裡讀）

#### [Endpoint 名稱] Response DTO

| API 欄位（前後端共用） | 型別 | 來源（DB / 計算） | 前端用途 | 備註 |
|----------------------|------|-------------------|---------|------|
| `interactionId` | string | `db.interaction_id` | 列表 key | — |
| `interactionType` | string | `db.call_type` mapping: INBOUND→inbound | Badge 顯示 | enum 見 enum_registry |
| `customer.name` | string | `db.customer_name` | 列表欄位 | nullable |
| `customer.phone` | string | `db.caller_number` | 列表欄位 | — |
| `talkDurationSec` | integer | `db.duration_sec` | 時長顯示 | 秒，前端自行格式化 |
| `ahtSec` | integer | `db.duration_sec + db.acw_duration_sec` | AHT 顯示 | 後端計算 |

**規則**：
- **API 欄位名 = 前端 Type 欄位名 = 後端 DTO 欄位名**（三者必須一致）
- **DB 欄位名可以不同**，但必須在「來源」欄標明 mapping 方式
- **巢狀結構**（如 `customer.name`）：後端 DTO 必須用巢狀物件，不可 flat
- **每個 endpoint 都必須有對應的 Contract YAML**：`contracts/F[XX]-[endpoint].yaml`

---

## 3. 資料模型

### 3.1 Schema 設計

#### [Table / Collection 名稱]
| 欄位 | 型別 | 約束 | 說明 | 對應 REQ |
|------|------|------|------|---------|
| id | BIGINT / UUID | PK, AUTO_INCREMENT | 主鍵 | — |
| [field] | [type] | [constraints] | [說明] | F[XX]-[YY] |

### 3.2 索引設計
| 索引名 | 欄位 | 類型 | 用途 |
|--------|------|------|------|
| idx_[name] | [columns] | [B-tree/Hash/GIN] | [查詢場景] |

### 3.3 資料遷移
- Migration 檔案命名：`V[版本]__[Feature]_[描述].sql`
- 向後相容性：[說明是否需要 backward compatible]

---

## 4. 前端架構

### 4.1 元件結構
```
src/
  views/
    [FeatureView].vue          ← 頁面層
  components/
    [feature]/
      [Component].vue          ← 元件層
  composables/
    use[Feature].ts            ← 邏輯層
  stores/
    [feature]Store.ts          ← 狀態層
  api/
    [feature]Api.ts            ← API 呼叫層
```

### 4.2 狀態管理
- Store 類型：[Pinia / Vuex / composable]
- 狀態範圍：[此 Feature 獨立 store 或共用]

### 4.3 路由
| Path | Component | Guard | 說明 |
|------|-----------|-------|------|
| `/[path]` | `[View].vue` | [auth/role] | [說明] |

### 4.4 Prototype 對應
| Prototype 畫面 | 對應元件 | 備註 |
|---------------|----------|------|
| [Prototype 截圖/區域描述] | `[Component].vue` | [差異說明，如果有] |

---

## 5. 共用元件與服務

### 5.1 本 Feature 提供的共用元件
> 其他 Feature 可以依賴這些元件（修改需走 CIA）

| 元件/服務 | 路徑 | 用途 | 依賴方 |
|-----------|------|------|--------|
| [名稱] | [path] | [說明] | F[XX], F[YY] |

### 5.2 本 Feature 依賴的共用元件
> 來自其他已完成 Feature 的共用元件

| 元件/服務 | 來源 Feature | 版本 | 備註 |
|-----------|-------------|------|------|
| [名稱] | F[XX] Tech Spec §[章節] | v[X] | [使用方式] |

---

## 6. 技術決策

### 6.1 關鍵決策記錄
| # | 決策 | 選項 | 選擇 | 理由 |
|---|------|------|------|------|
| TD-1 | [決策主題] | A: [方案A], B: [方案B] | [選擇] | [理由] |

### 6.2 與既有決策的一致性
> 必須與 DECISIONS.md 中的既有決策保持一致

| 相關決策 | 內容 | 本文件如何遵循 |
|----------|------|---------------|
| D[XX] | [決策內容] | [遵循方式] |

---

## 7. 錯誤處理與邊界情境

| 情境 | 處理方式 | 對應 AC |
|------|----------|--------|
| [邊界情境描述] | [處理邏輯] | AC-[XX] |

---

## 8. 安全性考量

- [ ] 輸入驗證：[方式]
- [ ] SQL Injection 防護：[方式]
- [ ] XSS 防護：[方式]
- [ ] CORS 設定：[範圍]
- [ ] 敏感資料處理：[加密方式]
- [ ] 合規要求：[FSC / GDPR / 其他]

---

## 9. 測試策略

| 測試層級 | 範圍 | 工具 | 目標覆蓋率 |
|----------|------|------|-----------|
| L1 Unit | [範圍] | [Jest/Vitest/JUnit] | [%] |
| L2 Integration | [範圍] | [工具] | [%] |
| L3 E2E | [範圍] | [Playwright/Cypress] | [關鍵路徑] |

### 9.1 Executable AC（Given/When/Then）

> **目的**：AC 直接對應 test case，消除「AC 寫了但不知道怎麼測」的問題。
> QA Agent 從這些 GWT 自動生成測試骨架，Backend/Frontend Agent 從 GWT 驗證實作。

#### AC-[XX]: [AC 描述]

```gherkin
Scenario: [情境名稱]
  Given [前置條件 — 系統狀態 / 使用者角色 / 資料狀態]
  When  [操作 — API 呼叫 / UI 操作]
  Then  [預期結果 — response / UI 變化 / DB 狀態]
  And   [額外驗證（可選）]

Scenario: [錯誤情境]
  Given [前置條件]
  When  [觸發錯誤的操作]
  Then  [預期錯誤 — error code / 提示訊息]

Scenario: [邊界情境]
  Given [邊界資料 — 空值 / 最大值 / 特殊字元]
  When  [操作]
  Then  [預期行為]
```

> **規則**：
> - 每個 AC 至少 3 個 Scenario（happy / error / boundary）
> - Given 必須是可程式化設定的狀態（不是「使用者覺得...」）
> - Then 必須是可斷言的結果（response code / DOM 狀態 / DB 值）

### 9.2 前端 Testability Mapping

> **目的**：Prototype 的 UI 元素對應 data-testid，Playwright 可直接定位。

| UI 元素 | data-testid | 對應 AC | 測試動作 |
|---------|-------------|---------|---------|
| [按鈕/輸入框/表格] | `[feature]-[element]-[action]` | AC-[XX] | click / fill / assert |

> **命名規則**：`{feature}-{element}-{action}`，例如 `customer-search-input`、`ticket-submit-btn`
> Prototype HTML 中加入：`data-testid="customer-search-input"`

---

## 10. 變更歷史

| 版本 | 日期 | 變更者 | 變更內容 | CIA 編號 |
|------|------|--------|----------|---------|
| v0.1 | [YYYY-MM-DD] | [Agent/凱子] | 初版建立 | — |

---

## Checklist（Plan Gate 前必須完成）

- [ ] 所有 API 端點有明確的 Request/Response 定義
- [ ] 所有 Schema 欄位有型別和約束
- [ ] 共用元件的依賴關係已標註
- [ ] 技術決策與 DECISIONS.md 一致
- [ ] 每個技術項目都能追溯到 REQ 功能編號
- [ ] 凱子確認此 Tech Spec
