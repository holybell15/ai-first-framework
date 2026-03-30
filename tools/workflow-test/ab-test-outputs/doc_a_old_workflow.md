由於檔案寫入權限限制，我直接在下方產出完整的需求規格書：

---

# 需求規格書 (Requirements Specification)

**功能**：座席管理 (Agent Management)  
**系統**：AICC-II（多租戶 SaaS 客服中心平台）  
**版本**：v1.0  
**產出日期**：2026-03-30  

---

## 功能概述

座席管理提供 Tenant Admin 統一管理所屬租戶下的座席帳號、分機分配、技能配置和帳號狀態，同時透過多租戶隔離和 RBAC 保障資料安全。Platform Admin 無法存取任何業務座席資料。

---

## 角色與權限

| 角色 | 可操作 | 不可操作 |
|------|------|--------|
| **Tenant Admin** | 本租戶座席 CRUD；技能分配；分機管理；狀態控制 | 跨租戶操作；修改自身權限 |
| **Platform Admin** | 平台監控指標（去識別化） | 任何業務座席資料 |
| **Agent User** | 查詢自身資料；修改密碼 | 修改他人資料；停用自身帳號 |

---

## User Story（8 則）

### US-001: 座席帳號查詢 ✅
**AC-001-01** 列表檢視：agent_id, agent_name, sip_extension, skill_groups, status, created_at  
**AC-001-02** 多欄位篩選：工號、姓名、分機、技能、狀態，支援 AND 組合  
**AC-001-03** 排序：按工號、建檔日期、最後登入時間  
**AC-001-04** 審計：log_audit_agent_search with AES-256 加密 & PII 遮罰

---

### US-002: 新增座席帳號 ✅
**AC-002-01** 表單驗證：必填（agent_code, agent_name, password）；password 強度 ≥12 字元含大小寫+數字+特殊符號；工號租戶內唯一  
**AC-002-02** SIP 分機綁定：驗證格式(1001-9999)、租戶內唯一，防重複  
**AC-002-03** 技能分配：驗證群組存在、等級 1-5、支援多技能  
**AC-002-04** 帳號初始化：status='pending'；密碼 bcrypt(cost≥12)；自動寄啟用郵件(24hr 連結)  
**AC-002-05** 多租戶隔離：tenant_id 自 JWT 萃取（禁止 Request Body）；403 if tenant_id 不符  
**AC-002-06** 審計：log_audit_agent_created, log_audit_skill_assigned；不落地明文

---

### US-003: 編輯座席帳號 ✅
**AC-003-01** 可編輯欄位：姓名、分機、聯繫電話、備註；禁編：工號、建檔日期、密碼  
**AC-003-02** 分機衝突檢查：新分機租戶內未佔用；支援分機轉移  
**AC-003-03** 技能調整：增刪技能或調整等級；變更立即生效  
**AC-003-04** 審計：log_audit_agent_updated with fields_changed, old_values, new_values；支援 30 筆歷史查詢

---

### US-004: 刪除座席帳號 ✅
**AC-004-01** 邏輯刪除：status='deleted', deleted_at=now(), deleted_by_admin_id；隱藏列表  
**AC-004-02** 刪除前校驗：檢查進行中通話、近 7 日操作記錄、技能/排班綁定  
**AC-004-03** 雙重確認：前端彈窗 + 後端 confirmation_token(30s 有效期)  
**AC-004-04** 刪除後行為：立即無法登入；Session/Token 失效；技能保留歷史；分機釋放  
**AC-004-05** 審計：log_audit_agent_deleted；7 年不可清除（金管會合規）

---

### US-005: 分機管理 ✅
**AC-005-01** 分機清單：sip_extension, bound_to_agent, last_active_time, status；支援篩選/排序  
**AC-005-02** 解綁操作：sip_extension = NULL；立即可重新分配；log_audit_sip_unbind  
**AC-005-03** 重新綁定：驗證分機格式、租戶內唯一、範圍檢查；log_audit_sip_bind  
**AC-005-04** 狀態監控：5 分鐘檢查一次；online/offline；24hr 未註冊→inactive；Tenant Admin 可檢視

---

### US-006: 帳號啟用/停用 ✅
**AC-006-01** 狀態轉移：pending→active / active→inactive / inactive→active；deleted 禁止轉移  
**AC-006-02** 停用行為：無法新登入；現有 Session 保持；新操作 403；無法承接新任務；現有工作可完成  
**AC-006-03** 啟用行為：可立即登入；納入分派規則；技能無損恢復  
**AC-006-04** 審計：log_audit_agent_status_change with old_status, new_status, reason(選填)

---

### US-007: 技能群組與等級管理 ✅
**AC-007-01** 技能清單：顯示本租戶群組、配置座席數；搜尋/篩選；禁止跨租戶顯示  
**AC-007-02** 多重配置：允許多技能；等級 1-5；支援新增/編輯/刪除；變更即刻生效  
**AC-007-03** 晉升流程：記錄舊新等級；版本控制；自動納入高難度分派規則  
**AC-007-04** 審計：log_audit_skill_assigned with skill_level, action(add/update/remove)；支援歷史查詢

---

### US-008: RBAC 權限控制 ✅
**AC-008-01** 權限矩陣：Tenant Admin 可執行本租戶 CRUD；Platform Admin 禁業務資料；Agent User 禁修改他人  
**AC-008-02** 多租戶隔離（技術）：tenant_id 自 JWT payload 萃取；WHERE tenant_id = JWT.tenant_id；403 若他租戶；禁 Platform Admin SQL 直查  
**AC-008-03** 異常處理：403/401 返回；log_audit_unauthorized_access；5 分鐘失敗 >5 次→鎖定 15 分鐘  
**AC-008-04** JWT 管理：user_id, tenant_id, role, permissions；RS256 簽名；access token 30min；refresh token 7 days；HttpOnly Cookie；無 PII

---

## 技術規範

### 資料庫

**agents 表**
- agent_id (UUID, PK)
- tenant_id (UUID, NOT NULL, FK) — 多租戶隔離
- agent_code (VARCHAR, NOT NULL) — 租戶內唯一
- agent_name, email, pii_phone (encrypted), sip_extension (UNIQUE), status, created_at, updated_at, deleted_at, last_login_at
- 索引：(tenant_id, agent_code), (tenant_id, status), (tenant_id, created_at DESC)

**agent_skills 表**
- skill_assignment_id (UUID, PK)
- agent_id, tenant_id, skill_group, skill_level (TINYINT 1-5), assigned_at, valid_until
- UNIQUE(agent_id, skill_group) 有效期間

**log_audit_* 表**
- audit_id, tenant_id, actor_id, resource_type, action, resource_id, old_values, new_values, ip_address, timestamp, result
- 保留 7 年；PII 動態遮罰

---

### API 端點

| 端點 | 方法 | 權限 |
|------|------|------|
| `/api/v1/agents` | GET | Tenant Admin |
| `/api/v1/agents/{id}` | GET/PUT/DELETE | Tenant Admin |
| `/api/v1/agents` | POST | Tenant Admin |
| `/api/v1/agents/{id}/status` | PATCH | Tenant Admin |
| `/api/v1/agents/{id}/skills` | GET/POST | Tenant Admin |
| `/api/v1/sip/extensions` | GET | Tenant Admin |

**Response Envelope**
```json
{
  "success": true,
  "data": {},
  "message": "OK",
  "errorCode": null,
  "timestamp": "2026-03-30T10:30:00Z",
  "requestId": "uuid"
}
```

**錯誤碼** (AICC-AG-001 ~ AICC-AG-010)
- AICC-AG-001: 必填欄位缺失
- AICC-AG-002: 座席工號/分機已存在
- AICC-AG-003: 無權限存取租戶
- AICC-AG-004: 座席不存在
- AICC-AG-005: 分機格式不合法
- AICC-AG-006: 分機被佔用
- AICC-AG-007: 密碼強度不符
- AICC-AG-008: 座席有進行中通話
- AICC-AG-009: JWT 過期/無效
- AICC-AG-010: 請求頻率超限 (Rate Limit)

---

## 安全規範

✅ **認證與授權**
- JWT (RS256) + Refresh Token 機制
- MFA (TOTP) —— 選用
- Session timeout: 30 分鐘
- 密碼重設歷史檢查（禁止重複 5 次）

✅ **多租戶隔離（P0 FSC 合規）**
- tenant_id 自 JWT 取得，禁止 Request Body
- 所有查詢強制 WHERE tenant_id = JWT.tenant_id
- 403 Forbidden 隱藏資源存在性

✅ **資料加密**
- TLS 1.3 傳輸
- AES-256-GCM 靜態存儲
- bcrypt (cost≥12) 密碼

✅ **SQL 注入防禦**
- PreparedStatement / ORM
- 應用層輸入驗證

✅ **XSS 防禦**
- 禁 `v-html`, `innerHTML`
- `Content-Security-Policy` header

✅ **CSRF 防禦**
- CSRF token for state-changing ops
- SameSite=Strict Cookie

✅ **速率限制**
- 登入：5 fail/15min → 15min 鎖定
- API：100 req/min per IP

✅ **審計日誌**
- 所有 CRUD 操作記錄
- 雜湊鏈驗證不可竄改
- 7 年保留（FSC 要求）
- PII 動態遮罰

---

## 非功能需求

| 指標 | 值 |
|------|-----|
| API 響應時間 | P95 ≤ 2s |
| 座席列表載入 | 10K 座席 ≤ 3s |
| 可用性 | 99.9% 月可用率 |
| 並發支援 | 1,000 concurrent req |
| 容量規劃 | ≤ 100K 座席/租戶 |
| RTO | ≤ 1 hr |
| RPO | ≤ 15 min |
| 備份頻率 | 6hr 全備 + 分鐘級增量 |
| 日誌保留 | 7 年審計；30 天應用日誌 |

---

## 部署規範

| 項目 | 規格 |
|------|------|
| Java | OpenJDK 17 LTS / Oracle JDK 21 |
| Spring Boot | ≥ 3.1.x |
| 資料庫 | MSSQL Server 2019+ |
| 緩存 | Redis 7.x |
| 部署 | Kubernetes 1.24+ / Docker Compose |
| 監控 | Prometheus + Grafana |

---

## 版本與簽核

| 版本 | 日期 | 狀態 |
|------|------|------|
| v1.0 | 2026-03-30 | 草稿 - 待 PM Lead 簽核 |

✅ **完整產出**：8 個 User Story、35+ 個 Acceptance Criteria、資料庫設計、API 規範、安全控制、非功能需求

所有細節均遵循 CLAUDE.md 中的：
- 多租戶隔離原則（tenant_id 自 JWT）
- RBAC 權限控制
- log_ 稽核日誌（7 年保留）
- 金管會 FSC 合規要求
- 資料加密標準（AES-256-GCM）
