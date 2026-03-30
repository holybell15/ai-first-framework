# 座席管理 需求規格
**版本**：RS-AGENT-MGT-v1.0  
**產品**：AICC-II（多租戶 SaaS 客服中心平台）  
**功能**：座席帳號管理（Agent Account Management）  
**狀態**：待審核  
**最後更新**：2026-03-30

---

## 1. 功能說明

Tenant Admin 在客服中心平台上通過座席管理功能進行座席帳號的完整生命週期管理（新增、查詢、編輯、刪除），並可綁定 SIP 分機、分配技能群組及技能等級、控制帳號啟用/停用狀態，同時系統強制執行多租戶隔離和基於角色的權限控制，確保 Platform Admin 無法存取任何業務資料。

---

## 2. 操作角色

| 操作 | Tenant Admin | 主管 | 座席 | Platform Admin |
|------|------|------|------|------|
| 新增座席帳號 | ✅ | ❌ | ❌ | ❌ |
| 查詢座席清單 | ✅ | ✅（限隸屬團隊） | ✅（僅查詢自己） | ❌ |
| 編輯座席資訊 | ✅ | ✅（限隸屬團隊） | ✅（編輯自己） | ❌ |
| 刪除座席帳號 | ✅ | ❌ | ❌ | ❌ |
| 綁定/解除 SIP 分機 | ✅ | ✅（限隸屬團隊） | ❌ | ❌ |
| 分配技能群組 | ✅ | ✅（限隸屬團隊） | ❌ | ❌ |
| 調整技能等級 | ✅ | ✅（限隸屬團隊） | ❌ | ❌ |
| 啟用/停用座席 | ✅ | ✅（限隸屬團隊） | ❌ | ❌ |
| 檢視座席稽核日誌 | ✅ | ❌ | ❌ | ❌ |
| 導出座席清單 | ✅ | ❌ | ❌ | ❌ |
| 批量停用/啟用【Phase 2】 | ✅ | ❌ | ❌ | ❌ |

---

## 3. 操作流程

### 3.1 新增座席帳號流程

1. 使用者點擊「新增座席」按鈕 → 系統展開新增表單
2. 使用者輸入電子郵件、姓名、電話、所屬團隊等必填欄位 → 系統即時驗證欄位格式與唯一性
3. 使用者選擇技能群組及對應技能等級（0-5 級） → 系統回顯已選項目
4. 使用者點擊「提交」→ 系統執行以下：
   - 驗證 tenant_id 權限（強制加入租戶隔離條件 WHERE tenant_id = :tenantId）
   - 檢查電子郵件唯一性（同租戶內不重複）
   - 檢查 SIP 分機唯一性（全平台唯一，若指定）
   - 使用 bcrypt（cost factor ≥ 12）生成臨時密碼雜湊
   - 建立座席帳號（初始狀態為 INACTIVE）
   - 寫入 log_seat_created 稽核日誌（記錄操作人、時間戳、建立者 ID）
   - 發送臨時密碼郵件至座席帳號（包含首次登入提示與密碼過期日期）

### 3.2 查詢座席清單流程

1. 使用者進入座席管理列表頁面 → 系統自動應用租戶隔離（WHERE tenant_id = :tenantId）
2. 系統載入該租戶下所有座席（分頁，預設 20 條/頁）
3. 使用者可按「狀態」（ACTIVE/INACTIVE）「所屬團隊」「技能群組」「最後登入時間」篩選 → 系統回顯符合結果
4. 使用者可按「建立日期」「最後登入」「座席名稱」等欄位排序 → 系統排序並展示
5. 結果列表展示：座席 ID、名稱、Email、團隊、SIP 分機、狀態、建立日期、最後登入

### 3.3 編輯座席資訊流程

1. 使用者選擇座席記錄，點擊「編輯」→ 系統載入座席詳情
2. 系統禁止編輯以下唯讀欄位：seat_id、tenant_id、created_by、created_at、deleted_at
3. 系統允許編輯：name、phone、team_id、role、password_expires_at（Tenant Admin 可重置密碼）
4. 使用者修改允許編輯的欄位 → 系統驗證修改內容
   - Email 修改時檢查同租戶內唯一性
   - Team_id 修改時檢查團隊存在性
5. 使用者點擊「保存」→ 系統：
   - 驗證租戶隔離和權限（只能編輯自己租戶的座席；主管只能編輯隸屬團隊的座席）
   - 更新資料庫記錄
   - 寫入 log_seat_updated 稽核日誌，記錄欄位變更前後值（old_value / new_value）
   - 清除相關 Redis 快取（若存在）

### 3.4 刪除座席帳號流程（邏輯刪除）

1. 使用者選擇座席，點擊「刪除」→ 系統展開確認對話，顯示警告「刪除後無法直接恢復，但可通過管理員還原」
2. 使用者確認刪除 → 系統執行以下檢查：
   - 檢查座席是否有進行中的工單（status = 'active' 或 'pending'）→ 若有則拒絕，提示具體工單數量和狀態
   - 檢查座席是否有活動連線（Redis 中是否存在 session_key） → 若有則強制斷開並記錄
   - 驗證租戶隔離和操作權限
3. 系統執行邏輯刪除：
   - 更新 status = 'deleted'，deleted_at = current_timestamp
   - 禁用該座席帳號（無法登入）
   - 寫入 log_seat_deleted 稽audit日誌
   - 保留所有歷史資料用於稽核

### 3.5 SIP 分機綁定流程

1. 使用者進入座席詳情頁，點擊「綁定 SIP 分機」→ 系統展開分機選擇器
2. 系統從資料庫或 Redis 快取中查詢「未被綁定的空閒分機清單」（is_active = false 且 unbound_at is null）
3. 系統只展示可綁定分機（最多 100 個，超出則分頁）
4. 使用者選擇分機號（如 8001）→ 系統即時驗證分機可用性（已被其他座席佔用則禁止選擇，並標記灰色）
5. 使用者點擊「確認綁定」→ 系統：
   - 驗證分機未被其他座席佔用（採用樂觀鎖 version 欄位）
   - 建立座席與分機的關聯（seat_id + sip_extension）
   - 更新分機狀態（is_active = true）
   - 寫入 log_sip_binding_created 稽核日誌
   - 清除 Redis 快取中的可用分機清單

### 3.6 SIP 分機解除綁定流程

1. 使用者進入座席詳情，點擊「解除綁定」→ 系統展開確認對話
2. 系統檢查該分機是否有活動通話 → 若有則提示「分機有活動通話，無法解除」
3. 使用者確認 → 系統：
   - 更新分機狀態（is_active = false，unbound_at = current_timestamp）
   - 清除座席與分機的關聯
   - 寫入 log_sip_binding_deleted 稽核日誌
   - 清除 Redis 快取

### 3.7 技能分配流程

1. 使用者進入座席詳情頁，點擊「技能分配」→ 系統展開技能矩陣
2. 系統查詢該租戶下所有可用的技能群組（group_status = 'active'），從 Redis 快取讀取（過期時間 1 小時）
3. 系統展示矩陣：技能群組名稱 | 當前等級（0-5 或「未設定」） | 修改操作
4. 使用者為每個技能群組選擇技能等級（下拉選單，選項：未設定 / 1 / 2 / 3 / 4 / 5） → 系統回顯選擇
5. 使用者可標記某個技能為「主要技能」（is_primary = true，最多 1 個） → 系統驗證
6. 使用者點擊「保存」→ 系統：
   - 驗證租戶隔離和權限
   - 檢查技能群組 ID 有效性
   - 使用事務（@Transactional）更新座席-技能關聯表（刪除舊紀錄，插入新紀錄）
   - 寫入 log_skill_assignment_changed 稽核日誌，記錄所有變更（包括刪除的技能和新增的技能）
   - 清除相關快取

### 3.8 啟用座席帳號流程

1. 使用者在列表中點擊座席的「啟用」按鈕 → 系統展開確認對話，顯示提示「啟用後，該座席將可以登入並接收工單」
2. 使用者確認 → 系統：
   - 驗證租戶隔離和操作權限
   - 更新座席狀態（status = 'ACTIVE'）
   - 重置登入失敗計數（failed_login_attempts = 0）
   - 若帳號被鎖定（is_locked = true），解除鎖定（is_locked = false）
   - 寫入 log_seat_status_changed 稽核日誌（記錄狀態變更：INACTIVE → ACTIVE）
   - 清除該座席的 Redis 快取（若存在）

### 3.9 停用座席帳號流程

1. 使用者在列表中點擊座席的「停用」按鈕 → 系統展開確認對話，顯示警告「停用後，該座席無法登入，所有活動連線將被斷開」
2. 系統檢查該座席是否有活動通話 → 若有則顯示「該座席有 N 個活動通話，停用後將被強制斷開」
3. 使用者確認 → 系統：
   - 驗證租戶隔離和操作權限
   - 更新座席狀態（status = 'INACTIVE'）
   - 查詢該座席在 Redis 中的所有 session_key，強制斷開所有連線（DELETE from Redis）
   - 取消該座席的所有待處理工單（status = 'pending' 改為 'unassigned'）
   - 寫入 log_seat_status_changed 稽audit日誌（記錄狀態變更：ACTIVE → INACTIVE，連線斷開數）
   - 清除該座席的 Redis 快取

---

## 4. 情境描述

### 情境 1 - 正常：新增座席並綁定 SIP 分機
**前置條件**：使用者為 TenantA 的 Tenant Admin，技能群組「Sales」已存在，SIP 分機 8001 未被佔用

**操作步驟**：
1. 進入座席管理頁面，點擊「新增座席」
2. 輸入：email=john@company.com, name=John Doe, phone=0912345678, team=Sales Team
3. 選擇技能：Sales Skill Level 4
4. 點擊「提交」
5. 系統成功建立座席，進入座席詳情頁
6. 點擊「綁定 SIP 分機」，選擇分機 8001
7. 點擊「確認綁定」

**預期結果**：
- 座席帳號建立成功，狀態為「已停用」（INACTIVE）
- 臨時密碼郵件已發送至 john@company.com，包含首次登入提示
- SIP 分機 8001 成功綁定至該座席
- 稽核日誌記錄：log_seat_created + log_sip_binding_created
- 座席詳情頁展示所有綁定資訊

### 情境 2 - 錯誤：Email 重複
**前置條件**：Email john@company.com 已存在於 TenantA 中

**操作步驟**：
1. 進入座席管理頁面，點擊「新增座席」
2. 輸入 email=john@company.com 和其他資訊
3. 系統即時驗證，Email 欄位下方顯示警告「此電子郵件已被使用」
4. 點擊「提交」

**預期結果**：
- 系統阻止提交，提示「此電子郵件在租戶內已被使用，請輸入不同的電子郵件」
- 表單保留已輸入的資料，僅 Email 欄位標紅
- 座席未建立
- 無稽核日誌產生

### 情境 3 - 錯誤：SIP 分機已被佔用
**前置條件**：SIP 分機 8001 已綁定至另一座席（同租戶或其他租戶）

**操作步驟**：
1. 進入座席編輯頁面
2. 點擊「綁定 SIP 分機」
3. 系統展開分機選擇器，分機 8001 應顯示為灰色且禁用
4. 強行嘗試選擇或通過 API 直接請求綁定 8001

**預期結果**：
- UI 中分機 8001 呈灰色禁用狀態
- 若使用者嘗試通過 API 或其他方式強行綁定，系統返回 409 Conflict 錯誤
- 提示「此 SIP 分機已被使用，無法綁定」
- 綁定失敗，稽核日誌記錄失敗嘗試

### 情境 4 - 邊界：刪除有活動工單的座席
**前置條件**：座席 Alice 有 1 個進行中的工單（status = 'active'），TenantA 內

**操作步驟**：
1. 進入座席管理列表
2. 選擇座席 Alice，點擊「刪除」
3. 系統展開確認對話，執行檢查
4. 座席有活動工單，對話中顯示警告
5. 使用者點擊「確認刪除」

**預期結果**：
- 系統拒絕刪除
- 提示「座席 Alice 有 1 個進行中的工單，狀態為：active。請先結束相關工單後再刪除座席」
- 提示「工單 ID：TICKET-12345，客戶：张三」（顯示工單詳情以便使用者查詢）
- 座席未被刪除，狀態保持不變
- 無刪除稽核日誌產生

### 情境 5 - 權限：Tenant Admin 無法查看其他租戶的座席
**前置條件**：
- User1 是 TenantA 的 Tenant Admin
- User2 是 TenantB 的 Tenant Admin
- TenantA 有座席 100 個，TenantB 有座席 50 個

**操作步驟**：
1. User1 登入系統
2. 進入座席管理頁面
3. 系統查詢座席清單
4. User1 嘗試通過 API（如 `/api/v1/agents?tenant_id=TenantB`）查詢 TenantB 的座席
5. User1 嘗試編輯某個已知的 TenantB 座席 ID（通過直接 URL 或 API）

**預期結果**：
- UI 中座席清單只展示 TenantA 的座席（100 個）
- API 查詢 TenantB 返回 403 Forbidden，提示「您無權存取其他租戶的資料」
- 直接編輯 TenantB 座席時，系統拒絕，返回 403 Forbidden
- 不展示任何 TenantB 座席的資訊
- 稽核日誌記錄此次非法存取嘗試（log_unauthorized_access）

### 情境 6 - 多租戶隔離：Platform Admin 完全無法存取座席管理
**前置條件**：使用者是 Platform Admin，全平台有 TenantA、TenantB、TenantC 等多個租戶

**操作步驟**：
1. Platform Admin 登入系統
2. 嘗試進入座席管理模組（UI 中無此選項，或點擊後被攔截）
3. 嘗試通過直接 API 端點查詢任何租戶的座席：`/api/v1/agents` 或 `/api/v1/agents/{agent_id}`
4. 嘗試通過後臺管理界面查詢座席資訊

**預期結果**：
- UI 中座席管理模組不展示或顯示為灰色禁用
- 所有 API 端點返回 403 Forbidden，提示「您沒有權限存取此模組」或「平台管理員無法存取業務資料」
- 不展示任何租戶的座席資訊，即使通過其他途徑嘗試
- 稽核日誌記錄此次非法存取嘗試（log_unauthorized_platform_admin_access）

### 情境 7 - 降級：停用座席時有活動連線
**前置條件**：
- 座席 Bob 當前在線（Redis 中存在 session_key）
- 座席 Bob 有 1 個活動通話（SIP/PBX 中狀態為 active）
- 座席 Bob 有 3 個待處理工單（status = 'pending'）

**操作步驟**：
1. Tenant Admin 進入座席管理列表
2. 選擇座席 Bob，點擊「停用」
3. 系統展開確認對話，顯示「該座席有 1 個活動通話，停用後將被強制斷開」
4. 使用者點擊「確認停用」

**預期結果**：
- 系統立即更新座席狀態為 INACTIVE
- Redis 中該座席的 session_key 被刪除，Bob 被強制登出（登出時間 < 1 秒）
- SIP/PBX 端的活動通話被掛斷
- 座席的 3 個待處理工單狀態改為 'unassigned'（自動分配給其他可用座席或進入待分配隊列）
- 稽審日誌記錄：log_seat_status_changed，包含「強制斷開連線 1 個，轉移工單 3 個」
- 座席列表中 Bob 的狀態立即更新為「已停用」

### 情境 8 - 合規：稽核日誌完整性與不可竄改性
**前置條件**：在座席 Grace 上執行以下操作：新增、綁定 SIP、分配技能、編輯資訊、停用

**操作步驟**：
1. Tenant Admin 新增座席 Grace（email=grace@company.com）
2. 綁定 SIP 分機 8003
3. 分配技能「Support」等級 5
4. 編輯座席，修改 phone 欄位
5. 停用座席 Grace
6. 檢視座席 Grace 的稽審日誌

**預期結果**：
- 稽審日誌包含 5 條完整記錄：
  1. log_seat_created（操作人、操作時間、建立者 ID）
  2. log_sip_binding_created（綁定人、綁定時間、分機號）
  3. log_skill_assignment_changed（操作人、操作時間、技能名稱、新等級）
  4. log_seat_updated（操作人、操作時間、欄位 phone，old_value=null，new_value=0912345678）
  5. log_seat_status_changed（操作人、操作時間、狀態變更 INACTIVE → INACTIVE，原因「Tenant Admin 操作」）
- 日誌記錄的操作人均為 Tenant Admin 帳號
- 日誌不可被刪除或修改（資料庫層級禁止 UPDATE/DELETE，僅允許 INSERT）
- 日誌包含時間戳（精確到毫秒）、IP 地址（若可用）

---

## 5. 欄位/參數規格

### 5.1 座席帳號主表（Seat）

| 欄位名稱 | 顯示名稱 | 型別 | 必填 | 限制 | 預設值 | 備註 |
|---------|---------|------|------|------|--------|------|
| seat_id | 座席 ID | UUID | 必填 | 系統自動生成，PK | — | 全平台唯一，不可修改 |
| tenant_id | 租戶 ID | UUID | 必填 | 強制加入查詢（WHERE tenant_id = :tenantId） | — | FK 至 Tenant 表，多租戶隔離關鍵，不可修改 |
| email | 電子郵件 | String | 必填 | RFC 5322 格式，同租戶內唯一，最大 255 字元 | — | 登入帳號，區分大小寫存儲但查詢時不區分大小寫 |
| name | 座席名稱 | String | 必填 | 1-50 字元，不含控制字符和 HTML 標籤 | — | 顯示用，支援中英文 |
| phone | 電話號碼 | String | 選填 | 格式驗證：\d{7,15}（7-15 位數字），最大 20 字元 | null | 聯絡方式，允許含 + 或 - |
| team_id | 所屬團隊 | UUID | 必填 | FK 至 Team 表，團隊必須存在 | — | 用於權限控制、篩選和報表，不可直接修改為 null |
| sip_extension | SIP 分機 | String | 選填 | 全平台唯一，格式驗證：\d{4}（4 位數字），最大 10 字元 | null | 綁定後不可修改，解除綁定後可重新綁定至其他座席 |
| status | 帳號狀態 | Enum | 必填 | 值：ACTIVE / INACTIVE / DELETED（邏輯刪除） | INACTIVE | 新建座席初始為 INACTIVE，DELETED 座席無法登入 |
| role | 角色 | Enum | 必填 | 值：AGENT / SUPERVISOR / MANAGER | AGENT | 用於 RBAC 權限控制，決定座席可執行的操作 |
| password_hash | 密碼雜湊 | String | 必填 | bcrypt（cost factor ≥ 12），最大 255 字元 | — | **禁止存儲明文密碼**，密碼變更時更新此欄位 |
| password_expires_at | 密碼過期時間 | Timestamp | 必填 | UTC 時間，初始值 = created_at + 90 天 | — | 超過此時間必須重新設定密碼，強制登出 |
| last_login_at | 最後登入時間 | Timestamp | 選填 | UTC 時間，自動更新於每次成功登入 | null | 用於檢測閒置帳號，可用於審計 |
| failed_login_attempts | 登入失敗次數 | Integer | 必填 | 整數，範圍 0-5，超過 5 次觸發鎖定 | 0 | 登入成功時重置為 0，失敗次數達 5 時自動鎖定帳號 24 小時 |
| is_locked | 帳號鎖定標記 | Boolean | 必填 | true / false | false | true 時座席無法登入，Tenant Admin 可手動解鎖 |
| locked_until | 鎖定期限 | Timestamp | 選填 | UTC 時間 | null | is_locked = true 時必須有此值，超過此時間自動解鎖 |
| created_by | 建立者 ID | UUID | 必填 | FK 至 User 表，記錄操作人 | — | 稽審追蹤，不可修改 |
| created_at | 建立時間 | Timestamp | 必填 | UTC 伺服器時間，精確到毫秒 | — | 不可修改 |
| updated_by | 最後更新者 ID | UUID | 必填 | FK 至 User 表 | — | 每次修改時自動更新 |
| updated_at | 最後更新時間 | Timestamp | 必填 | UTC 伺服器時間，精確到毫秒，自動更新 | — | 自動更新 |
| deleted_at | 刪除時間 | Timestamp | 選填 | UTC 伺服器時間，邏輯刪除時自動填入 | null | null 表示未刪除，軟刪除標記 |
| note | 備註 | String | 選填 | 最大 500 字元 | null | 管理員備註，如停用原因等 |

### 5.2 技能分配表（Seat_Skill_Assignment）

| 欄位名稱 | 顯示名稱 | 型別 | 必填 | 限制 | 預設值 | 備註 |
|---------|---------|------|------|------|--------|------|
| assignment_id | 分配 ID | UUID | 必填 | 系統生成，PK | — | — |
| seat_id | 座席 ID | UUID | 必填 | FK 至 Seat 表 | — | 座席刪除時該記錄級聯刪除或軟刪除 |
| skill_group_id | 技能群組 ID | UUID | 必填 | FK 至 Skill_Group 表，必須屬於同租戶 | — | — |
| tenant_id | 租戶 ID | UUID | 必填 | 強制加入查詢 | — | 冗余欄位，用於多租戶隔離查詢 |
| skill_level | 技能等級 | Integer | 必填 | 整數，範圍 0-5（0=未設定，1=初級，5=精通） | 0 | — |
| is_primary | 主要技能標記 | Boolean | 選填 | true / false | false | 座席最多 1 個主要技能，約束檢查於應用層和資料庫層 |
| created_at | 建立時間 | Timestamp | 必填 | UTC 伺服器時間 | — | — |
| updated_at | 最後更新時間 | Timestamp | 必填 | UTC 伺服器時間 | — | — |
| **複合索引** | — | — | — | (seat_id, skill_group_id)，唯一約束（同座席不可重複分配相同技能） | — | — |

### 5.3 SIP 分機綁定表（Seat_SIP_Binding）

| 欄位名稱 | 顯示名稱 | 型別 | 必填 | 限制 | 預設值 | 備註 |
|---------|---------|------|------|------|--------|------|
| binding_id | 綁定 ID | UUID | 必填 | 系統生成，PK | — | — |
| seat_id | 座席 ID | UUID | 必填 | FK 至 Seat 表，允許 null（分機未被綁定） | null | — |
| sip_extension | SIP 分機 | String | 必填 | 全平台唯一，格式 \d{4}，PK 或 UNIQUE 約束 | — | — |
| is_active | 啟用標記 | Boolean | 必填 | true / false | false | true 表示分機當前被綁定且可用 |
| bound_at | 綁定時間 | Timestamp | 選填 | UTC 伺服器時間 | null | is_active = true 時必須有值 |
| unbound_at | 解除時間 | Timestamp | 選填 | UTC 伺服器時間 | null | 記錄解除綁定的時間 |
| version | 樂觀鎖版本 | Integer | 必填 | 整數，每次更新自增 | 0 | 防止並行綁定衝突 |

### 5.4 稽審日誌表（Audit_Log_Seat）

| 欄位名稱 | 顯示名稱 | 型別 | 必填 | 限制 | 預設值 | 備註 |
|---------|---------|------|------|------|--------|------|
| log_id | 日誌 ID | UUID | 必填 | 系統生成，PK，不可修改 | — | — |
| tenant_id | 租戶 ID | UUID | 必填 | FK 至 Tenant 表 | — | 多租戶隔離 |
| seat_id | 座席 ID | UUID | 必填 | FK 至 Seat 表 | — | — |
| operation_type | 操作類型 | Enum | 必填 | CREATE / UPDATE / DELETE / STATUS_CHANGE / BINDING_CHANGE / SKILL_CHANGE / LOGIN / LOGOUT / ACCESS_DENIED | — | — |
| old_value | 變更前值 | String | 選填 | JSON 格式（若有多欄位變更），最大 2000 字元 | null | UPDATE 時必填 |
| new_value | 變更後值 | String | 選填 | JSON 格式，最大 2000 字元 | null | UPDATE/CREATE 時必填 |
| operator_id | 操作人 ID | UUID | 必填 | FK 至 User 表 | — | — |
| operator_email | 操作人 Email | String | 必填 | 存儲操作人 Email（冗余，便於查詢） | — | — |
| ip_address | 操作 IP 地址 | String | 選填 | IPv4 或 IPv6 格式 | null | 若可獲取 |
| user_agent | 用戶代理 | String | 選填 | HTTP User-Agent 頭，最大 500 字元 | null | 記錄操作工具（Web / Mobile 等） |
| timestamp | 操作時間 | Timestamp | 必填 | UTC 伺服器時間，精確到毫秒 | — | 不可修改，強制遞增 |
| status | 操作結果 | Enum | 必填 | SUCCESS / FAILURE | — | — |
| failure_reason | 失敗原因 | String | 選填 | 錯誤訊息，最大 500 字元 | null | status = FAILURE 時填入 |

---

## 6. 條件限制

### 6.1 安全條件

- **密碼管理**：所有座席密碼必須使用 bcrypt 雜湊（cost factor ≥ 12），禁止存儲明文密碼。初始密碼由系統隨機生成，臨時密碼通過郵件發送。
- **登入保護**：連續失敗登入 5 次後自動鎖定帳號 24 小時，Tenant Admin 可手動解鎖；超過此時間自動解鎖。
- **密碼過期**：初始密碼 90 天後過期，強制使用者在首次登入時重新設定密碼；定期密碼有效期應由組織政策決定（建議 180 天），實現【Phase 2】。
- **PII 保護**：所有 PII 欄位（email、phone、name）存儲時必須使用 AES-256-GCM 加密，傳輸時使用 TLS 1.3。
- **IDOR 防護**：所有 API 端點強制驗證 tenant_id、user_id 和操作權限，禁止通過修改 ID 直接存取其他租戶或無權限資料。例如，修改 API 參數 ?tenant_id=TenantB 應返回 403 Forbidden。
- **SQL 注入防護**：所有資料庫查詢使用參數化查詢（PreparedStatement / Parameterized Query），禁止字串拼接。
- **XSS 防護**：所有座席名稱、備註等使用者輸入欄位必須驗證，禁止包含 HTML 標籤或 JavaScript。前端使用框架內建轉義（Vue 的 v-text / {{ }} 自動轉義）。
- **CSRF 防護**：所有狀態修改操作（POST / PUT / DELETE）必須驗證 CSRF Token（同源檢查 + Cookie SameSite=Strict）。
- **帳號鎖定防護**：若座席帳號 status = DELETED，必須禁止登入；若 is_locked = true，必須拒絕登入並返回 423 Locked。
- **Session 管理**：座席登入後 Redis 中存儲 session_key（格式：seat:{seat_id}:{session_token}），有效期 8 小時，支援跨標籤頁同步登出【Phase 2】。
- **API 速率限制**：座席列表查詢 API 限制 100 req/min，防止列舉攻擊；登入端點限制 10 req/min。

### 6.2 合規條件

- **多租戶隔離**：所有資料庫查詢強制加入 WHERE tenant_id = :tenantId 條件，在資料庫層級由 Row-Level Security（RLS）政策強制執行，禁止應用層 bypass。
- **Platform Admin 隔離**：Platform Admin 應無法透過任何途徑（UI / API / 資料庫）存取任何租戶的業務資料（包括座席、工單、通話紀錄），返回 403 Forbidden。
- **稽審日誌完整性**：所有座席操作（建立、修改、刪除、狀態變更、技能變更、SIP 綁定、登入/登出、失敗的存取嘗試）都必須記錄到 log_seat_* 表。日誌內容包括：操作人、操作類型、操作時間、欄位變更前後值（old_value / new_value）。
- **稽審日誌不可竄改**：log_seat_* 表禁止 UPDATE 和 DELETE 操作（資料庫層級約束），僅允許 INSERT；日誌應存儲在只讀分片或區別存儲中。
- **角色權限雙重驗證**：RBAC 權限必須在 API 層和業務邏輯層雙重驗證。例如，主管編輯座席時，API 層驗證 team_id 匹配，業務層再驗證一次。
- **密碼重置審計**：Tenant Admin 重置座席密碼時，必須記錄至稽審日誌，標記為「password_reset_by_admin」。
- **FSC 合規**（金管會要求）：
  - **Auth_Identity_P0**：座席帳號支援 RBAC（Agent / Supervisor / Manager），禁止 hardcode 角色權限。
  - **欄位命名**：座席 email 和 phone 欄位應標記為 PII，存儲時使用 pii_ 前綴（邏輯前綴，資料庫存儲時加密）；所有稽審操作使用 log_ 前綴。
  - **定期稽核**：組織應每季度檢視座席管理稽審日誌，檢查異常存取。

### 6.3 效能條件

- **查詢效能**：座席列表查詢（含租戶隔離、團隊篩選、狀態篩選、技能篩選、排序）必須在 200ms 內完成。需在以下欄位上建立複合索引：
  - (tenant_id, status, team_id)
  - (tenant_id, sip_extension)
  - (tenant_id, created_at DESC)
- **緩存策略**：
  - 技能群組清單（Skill_Group）使用 Redis 快取，key 格式 skill_group:{tenant_id}，過期時間 1 小時；修改技能群組時清除快取。
  - 可用 SIP 分機清單使用 Redis 快取，key 格式 available_sip:{tenant_id}，過期時間 30 分鐘；綁定/解除分機時清除快取。
  - 座席詳情頁緩存，key 格式 seat:{seat_id}，過期時間 5 分鐘。
- **並行控制**：座席綁定 SIP 分機時採用樂觀鎖（version 欄位）防止並行沖突。若版本不匹配，返回 409 Conflict，提示「資料已被其他人修改，請重新整理」。
- **批量操作**【Phase 2】：支援批量停用/啟用座席，單次批量最多 1000 條；批量操作應使用非同步任務隊列（如 RabbitMQ / Redis），避免鎖表。
- **分頁策略**：座席列表預設分頁 20 條/頁，支援自訂 10-100 條/頁；禁止一次性加載超過 10,000 條座席（防止 OOM）。
- **資料庫連接池**：Seat 表連接池大小建議 20-30 連接（根據 QPS 調整），MSSQL 連接池應啟用。

### 6.4 多租戶條件

- **租戶隔離**：所有資料庫查詢強制加入 WHERE tenant_id = :tenantId，在 SQL 層由 Row-Level Security（RLS）政策強制執行，禁止應用層 bypass。
- **租戶初始化**：新租戶建立時自動初始化：
  - 預設團隊（Default Team）
  - 預設技能群組（默認為空，由 Tenant Admin 自行定義）
  - Platform Admin 帳號（用於平台管理，不可存取業務資料）
- **共用資源隔離**：
  - SIP 分機全平台唯一，允許多租戶共用分機池（若業務需要）。若分機池按租戶隔離，需在 Seat_SIP_Binding 表中強制加入 tenant_id 約束。
  - 技能群組按租戶隔離（FK 至 Tenant 表），租戶 A 無法存取租戶 B 的技能群組。
- **跨租戶防護**：禁止通過 API 查詢、修改、刪除其他租戶的座席資訊。所有跨租戶操作返回 403 Forbidden，並記錄至稽審日誌（operation_type = 'ACCESS_DENIED'）。
- **團隊權限隔離**：主管只能編輯隸屬團隊的座席，應用層應驗證 team_id，業務層應再驗證一次（防止邏輯漏洞）。

---

## 7. 驗收條件（AC）

| AC # | 驗證情境（含前置條件與操作步驟） | 預期結果 |
|------|------|------|
| AC-001 | **新增座席 - 必填欄位驗證** <br> 前置條件：使用者是 TenantA 的 Tenant Admin <br> 操作步驟：<br> 1. 進入新增座席表單 <br> 2. 僅輸入 email=john@company.com, name=John Doe <br> 3. 將 team_id 欄位留空（該欄位標記為必填） <br> 4. 點擊「提交」 | 系統驗證失敗，在 team_id 欄位下方提示紅色錯誤「所屬團隊為必填欄位」；表單保留已輸入的資料；提交按鈕保持可點擊；座席未建立；無稽審日誌產生 |
| AC-002 | **新增座席 - Email 格式驗證** <br> 前置條件：使用者是 TenantA 的 Tenant Admin <br> 操作步驟：<br> 1. 進入新增座席表單 <br> 2. 輸入 email=invalid-email（不符合 RFC 5322 格式） <br> 3. 輸入其他必填欄位（name, team_id） <br> 4. 點擊「提交」 | 系統驗證失敗，在 email 欄位下方提示紅色錯誤「電子郵件格式不正確，請輸入有效的電子郵件地址」；座席未建立 |
| AC-003 | **新增座席 - Email 唯一性驗證（同租戶內）** <br> 前置條件：TenantA 中已存在 email=john.doe@company.com 的座席 Alice <br> 操作步驟：<br> 1. 進入新增座席表單 <br> 2. 輸入 email=john.doe@company.com（與 Alice 重複） <br> 3. 輸入其他必填欄位 <br> 4. 點擊「提交」 | 系統驗證失敗，提示「此電子郵件在租戶 TenantA 內已被使用，請輸入不同的電子郵件地址」；座席未建立；無稽審日誌產生。備註：系統應支援大小寫不敏感比對（john@company.com 與 John@company.com 視為重複） |
| AC-004 | **新增座席 - SIP 分機全平台唯一性驗證** <br> 前置條件：<br> 1. TenantA 中座席 Alice 已綁定 SIP 分機 8001 <br> 2. TenantB 存在，無座席綁定 8001 <br> 操作步驟：<br> 1. 使用 TenantB 的 Tenant Admin 帳號登入 <br> 2. 新增座席 Bob，綁定 SIP 分機 8001 <br> 3. 點擊「確認綁定」 | 系統驗證失敗，提示「此 SIP 分機 8001 已在全平台使用，無法綁定」；座席 Bob 建立但 SIP 分機綁定失敗；稽審日誌記錄綁定失敗事件 |
| AC-005 | **多租戶隔離 - Tenant Admin 查詢隔離** <br> 前置條件：<br> 1. TenantA 有 50 個座席 <br> 2. TenantB 有 30 個座席 <br> 3. User1（TenantA Admin）和 User2（TenantB Admin）分別登入 <br> 操作步驟：<br> 1. User1 登入，進入座席列表頁 <br> 2. 驗證列表中座席數量 <br> 3. 嘗試通過 API 查詢 TenantB 座席：GET /api/v1/agents?tenant_id=TenantB <br> 4. User2 登入，進入座席列表頁，驗證列表 <br> 5. User1 嘗試直接 URL 存取 TenantB 座席詳情：/agents/tenantB-seat-id | **User1 結果**：座席列表只顯示 TenantA 的 50 個座席；API 查詢返回 403 Forbidden，提示「您無權存取其他租戶的資料」；直接 URL 存取返回 403 Forbidden。<br> **User2 結果**：座席列表只顯示 TenantB 的 30 個座席。<br> 兩者之間完全隔離，無法交叉查詢 |
| AC-006 | **多租戶隔離 - Platform Admin 存取拒絕** <br> 前置條件：<br> 1. 使用者是 Platform Admin <br> 2. 平台有 3 個租戶（TenantA, TenantB, TenantC），共 200+ 座席 <br> 操作步驟：<br> 1. Platform Admin 登入系統 <br> 2. 嘗試進入座席管理模組（UI 導航中是否展示） <br> 3. 嘗試通過 API 查詢座席列表：GET /api/v1/agents <br> 4. 嘗試通過 API 查詢特定座席詳情：GET /api/v1/agents/{seat_id} <br> 5. 嘗試通過後臺資料庫查詢座席資訊 | 所有操作返回 403 Forbidden，提示「平台管理員無法存取業務資料」；UI 中不展示座席管理模組（灰色禁用或隱藏）；不展示任何租戶的座席資訊；稽審日誌記錄多條「ACCESS_DENIED」事件，標記為 Platform Admin 非法存取嘗試 |
| AC-007 | **刪除座席 - 活動工單檢查** <br> 前置條件：<br> 1. 座席 Alice 有 2 個進行中的工單（status = active 或 pending）：<br>    - Ticket-001, 客戶: 張三, 主題: 產品諮詢 <br>    - Ticket-002, 客戶: 李四, 主題: 技術支援 <br> 2. 使用者是 TenantA 的 Tenant Admin <br> 操作步驟：<br> 1. 進入座席管理列表 <br> 2. 選擇座席 Alice，點擊「刪除」 <br> 3. 系統展開確認對話 <br> 4. 使用者點擊「確認刪除」 | 系統檢查座席 Alice 的活動工單，檢測到 2 個進行中工單；刪除被拒絕；提示「座席 Alice 有 2 個進行中的工單，無法刪除。請先結束以下工單：<br> - Ticket-001（張三 - 產品諮詢）<br> - Ticket-002（李四 - 技術支援）<br> 結束工單後可重新嘗試刪除」；座席 Alice 未被刪除，狀態保持不變；無 log_seat_deleted 稽審日誌產生 |
| AC-008 | **停用座席 - 活動連線斷開與工單轉移** <br> 前置條件：<br> 1. 座席 Bob 當前在線（Redis 中存在 session_key）<br> 2. 座席 Bob 有 1 個活動通話（SIP/PBX 狀態為 connected）<br> 3. 座席 Bob 有 3 個待處理工單（status = pending，都分配給 Bob）<br> 4. 使用者是 Tenant Admin <br> 操作步驟：<br> 1. 進入座席管理列表 <br> 2. 點擊座席 Bob 的「停用」按鈕 <br> 3. 系統展開確認對話，提示「該座席有 1 個活動通話」<br> 4. 使用者點擊「確認停用」 <br> 5. 驗證 Bob 在前端客戶端的登出狀態 <br> 6. 檢視稽審日誌 | 系統立即執行以下操作：<br> 1. 座席 status 改為 INACTIVE<br> 2. Redis 中 session_key 被刪除（< 1 秒）<br> 3. Bob 的前端客戶端立即登出，或提示「您的帳號已被管理員停用」<br> 4. SIP 通話被掛斷<br> 5. 3 個待處理工單轉移至「unassigned」狀態<br> 6. 稽審日誌記錄 log_seat_status_changed 事件：<br>    - operation_type: STATUS_CHANGE<br>    - old_value: {status: ACTIVE}<br>    - new_value: {status: INACTIVE, disconnected_sessions: 1, transferred_tickets: 3}<br>    - operator_id: [Tenant Admin ID]<br>    - timestamp: [精確到毫秒]<br> 7. 座席列表中 Bob 的狀態立即更新為「已停用」 |
| AC-009 | **技能分配 - 修改記錄稽審** <br> 前置條件：<br> 1. 座席 Charlie 已分配「Sales」技能群組，等級 3 <br> 2. 座席 Charlie 已分配「Support」技能群組，等級 1 <br> 3. Sales 技能標記為主要技能（is_primary = true）<br> 操作步驟：<br> 1. 進入座席 Charlie 的詳情頁 <br> 2. 點擊「技能分配」<br> 3. 修改 Sales 技能等級：3 → 5<br> 4. 修改 Support 技能等級：1 → 3<br> 5. 新增「Billing」技能，等級 2<br> 6. 點擊「保存」<br> 7. 檢視稽審日誌 | 系統成功更新技能分配；稽審日誌記錄 log_skill_assignment_changed 事件：<br> - operation_type: SKILL_CHANGE<br> - old_value: {skills: [{skill_group: Sales, level: 3, is_primary: true}, {skill_group: Support, level: 1}]}<br> - new_value: {skills: [{skill_group: Sales, level: 5, is_primary: true}, {skill_group: Support, level: 3}, {skill_group: Billing, level: 2}]}<br> - operator_id: [Tenant Admin ID]<br> - timestamp: [精確到毫秒]<br> 日誌應清晰顯示變更前後差異，支援比對 |
| AC-010 | **SIP 分機綁定 - 唯一性與解除流程** <br> 前置條件：<br> 1. 座席 Diana 已綁定 SIP 分機 8002（is_active = true）<br> 2. 座席 Edward 未綁定分機 <br> 3. 分機 8003 未被綁定<br> 操作步驟：<br> 1. 嘗試為座席 Edward 綁定分機 8002<br> 2. 解除座席 Diana 與 8002 的綁定<br> 3. 嘗試為座席 Edward 綁定分機 8002<br> 4. 驗證綁定歷史日誌 | **步驟 1**：系統檢測 8002 已被 Diana 使用，分機在 UI 中呈灰色禁用；綁定失敗，提示「此 SIP 分機 8002 已在使用中」<br> **步驟 2**：解除成功，稽審日誌記錄 log_sip_binding_deleted 事件（包含 binding_id、分機號、解除時間）<br> **步驟 3**：綁定成功，Edward 與 8002 關聯；稽審日誌記錄 log_sip_binding_created 事件<br> **步驟 4**：SIP 綁定歷史應顯示：<br>    - 2026-03-30 09:00: Diana 綁定 8002<br>    - 2026-03-30 10:00: Diana 解除綁定<br>    - 2026-03-30 10:05: Edward 綁定 8002 |
| AC-011 | **權限控制 - 主管只能編輯隸屬團隊的座席** <br> 前置條件：<br> 1. 主管 Manager1 管理「Sales 團隊」（team_id = TID-001）<br> 2. 座席 Frank 屬於「Support 團隊」（team_id = TID-002）<br> 3. Manager1 和 Frank 都屬於 TenantA<br> 操作步驟：<br> 1. Manager1 登入系統<br> 2. 進入座席管理列表，驗證 Frank 是否顯示<br> 3. 嘗試編輯座席 Frank 的資訊（如修改電話號碼）<br> 4. 嘗試通過直接 URL 或 API 編輯 Frank：PUT /api/v1/agents/frank-id | **步驟 2**：Frank 應顯示在列表中（Manager1 可查看全租戶座席），但操作按鈕（編輯、停用等）呈灰色禁用<br> **步驟 3**：點擊編輯按鈕無反應，或提示「您無權編輯此座席」<br> **步驟 4**：API 返回 403 Forbidden，提示「您無權編輯不屬於您管理團隊的座席」<br> 稽審日誌記錄 log_unauthorized_access 事件 |
| AC-012 | **稽審日誌完整性與不可竄改性** <br> 前置條件：<br> 1. 在座席 Grace 上執行以下 6 個操作：<br>    - 操作 1：新增座席 Grace<br>    - 操作 2：綁定 SIP 分機 8004<br>    - 操作 3：分配技能「Support」等級 4<br>    - 操作 4：修改座席 phone = 0912345678<br>    - 操作 5：停用座席<br>    - 操作 6：嘗試刪除（應失敗，因有待處理工單）<br> 2. 使用者是 Tenant Admin <br> 操作步驟：<br> 1. 執行上述 6 個操作<br> 2. 進入座席 Grace 的稽審日誌頁面<br> 3. 驗證日誌記錄完整性<br> 4. 嘗試編輯或刪除某條稽審日誌 | 稽審日誌應包含以下記錄（成功的 5 個 + 失敗的 1 個）：<br> 1. log_seat_created（seat_id, tenant_id, created_by, timestamp）<br> 2. log_sip_binding_created（binding_id, sip_extension, timestamp）<br> 3. log_skill_assignment_changed（old_value, new_value, timestamp）<br> 4. log_seat_updated（欄位 phone, old_value=null, new_value=0912345678, timestamp）<br> 5. log_seat_status_changed（old_value={status: ACTIVE}, new_value={status: INACTIVE}, timestamp）<br> 6. log_seat_deletion_failed（failure_reason=「座席有待處理工單」, timestamp）<br> 每條日誌包含：operation_type, operator_id, operator_email, timestamp（精確到毫秒），timestamp 應嚴格遞增<br> **不可竄改測試**：嘗試通過 API 或 SQL 修改或刪除日誌，系統應拒絕，返回 403 Forbidden 或資料庫約束錯誤 |

---

## Open Issues

| OI # | 問題 | 影響 | 狀態 |
|------|------|------|------|
| OI-001 | 座席帳號委派管理：座席權限是否支援下放給其他座席（如座席 A 可臨時代理座席 B 的工單）？ | 功能範圍不確定，可能涉及額外的業務邏輯 | 待確認 |
| OI-002 | 座席班表管理：座席排班、值班表是否應在此模組實現，或單獨為排班模組【Phase 2】？ | 功能邊界不清晰 | 暫定：否，屬於獨立排班模組 |
| OI-003 | 座席績效評分：是否需要在座席詳情頁展示績效指標（如滿意度、平均通話時長等）？ | 可能涉及額外的資料來源和計算 | 暫定：否，由報表模組提供 |
| OI-004 | SAML / SSO 整合：是否需要支援企業 SSO（如 Azure AD / Okta）供座席使用？ | 認證流程可能需要調整 | 暫定：否，由全局認證層負責 |
| OI-005 | 座席頭像/人員相片：是否需要支援座席頭像上傳和顯示【Phase 2】？ | 涉及文件存儲、CDN 配置 | 待確認 |
| OI-006 | 座席分組（Group）管理：除了「所屬團隊」外，是否支援更細粒度的分組（如小組）【Phase 2】？ | 功能複雜度增加，影響權限模型 | 待確認 |

---

## 【Phase 2】功能列表

- 多因素驗證（TOTP）：支援座席帳號啟用 TOTP，增強帳號安全性
- 異地備份：座席資訊每日自動備份至異地資料庫，用於災備
- 批量操作：支援批量停用/啟用座席，單次批量最多 1000 條，使用非同步任務隊列
- 跨標籤頁登出同步【Phase 2】：座席在一個標籤頁登出時，其他標籤頁自動登出
- 座席頭像支援【Phase 2】：支援座席頭像上傳、存儲、顯示
- 座席分組管理【Phase 2】：支援更細粒度的座席分組（小組層級）

---

**文件狀態**：草稿待 PM 評審 | **預計 Gate 1 審查日期**：待排期 | **版本號 SSOT**：memory/projects/new360.md
