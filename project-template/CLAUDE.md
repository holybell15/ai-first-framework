# CLAUDE.md — [專案名稱] 專案導航

> 每次新對話開始時，先讀這個檔案。
> 使用前請將所有 `[佔位符]` 替換為實際內容。

---

## 🧑‍💻 團隊協作快速入口

> 多人協作時，每次開工前：

```bash
git pull          # 1. 取最新狀態
```

```
/info-task-master      # 2. 讓 Task-Master 判斷現在該做什麼（或說「執行 Task-Master」）
```

Task-Master 會自動讀取 `memory/STATE.md` + `TASKS.md`，輸出派遣報告告訴你下一步。
不需要手動翻文件。

**啟動你的角色：** 見 `TEAM.md` → 各角色啟動指令

| 我是... | 讀取這個 Seed |
|---------|-------------|
| PM | `context-seeds/SEED_PM.md` |
| UX | `context-seeds/SEED_UX.md` |
| Architect | `context-seeds/SEED_Architect.md` |
| DBA | `context-seeds/SEED_DBA.md` |
| Backend | `context-seeds/SEED_Backend.md` |
| Frontend | `context-seeds/SEED_Frontend.md` |
| QA | `context-seeds/SEED_QA.md` |
| Security | `context-seeds/SEED_Security.md` |
| DevOps | `context-seeds/SEED_DevOps.md` |
| Review（Gate）| `context-seeds/SEED_Review.md`（新 session！）|

**完成後交接：** `git commit` → 通知下一位 → 更新 `memory/STATE.md` 的 `handoff_to`
詳細協議見 `TEAM.md`

---

## 🚀 新專案啟動流程（第一次使用必讀）

> 拿到這個 template 後，依序完成以下 5 個步驟，之後就可以正常開始工作。

**Step 1 — 替換專案資訊**
- 將本檔案（CLAUDE.md）中所有 `[專案名稱]` 替換為實際名稱
- 填寫「產品概覽」表格
- 更新 `memory/product.md`

**Step 2 — 設定設計系統主色**
- 打開 `01_Product_Prototype/components/comp_design_system.html`
- 修改 `:root` 中的 `--color-primary`（及 hover/light 色）為本專案主色
- 同步修改 `comp_base_template.html` 中的同名變數

**Step 3 — 確認技術棧**
- 更新 `memory/product.md` 的技術棧欄位
- 更新 11 個 SEED 檔案中的 `[佔位符]`（至少更新 SEED_Architect / SEED_Frontend / SEED_Backend）

**Step 4 — 建立術語表**
- 打開 `memory/glossary.md`，填入本專案的核心術語

**Step 5 — 初始化標準文件**
- 開啟 `10_Standards/DB/enum_registry.yaml`，清除範例 ENUM，填入本專案的業務 ENUM 值
- 開啟 `10_Standards/API/Error_Code_Standard_v1.0.md`，確認錯誤碼前綴已替換（`new-project.sh` 自動完成）
- 複製 `.env.example` 為 `.env`（`cp .env.example .env`），填入真實密鑰，**禁止 commit .env**

**Step 6 — 登記第一個 F-code，開始第一個 Pipeline**
- 在 `MASTER_INDEX.md` 的「F-code 分配登記」表格新增第一個 Feature
- 執行 `Pipeline: 需求訪談`，從 Interviewer Agent 開始

---

## 🔍 修改 PROJECT_DASHBOARD.html 前必做

> **禁止直接開始改**。先讀以下文件，確認你理解現有結構。

```
Read memory/dashboard.md
```

此文件記錄：Tab 結構、PROJECT_STATUS 物件欄位、所有 render 函式用途、CSS class 對照、Agent 比對邏輯、修改守則。

**改完後必須驗證 `<div>` 平衡（應為 455 對，diff = 0）。**

---

## ⚠️ UI 元件設計強制規則（違反即為錯誤）

### 新建任何 HTML 元件前，必須：
1. **先 Read** `01_Product_Prototype/components/comp_base_template.html`
2. **複製該檔案**作為起點，不得從空白 HTML 開始
3. **確認 `ICONS` 物件和 `svg()` 函式**已複製進新檔案

### 圖示（Icon）強制規範：
- `stroke-width: 1.75`（不得用 1.5 或 2）
- `fill: none`、`stroke-linecap: round`、`stroke-linejoin: round`
- 所有 icon path 從 `ICONS` 物件取，**不自行撰寫 SVG path**
- **禁止**任何外部 CDN icon library

### 設計系統參考：
- 色票、按鈕尺寸、Chip 狀態 → `comp_design_system.html`
- 完整 icon 目錄 → `comp_design_system.html` Section 2

---

## 產品概覽

| 欄位 | 內容 |
|------|------|
| **名稱** | [產品名稱] |
| **類型** | [SaaS / App / 內部工具 / ...] |
| **目標用戶** | [B2B / B2C / 內部] |
| **技術棧** | [前端框架] / [後端框架] / [資料庫] / [雲端平台] |
| **階段** | [概念期 / 規格期 / 開發期 / 上線期] |

詳見 → `memory/product.md`

---

## Agent 路由表

> **不知道從哪開始？** 先執行 `/info-task-master`

| 我的需求 | 指令 |
|----------|------|
| **不知道從哪開始 / 任務衝突 / 有新功能要加入** | `/info-task-master` |
| **有功能被 block / 多條線並行不知優先級** | `/info-task-master` |
| **單獨啟動某個 Agent** | `/info-agent`（選單）或 `/info-agent [名稱] [F##]`（直接啟動） |
| 啟動任何 Pipeline | `/info-pipeline`（選單） |
| 緊急線上問題 | `/info-hotfix` |

---

## Skill 路由表（自動化技能套件）

> 每個 Agent 的 SEED 檔已設定在對應時機自動讀取 skill。也可手動觸發：「請讀取 `context-skills/[skill-name]/SKILL.md`」

### 開發流程 Skill（obra/superpowers 系列）

| 情境 | Skill | 自動觸發時機 |
|------|-------|-------------|
| 寫測試/TDD/紅綠重構 | `context-skills/test-driven-development/` | P04 Backend / Frontend Agent 實作時 |
| 遇到 Bug/測試失敗/除錯 | `context-skills/systematic-debugging/` | 任何 Agent 遇到非預期錯誤 |
| 開新 Feature 分支 | `context-skills/using-git-worktrees/` | P04 每個 Feature 開始前 |
| 完成開發/合併/PR | `context-skills/finishing-a-development-branch/` | P04 Feature 完成後 |
| 提交 Code Review | `context-skills/requesting-code-review/` | Gate 2 / G4-ENG / Gate 3 |
| 討論想法/探索方案 | `context-skills/brainstorming/` | Interviewer Agent / 技術選型前 |
| 多 Agent 並行執行 | `context-skills/subagent-driven-development/` | UX 確認後並行啟動 Architect+DBA+Backend |
| Agent 完成前驗證 | `context-skills/verification-before-completion/` | 每個 Agent 寫交接摘要前 |

### 專業領域 Skill

| 情境 | Skill | 自動觸發時機 |
|------|-------|-------------|
| Playwright UI/E2E 測試 | `context-skills/webapp-testing/` | QA Agent / Prototype 驗證 |
| 技術調研/ADR 產出 | `context-skills/deep-research/` | Architect 選型 / Security 合規 |
| UI 設計品質把關 | `context-skills/frontend-design/` | UX / Frontend Agent 建立元件 |
| 截圖→像素級還原 | `context-skills/screenshot-to-code/` | 收到設計稿/截圖時 UX 或 Frontend 觸發 |
| Gate 1/2/G4-ENG/3 驗收 | `context-skills/quality-gates/` | Review Agent 執行 Gate |
| Pipeline 自動化協調 | `context-skills/pipeline-orchestrator/` | 「執行 Pipeline:」觸發 |
| 跨 session 任務追蹤 | `context-skills/planning-with-files/` | 多步驟 Pipeline / Context > 80% |
| 初始化新專案 | `context-skills/project-init/` | 「初始化新專案」「new project」「建新專案」觸發 |

---

## Pipeline 自動化流水線協議

> 觸發方式：你說「**執行 Pipeline: [名稱]**」，Claude 自動依序執行所有 Agent，每步完成後更新 TASKS.md。

### 使用規則
1. 每個 Agent 執行完畢，自動在 TASKS.md 寫入交接摘要
2. 每個 Agent 結束時，Claude 顯示確認訊息：「✅ [Agent名稱] 完成，繼續執行下一步嗎？」
3. 你只需回覆「繼續」或「停」即可控制流程
4. 每輪結束前，Claude 報告「目前理解的是...」供你確認（防幻覺機制）
5. **Gate Review 必須開新 session 執行**（見 §31.7）— Pipeline 最後一個 Agent 完成後，Orchestrator 會提示你開新 Cowork task 或 Claude Code session 來做 Gate 驗收

### 預設 Pipeline 清單

#### Pipeline: 舊專案接入（Brownfield Onboarding）

> 適用：已有 codebase 的專案，首次導入 AI-First Framework。
> 觸發方式：說「**執行 Pipeline: 舊專案接入**」
> 目標：建立當前狀態 baseline，之後的所有新工作走正常 Pipeline。

```
⚠️ 核心原則：不強迫補全舊 code 的所有文件。
   建立 baseline 快照，接入後的新工作才走完整 Pipeline。
   舊 code 的 Gate Review 不回頭跑，但技術債要顯性登記。

【Stage 1 — 技術全景掃描】 § 41 map-codebase（4 Agent 並行）
  Stack Agent     → 技術棧清單（語言/框架/版本/依賴）
  Architect Agent → 模組邊界 + 資料流
  Conventions Agent → 命名慣例 + 資料夾結構 + 已有設計模式
  Concerns Agent  → 風險清單 + 技術債初步盤點
  → 產出：memory/codebase_snapshot.md

【Stage 2 — Feature 盤點 + F-code 分配】
  PM Agent + Architect Agent
  → 列出所有現有功能模組 → 分配 F-code（從 F01 開始）
  → 登記至 MASTER_INDEX.md（maturity 全部標記 Baselined）
  → 在 TASKS.md 建立每個 F-code 的 Backlog 條目

【Stage 3 — 技術決策補記】
  Architect Agent（讀 codebase_snapshot.md）
  → 將已做的關鍵架構決策補寫為 ADR 記錄 memory/decisions.md
  → 不是重新設計，是把已存在的決策「顯性化」
  → 重點：技術棧選型 / DB 設計思路 / 外部系統整合理由

【Stage 4 — 技術債顯性登記】
  Architect Agent
  → 盤點現有問題（安全漏洞 / 效能瓶頸 / 缺少測試 / 命名混亂等）
  → 逐條寫入 memory/TECH_DEBT.md（含嚴重度 + 影響範圍 + 建議時機）
  → 不要求立即修復，但必須讓 AI 知道這些坑在哪

【Stage 5 — 標準差距評估（GAP Report）】
  Review Agent（讀 10_Standards/ + codebase_snapshot.md）
  → 對比三域標準（API / DB / UI）評估現有 code 合規程度
  → 產出 GAP 分析報告（不阻塞，只是讓團隊知道差距）
  → 高風險差距（安全/合規）標記 🔴，優先排入 TASKS.md Backlog

【Stage 6 — 環境 + CI 整合】
  DevOps Agent
  → 確認 .env.example 存在（從現有 .env 抽格式）
  → 確認 .github/CODEOWNERS 存在
  → 整合或新建 CI workflow（保留現有 CI，補缺的 Stage）
  → 確認 10_Standards/ 已有錯誤碼前綴（[PREFIX] 替換）

【Stage 7 — 接入宣告】
  → 建立接入 commit：feat: adopt AI-First Framework vX.X.X
  → 更新 memory/last_task.md 記錄接入完成
  → 在 TASKS.md 新增第一個 AI 輔助開發的 Feature 任務

完成後的工作方式：
  新功能    → 正常走 Pipeline: 需求訪談 → ... → Pipeline: 部署上線
  修改舊功能 → §42 Brownfield 改動流程（見下方）
  緊急線上問題 → 執行 Hotfix: [問題描述]
  大規模重構 → 先讀 memory/codebase_snapshot.md + TECH_DEBT.md，再走 Pipeline: 技術設計
```

**接入後不需要做的事（常見誤區）：**
- ❌ 不需要為每個舊功能補齊完整 RS 文件（按需補，動到才補）
- ❌ 不需要回頭跑舊 code 的 Gate Review
- ❌ 不需要把現有 code 改成符合 10_Standards 的格式（技術債慢慢還）
- ✅ 只需要新工作遵循框架，舊 code 遇到才補文件

---

#### §42 — Brownfield 修改舊 Code 流程

> 適用：舊專案接入後，修改任何已存在的功能或模組。
> 不需要特定觸發詞 — Claude 在舊專案 context 下自動套用此流程。

**規模判斷（依影響範圍，非檔案數）**

| 規模 | 判斷條件 | 路徑 |
|------|---------|------|
| 小 | 單一功能點、不改 API 介面、不影響其他模組 | 走簡化四步法（見下） |
| 中 | 改 API 介面 / DB Schema / 影響 1~2 個相關模組 | 走簡化四步法（RS 要求更嚴） |
| 大 | 跨模組重構 / 資料結構變動 / 接近新功能 | 走完整 `Pipeline: 技術設計` → `Pipeline: 實作開發` |

**簡化四步法（小 + 中 規模）**

```
Step 1 — Grounding（理解現況）
  · 讀 memory/codebase_snapshot.md 相關段落
  · 讀 memory/TECH_DEBT.md 確認此區域已知風險
  · 讀現有 code，理解當前行為（不假設、不猜測）

Step 2 — 補最小 RS（動 code 前必做）
  必補條件（任一符合即觸發）：
    · 改到 API 介面或 DB Schema
    · 此區域在 TECH_DEBT.md 標記 🔴
  其餘情況：
    · 補一個最小 RS section，描述現有行為 + 本次改動範圍即可
  → RS 不需完整，只需涵蓋此次改動

Step 3 — 補完整測試（仍在動 code 前）
  · 範圍：受影響的所有功能路徑（happy path + 主要 edge case）
  · 方式 A（現有行為正確）：先寫測試讓它 PASS（紀錄現況）→ 改完後仍應 PASS
  · 方式 B（現有行為有 bug）：測試反映預期正確行為（RED）→ 改完後 GREEN
  · 禁止：改完 code 才補測試

Step 4 — Execute + Verify
  · 執行修改 → 確認所有測試 PASS
  · 執行輕量 Gate Review（見下方清單）
  · 更新 MASTER_INDEX.md 對應 F-code 的 maturity
  · 若解決了 TECH_DEBT.md 的項目 → 標記已關閉並記錄日期
```

**輕量 Gate Review 清單（每次必做，不需開新 session）**

| 項目 | 小 | 中 |
|------|:--:|:--:|
| RS 補充涵蓋此次改動範圍 | ✅ | ✅ |
| 測試覆蓋受影響的所有功能路徑 | ✅ | ✅ |
| API 介面 / DB Schema 無未記錄變動 | — | ✅ |
| TECH_DEBT.md 更新（新增風險或關閉已解決項目） | ✅ | ✅ |
| 改動範圍最小化（無順帶重構） | ✅ | ✅ |

---

#### Pipeline: 需求訪談
```
Interviewer（訪談+摘要 → IR-[日期].md）→ PM（User Story + AC驗證提示 → F##-US.md）→ UX（流程+Prototype → F##-UX.md + .html）
輸出：02_Specifications/ + 01_Product_Prototype/
⚡ 各 Agent 完成前執行 LPC 輕量自檢 + CHC Context Health Check（workflow_rules.md §34、§32）
📋 P01 完成後，Pipeline Orchestrator 觸發 Discuss Phase（技術偏好確認，§33）
完成後 → 🔍 開新 session 執行 Gate 1（需求完整性 + NYQ 驗證提示覆蓋率）→ ✅ 通過後 🔀 切換到 Claude Code
```

#### Pipeline: 技術設計
```
📋 啟動前 Discuss Phase 確認（P01→P02 技術偏好，若已完成可略過）
🗺️ 若 src/ 已有程式碼 → 先執行 map-codebase（§41）產出 memory/codebase_snapshot.md
🌊 Wave 分析：W1[Architect+DBA 並行] → W2[Backend API Spec+Frontend 規劃 並行] → W3[Review]
Architect（軟體架構+硬體架構 → F##-SW-ARCH.md + F##-HW-ARCH.md）→ DBA（Schema → F##-DB.md）→ Review（架構驗收 → F##-ARCH-RVW.md）
輸出：03_System_Design/
⚡ 各 Agent 完成前執行 LPC + CHC（workflow_rules.md §34、§32）
完成後 → 🔍 開新 session 執行 Gate 2（技術可行性 + 資料契約）
```

#### Pipeline: 開發準備
```
Backend（API Spec → F##-API.md）→ Frontend（元件規劃 → F##-FE-PLAN.md）→ QA（測試案例設計 → F##-TC.md，從 AC 驗證提示開始 NYQ-02）
輸出：02_Specifications/ + 03_System_Design/
⚡ 各 Agent 完成前執行 LPC + CHC（workflow_rules.md §34、§32）
完成後 → 🔍 開新 session 執行 G4-ENG（工程設計驗收）⚠️ 必須通過才能啟動實作開發
```

#### ⛔ G4-ENG：工程設計驗收（P03 完成後強制執行，P04 的解鎖條件）
```
⚠️ 必須在獨立 session 中執行（見 §31.7）
Review Agent 執行驗收清單（見 memory/smoke_tests.md 與 Dashboard Gate Tab → G4-ENG）：
- GA 密度審查（API Spec + DB Schema ≥ 5 GA標記/千字）
- DDG 依賴圖完整性（ADR depends_on / depended_by 已填）
- 跨層一致性（欄位名稱 SSOT、API ↔ DB ↔ FE 型別對齊）
- PTC-04 Prototype 追溯抽查（3~5 個 UI 元件）
- SignoffLog 三方簽核（Architect / DBA / Review）
Pass → 解鎖 P04  |  Block → 退回 P03 修正後重審
輸出：F##-ENG-RVW.md + G4_{F碼}_SignoffLog_v1.yaml
```

#### Pipeline: 實作開發
```
⚠️ 觸發條件：G4-ENG 通過後（F##-ENG-RVW.md 存在且無未解 Block）
📋 啟動前 Discuss Phase 確認（P03→P04 實作偏好，若已完成可略過）
Backend（功能實作 → src/）→ Frontend（元件實作 → src/）→ QA（測試執行 + NYQ Smoke Test → F##-TR.md）
輸出：src/ + 08_Test_Reports/
⚡ 修改前判斷 Quick Mode（workflow_rules.md §37）；Step 4 Verify 失敗觸發 AFL 自動修復迴圈（§36）
完成後 → 🔍 開新 session 執行 Gate 3（交付前 + QM稽核 + CHC驗證 + AFL驗證 + AI 修改治理 + L1 Gate 回顧）
```

#### Pipeline: 合規審查
```
Security（資安+FSC審查 → F##-SEC.md）→ Review（合規文件審查 → F##-COMPLY-RVW.md）
輸出：04_Compliance/
⚠️ Review Agent 建議在獨立 session 中執行（見 §31.7）
```

#### Pipeline: 部署上線
```
DevOps（CI-CD + GCP 部署 → F##-DEPLOY.md）→ Review（部署驗收 → F##-DEPLOY-RVW.md）
輸出：03_System_Design/（DEPLOY.md）+ 09_Release_Records/（DEPLOY-RVW.md）
完成後觸發 L2 模組回顧
⚠️ Review Agent 建議在獨立 session 中執行（見 §31.7）
```

### TASKS.md 交接格式（每個 Agent 完成後寫入）
```markdown
| [ID] | [Agent名稱] 完成 | [Agent] | ✅ 完成 | 交接：[下一個Agent] 需知道→ [摘要] |
```

---

## 並行執行原則

> **功能為單位的並行**：UX 確認某個功能的互動方式後，Architect 即可開始該功能的架構設計，不需等待全部 UX 完成。

**執行順序邏輯（含工具切換與 Gate Review）：**
```
┌─ Cowork ─────────────────────────────────────────────┐
│                                                       │
│  P01 需求訪談（Interviewer + PM）                      │
│      ↓ 全部完成後                                      │
│  UX 設計（逐功能進行）                                  │
│      ↓ Pipeline 完成                                   │
│                                                       │
│  🔍 開新 Cowork task → Gate 1 Review（獨立 session）   │
│      ↓ Pass                                           │
└───────────────────────────────────────────────────────┘
        🔀 切換到 Claude Code
┌─ Claude Code ────────────────────────────────────────┐
│                                                       │
│  P02 技術設計                                          │
│      ↓ 每個功能 UX 確認後                               │
│      ├── Architect（該功能架構）← 可並行                 │
│      ├── DBA（該功能 Schema）  ← 可並行                 │
│      └── Backend（API Spec）   ← 可並行                │
│      ↓ Pipeline 完成                                   │
│                                                       │
│  🔍 開新終端機視窗 → Gate 2 Review（獨立 session）      │
│      ↓ Pass                                           │
│                                                       │
│  P03 開發準備（Backend → Frontend → QA）                │
│      ↓ Pipeline 完成                                   │
│                                                       │
│  🔍 開新終端機視窗 → G4-ENG Review（獨立 session）      │
│      ↓ Pass                                           │
│                                                       │
│  P04 實作開發（Backend → Frontend → QA）                │
│      ↓ Pipeline 完成                                   │
│                                                       │
│  🔍 開新終端機視窗 → Gate 3 Review（獨立 session）      │
│      ↓ Pass                                           │
│                                                       │
│  P05 合規審查 → P06 部署上線                            │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

## 🔍 Gate Review 獨立 Session 使用指南

> **核心原則：寫文件/寫程式的 session 不做 Review，Review 必須開新 session。**
> 詳見 `memory/workflow_rules.md` §31.7

### 為什麼？
同一個 session 的 Claude 已帶有討論慣性，容易忽略文件本身的邏輯漏洞。
獨立 session 以「新鮮的眼睛」只看文件產出，審查品質更高。
這等同於真實團隊中「寫 code 的人不自己做 code review」。

### Cowork 操作步驟

1. **開一個新的 Cowork task**
2. **選擇同一個專案資料夾**（關鍵！這樣 Review Agent 才能讀到前一個 task 的產出）
3. **第一句話**（複製貼上）：
   ```
   你是 Review Agent。請讀取 CLAUDE.md，然後執行 Gate [N] 驗收。

   驗收範圍：
   - 讀取 TASKS.md 了解目前進度
   - 讀取 context-skills/quality-gates/SKILL.md 取得 checklist
   - 逐項檢查對應的產出文件
   - 產出 Review 報告到 07_Retrospectives/
   ```
4. Review 完成後，回到原 task 繼續下一個 Pipeline

### Claude Code 操作步驟

1. **開一個新的終端機視窗**（不要用正在開發的那個）
2. `cd [專案路徑]` → `claude`
3. 第一句話同上
4. Review 完成後，回到原終端機繼續

### Review Agent 如何了解目前狀況？

兩個 session 指向同一個專案目錄，Review Agent 透過檔案系統取得完整 context：

| 檔案 | Review Agent 從中得知 |
|------|---------------------|
| `CLAUDE.md` | 專案全貌、Agent 路由、Pipeline 定義 |
| `TASKS.md` | 誰做了什麼、交接摘要、目前進度 |
| `memory/last_task.md` | 目前做到哪個階段 |
| `memory/decisions.md` | 所有技術決策（ADR） |
| `context-skills/quality-gates/SKILL.md` | Gate checklist |
| 各 Pipeline 產出文件 | 實際審查對象 |

不需要手動複製任何資訊，也不需要跟 Review Agent 解釋前因後果。

### Gate → 審查文件對照表

| Gate | 審查文件 |
|------|---------|
| Gate 1 | `06_Interview_Records/IR-*.md` + `02_Specifications/US_F##_*.md` + `01_Product_Prototype/*.html` |
| Gate 2 | `03_System_Design/F##-SW-ARCH.md` + `F##-DB.md` + ADR |
| G4-ENG | `02_Specifications/F##-API.md` + `03_System_Design/F##-DB.md` + Prototype PTC |
| Gate 3 | `src/` + `08_Test_Reports/F##-TR.md` + DSV 日誌 |

---

## 🚨 Hotfix / 緊急修復流程

> 線上問題專用通道，跳過正常 Pipeline，走最短路徑。
> 觸發方式：說「**執行 Hotfix: [問題描述]**」

### 嚴重度判定（第一步，必做）

| 嚴重度 | 判定條件 | 路徑 |
|--------|---------|------|
| 🔴 Critical | 服務中斷 / 資料外洩 / P0 合規違規 | → Hotfix Pipeline |
| 🟠 High | 核心功能完全失效 / 資料錯誤但未外洩 | → Hotfix Pipeline |
| 🟡 Medium | 功能部分異常，有替代方案 | → 正常 Sprint，優先排入 |
| 🟢 Low | 體驗問題 / 文字錯誤 | → 正常 Sprint |

> Medium/Low 不走 Hotfix。緊急感≠嚴重度。

---

### Pipeline: Hotfix（Critical / High 專用）

```
Step 1 — 開案（立即，< 15 分鐘）
  Review Agent 評估嚴重度 → 確認走 Hotfix Pipeline
  → 在 memory/hotfix_log.md 建立 HF-YYYY-NNN 條目
  → git checkout -b hotfix/HF-YYYY-NNN（從 main 切出）

Step 2 — 根因分析（< 1 小時）
  Backend/Frontend Agent 用 systematic-debugging skill
  → 確認根本原因（禁止猜測，必須有 evidence）
  → 在 hotfix_log.md 記錄根因

Step 3 — 最小化修復（< 2 小時）
  Backend/Frontend Agent 實作
  → 原則：只動必要的 code，不順帶重構、不加新功能
  → 修改範圍 ≤ 2 架構層（SC-01）
  → 執行受影響功能的回歸測試（smoke + unit）

Step 4 — Rollback 準備（部署前必做）
  DevOps Agent 確認：
  → Rollback 腳本可執行（git revert 或 DB rollback script）
  → Feature Flag 可作為緊急關閉開關
  → 若有 DB Migration：確認 down migration 已寫

Step 5 — 快速審查（< 30 分鐘，新 session）
  Review Agent 執行 HF-01~06 快速審查清單（見 SEED_Review.md）
  🔴 Critical 還需 Security Agent 快速掃描

Step 6 — 部署
  DevOps Agent → 部署到 Staging → 冒煙測試通過 → 部署到 Production
  → 在 hotfix_log.md 更新 resolved 狀態

Step 7 — 補件（48hr 內，可事後補）
  → 更新受影響 RS 的對應章節
  → 補 Gate Review 文件（GRN 記錄）
  → 將 hotfix branch merge 回 main 和 develop
  → 在 hotfix_log.md 標記 ✅ 已結案
```

### 命名規範

```
Branch:   hotfix/HF-YYYY-NNN          (e.g. hotfix/HF-2026-001)
Commit:   hotfix(F##): [一行描述]      (e.g. hotfix(F02): fix popup not showing on first call)
Log ID:   HF-YYYY-NNN                 (e.g. HF-2026-001，寫入 hotfix_log.md)
```

### Hotfix 鐵則

- 🚫 **禁止順帶重構**：範圍只限修這個 bug，其他問題另開 ticket
- 🚫 **禁止猜根因就動手**：Step 2 根因未確認前不進入 Step 3
- ✅ **Rollback 先於部署**：沒有確認 rollback 方案不得上線
- ✅ **48hr 補件**：文件欠債必須還，hotfix_log.md 追蹤補件狀態

---

## ⚡ GSD 快速參考（workflow_rules.md §32-§37）

| 機制 | 觸發時機 | 規則章節 |
|------|---------|---------|
| **Quick Mode** | 修改 ≤ 3 檔案、無新功能、5分鐘可驗證 → 跳過完整 Pipeline | §37 |
| **Context Health Check** | 每個 Agent 交接前自動執行，防止 context rot | §32 |
| **Discuss Phase** | P01→P02 和 P03→P04 銜接時，詢問技術/實作偏好 | §33 |
| **Plan Check（LPC）** | 每個 Agent 產出後自檢，最多 3 輪，不過才標記 UNRESOLVED | §34 |
| **Nyquist 驗證層** | PM 在每條 AC 附驗證提示；QA 從此開始設計 TC | §35 |
| **自動修復迴圈（AFL）** | Step 4 Verify 失敗 → 觸發 debug → fix → re-verify，最多 3 輪 | §36 |
| **STATE.md 記憶體** | Agent 交接後/暫停時自動寫入；新 session 開始時自動讀取 | §38 |
| **Wave-Based 並行** | 2+ Agent 並行前，先做依賴波分析再執行 | §39 |
| **Model Profiles** | 切換指令「切換 Profile: quality/balanced/budget」；預設 balanced | §40 |
| **map-codebase** | 首次進入既有 codebase / 大規模重構前，4 Agent 並行入場分析 | §41 |

---

## 不可違反原則

1. **技術棧不隨意更換**：已決定的技術棧除非有 ADR 紀錄，否則不更動
2. **多租戶安全**（若適用）：所有涉及業務資料的功能，必須有 tenant_id 隔離
3. **AI 成本意識**（若適用）：每個 AI 功能都要評估 token 用量和成本
4. **決策記錄**：重大技術決策必須寫入 `memory/decisions.md`
5. **先問清楚再動手**：需求模糊時，先用 Interviewer Agent 釐清

---

## 記憶庫索引

| 檔案 | 內容 |
|------|------|
| `memory/product.md` | 產品基本資訊、技術棧、Model Profile 設定 |
| `memory/decisions.md` | 技術決策記錄（ADR） |
| `memory/last_task.md` | 上次做到哪裡、下一步 |
| `memory/STATE.md` | 跨 Session 狀態快照 ⬅️ **新 session 開始時自動讀取（§38）** |
| `memory/codebase_snapshot.md` | Codebase 技術棧/架構/慣例/風險快照（map-codebase 產出，§41） |
| `memory/workflow_rules.md` | Agent 交接格式、文件規範、修改四步法、GSD §32-§41 ⬅️ **每次必讀** |
| `memory/dashboard.md` | PROJECT_DASHBOARD.html 結構、函式、CSS、修改守則 ⬅️ **改 Dashboard 前必讀** |
| `memory/hotfix_log.md` | Hotfix 緊急修復記錄 |
| `memory/token_budget.md` | Context Token 預算追蹤 |
| `memory/gate_baseline.yaml` | Gate Baseline Lock（G1-BL 通過後寫入，G2+ Diff Report 基準）|
| `TASKS.md` | 任務清單與進度 |
| `MASTER_INDEX.md` | 所有產出文件登記 + F-code 分配表 |

---

## 資料夾結構說明

> 文件性質分類原則：**計畫/規格** → 02 或 03；**執行結果/品質證據** → 08；**上線簽核** → 09；**合規** → 04

```
[專案名稱]/
├── CLAUDE.md                ← 你在這裡（導航總表）
├── TASKS.md                 ← 任務清單
├── PROJECT_DASHBOARD.html   ← 專案流程儀表板
├── contracts/               ← 資料契約文件（Field/ENUM Registry）
├── context-seeds/           ← 11 個 Agent 種子提示詞
├── memory/                  ← 跨 session 記憶庫
├── 01_Product_Prototype/    ← HTML Prototype（UX 產出）
├── 02_Specifications/       ← 計畫/規格文件（US、API Spec、測試案例 TC）
├── 03_System_Design/        ← 設計文件（架構 ARCH、DB Schema、部署計畫 DEPLOY）
├── 04_Compliance/           ← 資安合規文件（SEC、COMPLY-RVW）
├── 05_Archive/              ← 舊版文件
├── 06_Interview_Records/    ← 訪談紀錄（IR）
├── 07_Retrospectives/       ← 回顧與持續改善（Gate Review / Module Retro / PIP / 指標）
├── 08_Test_Reports/         ← 測試執行結果/品質證據（TR）
├── 09_Release_Records/      ← 上線交付簽核（DEPLOY-RVW）
└── 10_Standards/            ← 三域技術標準 SSOT（API / DB / UI）
    ├── API/                 ← API 設計規範 + 錯誤碼標準
    ├── DB/                  ← DB Schema 規範 + ENUM Registry + Field Registry 模板
    └── UI/                  ← UI 設計規範 + Design Token 速查
```

### 10_Standards/ 查詢路由

| 任務 | 查詢位置 |
|------|---------|
| API / DB / UI 規範查詢 | `10_Standards/` | 三域技術標準 SSOT |
| API 設計 / 錯誤碼 | `10_Standards/API/STD_API_Design.md` + `Error_Code_Standard_v1.0.md` |
| DB Schema / ENUM / Field Registry 模板 | `10_Standards/DB/` |
| UI Design Token / 元件規範 | `10_Standards/UI/` |

---

*此檔案為通用範本。使用前請更新產品概覽區塊，並將 `[佔位符]` 替換為實際內容。*
