---
name: external-integration
description: >
  異質系統串接的強制品質流程。當 Feature 涉及外部 SDK、第三方 API、WebSocket、SIP、MQ、
  或任何非本專案控制的協議時，必須依序通過 5 個 Gate 才能進入下一步。
  觸發條件：Tech Spec 或任務中有「外部系統」、「SDK」、「第三方 API」、「WebSocket」、
  「串接」、「整合」、「對接」、「integration」等關鍵字。
source: AI-First Framework v4.0 — 異質系統串接品質事故回顧
---

# External Integration Skill

## 為什麼需要這個？

異質系統串接的 Bug 幾乎都是**靜默失敗**——JSON 差一個欄位、型別錯一個、少一個必填欄位，
對方直接丟棄不回錯誤。傳統 TDD 抓不到這類問題，因為測試的基準是你自己的「理解」，不是對方的「規格」。

更常見的失敗模式：
- **沒讀 spec 就開工** → 欄位名、協議、格式全靠猜測
- **架構沒確認就寫 code** → 後端 WS + SDK WS 衝突、職責不明、反覆重寫
- **本地沒跑通就部署** → 真機才發現 WS 連不上、event 收不到
- **手動部署** → 路徑搞混、忘記重啟、環境不一致

**核心原則：依序通過 5 個 Gate，前一個沒過不做下一個。**

---

## 觸發條件

Tech Spec 或 Feature 涉及以下任一項時，本 Skill 為**強制載入**：

- 外部 SDK 整合（CTI SDK、支付 SDK、SSO SDK…）
- 第三方 REST/GraphQL API 呼叫
- WebSocket / TCP / SIP 等非 HTTP 協議
- 外部系統事件訂閱（Webhook、SSE、MQ）
- 任何需要遵守對方定義的格式（JSON/XML/Protobuf）

---

## Gate 0 — 讀 Spec + 介面契約摘要（開工前必做）

**目的：確保你真正理解對方的協議，不是靠記憶或猜測。**

### 執行步驟

1. **找到並讀取**外部系統的官方文件（SDK doc / API spec / 協議文件）
2. **產出介面契約摘要**（Interface Contract Summary），包含：

```markdown
# 介面契約摘要：[系統名稱]

## 文件來源
- 文件名稱：[名稱]
- 版本：[版本號]
- 位置：[路徑或 URL]

## 通訊協議
- 協議類型：[REST / WebSocket / TCP / SIP / MQ / ...]
- 連線方式：[URL pattern / port / 認證方式]
- 連線生命週期：[長連線 / 短連線 / 心跳機制]

## 送出的指令（本系統 → 外部系統）
| 指令名稱 | 用途 | 必填欄位 | 回應方式 |
|---------|------|---------|---------|
| ... | ... | ... | 同步回應 / 異步事件 |

## 接收的事件（外部系統 → 本系統）
| 事件名稱 | 觸發時機 | 關鍵欄位 | 處理方式 |
|---------|---------|---------|---------|
| ... | ... | ... | ... |

## 狀態模型
- 外部系統定義的狀態有哪些？
- 狀態轉換的觸發條件？
- 哪些狀態轉換是由本系統發起 vs 外部系統發起？

## 待確認項目
- [ ] [任何 spec 中不明確的地方]
```

3. **提交給用戶確認** → 用戶確認後才進 Gate 1

### 完成標準
- 介面契約摘要已產出
- 用戶已確認摘要正確
- 待確認項目已標記（可帶入 Gate 1 討論）

---

## Gate 1 — 架構設計確認（寫 code 之前必做）

**目的：明確元件職責分工和資料流方向，避免架構反覆。**

### 執行步驟

1. **畫出元件關係圖**（文字版即可），回答：
   - 哪個元件負責**建立連線**？（WS / TCP / HTTP client）
   - 哪個元件負責**協議轉譯**？（外部格式 ↔ 內部格式）
   - 哪個元件負責**狀態管理**？（連線狀態 / 業務狀態）
   - 事件從外部系統 → 前端的**完整路徑**是什麼？
   - 指令從前端 → 外部系統的**完整路徑**是什麼？

2. **元件職責表**：

```markdown
| 元件 | 職責 | 輸入 | 輸出 | 不做什麼 |
|------|------|------|------|---------|
| ConnectionManager | 建立/維護 WS 連線、心跳 | config | 連線狀態事件 | 不解析業務 payload |
| ProtocolAdapter | 外部 JSON ↔ 內部 DTO | raw JSON | typed DTO | 不管連線狀態 |
| EventRouter | 收到事件後分發 | typed DTO | domain event | 不做業務邏輯 |
| CommandService | 組裝指令 payload | 業務參數 | raw JSON | 不管傳輸層 |
| ... | ... | ... | ... | ... |
```

3. **提交給用戶確認** → 用戶確認後才動手寫 code

### 完成標準
- 元件關係圖已產出（含資料流方向）
- 5 個架構問題都有明確答案
- 用戶已確認架構設計

---

## Gate 2 — Contract Test 先行（TDD 的第一步）

**目的：用 SDK spec 作為測試基準，不是用自己的程式碼。**

### Step 2a — 提取 Contract Fixture

從 Gate 0 的介面契約摘要中，為每個指令和事件建立 test fixture：

```
src/test/resources/contracts/[系統名稱]/
  commands/          ← 送出的指令，每個一個 JSON
  events/            ← 接收的事件，每個一個 JSON
  enums/             ← 列舉值定義
```

每個 fixture 必須包含：

```json
{
  "_source": "[文件名稱] §[章節]",
  "_description": "[用途說明]",
  "name": "[指令/事件名稱]",
  "requiredFields": ["field1", "field2"],
  "fieldTypes": { "field1": "string", "field2": "number" },
  "enumConstraints": { "field1": ["VALUE_A", "VALUE_B"] },
  "example": { ... }
}
```

**規則：**
- `_source` 必須指向 spec 文件的具體章節
- 欄位名稱、型別、列舉值從 spec 逐字抄錄，**禁止推測**
- spec 不明確的標記 `"uncertain": true`

### Step 2b — 寫 Contract Test

針對每個 fixture 寫自動化測試：
- 送出的指令：驗證程式碼產出的 payload 逐欄位匹配 fixture
- 接收的事件：驗證程式碼能正確解析 fixture 中的 example
- 列舉值：驗證程式碼使用的值在 fixture 允許範圍內

**Contract test 在 TDD RED 階段第一個寫。失敗 = 阻塞，不允許繼續。**
**禁止修改 fixture 來讓測試通過。**

### 完成標準
- spec 中每條指令都有 command fixture + test
- spec 中每個事件都有 event fixture + test
- 所有 contract test 全綠

---

## Gate 3 — 本地可測試（部署前必做）

**目的：在本地跑通完整流程，不靠真機試錯。**

### 執行步驟

1. **建立 Mock Server**（在開發初期，不是出問題後才補）
   - 收到指令時**驗證格式**（不符合 fixture 定義 → 回 error，不靜默丟棄）
   - 回傳對應的**事件序列**（模擬真實狀態流程）
   - 驗證**狀態前置條件**（不在正確狀態就拒絕指令）

2. **本地跑通完整流程**：
   - 連線 → 認證 → 正常操作流程 → 異常流程 → 斷線重連
   - 後端連 Mock 跑通
   - 前端連後端（後端連 Mock）跑通

3. **Playwright E2E**（如果有 UI）：
   - 每個主要操作流程一個 spec
   - Mock 提供 REST API 讓 Playwright 觸發事件
   - 在 Mock 環境下全部通過

### 測試層次

```
L1  Contract Test     秒級   每個零件的規格是否正確（欄位名、型別、必填）
L2  Mock 整合測試     分鐘級  零件組裝起來流程是否走得通（指令→事件→狀態）
L3  瀏覽器 E2E       分鐘級  使用者操作是否得到正確結果（UI 層驗證）
```

**執行順序：L1 → L2 → L3，前一層不過就不跑下一層。**

### 完成標準
- Mock Server 可模擬 Tech Spec 中每個主要流程
- L1 + L2 + L3 全部通過
- 本地沒通過 → 不部署

---

## Gate 4 — 部署腳本化（不手動操作）

**目的：消除手動部署的人為錯誤。**

### 執行步驟

1. **deploy.sh 一鍵部署**（或等效的自動化腳本）
   - 路徑寫在 script 裡，不靠記憶
   - 包含 build → 傳輸 → 重啟 → 等待就緒
   
2. **部署後自動 smoke test**：
   - curl/wget 打幾個 health endpoint 確認服務活著
   - 確認外部系統連線狀態
   - 輸出明確的 PASS / FAIL

3. **部署日誌**：
   - 記錄部署時間、版本、commit hash
   - 記錄 smoke test 結果

### 完成標準
- deploy.sh 存在且可一鍵執行
- 部署後 smoke test 全部通過
- 禁止手動 scp / 手動 ssh 操作

---

## 流程總覽

```
Gate 0: 讀 Spec        → 介面契約摘要   → 用戶確認 ✓
Gate 1: 架構設計        → 元件圖+資料流  → 用戶確認 ✓
Gate 2: Contract Test   → Fixture + Test → 全綠 ✓
Gate 3: 本地跑通        → Mock + E2E     → 全綠 ✓
Gate 4: 腳本化部署      → deploy.sh      → Smoke PASS ✓
```

**違反任何一步 → 停下來補，不要繼續往前衝。**

---

## 與其他 Skill 的關係

| Skill | 關係 |
|-------|------|
| `test-driven-development` | Contract Test 在 TDD RED 階段第一個寫，然後才寫業務邏輯測試 |
| `ground` | 修改串接相關 code 前，除了 ground 的 Read Before Write，還要重讀 fixture |
| `webapp-testing` | L3 瀏覽器 E2E 遵循 webapp-testing skill 的規範 |
| `gate-check` | Build Gate 出口標準新增 Contract 驗證 + E2E 驗證項目 |
| `verification-before-completion` | Agent 完成前必須確認 5 個 Gate 全部通過 |
| `systematic-debugging` | 串接 Bug 先查 contract fixture 是否完整，再查 code |

---

## 常見錯誤 → 正確做法

| 錯誤 | 正確做法 |
|------|---------|
| 沒讀 spec 就開始寫 code | Gate 0：先讀 spec、產出摘要、用戶確認 |
| 架構邊寫邊改 | Gate 1：先畫圖確認職責，用戶同意再動手 |
| 用自己的理解當測試基準 | Gate 2：fixture 從 spec 逐字抄，不靠猜 |
| 出問題後才建 mock server | Gate 3：開發初期就建，不是補救措施 |
| 手動 scp 部署 | Gate 4：deploy.sh 一鍵部署 + smoke test |
| 本地沒跑通就上真機 | Gate 3：本地全綠才部署 |
| 同時改架構又修 bug | 一次只做一件事，架構改完確認再修 bug |
