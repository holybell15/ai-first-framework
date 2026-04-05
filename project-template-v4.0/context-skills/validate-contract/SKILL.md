---
name: validate-contract
description: >
  **前後端 Contract 雙向驗證 — 確保 API response 結構前後端一致。**

  Triggered by: Build Gate 前（強制）、API endpoint 新增/修改後、前端 Type 修改後、
  「前後端不匹配」、「DTO 欄位對不上」、「API response 結構跟前端不一樣」。

  教訓：F04 前端定義了 4 個 API endpoint 但後端 Controller 不存在。
  F06 後端返回 DB 欄位名（callType），前端期望 UI 欄位名（interactionType），合併後全炸。

  v4.1 升級為 Tier 1 強制。

source: AI-First Framework v4.1 — Contract-First Development
user-invocable: false
allowed-tools: "Read, Glob, Grep, Write, Edit"
---

# Validate Contract: 前後端 DTO 雙向驗證

## 為什麼需要？

**前後端各自發明 DTO = 合併必炸。**

```
沒有 Contract：
  Backend: { callType: "INBOUND", durationSec: 120 }     ← DB 欄位名
  Frontend: { interactionType: "inbound", talkDurationSec: 120 }  ← UI 欄位名
  → 結果：NaN、undefined、全部跑版

有 Contract（SSOT）：
  Contract YAML: { interactionType: "string", talkDurationSec: "integer" }
  Backend DTO:   { interactionType: "string", talkDurationSec: int }     ← 從 contract 生成
  Frontend Type: { interactionType: string; talkDurationSec: number }    ← 從 contract 生成
  → 結果：欄位名一致，型別一致，正常運作
```

---

## Contract 檔案

位置：`contracts/F[XX]-[endpoint].yaml`
模板：`contracts/TEMPLATE_API_Contract.yaml`

**每個 API endpoint 都必須有對應的 Contract YAML。**

---

## 驗證流程（Build Gate 前強制執行）

### Step 1: 列出所有 Contract 檔案

```bash
ls contracts/F*.yaml
```

### Step 2: 對每個 Contract 執行三向驗證

```
Contract YAML（SSOT）
  ↕ 驗證 1: Backend DTO 欄位名 = Contract 欄位名
  ↕ 驗證 2: Frontend Type 欄位名 = Contract 欄位名
  ↕ 驗證 3: Backend DTO 欄位名 = Frontend Type 欄位名（三角一致）
```

#### 驗證 1: Backend DTO vs Contract

```
讀取 Contract YAML → response_item 的所有欄位名
讀取 Contract YAML → validation.backend_dto_class
搜尋 Backend DTO Java class → 提取所有欄位名
比對：

✅ 一致：Contract 說 interactionType → DTO 有 interactionType
❌ 不匹配：Contract 說 interactionType → DTO 用 callType → BLOCK
❌ 缺失：Contract 定義了但 DTO 沒有 → BLOCK
❌ 多餘：DTO 有但 Contract 沒定義 → 警告（可能是內部欄位）
```

#### 驗證 2: Frontend Type vs Contract

```
讀取 Contract YAML → response_item 的所有欄位名
讀取 Contract YAML → validation.frontend_type_file + frontend_type_name
搜尋 Frontend Type/Interface → 提取所有欄位名
比對：同上邏輯
```

#### 驗證 3: Endpoint 存在性

```
Contract 定義了 endpoint（method + path）
  → 後端有對應的 @RequestMapping？ 沒有 = 🔴 BLOCK（F04 教訓）
  → 前端有對應的 API call？ 沒有 = ⚠️ 警告
```

### Step 3: 產出驗證報告

```markdown
## Contract Validation Report — F[XX]

### 驗證摘要
- Contract 檔案數：[N]
- 全部通過：[Y/N]

### 逐一結果

#### F06-interaction-list.yaml
| 檢查項 | 結果 | 詳情 |
|--------|------|------|
| Backend DTO 存在 | ✅ | InteractionListResponse.java |
| Backend 欄位匹配 | ❌ | Contract: interactionType → DTO: callType |
| Frontend Type 存在 | ✅ | InteractionListItem in types/interaction.ts |
| Frontend 欄位匹配 | ❌ | Contract: talkDurationSec → Type: talkDuration |
| Endpoint 存在 (BE) | ✅ | InteractionController.java |
| Endpoint 存在 (FE) | ✅ | api/interaction.ts |

#### 不匹配清單（必修）
| Contract 欄位 | Backend 實際 | Frontend 實際 | 修正方向 |
|--------------|-------------|--------------|---------|
| interactionType | callType | interactionType | Backend 改名 |
| talkDurationSec | durationSec | talkDuration | 兩邊都改 |
```

---

## 觸發時機

| 時機 | 動作 |
|------|------|
| **Tech Spec §2.5 確認後** | 建立 Contract YAML |
| **寫 Backend code 前** | gate-checkpoint 檢查 contract YAML 存在 |
| **寫 Frontend code 前** | gate-checkpoint 檢查 contract YAML 存在 |
| **Build Gate 前（G4-ENG-R）** | 執行完整三向驗證 |
| **API 欄位修改後** | 觸發 CIA → 更新 Contract YAML → 重新驗證 |

---

## Contract 變更規則

Contract YAML 是 Baselined 文件。修改走 CIA：

```
想改 API response 欄位
  → 修改 Contract YAML（附 CIA 編號）
  → Backend 和 Frontend 都要跟著改
  → 重跑 validate-contract
  → 三向一致才能過 Gate
```

---

## 與其他 Skill 的整合

| Skill | 整合方式 |
|-------|---------|
| `gate-check` | G4-ENG-R 新增 R-04b：Contract 驗證必須通過 |
| `ground` | Build Grounding 時列出需要的 Contract YAML |
| `cia` | Contract YAML 修改必須走 CIA |
| `test-driven-development` | Contract Test = @real test 的一種 |
| `concurrent-build` | BE/FE split 時，Contract YAML 是共用的 read-only 邊界 |
