# 接力摘要 - 上次做到哪裡

> 每次結束工作前更新這裡，下次開始時先讀這個檔案。

---

## 📌 UI Prototype 功能索引（每次完成新功能後更新此表）

> 此表取代硬寫檔名——配合 CLAUDE.md 的 `ls -t` 找法使用。

### 主控台（座席畫面）`AICC-X_主控台_*.html`  ← 最新版：v0.9

| 功能 | 狀態 | 加入版本 | 說明 |
|------|------|---------|------|
| Top Bar（Session Chips / Channel 狀態 / 通知 / 頭像）| ✅ | v0.3 | Light Theme，可捲動 Chips |
| Sidebar（Left Toolbar）| ✅ | v0.5 | 56px 可展開，IA：首頁/歷史記錄/客戶/案件 |
| 中欄 CRM（12 區段完整版）| ✅ | v0.3 | 進線資訊、文書 ACW、服務代碼等 |
| 來電彈窗（.slide-panel）| ✅ | v0.3 | Phase 0→1→2 漸進式載入 |
| 右欄 AI 輔助（情緒偵測 / KB）| ✅ | v0.3 | 3 情境 demo |
| Control Strip（Footer）| ✅ | v0.3 | 深色唯一例外 |
| 外撥搜尋 B1（鍵盤撥號 + 客戶搜尋 + ob-header）| ✅ | v0.3 | 7 狀態機 |
| 儀表板（首頁 view-dash）| ✅ | v0.4 | 整合自儀表板 v0.3 |
| 歷史記錄（view-history）| ✅ | v0.5 | 列表 + 詳細（Agent 服務軌跡）|
| Footer Bar v2（Light Theme）| ✅ | v0.6 | 語音/Chat/視訊渠道 + hover flyout |
| 客戶查詢（view-customer）| ✅ | v0.7 | 列表 + 詳細（3 Tab）+ 新增客戶 Modal + 撥號 |
| 案件系統（Zendesk 風格，view-cases）| ✅ | v0.9 | 4 分頁 + 會話 Thread + 右側欄可編輯屬性 |
| Demo Bar 收合/展開功能 | ✅ | v0.9 | dc-tab 下掛 tab，translateY 滑動動畫 |
| CRM ↔ Demo 流程整合 | ✅ | v0.9 | 進線響鈴自動開 Panel，接聽後 CRM 動態更新 |

### 儀表板 `AICC-X_儀表板_*.html`（已整合進主控台，獨立檔案不再更新）

### 後台管理 `AICC-X_後台_*.html`  ← 最新版：v0.1

| 功能 | 狀態 | 加入版本 | 說明 |
|------|------|---------|------|
| 即時監控（KPI + 渠道隊列 + 座席狀態 Grid）| ✅ | v0.1 | 16 位座席 Mock，即時狀態色彩 |
| 座席管理（列表 + 篩選 + 新增 Modal）| ✅ | v0.1 | 8 筆 Mock，角色/技能組 |
| 歷史報表（KPI + SVG 長條圖 + 績效表）| ✅ | v0.1 | 10 筆 Mock，CSAT 熱圖色 |
| 系統設定（技能組 / IVR / 公告 / AI 參數）| ✅ | v0.1 | 4 子 Tab 完整展示 |
| Demo Bar（角色切換 / 視圖切換 / 收合）| ✅ | v0.1 | 權限依角色動態顯示 nav |

---

## 最後更新
- **日期**：2026-03-13（GSD 工作流程整合完成）
- **執行 Agent**：系統維護（Cowork）
- **工作模式**：workflow_rules.md 擴充 + SEED/SKILL/CLAUDE.md/Dashboard 聯動更新 + md5 跨專案一致性
- **本次方法論版本**：v2.2（workflow_rules.md §32-§37 新增）

---

## ✅ 本次完成（2026-03-13 GSD 整合）

### GSD 工作流程整合（6 大機制，均整合進 workflow_rules.md §32-§37）

1. **§32 Context Rot 防護（CHC）**：CHC-01~03 需求對齊/決策一致/術語漂移自檢；CR-01~04 Context 隔離執行原則；長對話提示開新 session
2. **§33 Discuss Phase（實作偏好鎖定）**：P01→P02 技術偏好確認；P03→P04 實作偏好確認；結果寫入 decisions.md/SEED
3. **§34 Plan Checker（LPC）**：5 維度自檢（完整性/可行性/一致性/可驗證性/範圍控制），最多 3 輪，LPC-UNRESOLVED 機制
4. **§35 Nyquist 驗證層（NYQ）**：PM 在每條 AC 附驗證提示（驗證方式+預期測試指令+邊界條件）；QA 從 AC 驗證提示開始設計 TC
5. **§36 自動修復迴圈（AFL）**：Step 4 Verify 失敗 → debug → fix plan → re-verify，最多 3 輪後 git reset 回退
6. **§37 Quick Mode 快速通道（QM）**：5 條件判斷（≤3檔/無新功能/無Schema變更/無API介面變更/5分鐘可驗證）；Sprint 上限 10 次

### 聯動更新
- **pipeline-orchestrator SKILL.md**：加入 Quick Mode 判斷、CHC 聲明、Discuss Phase 提示
- **SEED_PM.md**：AC 格式新增「驗證提示」欄位（NYQ-01）；自我審查新增 LPC+NYQ 檢查
- **SEED_QA.md**：Pre-check 加 P5 NYQ-02 確認；加入 AC-TC 追溯矩陣和 NYQ Smoke Test 說明
- **SEED_Review.md**：Gate 1 加 G1-NYQ；Gate 3 加 G3-QM1~3/G3-CHC/G3-AFL
- **CLAUDE.md**：Pipeline 定義加入 LPC/CHC/Discuss/NYQ/AFL/QM 節點說明；新增「GSD 快速參考」表格
- **PROJECT_DASHBOARD.html**：Agent Tab 新增「⚡ GSD 工作流程增強機制」區塊（6 張紫色卡片）；div 平衡 668/668

### 同步完成
- 4 個專案 7 個檔案 md5 全一致：AICC-X / TimeX / _PROJECT_TEMPLATE / Softphone_Demo

---

## ✅ 前次完成（2026-03-11 Dashboard v2.2+ 改版）

### Dashboard 結構改善
1. **G4-ENG Gate 樣式統一**：新增 `--gate4eng` CSS 變數，移除特殊 border/font，與 G1/G2/G3 一致
2. **G1/G2/G3 獨立 Gate 區塊**：Pipeline 之間新增獨立 Gate badge（雙重顯示：footer + standalone block）
3. **Review Agent 全覆蓋**：P01/P03/P04 加入 Review Agent（P02/P05/P06 已有）
4. **Gate Tab G3 樣式修復**：改用 `.gate-cols` class + 3 欄 CSS override
5. **Retro Tab 強制標記**：L1/L2/L3 加紅色「（強制執行）」
6. **Agent Tab Skill 目錄**：新增「自動化 Skill 目錄」區段，14 個 Skill 卡片含描述/觸發時機/關聯 Agent
7. **Agent 卡片 Skill 描述**：展開 Agent 卡片可看到每個 Skill 的中文說明
8. **健康儀表板升級**：功能顯示完整名稱（featureNames）、文件類型 5→9 種、缺少文件摘要區塊

### 同步完成
- 4 個專案一致：AICC-X / TimeX / _PROJECT_TEMPLATE / Softphone_Demo

---

## ✅ 前次完成（2026-03-10 本 session）

### 1. 案件 JS 語法三大 Bug 修復
1. **onclick data-id**：`csRenderList` 的 tr 原用 `caseOpenDetail(''+c.id+'')` → 改為 `data-id=` attribute + `caseOpenDetail(this.dataset.id)`
2. **onchange data-prop**：`csPropChange('status',this.value)` 引號衝突 → 改為 `data-prop="status" onchange="csPropChange(this.dataset.prop,this.value)"`
3. **csDial 引號衝突**：`csToast()` 在 onclick 裡衝突 → 改為獨立 `csDial()` 函數，讀取 `_csCurrent.custPhone`

### 2. Demo Bar 收合/展開功能
- **設計**：bar 右下角掛 `.dc-tab` 按鈕，`position:absolute; bottom:-22px` 自然下掛
- **收合**：`translateY(-100%)` 動畫（0.22s cubic-bezier），bar 滑出視口，tab 停在頂端可見
- **展開**：再點 tab，bar 滑回，chevron 圖示旋轉 180°
- **JS**：`toggleDemoBar()` 切換 `dc-hidden` class

### 3. CRM ↔ Demo 接聽流程整合
- **`CRM_CALLERS` 資料物件**：idle（王小明）/ known（林小華 VIP）/ unknown（未知）三種狀態
- **`loadCrmCaller(key)`**：動態更新 avatar、姓名、UID、標籤、欄位 grid；含 highlight 動畫
- **`setTopbarScenario` 擴充**：
  - ringing → 自動 `simulateIncoming('known')`
  - voice1/vc/max → `closeSlidePanel()` + `loadCrmCaller('known')`
  - idle → `closeSlidePanel()` + `loadCrmCaller('idle')`
- **Slide Panel 接聽/拒接按鈕**：新增 `.sp-answer-bar`，`spAnswerCall()` / `spRejectCall()` 同步 demo bar active 狀態
- **`answerCall()` 整合**：接聽後自動呼叫 `loadCrmCaller('known')`
- **SCENARIOS 統一**：ringing/voice1 的 name 統一改為「林小華」，與 slide panel 資料一致

### 4. UX 文件同步
- 產出 `03_System_Design/F00_UX_主控台原型_v0.9.md`（完整 UX spec）
- 更新 `memory/product.md`（功能現狀 + 設計語言）
- 更新 `memory/decisions.md`（新增 D004–D006）

---

## ⬜ 下一步（優先順序）

1. **後台管理頁面 v0.1** ✅ 完成
2. **案件與客戶跨頁連結**：案件詳細頁側欄可點擊跳至客戶查詢頁
3. **Chat 渠道 CRM 整合**：類似語音，Chat 進線時也觸發 slide panel + CRM 更新
4. **後台 v0.2 可選方向**：即時監控座席卡片點擊（展開詳細）/ 報表匯出邏輯 / 公告新增 Modal

---

## 設計系統決策彙整（v0.9 確認版）

| 項目 | 決策 |
|------|------|
| 主題 | 全面 Light Theme |
| 主色 | `--primary: #1B5FD6` |
| 頁面背景 | `--bg-page: #F1F5F9` |
| 邊框色 | `--border: #E2E8F0` |
| Top Bar | `background:#fff; border-bottom:1px solid var(--border)` |
| Sidebar | `background:#fff; width:56px`（展開 200px）|
| Control Strip | `background:linear-gradient(135deg,#0F172A,#1E293B)`（深色唯一例外）|
| Footer Bar | `background:#fff; border-top:1px solid var(--border); height:40px` |
| Card border-radius | `border-radius:0`（全面直角）|
| 所有視圖 padding | `0`（dash / hist / CRM / customer / cases 均無 padding）|
| 圖示規範 | `stroke-width:1.75`，inline SVG，ICONS 物件取 path，禁外部 CDN |
| 欄位樣式 | `cf-lbl`（10px 灰色大寫）+ `cf-val`（13px 標準色）|
| Demo Bar | `background:#0F172A`（深色），`height:32px`，可收合 |

---

## 技術注意事項
- overflow:hidden 不加在有 tooltip/dropdown 的父元素
- 禁用外部 CDN（包括 Lucide CDN）
- 注入 JS 時必須包 `<script>...</script>` tag
- CSS anchor 字串必須是唯一且精確的，建議用 ID selector 而非 comment
- Python 字串裡的 `\n` 直接注入 HTML 會變成真實換行，破壞 JS 字串字面量 → 需事後修復或改用 `\\n`
- onclick 屬性內的 JS 函數若有字串引數，會與外層 JS 字串引號衝突 → 一律改用 `data-*` attribute 傳值
- 多租戶：所有業務資料功能需有 tenant_id 隔離
