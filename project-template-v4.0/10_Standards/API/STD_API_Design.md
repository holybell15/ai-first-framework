# API 設計規範 — [專案名稱]

> **版本**：v1.0 | **SSOT**：本文件 + `Error_Code_Standard_v1.0.md`
> **適用對象**：backend-agent、review-agent、architect-agent

---

## 1. URL 路徑規範

```
/api/v{N}/{resource}/{id}/{sub-resource}
```

| 規則 | 說明 |
|------|------|
| 版本控制 | URL 路徑版本 `/api/v1/`，禁止用 Header 版本 |
| 維護版本數 | 同時最多 **2 個主要版本**（v3 上線 = v1 必須下線）|
| 資源命名 | 小寫 kebab-case 複數（`/tickets`、`/call-records`）|
| 操作語意 | GET=查詢 / POST=新增 / PUT=完整更新 / PATCH=部分更新 / DELETE=刪除 |

**版本升版規則：**
- Breaking change（欄位刪除、型別改變）→ 升主版本（v1→v2）
- 新增欄位（向下相容）→ Minor（文件標記）
- Bug 修正 → Patch（不需升版）
- 舊版 API 必須標 `@Deprecated` + Response Header 加 `Sunset: <date>`

---

## 2. Response Envelope（強制格式）

```json
{
  "success": true,
  "data": { ... },
  "message": "操作成功",
  "errorCode": null,
  "timestamp": "2026-03-15T10:00:00Z"
}
```

**錯誤時：**
```json
{
  "success": false,
  "data": null,
  "message": "Token 無效或過期",
  "errorCode": "[PREFIX]-A001",
  "timestamp": "2026-03-15T10:00:00Z"
}
```

> 禁止直接回傳 Entity 物件。所有 Response 必須經 VO 轉換層。

---

## 3. 多租戶隔離（強制）

- `tenant_id` **只能從 JWT token 取得**，禁止從 Request Body / Query Param 傳入
- 所有業務查詢必須加 `WHERE tenant_id = :tenantId`
- 違反者在 Code Review Gate 退回（不可 CONDITIONAL_PASS）

---

## 4. 認證與授權

| 機制 | 規則 |
|------|------|
| 認證 | JWT Bearer Token，每個 API 均需驗證 |
| 授權 | RBAC（Role-Based Access Control），從 JWT claims 取得 role |
| Token 過期 | 回傳 `[PREFIX]-A001`，前端自動 refresh |
| 匿名存取 | 禁止，所有業務 API 需身份驗證 |

---

## 5. 輸入驗證規則

| 層級 | 職責 |
|------|------|
| Layer 1（前端）| Zod Schema 驗證，與後端語意等價（L1=L2 等價原則）|
| Layer 2（Controller）| DTO 欄位格式驗證（NOT NULL、長度、格式）|
| Layer 3（Service）| 業務規則驗證（狀態機、跨欄位邏輯）|

- ENUM 值從 `10_Standards/DB/enum_registry.yaml` 產出，禁止 hardcode 字串
- 驗證失敗回傳 `[PREFIX]-V001~V003`

---

## 6. 錯誤碼規範

> 完整清單見 `Error_Code_Standard_v1.0.md`

**格式**：`[PREFIX]-{LAYER}{CODE}`

| Layer | 說明 | 範例 |
|-------|------|------|
| A | 認證/授權 | [PREFIX]-A001 |
| V | 輸入驗證 | [PREFIX]-V001 |
| B | 業務邏輯 | [PREFIX]-B001 |
| D | 資料庫 | [PREFIX]-D001 |
| I | 外部整合 | [PREFIX]-I001 |
| S | 系統/基礎設施 | [PREFIX]-S001 |

---

## 7. 事務管理（Transaction）

| 規則 | 說明 |
|------|------|
| TX-01 | `@Transactional` 只能宣告在 **Service 層** |
| TX-02 | 預設 `Propagation.REQUIRED`；稽核日誌用 `REQUIRES_NEW` |
| TX-03 | 唯讀查詢標記 `readOnly = true` |
| TX-04 | 明確宣告 `rollbackFor = Exception.class` |
| TX-05 | 長交易（>3 秒）拆分為 Saga / Outbox Pattern |
| TX-06 | 跨模組禁止共用交易，使用事件驅動（NATS/MQ）|

---

## 8. API 版本切換管理

```
Controller 按版本分包：controller.v1.* / controller.v2.*
Service 層版本無關（版本差異只在 Controller ↔ VO 映射層）
版本升級必須附 Migration Guide（命名：API_MigrationGuide_v1_to_v2.md）
```

---

## 9. 效能基準（Gate 3 強制）

| 指標 | 門檻 |
|------|------|
| API P95 回應時間 | ≤ 2 秒（一般查詢）/ ≤ 5 秒（AI 功能）|
| API P99 回應時間 | ≤ 5 秒 |
| 5xx 錯誤率（壓力下）| < 1% |
| Rate Limit | 依功能定義，Auth API 最嚴（100 req/min/IP）|

---

## 10. OpenAPI 文件要求

- 每個 Endpoint 必須有完整 OpenAPI 3.0 描述
- Request / Response 範例必填
- 錯誤碼清單必填
- Deprecated API 標記 `deprecated: true` + 說明替代版本

<!-- STD-SIG: API Design Standard v1.0 | 2026-03-15 -->
