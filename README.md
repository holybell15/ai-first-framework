# AI-First Framework

> **為 Claude Code 和 Cowork 打造的生產級多 Agent 開發系統。**
> 透過結構化 Pipeline、11 個專業 AI Agent 和內建品質關卡，將任何產品想法變成可交付的程式碼。

---

## 這是什麼？

AI-First Framework 是一套以 Context Engineering 和規格驅動開發為核心的系統，讓 AI 輔助開發變得**可靠、可追溯、可重複**。告別隨意 prompting，改用：

- **6 條 Pipeline** — 從想法到上線的結構化工作流
- **11 個 Agent 角色** — 各司其職（PM、Architect、DBA、Backend、Frontend、UX、QA、Security、DevOps、Review、Interviewer）
- **4 個品質關卡** — 強制檢查點，防止帶著爛地基往下走
- **29 個 Skills** — Agent 自動調用的可重用能力模組
- **8 個 Slash Commands** — 常用框架操作的一行指令
- **三域技術標準** — API / DB / UI 的 SSOT 規範，全 Agent 強制遵守
- **GSD 機制** — 10 個可靠性機制，內建於每條 Pipeline（§32–§41）

---

## 快速開始（5 分鐘）

### Step 1 — Clone 框架

```bash
git clone https://github.com/holybell15/ai-first-framework.git
cd ai-first-framework
```

### Step 2 — 建立你的專案

```bash
./scripts/new-project.sh 我的產品名稱
# → 自動在上層目錄建立完整設定的專案資料夾
```

或接入現有專案：

```bash
./scripts/adopt-project.sh /path/to/existing-project
```

### Step 3 — 用 Cowork 或 Claude Code 開啟

**Cowork**：開新 task，選擇 `我的產品名稱/` 資料夾。

**Claude Code**：
```bash
cd ../我的產品名稱
claude
```

### Step 4 — 開始第一條 Pipeline

```
讀取 CLAUDE.md，然後執行 Pipeline: 需求訪談
```

就這樣。Claude 讀取導航檔，啟動 Interviewer Agent，開始結構化的需求蒐集。

---

## 框架結構

```
ai-first-framework/
├── README.md                    ← 你在這裡
├── CHANGELOG.md                 ← 版本歷史
├── VERSION                      ← 當前版本（2.4.0）
├── scripts/
│   ├── new-project.sh           ← 一鍵建立新專案
│   └── adopt-project.sh         ← 接入既有 Codebase
├── docs/
│   ├── PIPELINES.md             ← 6 條 Pipeline 詳解
│   ├── AGENTS.md                ← 11 個 Agent 角色參考
│   └── AGENT_SYNC.md            ← 多 Agent 協調指南
├── tools/
│   └── workflow-test/           ← 框架健康測試工具
└── project-template/            ← 每個新專案複製這個
    ├── CLAUDE.md                ← 導航總表（SSOT）
    ├── TASKS.md                 ← 任務清單（F-code + @負責人）
    ├── TEAM.md                  ← 多人協作設定 + 交接協議
    ├── MASTER_INDEX.md          ← 文件登記索引
    ├── PROJECT_DASHBOARD.html   ← 視覺化進度儀表板
    ├── .claude/
    │   └── commands/            ← 8 個 slash commands
    ├── 10_Standards/            ← 三域技術標準（SSOT）
    │   ├── API/                 ← API 設計 + 錯誤碼標準
    │   ├── DB/                  ← Schema 規範 + ENUM / Field Registry
    │   └── UI/                  ← Design Token + 元件規範
    ├── context-seeds/           ← 11 個 Agent 啟動提示詞
    ├── context-skills/          ← 29 個能力 Skill 模組
    ├── contracts/               ← 資料契約 + Field Registry
    ├── memory/                  ← 跨 Session 狀態與規則
    │   ├── workflow_rules.md    ← GSD §32–§41 完整規則手冊
    │   ├── STATE.md             ← Session 狀態快照（§38）
    │   ├── decisions.md         ← 技術決策記錄（ADR）
    │   ├── gate_baseline.yaml   ← Gate 出口基準
    │   ├── token_budget.md      ← Context 預算追蹤
    │   └── smoke_tests.md       ← 部署冒煙測試清單
    └── 01–09 folders/           ← 結構化產出目錄
```

---

## 6 條 Pipeline

| # | Pipeline | 產出 | 品質關卡 |
|---|---------|------|---------|
| P01 | 需求訪談 | 訪談紀錄、User Story、Prototype | Gate 1 |
| P02 | 技術設計 | 架構、DB Schema、ADR | Gate 2 |
| P03 | 開發準備 | API Spec、元件規劃、測試案例 | G4-ENG |
| P04 | 實作開發 | 可運行的程式碼 + 通過的測試 | Gate 3 |
| P05 | 合規審查 | 資安與合規文件 | — |
| P06 | 部署上線 | CI/CD 設定、部署紀錄、Release | — |

觸發方式：`執行 Pipeline: [名稱]`

---

## 11 個 Agent 角色

| Agent | 職責 | Seed 檔 |
|-------|------|---------|
| Interviewer | 需求蒐集與訪談 | `context-seeds/SEED_Interviewer.md` |
| PM | User Story + 驗收條件 | `context-seeds/SEED_PM.md` |
| Architect | 系統設計 + ADR | `context-seeds/SEED_Architect.md` |
| UX | 使用者流程 + HTML Prototype | `context-seeds/SEED_UX.md` |
| Frontend | UI 元件 + 設計系統 | `context-seeds/SEED_Frontend.md` |
| Backend | API + 業務邏輯 | `context-seeds/SEED_Backend.md` |
| DBA | DB Schema + Migration | `context-seeds/SEED_DBA.md` |
| DevOps | CI/CD + 雲端部署 | `context-seeds/SEED_DevOps.md` |
| QA | 測試案例設計 + 執行 | `context-seeds/SEED_QA.md` |
| Security | 資安審查 + 合規 | `context-seeds/SEED_Security.md` |
| Review | Gate 驗收 + Code Review | `context-seeds/SEED_Review.md` |

啟動任何 Agent：`讀取 context-seeds/SEED_[角色].md，你現在是 [角色] Agent`

---

## Slash Commands

每個專案內建的一行指令（`.claude/commands/`）：

| 指令 | 功能 |
|------|------|
| `/init` | 新專案初始化：驗證結構 → 填寫佔位符 → 設定團隊 → 建立 F01 |
| `/health` | 框架完整性檢查 + `tools/workflow-test` 測試套件 |
| `/quick` | Quick Mode（GSD §37），≤3 個檔案的小修正 |
| `/progress` | 從 STATE.md + TASKS.md 輸出即時進度快照 |
| `/pause` | 暫停工作，將 `resume_command` 寫入 STATE.md |
| `/handoff` | Agent 完成交接：更新 TASKS.md + STATE.md |
| `/complete-milestone` | Gate 通過後歸檔 + 更新狀態 + 可選 git tag |
| `/setup-team` | 互動式設定 TEAM.md（全 11 個角色） |

---

## 三域技術標準（`10_Standards/`）

所有 Agent 強制遵守的規範，改一處，全局生效。

| 領域 | 檔案 | 核心規則 |
|------|------|---------|
| **API** | `STD_API_Design.md` · `Error_Code_Standard_v1.0.md` | `/api/v{N}/` 版本路由 · `{ success, data, message, errorCode }` 回應格式 · `AICC-{LAYER}{CODE}` 錯誤碼格式 |
| **DB** | `STD_DB_Schema.md` · `enum_registry.yaml` · `field_registry_template.yaml` | UUID 主鍵 · `tenant_id NOT NULL` · `pii_` / `log_` / `enc_` 欄位前綴 · 可逆 Migration |
| **UI** | `STD_UI_Design.md` · `Design_Token_Reference.md` | 只用 CSS 變數 · WCAG 2.1 AA · 44px 點擊目標 · 禁止 hardcode hex |

---

## GSD 機制（§32–§41）

自動內建於每條 Pipeline，無需額外設定。

| 機制 | 功能 | §參考 |
|------|------|------|
| Context Health Check | 交接前偵測 context 衰退 | §32 |
| Discuss Phase | Pipeline 銜接時確認技術偏好 | §33 |
| Lightweight Plan Check | Agent 產出後的 5 維度自檢 | §34 |
| Nyquist 驗證層 | 每條 AC 附驗證提示，QA 從此設計 TC | §35 |
| Auto-Fix Loop | Verify 失敗 → debug → fix → re-verify（最多 3 輪）| §36 |
| Quick Mode | 小修正跳過完整 Pipeline | §37 |
| STATE.md 記憶體 | 跨 Session 狀態快照，永不失憶 | §38 |
| Wave-Based 並行 | 並行前先做依賴波分析 | §39 |
| Model Profiles | quality / balanced / budget 三檔切換 | §40 |
| map-codebase | 進入既有 Codebase 前的 4 Agent 並行掃描 | §41 |

---

## 29 個 Skills

Skill 是 Agent 自動調用的能力模組，存放於每個專案的 `context-skills/` 目錄。

**工作流 Skills（17 個）：**
`pipeline-orchestrator` · `quality-gates` · `brainstorming` · `systematic-debugging` · `verification-before-completion` · `subagent-driven-development` · `test-driven-development` · `using-git-worktrees` · `finishing-a-development-branch` · `requesting-code-review` · `webapp-testing` · `deep-research` · `frontend-design` · `update-dashboard` · `project-init` · `planning-with-files` · `screenshot-to-code`

**文件 Skills（6 個）：**
`docx` · `xlsx` · `pptx` · `pdf` · `doc-coauthoring` · `internal-comms`

**平台 Skills（6 個）：**
`algorithmic-art` · `theme-factory` · `web-artifacts-builder` · `mcp-builder` · `schedule` · `skill-creator`

---

## 品質關卡

關卡是強制檢查點，未通過不得進入下一條 Pipeline。

| 關卡 | 在何時執行 | 檢查內容 | 工具 |
|------|----------|---------|------|
| Gate 1 | P01 完成後 | 需求完整性、AC 可測試性、Prototype 覆蓋率 | `quality-gates` skill |
| Gate 2 | P02 完成後 | 架構可行性、ADR 完整性、DB Schema | `quality-gates` skill |
| G4-ENG | P03 完成後 | 跨層一致性、GA 密度、工程簽核 | `quality-gates` skill |
| Gate 3 | P04 完成後 | 測試覆蓋率 ≥80%、E2E 通過、安全審查 | `quality-gates` skill |

**重要：** Gate Review 必須在**獨立的 session** 中執行，與產出文件的 Pipeline 分開。道理等同「寫 code 的人不自己做 code review」。

```
# Cowork：開一個新的 Cowork task，選同一個專案資料夾
# Claude Code：開一個新的終端機視窗

第一句話：
"你是 Review Agent。讀取 CLAUDE.md，執行 Gate [N] 驗收。"
```

---

## 多人協作

`TEAM.md` 定義每個成員負責哪個 Agent 角色、交接協議，以及 Git 分支命名規範。`task-master` agent 讀取 `TASKS.md` + `STATE.md`，自動分配工作並在遇到阻塞時重新路由。

TASKS.md 格式：
```
| F## | 功能描述 | @負責人 | 狀態 | 阻塞項 |
```

跨 Feature 依賴：
```
F05 depends_on: F02-API-完成
```

---

## 版本

當前：**v2.4.0** — 多人協作 TEAM.md、8 個 Slash Commands、三域 10_Standards/、adopt-project 接入流程、框架健康測試工具。

完整歷史見 [CHANGELOG.md](./CHANGELOG.md)。

---

## License

MIT — 自由使用，歡迎標註出處。
