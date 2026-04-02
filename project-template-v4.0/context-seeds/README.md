# 🎯 PROJECT_TEMPLATE — 通用版 Agent SEED 提示詞集

## 簡介

這個目錄包含 **11 個通用化的 SEED 提示詞檔案**，用於快速啟動不同角色的 Claude Agent。

每個 SEED 檔案都已將產品相關的具體細節替換為 **[佔位符]**，便於複用到任何新專案。

---

## 檔案清單與用途

| 序號 | 檔案名稱 | 角色 | 適用場景 | 輸出物 |
|------|---------|------|---------|--------|
| 1 | `SEED_Interviewer.md` | 需求訪談師 | 新功能想法討論、需求釐清 | 訪談摘要 |
| 2 | `SEED_PM.md` | 產品經理 | 將訪談轉化為 RS、User Story | RS 文件、優先級清單 |
| 3 | `SEED_UX.md` | UX 設計師 | 用戶旅程、頁面流程、Wireframe | 用戶旅程圖、Wireframe |
| 4 | `SEED_Architect.md` | 系統架構師 | 架構設計、技術選型、ADR | 技術決策記錄（ADR） |
| 5 | `SEED_Frontend.md` | 前端工程師 | UI 元件實作、頁面開發 | 可執行的 HTML / 框架程式碼 |
| 6 | `SEED_Backend.md` | 後端工程師 | API 設計、商業邏輯、AI 整合 | API 規格文件、程式碼 |
| 7 | `SEED_DBA.md` | 資料庫管理師 | 資料模型設計、Schema | 資料表設計、ERD |
| 8 | `SEED_DevOps.md` | 部署工程師 | 環境建置、CI/CD、部署 | Dockerfile、設定檔、部署指令 |
| 9 | `SEED_QA.md` | QA 工程師 | 測試計劃、測試案例、Bug 回報 | 測試計劃、Test Cases |
| 10 | `SEED_Security.md` | 資安專家 | 資安審查、合規確認 | 安全審查報告 |
| 11 | `SEED_Review.md` | 總審查官 | Code Review、文件審查 | Review 報告、改進建議 |

---

## 使用流程

### 第 1 步：複製並更新佔位符

在使用任何 SEED 之前，請將檔案中的 **[佔位符]** 替換為實際內容：

```markdown
[產品名稱]         → 你的產品名稱
[SaaS / App / ...] → 實際產品類型
[前端]             → 例：Vue 3
[後端]             → 例：Java Spring Boot
[資料庫]           → 例：MySQL + MSSQL
[雲端]             → 例：Google Cloud Platform
[技術背景描述]     → 例：軟體工程師、15 年經驗
```

### 第 2 步：貼到新對話的開頭

在 Claude.ai 建立新對話，將更新後的 SEED 內容貼到開頭，Claude 就會進入該角色模式。

### 第 3 步：按需求輸出

每個 Agent 會根據需求輸出對應的文件或程式碼，交付到指定位置。

---

## Agent 協作流程示例

### Pipeline: 需求訪談 → 規格文件

```
1. Interviewer Agent：進行需求訪談 → 輸出《訪談摘要》
2. PM Agent：整理 User Story、AC → 輸出《RS 文件》
3. 存檔位置：02_Specifications/RS-[編號].md
```

### Pipeline: 功能設計 → 系統架構

```
1. UX Agent：設計用戶旅程、Wireframe → 輸出《用戶旅程圖》
2. Architect Agent：評估技術方案 → 輸出《ADR 決策記錄》
3. DBA Agent：設計資料模型 → 輸出《Schema 設計》
4. 存檔位置：03_System_Design/
```

### Pipeline: 開發實作 → 交付

```
1. Frontend Agent：實作 UI 元件 → 輸出《HTML/Vue 程式碼》
2. Backend Agent：實作 API 與邏輯 → 輸出《API Spec 與程式碼》
3. QA Agent：撰寫測試計劃 → 輸出《測試案例》
4. Review Agent：Code Review → 輸出《Review 報告》
5. 存檔位置：01_Product_Prototype/ + 程式碼倉庫
```

---

## 佔位符速查表

### 產品信息

| 佔位符 | 說明 | 範例 |
|--------|------|------|
| `[產品名稱]` | 你的產品或專案名稱 | AICC-X、訂單管理系統 |
| `[SaaS / App / ...]` | 產品類型 | SaaS、內部工具、行動應用 |
| `[負責人背景]` | 溝通物件的技術背景 | 軟體工程師、產品經理、CEO |

### 技術棧

| 佔位符 | 說明 | 範例 |
|--------|------|------|
| `[前端框架]` | 前端技術棧 | Vue 3、React、Flutter |
| `[後端框架與語言]` | 後端技術 | Java Spring Boot、Node.js Express |
| `[主資料庫]` | 主資料庫 | MySQL 8.0、PostgreSQL |
| `[整合資料庫]` | 輔助資料庫（可選） | Redis、MongoDB、MSSQL |
| `[雲端平台]` | 部署雲端 | Google Cloud Platform、AWS、Azure |
| `[AI 整合]` | AI 方案 | OpenAI API、Claude API、Gemini API |

### 法規與環境

| 佔位符 | 說明 | 範例 |
|--------|------|------|
| `[適用法規]` | 合規要求 | 個資法、GDPR、金融法規 |
| `[環境]` | 部署環境 | dev、staging、prod |

---

## 文件格式標準

### 輸出位置約定

所有輸出物應遵循以下資料夾結構：

```
PROJECT_ROOT/
├── 01_Product_Prototype/     ← Frontend 產出：HTML、Prototype
├── 02_Specifications/        ← PM、QA 產出：RS、測試計劃
├── 03_System_Design/         ← Architect、DBA、Backend、DevOps 產出
├── 04_Compliance/            ← Security、Review 產出
├── 05_Archive/               ← 舊版文件
├── 06_Interview_Records/     ← Interviewer 產出
└── memory/                   ← 跨 session 記憶庫
```

### Markdown 文件命名規則

- RS 文件：`RS-[編號]_[功能名稱].md`
- 訪談記錄：`[日期]_[功能名稱]_訪談摘要.md`
- 架構決策：`ADR-[編號]_[決策主題].md`
- 資料設計：`DB_[功能名稱]_Schema.md`
- API 規格：`API_[功能名稱]_Spec.md`
- 測試計劃：`QA_[功能名稱]_TestPlan.md`
- 安全報告：`Security_[功能/日期]_審查報告.md`

---

## 快速開始

### 步驟 1：複製 SEED 內容

選擇對應的 SEED 檔案，複製其內容。

### 步驟 2：替換佔位符

編輯複製的內容，將 `[XXX]` 改為實際值。

範例：
```diff
- 你是 [產品名稱] 產品團隊的...
+ 你是 KanbanBoard 產品團隊的...

- 前端：[前端框架]
+ 前端：Vue 3
```

### 步驟 3：在 Claude 新對話中貼上

在 Claude.ai 開啟新對話，將更新後的 SEED 貼到最上方。Claude 會自動進入該角色。

### 步驟 4：開始互動

按照 SEED 中的提示進行對話，Claude 會產出對應的文件或程式碼。

---

## 常見問題

### Q: 我可以修改 SEED 的內容嗎？

**A:** 可以。SEED 只是範本，你可以根據專案需求調整：
- 修改驗收條件格式
- 調整輸出位置
- 新增專案特定的規範

### Q: 多個 Agent 協作時如何交接？

**A:** 建議在 `TASKS.md` 中記錄每個 Agent 的產出與下一步：
```markdown
| Task-1 | Interviewer 完成 | 訪談摘要 | ✅ | 交接給 PM：確認目標用戶與AC |
| Task-2 | PM 完成 | RS-001 | ✅ | 交接給 UX：開始設計流程 |
```

### Q: 如果需求中途改變怎麼辦？

**A:** 透過 Interviewer 或 PM Agent 重新訪談或修改 RS，其他 Agent 的輸出會相應調整。

### Q: 這些 SEED 可以用在多個專案嗎？

**A:** 完全可以。這正是通用版的設計目標。每個新專案只需替換佔位符即可。

---

## 版本與更新

- **版本**：1.0（2026-03-08）
- **適用產品模板**：PROJECT_TEMPLATE
- **建議更新週期**：每季度檢視一次，根據實際專案經驗微調

---

## 相關資源

- 詳見項目 `CLAUDE.md` 主導航
- 記憶庫位置：`memory/`
- 決策記錄：`memory/decisions.md`
- 任務清單：`TASKS.md`

