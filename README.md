# AI-First Framework

> **為 Claude Code 和 Cowork 打造的生產級多 Agent 開發系統。**
> 透過結構化 Pipeline、12 個專業 AI Agent 和內建品質關卡，將任何產品想法變成可交付的程式碼。

---

## 這是什麼？

AI-First Framework 是一套以 Context Engineering 和規格驅動開發為核心的系統，讓 AI 輔助開發變得**可靠、可追溯、可重複**。告別隨意 prompting，改用：

- **3 類 Pipeline** — 新專案開發 / 舊專案接入 / 緊急修復
- **12 個 Agent 角色** — 各司其職，清楚交接
- **4 個品質關卡** — 強制檢查點，防止帶著爛地基往下走
- **29 個 Skills** — Agent 自動調用的可重用能力模組
- **13 個 Slash Commands** — 常用操作的一行指令
- **三域技術標準** — API / DB / UI 的唯一真理來源，全 Agent 強制遵守
- **10 個可靠性機制** — 防幻覺、跨 session 記憶、並行協調，內建於每條 Pipeline

---

## 快速開始（5 分鐘）

第一次接觸這個框架時，建議先看 [docs/START_HERE.md](docs/START_HERE.md)。

### Step 1 — Clone 框架

```bash
git clone https://github.com/holybell15/ai-first-framework.git
cd ai-first-framework
```

### Step 2 — 建立你的專案

**全新專案：**
```bash
./scripts/new-project.sh 我的產品名稱
```

**接入現有 Codebase：**
```bash
./scripts/adopt-project.sh /path/to/existing-project
```

### Step 3 — 用 Cowork 或 Claude Code 開啟

**Cowork**：開新 task，選擇專案資料夾。

**Claude Code**：
```bash
cd ../我的產品名稱
claude
```

### Step 4 — 開始

```
讀取 CLAUDE.md，然後執行 /info-init
```

### 第一次使用建議：先走 Lite Mode

如果你是第一次導入這個框架，或目前只有 1-2 人推進，建議不要一開始就跑滿完整 Pipeline。

建議直接用這句開始：

```
讀取 CLAUDE.md，使用 Lite Mode 啟動 F01
```

Lite Mode 會保留 Task-Master、STATE、TASKS、10_Standards 與最小 Review，但降低早期文件與角色切換成本。

詳見 [docs/LITE_MODE.md](docs/LITE_MODE.md)。
若驗證失敗或入口不完整，先看 [docs/VALIDATION_REPAIR.md](docs/VALIDATION_REPAIR.md)。

---

## 框架結構

```
ai-first-framework/
├── README.md
├── CHANGELOG.md
├── VERSION                      ← 當前版本（2.4.0）
├── scripts/
│   ├── new-project.sh           ← 一鍵建立新專案
│   └── adopt-project.sh         ← 接入既有 Codebase
├── docs/
│   ├── PIPELINES.md
│   ├── AGENTS.md
│   └── AGENT_SYNC.md
├── tools/
│   └── workflow-test/           ← 框架健康測試工具
└── project-template/
    ├── CLAUDE.md                ← 導航總表
    ├── TASKS.md                 ← 任務清單（F-code + @負責人）
    ├── TEAM.md                  ← 多人協作設定 + 交接協議
    ├── MASTER_INDEX.md          ← 文件登記索引
    ├── PROJECT_DASHBOARD.html   ← 視覺化進度儀表板
    ├── .claude/commands/        ← 13 個 slash commands
    ├── 10_Standards/            ← 三域技術標準（唯一真理來源）
    │   ├── API/
    │   ├── DB/
    │   └── UI/
    ├── context-seeds/           ← 12 個 Agent 啟動提示詞
    ├── context-skills/          ← 29 個能力 Skill 模組
    ├── contracts/               ← 資料契約 + Field Registry
    └── memory/                  ← 跨 Session 狀態與規則
```

---

## 最常見的 5 個入口

| 你現在要做什麼 | 直接從這裡開始 |
|----------------|---------------|
| 建立新專案 | `./scripts/new-project.sh 我的產品名稱` |
| 接入既有專案 | `./scripts/adopt-project.sh /path/to/project` |
| 不知道下一步 | `/info-task-master` |
| 想跑第一個最小 feature | `讀取 CLAUDE.md，使用 Lite Mode 啟動 F01` |
| 想驗證框架本身 | `./scripts/validate-framework.sh` |

---

## Pipeline

### 新專案開發（P01–P06）

從零開始的完整開發流程，6 條 Pipeline 依序執行，每條結束前通過品質關卡才能繼續。

| # | Pipeline | 產出 | 品質關卡 |
|---|---------|------|---------|
| P01 | 需求訪談 | 訪談紀錄、User Story、Prototype | Gate 1 |
| P02 | 技術設計 | 架構、DB Schema、ADR | Gate 2 |
| P03 | 開發準備 | API Spec、元件規劃、測試案例 | G4-ENG |
| P04 | 實作開發 | 可運行的程式碼 + 通過的測試 | Gate 3 |
| P05 | 合規審查 | 資安與合規文件 | — |
| P06 | 部署上線 | CI/CD、部署紀錄、Release | — |

觸發方式：`執行 Pipeline: [名稱]`

Gate Review 必須在**獨立的新 session** 執行：
```
# Cowork：開新 task，選同一個資料夾
# Claude Code：開新終端機視窗

"你是 Review Agent。讀取 CLAUDE.md，執行 Gate [N] 驗收。"
```

若你是第一次使用、功能單純、或目前只有 1-2 人，建議先用 [docs/LITE_MODE.md](docs/LITE_MODE.md) 跑第一個 feature，再視複雜度升級回完整 Pipeline。

---

### 舊專案接入（Brownfield Onboarding）

已有 Codebase 的專案首次導入框架。保留完整理想流程，但預設先做「最小可用接入」，避免小團隊在第一天就卡在補文件。

觸發方式：`執行 Pipeline: 舊專案接入`

**Lite 接入（推薦給 1-2 人團隊 / 第一次導入）：**

| 階段 | 重點 | 產出 |
|------|------|------|
| Stage 0 — 現況盤點 | 確認預設分支、部署方式、測試現況、CI 是否存在 | `memory/adoption_gap_report.md` |
| Stage 1 — 建立 baseline | 補齊框架核心入口，不覆蓋既有程式 | `CLAUDE.md`、`TASKS.md`、`MASTER_INDEX.md`、`memory/STATE.md` |
| Stage 2 — 單次 codebase 掃描 | 先理解系統邊界、模組、依賴、風險點 | `memory/codebase_snapshot.md` |
| Stage 3 — GAP 報告 | 標出缺的標準、缺的 CI、缺的文件，不要求一次補完 | `memory/adoption_gap_report.md` |
| Stage 4 — 選第一個接入功能 | 選 1 個真實維護需求作為接入起點 | `TASKS.md` 接續執行 |

**Standard 接入（完整理想流程）：**

| 步驟 | Agent | 產出 |
|------|-------|------|
| 技術全景掃描 | Architect + 3 個並行 Agent | `memory/codebase_snapshot.md` |
| Feature 盤點 + F-code 分配 | PM + Architect | `MASTER_INDEX.md` + `TASKS.md` |
| 技術決策補記 | Architect | `memory/decisions.md` |
| 技術債顯性登記 | Architect | `memory/TECH_DEBT.md` |
| 標準差距評估 | Review | `memory/adoption_gap_report.md` |
| 環境 + CI 整合 | DevOps | `.github/workflows/` + `.env.example` |
| 接入宣告 | Review + DevOps | 接入 commit + 後續工作路由 |

**接入後修改舊功能的四步法：**

| 步驟 | 最低要求 |
|------|----------|
| 理解現況 | 補 1 段現況摘要，確認影響模組、資料流、風險 |
| 補最小 RS | 只補這次修改涉及的 User Story / 驗收條件，不追補整個 legacy 模組 |
| 補測試 | 至少補 1 個會失敗的檢查或回歸驗證，優先鎖住這次修正範圍 |
| 執行驗證 | 跑現有 test、smoke test，沒有自動化時至少留下手動驗證紀錄 |

大幅重構、跨模組整併、資料庫結構重設，才升級回完整 P01-P06。

---

### 緊急修復（Hotfix）

線上問題專用通道，跳過正常 Pipeline，走最短修復路徑。保留完整理想流程，但允許小團隊先用 Lite Hotfix 穩住現場。

觸發方式：`執行 Hotfix: [問題描述]`（或 `/info-hotfix`）

**嚴重度判定（先做這步）：**

| 嚴重度 | 條件 | 路徑 |
|--------|------|------|
| 🔴 Critical / 🟠 High | 服務中斷、資料錯誤、核心功能失效 | → Hotfix |
| 🟡 Medium / 🟢 Low | 功能部分異常、體驗問題 | → 正常 Sprint |

**Lite Hotfix（推薦給小團隊 / 基礎設施未成熟）：**

| 步驟 | 最低要求 | 備註 |
|------|----------|------|
| 嚴重度評估 + 開案 | 建立 HF 條目、確認影響範圍 | < 15 分鐘 |
| 根因確認 | 必須有 evidence，不可憑感覺改 | < 1 小時 |
| 最小化修復 | 只修這次事故，不順帶重構 | < 2 小時 |
| 回滾方案 | 至少 1 個可執行方案：`git revert`、前版 artifact、手動回復步驟 | 部署前 |
| 快速驗證 | 執行 smoke test；沒有 staging 時，改成明確的 production 前驗證清單 | 部署前 |
| 補件 | 48 小時內補齊最小事故紀錄 | 見下方 |

**Standard Hotfix（完整理想流程）：**

| 步驟 | 負責 | 時限 |
|------|------|------|
| 嚴重度評估 + 開案 | Review | < 15 分鐘 |
| 根因分析 | Backend / Frontend | < 1 小時 |
| 最小化修復 | Backend / Frontend | < 2 小時 |
| Rollback 準備 | DevOps | 部署前 |
| 快速審查 | Review（+ Security 若 Critical） | < 30 分鐘 |
| Staging 冒煙 + 部署 | DevOps | — |
| 補件（完整 RS + Gate 文件） | PM + Review | 48hr 內 |

**Hotfix 最小補件集（Lite 與 Standard 都適用）：**

- 事故條目已補上根因、修復摘要、驗證結果
- 至少 1 條後續 backlog 項目，避免同類事故重演
- 若修改了需求或行為，補最小 RS 更新
- 若是 Critical，補 Security 快速審查結果

---

## 12 個 Agent 角色

| Agent | 職責 | Seed 檔 |
|-------|------|---------|
| Task-Master | 讀取 TASKS.md + STATE.md，自動判斷優先任務、派遣 Agent、處理阻塞 | `/info-task-master` |
| Interviewer | 需求蒐集與訪談 | `SEED_Interviewer.md` |
| PM | User Story + 驗收條件 | `SEED_PM.md` |
| Architect | 系統設計 + ADR | `SEED_Architect.md` |
| UX | 使用者流程 + HTML Prototype | `SEED_UX.md` |
| Frontend | UI 元件 + 設計系統 | `SEED_Frontend.md` |
| Backend | API + 業務邏輯 | `SEED_Backend.md` |
| DBA | DB Schema + Migration | `SEED_DBA.md` |
| DevOps | CI/CD + 雲端部署 | `SEED_DevOps.md` |
| QA | 測試案例設計 + 執行 | `SEED_QA.md` |
| Security | 資安審查 + 合規 | `SEED_Security.md` |
| Review | Gate 驗收 + Code Review | `SEED_Review.md` |

Seed 檔位於 `context-seeds/` 目錄。啟動方式：`讀取 context-seeds/SEED_[角色].md，你現在是 [角色] Agent`

---

## Slash Commands

| 指令 | 功能 |
|------|------|
| `/info-task-master` | 讀取 TASKS.md + STATE.md，輸出派遣報告，告訴你現在該做什麼 |
| `/info-init` | 新專案初始化：驗證結構 → 填寫佔位符 → 設定團隊 → 建立 F01 |
| `/info-health` | 框架完整性檢查 + workflow-test 測試套件 |
| `/info-quick` | 小修正快速模式，≤3 個檔案，跳過完整 Pipeline |
| `/info-progress` | 從 STATE.md + TASKS.md 輸出即時進度快照 |
| `/info-pause` | 暫停工作，將 resume_command 寫入 STATE.md |
| `/info-handoff` | Agent 完成交接：更新 TASKS.md + STATE.md |
| `/info-complete-milestone` | Gate 通過後歸檔 + 更新狀態 + 可選 git tag |
| `/info-setup-team` | 互動式設定 TEAM.md（全 12 個角色） |
| `/info-pipeline` | Pipeline 選單，選擇要執行的 Pipeline |
| `/info-agent` | Agent 選單，直接啟動指定 Agent |
| `/info-gate` | Gate 驗收流程指引 |
| `/info-hotfix` | 緊急修復流程啟動 |

---

## 三域技術標準（`10_Standards/`）

所有 Agent 強制遵守的規範，改一處，全局生效。

| 領域 | 核心規則 |
|------|---------|
| **API** | `/api/v{N}/` 版本路由 · `{ success, data, message, errorCode }` 回應格式 · `AICC-{LAYER}{CODE}` 錯誤碼 |
| **DB** | UUID 主鍵 · `tenant_id NOT NULL` · `pii_` / `log_` / `enc_` 欄位前綴 · 可逆 Migration |
| **UI** | 只用 CSS 變數 · WCAG 2.1 AA · 44px 點擊目標 · 禁止 hardcode hex |

---

## 流程品質保障層

以下機制自動內建於 Pipeline，無需額外設定：

| 機制 | 功能 |
|------|------|
| 跨 Session 記憶 | Agent 交接或暫停時自動寫入 STATE.md，新 session 讀取後無縫續接 |
| 交接前健康檢查 | 每次 Agent 交接前檢查 context 品質，防止資訊腐敗 |
| 輕量自檢 | Agent 產出後 5 維度自檢，不通過標記 UNRESOLVED |
| 驗證提示層 | 每條驗收條件附帶測試方法提示，QA 從此開始設計測試案例 |
| 自動修復迴圈 | 驗證失敗 → debug → 修復 → 重新驗證，最多 3 輪 |
| 並行波次分析 | 多 Agent 並行前先分析依賴關係，分波執行，防止覆蓋衝突 |
| 快速模式 | ≤3 個檔案的小修正跳過完整 Pipeline，含聲明與驗證 |
| Codebase 入場掃描 | 進入既有 Codebase 前由 4 個 Agent 並行掃描，產出技術快照 |
| 技術偏好確認 | Pipeline 銜接時主動確認技術與實作偏好，減少方向偏差 |
| Model 分級 | quality（精準）/ balanced（預設）/ budget（快速）三檔可切換 |

---

## 品質關卡

| 關卡 | 執行時機 | 檢查內容 |
|------|---------|---------|
| Gate 1 | P01 完成後 | 需求完整性、驗收條件可測試性、Prototype 覆蓋率 |
| Gate 2 | P02 完成後 | 架構可行性、ADR 完整性、DB Schema |
| G4-ENG | P03 完成後 | 跨層一致性、工程設計密度、三方簽核 |
| Gate 3 | P04 完成後 | 測試覆蓋率 ≥80%、E2E 通過、安全審查 |

---

## 多人協作

`TEAM.md` 定義每個成員負責哪個 Agent 角色、交接協議，以及 Git 分支命名規範。Task-Master Agent 自動讀取 `TASKS.md` + `STATE.md`，判斷優先順序並在遇到阻塞時重新路由。

```
| F## | 功能描述 | @負責人 | 狀態 | 阻塞項 |

F05 depends_on: F02-API-完成
```

---

## 優先補強路線圖

框架目前已具備完整方法論與模板系統，下一階段重點是把它推進成更低摩擦、更可驗證、更容易被團隊穩定採用的產品。

優先順序如下：

1. 定義最小可用版本（Lite Mode）
2. 把核心規則轉成可驗證腳本
3. 收斂核心文件邊界，降低同步成本
4. 建立端到端示範專案
5. 強化採用體驗與入口設計

詳見 [docs/ROADMAP_PRIORITIES.md](docs/ROADMAP_PRIORITIES.md)。

---

## 版本

當前：**v2.4.0** — 多人協作 TEAM.md、13 個 Slash Commands、三域 10_Standards/、Brownfield 接入流程、框架健康測試工具。

完整歷史見 [CHANGELOG.md](./CHANGELOG.md)。

---

## License

MIT — 自由使用，歡迎標註出處。
