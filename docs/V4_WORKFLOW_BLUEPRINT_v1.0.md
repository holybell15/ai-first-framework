# V4 Workflow Blueprint v1.0

> **Status**: Approved — 正式藍圖基底
> **Approved by**: 凱子 + Codex Review (2 rounds) + Opus Draft
> **Date**: 2026-03-31
> **Changelog**:
> - v0.1 — Codex 初版骨架
> - v0.2 — Opus 補充（Superpowers 分析、Skill 分層、CLAUDE.md 瘦身、遷移策略）
> - v0.3 — 採納 Codex Review R1：恢復 Task-Master dispatcher、specialist role matrix、artifact registry、獨立 planning discipline
> - v0.4 — 採納 Codex Review R2：Review specialist 跨階段化、planning-with-tasks 擴充 findings/progress、Task-Master drift 職責釐清為 signal routing
> - v1.0 — 定稿，加入 residual risks 和 token budget 建議，進入實作階段

---

## 0. 設計原則 (Design Tenets)

以下五條原則指導 v4 所有設計決策。遇到取捨時，以原則編號小的優先。

| # | 原則 | 說明 |
|---|------|------|
| T1 | **Evidence over Assertion** | 所有宣稱必須附帶可驗證的證據。不是 checklist 打勾，而是跑實際指令、看實際 output。 |
| T2 | **Scope is Sacred** | Discover Gate 通過後，需求文件是唯一範圍基準。No silent scope change / redesign / requirement rewrite。 |
| T3 | **Context is Currency** | 每多載入 1K tokens 的 context 就是在花錢。Agent 只載入當前任務需要的最小 context；subagent 不繼承 controller 的 session history。 |
| T4 | **Fix Upstream, Not Downstream** | 若發現需求/設計有誤，回上游文件修正後再重新往下執行。不在下游硬修、不靠 patch 掩蓋。 |
| T5 | **Process over Guessing** | 遇到問題用結構化流程解決，不用直覺猜。 |

---

## 1. 流程骨架 (Pipeline Stages)

### 1.1 主流程

```
Discover → Plan → Build → Verify → Ship
```

| 階段 | 目的 | 典型產出 | 出口 Gate |
|------|------|----------|-----------|
| **Discover** | 收集需求、釐清範圍、確認 MVP 邊界 | SRS、AC、WBS、Scope Baseline | Discover Gate |
| **Plan** | 架構設計、模組邊界、API/DB/UI baseline | System Design、Slice Backlog、Design Baseline | Plan Gate |
| **Build** | 垂直切片實作、TDD、Code Review | Working code、Test suites、PR | Build Gate |
| **Verify** | 整合測試、回歸測試、合規審查 | Test Reports、Security Audit、Release Evidence | Ship Gate |
| **Ship** | 部署、Smoke Test、監控、Retrospective | Release Notes、Deployment Record、Retro Report | — |

### 1.2 特殊通道

| 通道 | 觸發條件 | 流程 |
|------|----------|------|
| **Lite** | 首次功能 / 小型需求 / PoC | Discover(簡) → Plan(簡) → Build → Ship（跳過 Verify 的合規部分） |
| **Brownfield** | 接手既有程式碼 | Baseline → Snapshot → Gap Report → First Real Change → 併入主流程 |
| **Hotfix** | 線上 Critical/High 事件 | Incident → Root Cause → Minimal Fix → Rollback Plan → Smoke → Follow-up Issue |

### 1.3 Task-Master Dispatcher

> **v0.3 修正**：v0.2 試圖將 Task-Master 完全嵌入 CLAUDE.md 作為 if-else 路由。Codex review 指出路由判斷經常需要上下文推理（判斷 blocker 歸屬、scope drift 偵測、跨角色依賴），不是純 if-else 能解決。v0.3 恢復 Task-Master 為獨立 dispatcher，但做輕量化改造。

**Task-Master 是什麼**：一個輕量 dispatcher 角色，不是 v3.3 那種吃全局 context 的 pipeline-orchestrator Agent。

**Task-Master 的職責（只做這三件事）**：

1. **分派（Route）**— 讀 STATE.md + TASKS.md，判斷下一步該由哪個 specialist 執行、載入哪些 skill
2. **接收信號並路由（Receive Signal & Route）**— 接收 specialist 回報的 blocked / scope drift / design drift / test escalation 信號，根據信號類型決定退回哪一層或轉交哪個 specialist
3. **交接（Handoff）**— 管理 specialist 之間的交接，確保 handoff protocol 被執行

> **v0.4 釐清：Task-Master 對 drift 是「路由」而非「判斷」**
>
> Task-Master **不主動偵測** scope drift 或 design drift — 它的可見資訊（STATE + TASKS）不足以獨立做出這類判斷。Drift 的發現責任在 specialist 身上（例如 Backend 發現實作需求超出 SRS 範圍、Frontend 發現設計與 Baseline 不符）。
>
> Specialist 發現 drift 後，必須向 Task-Master 發出 **drift signal**，格式為：
> ```
> DRIFT_SIGNAL:
>   type: scope_drift | design_drift | test_escalation
>   source_specialist: "[誰發現的]"
>   evidence: "[具體描述 + 對照的 baseline 文件]"
>   suggested_action: "[specialist 建議的處理方式]"
> ```
>
> Task-Master 收到 signal 後：
> 1. 讀取 ARTIFACTS.md 確認相關文件的 baselined 狀態
> 2. 根據 drift type 決定路由：scope drift → 退回 Discover；design drift → 退回 Plan；test escalation → 判斷是 code bug（留 Build）還是上游問題（退回）
> 3. 更新 STATE.md 和 TASKS.md

**Task-Master 不做的事**：
- 不主動偵測 drift（那是 specialist 的責任）
- 不載入專案的完整技術 context
- 不做實作、不寫 code、不做設計
- 不做 Gate 審查（那是 Review specialist 的事）
- 不取代 specialist 的專業判斷

**Task-Master 的 context 限制**：
- 必載：STATE.md (~300 tokens) + TASKS.md (任務清單部分)
- 可載：project-config.yaml（判斷啟用了哪些 skill）、ARTIFACTS.md（確認 baselined 狀態，僅在處理 drift signal 時讀取）
- 不載：SRS、API Spec、Schema、任何正式文件的完整內容

**Task-Master skill**：
```
context-skills/task-master/SKILL.md
├── 分派規則：stage → specialist → skill loadout 的對照表
├── 攔截規則：哪些狀態必須回 Task-Master
├── 交接模板：handoff log 格式
└── 回退規則：各種回退場景的處理方式
```

**何時回到 Task-Master**：
- 任務 blocked
- 需要 handoff 到不同 specialist
- scope issue / design drift 被偵測到
- 測試 escalation（測試顯示上游文件有誤）
- specialist 完成當前任務
- Agent 主動呼叫（遇到超出職責範圍的判斷）

**何時不需要回 Task-Master**：
- specialist 在自己職責範圍內的連續任務（例如 Backend 連續完成多個 API endpoint）
- 同一個 specialist 的下一個 task 已經在 TASKS.md 中明確排定

---

## 2. 檢查口 (Quality Gates)

### 2.1 Gate 定義

| Gate | 位於 | 必須滿足 | 審查方式 |
|------|------|----------|----------|
| **Discover Gate** | Discover → Plan | SRS 完整、AC 可測試、WBS 已拆、MVP 邊界已確認、Stakeholder 已簽核 | Review specialist (Standard) 或 Checklist pass (Lite) |
| **Plan Gate** | Plan → Build | 架構完整、模組邊界清楚、API/DB spec 已定義、UI Design Baseline locked、Slice Backlog 已建立、測試策略已定義 | Review specialist (Standard) 或 Checklist pass (Lite) |
| **Build Gate** | Build → Verify | 所有 Slice 實作完成、unit/integration test 通過率達標、無 scope drift（對照 SRS）、Code Review 已通過 | Review specialist + 自動化測試報告 |
| **Ship Gate** | Verify → Ship | E2E/Smoke test 通過、合規審查完成（如適用）、Rollback plan 已準備、Release evidence 齊全 | Review specialist + 部署前 checklist |

### 2.2 Gate 輕重量級

| 模式 | 適用場景 | 做法 |
|------|----------|------|
| **Standard** | 正式專案、多人協作、客戶交付 | 完整 Review specialist session，產出 Gate Review Note |
| **Lite** | PoC、個人專案、內部工具 | 自動 checklist 驗證，人工確認關鍵項即可 |

### 2.3 Gate 失敗處理

Gate 未通過時：
1. 列出具體未達標項目（附證據，非主觀判斷）
2. 判斷問題出在哪一層（需求？設計？實作？測試？）
3. **退回到問題所在的上游階段修正**（T4 原則）
4. 修正完畢後重新執行 Gate

---

## 3. Agent 架構 (Specialist Role Matrix)

> **v0.3 修正**：v0.2 將 11 個角色壓成 3 個 Profile，Codex review 指出不同角色有不同的禁止事項和品質標準，壓太扁會丟失治理精度。v0.3 恢復 specialist role matrix，但做結構性重組：以 3 個 Agent Group 為骨架，每個 Group 內保留 specialist role 的區分。

### 3.1 架構概覽

```
Task-Master (dispatcher)
  │
  ├── Discovery Group
  │     ├── Interviewer / PM specialist
  │     ├── UX specialist
  │     └── Architect specialist
  │
  ├── Build Group
  │     ├── Backend specialist
  │     ├── Frontend specialist
  │     └── DBA specialist
  │
  ├── Verify Group
  │     ├── QA specialist
  │     ├── Security specialist
  │     └── DevOps specialist
  │
  └── Review specialist ← 跨階段角色，不隸屬任何 Group
```

> **v0.4 修正：Review specialist 提升為跨階段角色**
>
> v0.3 將 Review specialist 放在 Verify Group 內，但 Discover Gate 和 Plan Gate 也依賴 Review specialist 審查。若 Task-Master 按 stage → Group → specialist 路由，Discover/Plan 階段就無法合理調度 Review。
>
> v0.4 將 Review specialist 從 Verify Group 中提出，定義為**跨階段角色**：
> - Review specialist 可在**任何 stage** 被 Task-Master 調度
> - 它的主要觸發點是 Gate（Discover Gate、Plan Gate、Build Gate、Ship Gate）
> - 它也可以在 stage 中途被呼叫（例如 Build 階段的 Code Review）
> - 它有自己獨立的角色定義檔案，不放在任何 GROUP_*.md 中

### 3.2 Group vs Specialist 的分工

| 層級 | 定義 | 決定什麼 |
|------|------|----------|
| **Group** | 同階段的 specialist 共享的通用行為 | 可用 skill 範圍、交接格式、與其他 Group 的介面 |
| **Specialist** | 特定職能的角色約束 | 禁止事項、品質標準、輸入/輸出契約、專用 context |

### 3.3 Specialist 定義檔案結構

取代 v3.3 的 13 個獨立 SEED 檔案，v4 採用 **Group 檔 + Specialist 區塊** 的結構：

```
context-roles/
├── GROUP_Discovery.md      (~1.5K tokens)
│   ├── §通用行為（所有 Discovery specialist 共享）
│   ├── §Interviewer/PM specialist
│   ├── §UX specialist
│   └── §Architect specialist
│
├── GROUP_Build.md           (~1.5K tokens)
│   ├── §通用行為（所有 Build specialist 共享）
│   ├── §Backend specialist
│   ├── §Frontend specialist
│   └── §DBA specialist
│
├── GROUP_Verify.md          (~1.2K tokens)
│   ├── §通用行為（所有 Verify specialist 共享）
│   ├── §QA specialist
│   ├── §Security specialist
│   └── §DevOps specialist
│
└── ROLE_Review.md           (~800 tokens) ← 獨立檔案，跨階段
    ├── §職責：Gate 審查 + Code Review
    ├── §可被調度的時機（任何 stage 的 Gate + Build 中途 Code Review）
    ├── §審查標準（依 Gate 類型不同）
    └── §禁止事項（不可修改被審查的 artifact）
```

**為什麼不是 13 個獨立檔案**：
- 同 Group 的 specialist 有大量共享行為（例如所有 Build specialist 都要遵守 TDD、都用 git worktree）
- 共享行為寫一次，specialist 區塊只寫差異部分
- 4 個檔案（3 Group + 1 跨階段 Review）比 13 個更容易維護和同步

**為什麼不是只有 3 個 Profile**：
- Backend specialist 和 Frontend specialist 的禁止事項不同（Backend 不碰 UI，Frontend 不碰 DB）
- DBA specialist 需要載入 DB standards，Backend 不一定需要
- Review specialist 需要跨階段調度，如果綁死在 Verify Group 會造成前兩個 Gate 的路由歧義
- 這些差異如果不明確寫出來，Agent 會自己亂跨界

### 3.4 每個 Specialist 區塊的結構

```markdown
### [Specialist Name]

**職責**：[1-2 句]
**必載 Skill**：[此 specialist 進場時必須載入的 skill]
**可選 Skill**：[依任務按需載入]
**專用 Context**：[此 specialist 需要讀取的參考檔案]
**禁止事項**：[明確列出不可做的事]
**完成標準**：[任務完成時必須滿足的條件]
```

### 3.5 Specialist Skill Loadout（完整對照表）

| Specialist | 必載 Skill | 可選 Skill |
|------------|-----------|------------|
| **Task-Master** | task-master, verification-before-completion | — |
| **Interviewer/PM** | brainstorming, planning-with-tasks, verification-before-completion | deep-research, doc-coauthoring |
| **UX** | brainstorming, frontend-design, verification-before-completion | screenshot-to-code |
| **Architect** | brainstorming, writing-plans, deep-research, verification-before-completion | — |
| **Backend** | writing-plans, test-driven-development, systematic-debugging, using-git-worktrees, requesting-code-review, verification-before-completion | ground, validate-contract |
| **Frontend** | writing-plans, test-driven-development, systematic-debugging, frontend-design, using-git-worktrees, requesting-code-review, verification-before-completion | ground, screenshot-to-code |
| **DBA** | verification-before-completion, validate-contract | ground |
| **QA** | webapp-testing, systematic-debugging, verification-before-completion | — |
| **Security** | verification-before-completion, deep-research | — |
| **DevOps** | verification-before-completion | — |
| **Review** | gate-check, verification-before-completion | — |

**原則**：
- Agent 不自己挑 skill，進場時由 Task-Master 根據 stage + specialist 決定 loadout
- Domain skill（如 call-center-domain）掛在既有 specialist 上，不另開 specialist
- 同一個 specialist 在不同任務可能有不同的可選 skill 載入

### 3.6 Subagent 拆分規則

當任務需要深度專業知識，且 context 會互相干擾時，從 specialist 拆出 subagent：

```
觸發條件：
- 複雜 DB migration（需要完整 schema context）
- 安全審查（需要 OWASP/合規 reference）
- 效能優化（需要 profiling data）
- 3+ 個獨立任務可平行執行（使用 subagent-driven-development skill）

subagent 規則：
- Controller（Task-Master 或當前 specialist）主動組裝 subagent 需要的最小 context
- Subagent 不繼承 controller 的 session history（T3 原則）
- Subagent 完成後回報結果，由 controller 整合
- 使用 git worktree 做隔離開發（如涉及程式碼修改）
```

---

## 4. Skill 架構 (Skill Tiers)

### 4.1 三層分類

| 層級 | 定義 | 載入方式 | 數量 |
|------|------|----------|------|
| **Tier 1: Core Disciplines** | 行為約束型 — 「你必須怎麼做」 | 符合條件時強制載入，不可跳過 | 11 |
| **Tier 2: Domain & Governance** | 領域/治理型 — 「這個專案的特殊規則」 | 依 project-config.yaml 按需載入 | 按專案定義 |
| **Tier 3: Platform Tools** | 工具型 — 「幫你產出特定格式」 | 由平台（Cowork/Claude Code）自動處理 | 不計入框架 |

### 4.2 Tier 1: Core Disciplines（框架核心，全專案通用）

| Skill | 觸發條件 | v0.3 說明 |
|-------|----------|-----------|
| **task-master** | 每個 session 開始、每次 handoff、每次 blocked | **新增** — Task-Master dispatcher 的分派/攔截/交接規則 |
| **test-driven-development** | 寫任何新 code 時 | 保留 |
| **systematic-debugging** | 遇到 bug / 非預期行為 | 保留 |
| **verification-before-completion** | 任何 specialist 完成任務前 | 保留，合併 forced-thinking 的思考模板 |
| **brainstorming** | 探索新功能 / 不確定方向時 | 保留 |
| **writing-plans** | 開始實作前的計畫拆解 | 保留（負責把任務拆成可執行的 plan） |
| **planning-with-tasks** | 執行過程中的進度追蹤與過程知識記錄 | **v0.4 擴充**：除了 TASKS.md 狀態追蹤，增加 findings/progress 落點，承接執行過程中的中間知識（research findings、debug observations、驗證結果、失敗嘗試等） |
| **requesting-code-review** | 提交 code review 時 | 保留 |
| **using-git-worktrees** | 開始 feature 開發時 | 保留 |
| **gate-check** | 階段結束，準備過 Gate 時 | 從 quality-gates 簡化重構 |
| **ground** | AI 修改既有程式碼前 | 保留 |

**共 11 個 Tier 1 skill。**

**writing-plans vs planning-with-tasks 的分工**：
| | writing-plans | planning-with-tasks |
|---|---|---|
| **何時用** | 任務開始前 | 任務執行中 |
| **做什麼** | 把 Feature 拆解成 2-5 分鐘的原子任務，寫出具體的 code / 指令 / 路徑 | 追蹤 TASKS.md 狀態 + 記錄執行過程中的 findings 和 progress |
| **產出** | 可執行的實作計畫 | 更新後的 TASKS.md + findings.md + progress.md |
| **為什麼不合併** | Plan（思考如何做）和 Track（記錄做到哪 + 學到什麼）是不同的認知活動 |

> **v0.4 擴充：planning-with-tasks 的 findings/progress 機制**
>
> v0.3 將 planning-with-tasks 定義得太窄，只做 TASKS.md 狀態更新。但長流程中會產生大量中間知識（research findings、debug observations、驗證結果、失敗嘗試），這些如果不落在正式 artifact 或 ADR，就會漂回對話裡消失。
>
> v0.4 擴充 planning-with-tasks 為三個落點：
>
> | 落點 | 用途 | 範例 |
> |------|------|------|
> | **TASKS.md** | 任務狀態追蹤 | task status 更新、dependency 標記、blocker 記錄 |
> | **findings.md** | 過程中的發現與觀察（per-feature，放在 task 工作目錄） | debug 時發現的 root cause 分析、research 比較結果、「這個方案行不通因為...」的記錄 |
> | **progress.md** | 階段性進度總結（per-feature，放在 task 工作目錄） | 「目前完成了 3/7 個 API，發現 schema 需要調整，已發 drift signal」 |
>
> **findings.md 和 progress.md 的定位**：
> - 它們不是正式文件（不登記在 ARTIFACTS.md）
> - 它們是 specialist 的「工作筆記」，幫助同一 specialist 跨 session 恢復 context，或幫助下一個 specialist 理解前因後果
> - 如果 finding 足夠重要（例如發現了架構性問題），應該提升為 ADR 寫進 DECISIONS.md
> - 每個 Feature 的 findings/progress 放在該 Feature 的工作目錄下，Feature 完成後可歸檔或刪除

### 4.3 Tier 2: Domain & Governance（專案特定，按需配置）

| Skill | 類型 | 何時載入 |
|-------|------|----------|
| **call-center-domain** | Domain | 專案屬於 Call Center 領域 |
| **frontend-design** | Governance | Build 階段做 UI 實作時 |
| **deep-research** | Technique | 技術選型 / 比較方案時 |
| **webapp-testing** | Technique | 測試 Prototype 或前端元件 |
| **doc-coauthoring** | Technique | 共同撰寫正式文件 |
| **screenshot-to-code** | Technique | 收到設計稿需還原 |
| **validate-contract** | Governance | API/Schema 變更時驗證一致性 |
| **cia** | Governance | 變更已 Approved/Baselined 文件前 |
| **ssot-guardian** | Governance | 懷疑文件資訊不同步時 |
| **retro** | Technique | 完成 milestone 後做回顧（合併 quantitative-retro） |
| **finishing-a-development-branch** | Technique | Feature 完成，準備 merge |
| **subagent-driven-development** | Technique | 需要多 Agent 並行時 |
| **new-doc** | Technique | 需要建立新的正式文件 |
| **project-init** | Utility | 初始化新專案 |

**Tier 2 skill 由專案的 `project-config.yaml` 定義啟用清單。**

### 4.4 Tier 3: Platform Tools（移出框架，由平台處理）

| Skill | 原因 |
|-------|------|
| docx / pptx / xlsx / pdf | 平台文件工具 |
| algorithmic-art | 平台創意工具 |
| theme-factory | 平台樣式工具 |
| web-artifacts-builder | 平台 artifact 工具 |
| mcp-builder | 開發者工具，非框架核心 |
| schedule | 平台排程工具 |
| internal-comms | 通用溝通工具，非框架核心 |
| gemini-designer / codex | 外部 AI 工具 |

### 4.5 淘汰 / 合併清單

| 原 Skill | 處置 | 原因 |
|----------|------|------|
| pipeline-orchestrator | **重構**為 task-master skill | 瘦身為 dispatcher 邏輯 |
| planning-with-files | **重新命名**為 planning-with-tasks | 專注 TASKS.md 追蹤，不再管 plan 拆解 |
| slice-cycle | **合併**至 Build 階段流程 | 垂直切片是 Build 的標準做法，不需獨立 skill |
| quality-gates | **重構**為 gate-check | 簡化，只做 checklist 驗證 + evidence 收集 |
| forced-thinking | **合併**至 verification-before-completion | 思考模板整合進完成驗證流程 |
| execution-trace | **淘汰** | 過度 overhead，用 git log + TASKS.md 取代 |
| destructive-guard | **降級**為 git hook | 不需要是 skill，用 pre-commit hook 處理 |
| info-ship / info-canary / info-doc-sync | **合併**為 Ship 階段的標準步驟 | 不需要 3 個獨立 skill |
| update-dashboard | **淘汰** | Dashboard 改為從 TASKS.md + ARTIFACTS.md 自動生成 |
| find-skills | **淘汰** | v4 skill 結構清晰，不需要搜尋工具 |
| skill-creator | **保留但移出核心** | 開發者工具 |
| quantitative-retro | **合併**至 retro | 一個回顧 skill 即可 |

---

## 5. 記憶體架構 (Memory System)

### 5.1 核心記憶（Active Memory）— 4 個檔案

> **v0.3 修正**：v0.2 的 3 個檔案 + v0.3 恢復 ARTIFACTS.md 作為第 4 個，承接 MASTER_INDEX.md 的 artifact registry 功能。

#### `memory/STATE.md` — 現在在哪（~300 tokens）

```yaml
stage: "Build"                      # Discover | Plan | Build | Verify | Ship
mode: "standard"                    # standard | lite
task_current: "F01-API-users"       # 當前任務 ID
task_status: "in_progress"          # todo | in_progress | blocked | in_review
blocked_by: null                    # null 或 "[原因]"

dispatcher:
  active_specialist: "Backend"      # 當前 specialist 角色
  active_group: "Build"             # 當前 Group
  skills_loaded:                    # 當前已載入的 skill
    - test-driven-development
    - using-git-worktrees
    - writing-plans

next_action: "寫 GET /users 的 unit test"
resume_command: "繼續 Backend specialist, 任務 F01-API-users"
last_updated: "2026-03-31T14:00:00+08:00"
```

#### `memory/TASKS.md` — 要做什麼（唯一任務真相來源）

```markdown
# TASKS — Single Source of Truth

## WBS: F01 使用者管理
| Task ID | Description | Status | Specialist | Evidence | Dependency |
|---------|-------------|--------|------------|----------|------------|
| F01-API-users | GET /users endpoint | done | Backend | test passed, PR #12 | — |
| F01-API-user-detail | GET /users/:id endpoint | in_progress | Backend | — | — |
| F01-UI-list | 使用者列表頁面 | todo | Frontend | — | F01-API-users |
| F01-UI-detail | 使用者詳情頁面 | blocked | Frontend | — | blocked: F01-API-user-detail |

## Handoff Log
| Time | From | To | Summary | Artifacts | Blockers | Frozen |
|------|------|----|---------|-----------|----------|--------|
| 03-31 12:00 | UX | Architect | Prototype 完成 | proto_F01.html | 無 | Exploration proto |
| 03-31 14:00 | Architect | Backend | System Design 完成，Plan Gate 通過 | SD.md, API-Spec.md | 無 | SRS, SD, API-Spec, DB-Schema |

## Open Questions
- 🔴 [阻塞] 使用者匯入格式待客戶確認 — Owner: PM
- 🟡 [待討論] 是否支援 batch delete — Owner: Architect
```

#### `memory/ARTIFACTS.md` — 正式產出登記簿

> **v0.3 新增**：恢復 MASTER_INDEX.md 的核心功能，但簡化為只追蹤正式文件（不追蹤草稿和工作檔案）。

```markdown
# ARTIFACTS — Formal Document Registry

| doc_id | Name | Version | Maturity | Gate Locked | Owner | Path |
|--------|------|---------|----------|-------------|-------|------|
| SRS.F01 | F01 使用者管理需求規格 | 1.0 | Baselined | Discover Gate | PM | docs/specifications/SRS_F01.md |
| SD.F01 | F01 系統設計 | 1.0 | Baselined | Plan Gate | Architect | docs/design/SD_F01.md |
| API.F01 | F01 API 規格 | 1.0 | Baselined | Plan Gate | Architect | docs/design/API_F01.md |
| DB.F01 | F01 DB Schema | 1.0 | Baselined | Plan Gate | DBA | docs/design/DB_F01.md |
| TR.F01 | F01 測試報告 | — | Draft | — | QA | docs/test-reports/TR_F01.md |
```

**Maturity 生命週期**：
```
Draft → In Review → Approved → Baselined (Gate locked) → Deprecated
```

- **Baselined** = Gate 鎖定後不可修改，除非走 CIA（Change Impact Assessment）流程退回上游
- **Deprecated** = 被新版本取代，保留在 registry 但標記為 deprecated

**ARTIFACTS.md 的維護規則**：
- 只登記正式文件（經過 Gate 或正式 review 的）
- 草稿、工作筆記、暫存檔不登記
- 每次 Gate 通過時，由 Review specialist 更新 maturity 和 gate_locked

#### `memory/DECISIONS.md` — 為什麼這樣做（Append-only ADR log）

```markdown
# Architecture Decision Records

## ADR-001: 使用 PostgreSQL 而非 MongoDB
- **Date**: 2026-03-28
- **Status**: Accepted
- **Context**: 需要 ACID transaction 支援，資料結構偏 relational
- **Decision**: PostgreSQL 15+
- **Consequences**: 需要 migration tool (Prisma)，團隊需熟悉 SQL

## ADR-002: API 採用 REST 而非 GraphQL
- **Date**: 2026-03-29
- **Status**: Accepted
- **Context**: 前端需求明確，不需要 flexible query
- **Decision**: RESTful API with OpenAPI 3.0 spec
- **Consequences**: 可能需要 BFF layer 若未來前端需求複雜化
```

### 5.2 靜態參考（Reference — 不算記憶體，按需讀取）

```
context/
├── product.md          # 產品概述（名稱、類型、技術棧、階段）
├── domain/             # 領域知識（call-center-domain 等）
├── standards/          # API/DB/UI 設計標準
├── company/            # 公司/組織背景
└── people/             # 團隊成員資訊
```

### 5.3 記憶體原則

| 原則 | 說明 |
|------|------|
| **STATE 只記現在** | 不記歷史，不記「做過什麼」，只記「現在在哪、下一步、誰在做」 |
| **TASKS 是唯一任務真相** | Dashboard、報告、進度追蹤全部從 TASKS.md 衍生 |
| **ARTIFACTS 只記正式文件** | 草稿不登記；每次 Gate 更新 maturity |
| **DECISIONS 只增不改** | 決策可以被新 ADR supersede，但不刪除舊的 |
| **Subagent 不繼承記憶** | Controller 從這 4 個檔案中提取 subagent 需要的最小資訊，手動傳入（T3 原則） |
| **Context > 60% 時存檔** | 自動將當前狀態寫入 STATE.md，確保下一個 session 可以接續 |

---

## 6. CLAUDE.md 架構（目標 < 5K tokens）

> **v0.3 修正**：v0.2 目標 < 3K，但恢復 Task-Master dispatcher 和 specialist matrix 後，CLAUDE.md 需要包含分派邏輯和角色索引。調整目標為 < 5K tokens。

### 6.1 v4 CLAUDE.md 結構

```markdown
# [專案名稱]

## 專案概要
- 產品：[名稱]
- 類型：[web-app | api | mobile | library]
- 技術棧：[stack]
- 模式：[standard | lite]
- 當前階段：讀取 memory/STATE.md

## 設計原則
1. Evidence over Assertion — 所有宣稱附帶證據
2. Scope is Sacred — Gate 後不擅自擴範圍
3. Context is Currency — 只載入需要的 context
4. Fix Upstream — 問題回上游修
5. Process over Guessing — 結構化解決

## Task-Master Dispatcher
### 分派邏輯
1. 讀 STATE.md → 判斷 stage + current task
2. 根據 stage 判斷 Group → 根據 task 性質判斷 specialist
3. 根據 specialist 載入必載 skill + 依任務加載可選 skill
4. 移交給 specialist 執行

### Signal Routing（specialist 回報 → Task-Master 路由）
- blocked / needs_discussion → Task-Master 判斷轉交或等待
- drift signal（scope/design/test） → Task-Master 讀 ARTIFACTS.md baseline 後路由回退
- handoff → Task-Master 執行交接協議
- specialist 完成任務 → Task-Master 分派下一個

### 回退規則
- 需求層問題 → 退回 Discover，重過 Discover Gate
- 設計層問題 → 退回 Plan，重過 Plan Gate
- 實作層問題 → 在 Build 內修復
- 合規層問題 → 在 Verify 內修復

## Specialist Role Index
| Group | Specialist | Role File |
|-------|------------|-----------|
| Discovery | Interviewer/PM, UX, Architect | context-roles/GROUP_Discovery.md |
| Build | Backend, Frontend, DBA | context-roles/GROUP_Build.md |
| Verify | QA, Security, DevOps | context-roles/GROUP_Verify.md |
| 跨階段 | Review | context-roles/ROLE_Review.md |

## Skill 觸發索引
### Tier 1 — 強制（符合條件時必須載入）
| 觸發條件 | Skill |
|----------|-------|
| session 開始 / handoff | task-master |
| 寫任何 code | test-driven-development |
| 遇到 bug | systematic-debugging |
| 完成任務前 | verification-before-completion |
| 探索想法 | brainstorming |
| 開始實作計畫 | writing-plans |
| 追蹤任務進度 | planning-with-tasks |
| 提交 review | requesting-code-review |
| 開 feature branch | using-git-worktrees |
| 過 Gate | gate-check |
| 改既有 code | ground |

### Tier 2 — 按需（依 project-config.yaml）
見 project-config.yaml → tier2_skills

## 記憶體
| 用途 | 檔案 |
|------|------|
| 現在在哪 | memory/STATE.md |
| 要做什麼 | memory/TASKS.md |
| 正式產出 | memory/ARTIFACTS.md |
| 為什麼這樣做 | memory/DECISIONS.md |
| 參考資料 | context/ |
```

---

## 7. 交接協議 (Handoff Protocol)

### 7.1 標準交接格式

每次 specialist 切換時，必須在 TASKS.md 的 Handoff Log 寫入：

```markdown
| Time | From | To | Summary | Artifacts | Blockers | Frozen |
|------|------|----|---------|-----------|----------|--------|
| [timestamp] | [specialist] | [specialist] | [1-2句摘要] | [產出檔案] | [blocker或無] | [已凍結文件] |
```

### 7.2 同時更新 STATE.md

```yaml
stage: "[新階段]"
task_current: "[下一個任務 ID]"
dispatcher:
  active_specialist: "[新 specialist]"
  active_group: "[新 Group]"
  skills_loaded: []    # 清空，由 Task-Master 根據新任務重新載入
next_action: "[下一位要做什麼]"
resume_command: "[恢復指令]"
```

### 7.3 交接必含項目

1. **完成事項** — 做了什麼（1-3 句）
2. **證據** — 產出的檔案、通過的測試、PR 連結
3. **已凍結內容** — 不可再改的文件（Gate 鎖定的，登記在 ARTIFACTS.md）
4. **待決策** — 需要人工判斷的 open question
5. **風險與 blocker** — 已知的阻塞和風險
6. **下一位可動範圍** — 明確界定接手者能做和不能做的事

---

## 8. WBS 與執行監控

### 8.1 WBS 規則

- 每個 Feature 必須先拆成 WBS，再進 Build
- 每個 Task 拆到 **2-5 分鐘可完成**的粒度
- 每個 Task 必須有明確的完成標準（不是「寫 API」，而是「建立 GET /users endpoint，回傳 mock data，通過 unit test」）
- Task 不可含 placeholder 或 TBD
- 每個 Task 必須標記 Dependency（如果有）

### 8.2 任務狀態

```
todo → in_progress → [blocked | needs_discussion | in_review] → done
```

| 狀態 | 定義 | 誰可以設定 |
|------|------|------------|
| **todo** | 已定義，未開始 | Task-Master / writing-plans |
| **in_progress** | 正在執行（同一時間只有 1 個） | 當前 specialist |
| **blocked** | 被外部依賴阻塞 | 當前 specialist → 回 Task-Master |
| **needs_discussion** | 需要人工決策 | 當前 specialist → 回 Task-Master |
| **in_review** | 等待 code review 或 Gate | 當前 specialist → Review specialist |
| **done** | 完成，附帶 evidence | 當前 specialist（經 verification-before-completion 確認） |

### 8.3 監控原則

- **TASKS.md 是唯一任務真相來源**
- Dashboard（如果需要）從 TASKS.md + ARTIFACTS.md 自動生成，不手動維護
- 不維護獨立的 sprint board、kanban、或 Gantt

---

## 9. 設計與 Prototype 範圍控制

### 9.1 Prototype 分類

| 類型 | 用途 | 可修改範圍 |
|------|------|------------|
| **Exploration Prototype** | Discover 階段探索，不代表最終設計 | 任意修改 |
| **Approved Prototype** | Plan Gate 通過後鎖定的設計基準 | 僅限 `[unlocked: 原因]` 標記的元素 |

### 9.2 Design Baseline（Plan Gate 產出）

Plan Gate 通過時必須產出 Design Baseline，包含：
- 視覺方向（色彩、字型、間距 token）
- 元件語言（使用的 design system）
- 版面結構（layout grid）
- 互動原則（hover/click/transition）

Design Baseline 登記在 ARTIFACTS.md，maturity 設為 Baselined。

### 9.3 Build 階段 UI 規則

**允許**：Fidelity 實作、響應式修正、可用性微調、接線必要調整

**禁止**（預設 locked，除非明確標記 `[unlocked: 原因]`）：
- 更換風格 / 視覺方向
- 更換版型 / layout 結構
- 更換主要互動模式
- 更換設計語言 / 核心元件

**超出範圍 → 走 CIA 流程 → 退回 Plan Gate 重審**

---

## 10. 測試治理

### 10.1 追溯鏈

```
AC (Acceptance Criteria) → Test Case → Test Execution → Test Report
```

- 每個 AC 必須有對應的 Test Case
- 沒有需求依據的測試不算正式覆蓋
- 沒有測試證據不得宣稱完成（T1 原則）

### 10.2 測試層級與 Gate 門檻

| 層級 | 範圍 | Build Gate 最低要求 |
|------|------|---------------------|
| **Unit** | 單一函式/模組 | 80% coverage |
| **Integration** | 模組間互動 | 關鍵路徑 100% |
| **E2E** | 使用者完整流程 | Happy path + 主要 edge case |
| **Smoke** | 部署後快速驗證 | Ship Gate 必要 |

### 10.3 測試失敗處理

1. 判斷是 code bug 還是需求/設計本身有誤
2. code bug → 在 Build 階段修復
3. 需求/設計有誤 → **退回上游文件修正**（T4 原則），不靠 patch 掩蓋
4. 退回時走 CIA 流程，更新 ARTIFACTS.md 的文件版本

---

## 11. Brownfield / Hotfix

### 11.1 Brownfield（接手既有程式碼）

```
1. Baseline：建立現有程式碼的 snapshot（git tag）
2. Snapshot：記錄現狀（tech stack, dependencies, test coverage, known issues）
3. Gap Report：對照目標，列出需要改的東西
4. First Real Change：第一個實際修改，走正式 Build 流程
5. 之後併入主流程
```

### 11.2 Hotfix（緊急修復）

```
1. Incident：記錄問題（severity, impact, reporter）
2. Root Cause：找到根因（mandatory systematic-debugging skill）
3. Minimal Fix：最小修復，不擴大範圍
4. Rollback Plan：確認可以 rollback
5. Smoke Test：部署後立即驗證
6. Follow-up：建立正式 issue 追蹤後續
```

Hotfix 不可用來偷渡新功能。修復範圍限於 incident 直接相關的 code。

---

## 12. 專案配置 (Project Config)

### 12.1 `project-config.yaml`

```yaml
project:
  name: "[專案名稱]"
  type: "web-app"              # web-app | api | mobile | library
  stack: "Vue 3 + Node.js + PostgreSQL"
  mode: "standard"             # standard | lite

tier2_skills:                  # 啟用的 Tier 2 skill
  - frontend-design
  - webapp-testing
  - deep-research
  - validate-contract
  - doc-coauthoring

domain:
  - call-center-domain         # 載入的 domain skill

gate_mode:
  discover: "standard"         # standard | lite
  plan: "standard"
  build: "standard"
  ship: "standard"

test_thresholds:
  unit_coverage: 80
  integration_critical_path: 100
  e2e_happy_path: true

artifact_maturity_tracking: true  # 是否啟用 ARTIFACTS.md 的完整成熟度追蹤
```

---

## 13. 檔案結構 (v4 Template)

```
[project-root]/
├── CLAUDE.md                        # < 5K tokens 精簡導航 + dispatcher 邏輯
├── project-config.yaml              # 專案設定
│
├── memory/
│   ├── STATE.md                     # 現在在哪（~300 tokens）
│   ├── TASKS.md                     # 要做什麼（唯一任務真相來源）
│   ├── ARTIFACTS.md                 # 正式產出登記簿
│   └── DECISIONS.md                 # ADR log
│
├── context/
│   ├── product.md                   # 產品概述
│   ├── domain/                      # 領域知識
│   ├── standards/                   # API/DB/UI 設計標準
│   │   ├── api-design.md
│   │   ├── db-schema.md
│   │   └── ui-design.md
│   ├── company/                     # 公司背景
│   └── people/                      # 團隊成員
│
├── context-roles/
│   ├── GROUP_Discovery.md           # Interviewer/PM + UX + Architect
│   ├── GROUP_Build.md               # Backend + Frontend + DBA
│   ├── GROUP_Verify.md              # QA + Security + DevOps
│   └── ROLE_Review.md               # Review specialist（跨階段）
│
├── context-skills/                  # Tier 1 + Tier 2 skills
│   ├── task-master/                 # Dispatcher 規則
│   ├── test-driven-development/
│   ├── systematic-debugging/
│   ├── verification-before-completion/
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── planning-with-tasks/         # 重新命名自 planning-with-files
│   ├── requesting-code-review/
│   ├── using-git-worktrees/
│   ├── gate-check/
│   ├── ground/
│   └── [tier-2-skills]/             # 依 project-config.yaml 配置
│
├── docs/
│   ├── specifications/              # SRS、AC、Scope Baseline
│   ├── design/                      # Architecture、API Spec、DB Schema
│   ├── test-reports/                # Test execution results
│   └── releases/                    # Release notes、deploy records
│
├── prototypes/
│   ├── exploration/                 # Discover 階段探索用
│   └── approved/                    # Plan Gate 後鎖定的設計基準
│
└── src/                             # 程式碼（依技術棧結構）
```

### 13.1 v3.3 → v4 檔案對照

| v3.3 | v4 | 說明 |
|------|----|------|
| CLAUDE.md (25K) | CLAUDE.md (< 5K) | 瘦身但保留 dispatcher 邏輯 |
| context-seeds/ (13 files) | context-roles/ (3 Group + 1 Review) | 合併為 Group + specialist 區塊，Review 獨立跨階段 |
| memory/ (17 files) | memory/ (4 files) | STATE + TASKS + ARTIFACTS + DECISIONS |
| MASTER_INDEX.md | memory/ARTIFACTS.md | 簡化為 artifact registry |
| 10_Standards/ | context/standards/ | 位置調整 |
| 01_Product_Prototype/ | prototypes/ (exploration + approved) | 分兩類 |
| 02_Specifications/ | docs/specifications/ | 合併到 docs |
| 03_System_Design/ | docs/design/ | 合併到 docs |
| 04_Compliance/ | docs/design/compliance/ | 併入 design |
| 05_Archive/ | 淘汰 | 用 git history + ARTIFACTS.md deprecated 取代 |
| 06_Interview_Records/ | docs/specifications/interviews/ | 併入 specs |
| 07_Retrospectives/ | docs/releases/retro/ | 併入 releases |
| 08_Test_Reports/ | docs/test-reports/ | 位置調整 |
| 09_Release_Records/ | docs/releases/ | 位置調整 |
| ETHOS.md | 併入 CLAUDE.md §設計原則 | — |
| PROJECT_DASHBOARD.html | 從 TASKS.md + ARTIFACTS.md 自動生成 | 不手動維護 |
| workflow_rules.md (105KB) | 分散到各 skill + Group file | 淘汰單一巨大規則檔 |

---

## 14. Cowork / Claude Code 分界

### 14.1 平台能力差異

| 能力 | Cowork | Claude Code |
|------|--------|-------------|
| 檔案讀寫 | ✅ | ✅ |
| Shell 指令 | ✅ (sandbox) | ✅ (local) |
| Git 操作 | ❌ | ✅ |
| Computer Use | ✅ | ❌ |
| MCP 連接器 | ✅ | ✅ |
| Subagent | ✅ (Agent tool) | ✅ (Task tool) |
| 瀏覽器操作 | ✅ (Chrome MCP) | ❌ |

### 14.2 建議分工

| 階段 | 建議平台 | 原因 |
|------|----------|------|
| **Discover** | Cowork | 需要與人互動、做 Prototype、可能用到 Chrome 查資料 |
| **Plan** | Cowork 或 Claude Code | 架構設計可在任一平台進行 |
| **Build** | Claude Code | 需要 git、local shell、完整開發工具鏈 |
| **Verify** | Claude Code | 需要跑完整測試套件、git 操作 |
| **Ship** | Claude Code | 需要 deploy 指令、git tag |

### 14.3 跨平台交接

Cowork → Claude Code 的交接點通常在 Plan Gate 通過後：
1. Cowork 完成 Discover + Plan，所有產出存在 git repo
2. `git push` 到 remote
3. Claude Code `git pull`，讀取 STATE.md 接續
4. Task-Master dispatcher 在 Claude Code 中重新啟動，載入正確的 specialist

---

## 15. 遷移策略 (v3.3 → v4)

### 15.1 新專案

直接使用 v4 template（更新 project-init skill）。

### 15.2 進行中的專案

| 專案狀態 | 遷移方式 |
|----------|----------|
| 還在 Discover/Plan | 直接切換到 v4 結構，遷移文件到新路徑 |
| 已在 Build | 完成當前 Feature 後切換，不中途遷移 |
| 接近完成 | 不遷移，用 v3.3 完成 |

### 15.3 遷移步驟

```
1. 備份現有專案
2. 建立 v4 檔案結構
3. 遷移 memory：
   - STATE.md → 調整格式（加入 dispatcher 區塊）
   - TASKS.md → 從舊 TASKS.md + WBS 合併
   - ARTIFACTS.md → 從 MASTER_INDEX.md 提取正式文件清單
   - DECISIONS.md → 從 decisions.md 直接搬移
   - 其他 memory 檔案 → 併入 context/ 或淘汰
4. 遷移角色：
   - 13 個 SEED → 3 個 GROUP file + 1 個 ROLE_Review.md（保留 specialist 差異）
5. 遷移 skill：
   - pipeline-orchestrator → 重構為 task-master
   - planning-with-files → 重新命名為 planning-with-tasks
   - Tier 2 skill → 依 project-config.yaml 決定保留
   - Tier 3 skill → 移除（平台自帶）
6. 重寫 CLAUDE.md（< 5K tokens）
7. 建立 project-config.yaml
8. 跑一次 gate-check 驗證結構完整性
```

---

## 16. Agent Teams（第二階段）

### 16.1 導入前提

- WBS 清楚（每個 Task 有明確完成標準 + Dependency 標記）
- 狀態模型清楚（TASKS.md 格式已穩定）
- Gate 清楚（gate-check skill 運作正常）
- Evidence 清楚（每個完成的 Task 有對應證據）
- Artifact 追蹤清楚（ARTIFACTS.md 正常運作）
- 依賴與 wave 清楚（哪些任務可以平行、哪些有前後關係）

### 16.2 導入方式

在以上前提滿足後：
1. 在 TASKS.md 中標記可平行的 Task 組
2. 使用 subagent-driven-development skill 分派
3. 每個 subagent 使用 git worktree 隔離
4. Controller（Task-Master）不做實作，只做分派和整合
5. 每個 subagent 完成後經過 spec review + code review 兩道 gate

---

## Appendix A: v3.3 → v4 Skill 完整對照表

| v3.3 Skill | v4 Tier | v4 處置 | 說明 |
|------------|---------|---------|------|
| pipeline-orchestrator | T1 | **重構**為 task-master | 瘦身為 dispatcher |
| planning-with-files | T1 | **重新命名 + 擴充**為 planning-with-tasks | 進度追蹤 + findings/progress 記錄 |
| test-driven-development | T1 | 保留 | 核心紀律 |
| systematic-debugging | T1 | 保留 | 核心紀律 |
| verification-before-completion | T1 | 保留 + 合併 forced-thinking | 核心紀律 |
| brainstorming | T1 | 保留 | 核心紀律 |
| writing-plans（新增） | T1 | **新增** | 計畫拆解（從 Superpowers 引入） |
| requesting-code-review | T1 | 保留 | 核心紀律 |
| using-git-worktrees | T1 | 保留 | 核心紀律 |
| quality-gates | T1 | **重構**為 gate-check | 簡化 |
| ground | T1 | 保留 | 防幻覺 |
| call-center-domain | T2 | 保留 | Domain |
| frontend-design | T2 | 保留 | Governance |
| deep-research | T2 | 保留 | Technique |
| webapp-testing | T2 | 保留 | Technique |
| doc-coauthoring | T2 | 保留 | Technique |
| screenshot-to-code | T2 | 保留 | Technique |
| validate-contract | T2 | 保留 | Governance |
| cia | T2 | 保留 | Governance |
| ssot-guardian | T2 | 保留 | Governance |
| retro | T2 | 保留 + 合併 quantitative-retro | Technique |
| finishing-a-development-branch | T2 | 保留 | Technique |
| subagent-driven-development | T2 | 保留 | Technique |
| new-doc | T2 | 保留 | Technique |
| project-init | T2 | 保留 | Utility |
| slice-cycle | — | 合併至 Build 流程 | 不再獨立 |
| forced-thinking | — | 合併至 verification-before-completion | 整合 |
| execution-trace | — | 淘汰 | overhead 過高 |
| destructive-guard | — | 降級為 git hook | 不需要是 skill |
| info-ship | — | 合併至 Ship 階段 | 不再獨立 |
| info-canary | — | 合併至 Ship 階段 | 不再獨立 |
| info-doc-sync | — | 合併至 Ship 階段 | 不再獨立 |
| update-dashboard | — | 淘汰 | 自動生成 |
| find-skills | — | 淘汰 | 不再需要 |
| skill-creator | — | 移出核心 | 開發者工具 |
| quantitative-retro | — | 合併至 retro | 統一回顧 |
| docx / pptx / xlsx / pdf | T3 | 移出框架 | 平台工具 |
| algorithmic-art | T3 | 移出框架 | 平台工具 |
| theme-factory | T3 | 移出框架 | 平台工具 |
| web-artifacts-builder | T3 | 移出框架 | 平台工具 |
| mcp-builder | T3 | 移出框架 | 開發者工具 |
| schedule | T3 | 移出框架 | 平台工具 |
| internal-comms | T3 | 移出框架 | 通用工具 |
| gemini-designer / codex | T3 | 移出框架 | 外部 AI |

**統計**：
- **Tier 1 Core Disciplines**: 11 個（含新增的 task-master 和 writing-plans）
- **Tier 2 Domain & Governance**: 14 個（依專案啟用）
- **Tier 3 移出框架**: 12 個
- **淘汰/合併**: 10 個
- **框架內總計**: 25 個（其中強制載入 11 個，按需載入 14 個）

---

## Appendix B: 版本變更歷史

### v0.2 → v0.3（Codex Review R1）

| 項目 | v0.2 | v0.3 | 原因 |
|------|------|------|------|
| **Task-Master** | 淘汰，嵌入 CLAUDE.md 路由邏輯 | 恢復為輕量 dispatcher（獨立 skill） | 路由判斷需要上下文推理，不是純 if-else |
| **Agent 角色** | 3 個 Profile（Discovery/Build/Verify） | 3 個 Group + 10 個 specialist role | 不同 specialist 有不同禁止事項和品質標準 |
| **角色定義檔** | 3 個 PROFILE_*.md (~800 tokens each) | 3 個 GROUP_*.md (~1.5K tokens each) | 保留 specialist 區分但減少檔案數 |
| **MASTER_INDEX** | 淘汰 | 恢復為 memory/ARTIFACTS.md | 正式文件需要獨立的成熟度追蹤 |
| **planning-with-files** | 合併至 writing-plans | 獨立保留，重新命名為 planning-with-tasks | Plan（拆解）和 Track（追蹤）是不同認知活動 |
| **記憶體檔案數** | 3 個 | 4 個 | +ARTIFACTS.md |
| **CLAUDE.md 大小** | < 3K tokens | < 5K tokens | 需容納 dispatcher 邏輯和 specialist 索引 |
| **Tier 1 skill 數** | 9 個 | 11 個 | +task-master, +planning-with-tasks |
| **框架內 skill 總數** | 22 個 | 25 個 | 恢復部分被過度精簡的 skill |

### v0.3 → v0.4（Codex Review R2）

| 項目 | v0.3 | v0.4 | 原因 |
|------|------|------|------|
| **Review specialist** | 放在 Verify Group 內 | 提升為跨階段角色，獨立 ROLE_Review.md | Discover Gate / Plan Gate 也依賴 Review，放在 Verify Group 會造成路由歧義 |
| **planning-with-tasks** | 只做 TASKS.md 狀態更新 | 擴充為 tracking + findings + progress 三個落點 | 長流程中的 research findings、debug observations 需要正式落點，否則漂回對話消失 |
| **Task-Master drift 職責** | 「偵測 scope drift / design drift」 | 改為「接收 specialist 的 drift signal 後路由」 | Task-Master 的可見資訊不足以獨立判斷 drift，drift 發現責任在 specialist |
| **Task-Master context** | 只讀 STATE + TASKS | 處理 drift signal 時可額外讀 ARTIFACTS.md | 需要確認 baselined 狀態才能判斷回退層級 |
| **角色定義檔** | 3 個 GROUP_*.md | 3 個 GROUP_*.md + 1 個 ROLE_Review.md | Review 獨立跨階段 |
| **drift signal 格式** | 未定義 | 定義 DRIFT_SIGNAL 結構化格式 | specialist → Task-Master 的通訊需要標準化 |

---

## Appendix C: 開放議題 (Open Questions)

| # | 議題 | 影響範圍 | 建議決策時機 |
|---|------|----------|-------------|
| OQ-1 | Dashboard 自動生成的實作方式？從 TASKS.md + ARTIFACTS.md 轉換為 HTML 的 script 設計 | Ship 階段 | v4.1 |
| OQ-2 | Cowork 和 Claude Code 的 Skill 是否需要分開兩套？還是共用同一套、依平台能力自動降級？ | 全框架 | v4.0 實作前 |
| OQ-3 | project-config.yaml 的 schema 驗證機制？用 JSON Schema 還是 skill 驗證？ | 專案初始化 | v4.0 實作時 |
| OQ-4 | 多人協作時 STATE.md 的 merge conflict 怎麼處理？ | 團隊使用 | v4.1 |
| OQ-5 | Lite mode 各 Gate 的具體 checklist 項目？ | Lite 通道 | v4.0 實作時 |
| OQ-6 | Task-Master skill 是否需要區分 Cowork 版和 Claude Code 版？ | 跨平台 | v4.0 實作時 |
| OQ-7 | GROUP file 中 specialist 區塊的最小必要內容？需要 benchmark token 消耗 | 效能 | v4.0 實作時 |
| ~~OQ-8~~ | ~~Review specialist 歸屬問題~~ | ~~已解決~~ | ~~v0.4：跨階段角色~~ |

---

## Appendix D: Residual Risks & Implementation Notes（Codex R2 收尾建議）

以下不是藍圖缺陷，而是進入實作時需要優先處理的風險項。

### RR-1: findings.md / progress.md 的路徑與生命週期

**風險**：不同專案可能各自放法，導致 planning-with-tasks skill 找不到或重複建立。

**建議**：在實作 planning-with-tasks skill 時，固定路徑慣例：
```
src/[feature-id]/
├── findings.md       # per-feature 工作筆記
└── progress.md       # per-feature 進度總結
```
Lifecycle：Feature 完成後歸檔到 `docs/archive/[feature-id]/`，或直接刪除（因為重要 finding 已提升為 ADR）。

### RR-2: CIA 流程落地

**風險**：CIA（Change Impact Assessment）在藍圖中概念清楚，但還沒有對應的 checklist、artifact format、觸發自動化。

**建議**：實作時把 cia skill 的 SKILL.md 擴充為包含：
- CIA checklist template（必填欄位：變更項目、影響範圍、受影響文件 ID、需要重過的 Gate）
- CIA artifact format（登記在 ARTIFACTS.md 的格式）
- 自動觸發條件（修改任何 maturity=Baselined 的文件時強制觸發）

### RR-3: Token Budget 上限

**風險**：Task-Master skill、ROLE_Review.md、GROUP_*.md 一旦開始實作，最容易再次膨脹回 v3.3 的狀態。

**建議 token 預算**：

| 檔案 | Token 上限 | 原因 |
|------|-----------|------|
| CLAUDE.md | 5,000 | 每個 session 都會載入 |
| task-master/SKILL.md | 2,000 | 高頻載入 |
| ROLE_Review.md | 1,000 | 跨階段但職責單一 |
| GROUP_Discovery.md | 2,000 | 含 3 個 specialist |
| GROUP_Build.md | 2,000 | 含 3 個 specialist |
| GROUP_Verify.md | 1,500 | 含 3 個 specialist（Review 已移出） |
| STATE.md | 400 | 每次都讀 |
| ARTIFACTS.md | 依專案規模 | 只在 drift signal 處理時讀 |

**執行方式**：在 project-init skill 中加入 token budget 驗證，初始化時檢查所有檔案是否超標。

---

*v1.0 — Approved Blueprint*
*Authored by: Opus (draft) + Codex (review x2) + 凱子 (direction & final approval)*
*Next step: 實作規格與模板 — 從 CLAUDE.md、project-config.yaml、task-master skill 開始*
