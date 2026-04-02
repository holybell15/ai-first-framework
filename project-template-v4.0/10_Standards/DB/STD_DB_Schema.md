# DB Schema 設計規範 — [專案名稱]

> **版本**：v1.0 | **SSOT**：本文件 + `enum_registry.yaml` + `field_registry_F##.yaml`
> **適用對象**：dba-agent、backend-agent、review-agent

---

## 1. 命名規範

| 項目 | 規則 | 範例 |
|------|------|------|
| 資料表 | `snake_case` 複數 | `tickets`、`call_records` |
| 欄位 | `snake_case` | `created_at`、`tenant_id` |
| 索引 | `idx_{table}_{columns}` | `idx_tickets_tenant_id` |
| 外鍵 | `fk_{table}_{ref_table}` | `fk_tickets_customers` |
| 語意前綴 | 見下方前綴規則 | `pii_phone`、`log_action` |

**強制語意前綴：**

| 前綴 | 意義 | 要求 |
|------|------|------|
| `pii_` | 個人資料（姓名、電話、Email）| 必須加密儲存或遮罩顯示 |
| `log_` | 稽核欄位 | 不可修改，只能 INSERT |
| `enc_` | 敏感金融資料 | AES-256-GCM 加密，`enc_` 欄位不進 API Response |

---

## 2. 業務資料表必要欄位

每張業務資料表**必須包含**以下欄位，缺一不可：

```sql
id          UUID        PRIMARY KEY DEFAULT gen_random_uuid()
tenant_id   UUID        NOT NULL    -- 多租戶隔離，所有查詢強制過濾
created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
created_by  UUID        REFERENCES users(id)  -- 誰建立
updated_by  UUID        REFERENCES users(id)  -- 誰最後更新
```

> `tenant_id` 缺失 = Schema Review 🔴 阻塞，不得合併

---

## 3. 多租戶隔離規則

- 所有查詢必須加 `WHERE tenant_id = :tenantId`
- 建立 Row-Level Security（RLS）作為資料庫層防護
- 跨 tenant 資料存取觸發 Critical 告警
- **禁止**在 Application 層做 tenant 過濾後省略 DB 層過濾

---

## 4. ENUM 管理規則

**SSOT**：`10_Standards/DB/enum_registry.yaml`

```yaml
# 格式範例
ticket_status:
  description: 案件狀態
  values:
    - value: open
      label_zh: 待處理
    - value: in_progress
      label_zh: 處理中
    - value: closed
      label_zh: 已結案
  db_constraint: CHECK (status IN ('open', 'in_progress', 'closed'))
```

**三端同步規則：**
- DB CHECK Constraint 從 enum_registry.yaml 產出
- Java/TypeScript Enum 從 enum_registry.yaml 產出
- 前端 Select 選項從 enum_registry.yaml 產出
- 禁止任何一端 hardcode ENUM 字串值

---

## 5. Field Registry 規則

每個 Feature 必須建立 `contracts/field_registry_F##.yaml`：

```yaml
# 格式範例（field_registry_F01.yaml）
feature: F01
fields:
  - name: ticket_id
    type: UUID
    nullable: false
    pii: false
    description: 案件唯一識別碼
    api_exposed: true
  - name: pii_customer_phone
    type: VARCHAR(20)
    nullable: true
    pii: true
    encryption: AES-256-GCM
    api_exposed: false   # 僅回傳遮罩版本
```

---

## 6. Migration 規範

| 規則 | 說明 |
|------|------|
| 必須可逆 | 每個 Migration 必須有 `up()` 和 `down()` |
| 不可刪資料 | 生產環境禁止 DROP COLUMN（改用 soft delete 或 rename）|
| 命名格式 | `V{序號}__{描述}.sql`（如 `V002__add_tenant_id_to_tickets.sql`）|
| 執行環境 | Dev → Staging 驗證 48hr → Production |
| 大表異動 | 超過 100 萬筆的表異動必須使用 online migration 工具 |

---

## 7. 索引策略

```sql
-- 所有業務表必建 tenant_id 索引
CREATE INDEX idx_{table}_tenant_id ON {table}(tenant_id);

-- 常見查詢組合索引
CREATE INDEX idx_{table}_tenant_status ON {table}(tenant_id, status);

-- 時間範圍查詢
CREATE INDEX idx_{table}_created_at ON {table}(created_at DESC);
```

**禁止**在沒有 tenant_id 的前提下建立大範圍索引。

---

## 8. 稽核日誌資料表規範

所有有 `log_` 前綴欄位的資料，必須有對應的稽核日誌表：

```sql
CREATE TABLE audit_logs (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL,
    actor_id    UUID NOT NULL,         -- 操作者
    action      VARCHAR(50) NOT NULL,  -- CREATE/UPDATE/DELETE/EXPORT
    target_type VARCHAR(100) NOT NULL, -- 資源類型
    target_id   UUID NOT NULL,         -- 資源 ID
    before_data JSONB,                 -- 操作前快照
    after_data  JSONB,                 -- 操作後快照
    ip_address  INET,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 稽核日誌禁止 UPDATE / DELETE，只能 INSERT
-- 保存期限：≥ 1 年（依適用法規規定）
```

---

## 9. 資料加密規範

| 類型 | 機制 | 欄位前綴 |
|------|------|---------|
| 傳輸加密 | TLS 1.3 | — |
| 靜態加密（PII）| AES-256-GCM，應用層加密 | `pii_` |
| 靜態加密（金融）| AES-256-GCM，HSM 金鑰管理 | `enc_` |
| 密碼 | bcrypt（cost ≥ 12）| 不用前綴，欄位名 `password_hash` |

---

## 10. Gate Review 驗收項目

G4-ENG / Gate 3 前 DBA 必須確認：
- [ ] 所有業務表含必要欄位（id / tenant_id / created_at / updated_at）
- [ ] ENUM 值已寫入 enum_registry.yaml
- [ ] Field Registry（field_registry_F##.yaml）已產出
- [ ] Migration 可執行且可逆
- [ ] PII 欄位已加密，API 不直接暴露原始值
- [ ] 稽核日誌涵蓋所有資料異動操作

<!-- STD-SIG: DB Schema Standard v1.0 | 2026-03-15 -->
