# V4 Workflow Blueprint v0.2

> **Status**: Draft — 待 Codex 審查
> **Base**: v0.1 (Codex) + Claude Opus 補充修訂
> **Date**: 2026-03-31
> **Purpose**: 取代 v3.3 框架，解決 context 膨脹、Skill 混亂、記憶體分散、Agent 定位模糊等問題

---

## 0. 設計原則 (Design Tenets)

以下五條原則指導 v4 所有設計決策。遇到取捨時，以原則編號小的優先。

| # | 原則 | 說明 |
|---|------|------|
| T1 | **Evidence over Assertion** | 所有宣稱必須附帶可驗證的證據。不是 checklist 打勾，而是跑實際指令、看實際 output。 |
| T2 | **Scope is Sacred** | Discover Gate 通過後，需求文件是唯一範圍基準。No silent scope change / redesign / requirement rewrite。 |
| T3 | **Context is Currency** | 每多載入 1K tokens 的 context 就是在花錢。Agent 只載入當前任務需要的最小 context；subagent 不繼承 controller 的 session history。 |
| T4 | **Fix Upstream, Not Downstream** | 若發現需求/設計有誤，回上游文件修正後再重新往下執行。不在下游硬修、不靠 patch 掩蓋。 |
| T5 | **Process over Guessing** | 遇到問題用結構化流程解決，不用直覺猜。（借鑑 Superpowers 核心哲學） |

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

### 1.3 階段路由邏輯 (取代 Task-Master Agent)

v3.3 使用獨立的 pipeline-orchestrator Agent 做中央調度。v4 改為**輕量路由邏輯**，嵌入 CLAUDE.md：

```
路由判斷流程：
1. 讀取 STATE.md → 取得 current_stage, current_task, blocked_by
2. IF blocked_by != null → 顯示 blocker，等待人工決策
3. IF current_task 完成 → 檢查是否為該階段最後一個任務
   3a. 是 → 觸發 Gate Check skill
   3b. 否 → 載入下一個任務所需的 skill 組合，繼續執行
4. IF Gate 通過 → 更新 STATE.md stage，載入下一階段 skill 組合
5. IF Gate 未通過 → 列出未達標項目，回到當前階段修正
```

**為什麼不要 Task-Master Agent**：
- 作為獨立 Agent，它需要載入全局 context 才能「理解全局」，違反 T3
- 路由決策本質上是一個 if-else 判斷，不需要 LLM 推理
- 嵌入 CLAUDE.md 後，任何 Agent session 都能執行路由，不需要額外切換

**何時回到路由判斷**：
- 任務 blocked
- 需要 handoff 到不同能力的 Agent
- scope issue / design drift 被偵測到
- 測試 escalation（測試顯示上游文件有誤）
- Agent 完成當前任務

---

## 2. 檢查口 (Quality Gates)

### 2.1 Gate 定義

| Gate | 位於 | 必須滿足 | 審查方式 |
|------|------|----------|----------|
| **Discover Gate** | Discover → Plan | SRS 完整、AC 可測試、WBS 已拆、MVP 邊界已確認、Stakeholder 已簽核 | Review skill (Standard) 或 Checklist pass (Lite) |
| **Plan Gate** | Plan → Build | 架構完整、模組邊界清楚、API/DB spec 已定義、UI Design Baseline locked、Slice Backlog 已建立、測試策略已定義 | Review skill (Standard) 或 Checklist pass (Lite) |
| **Build Gate** | Build → Verify | 所有 Slice 實作完成、unit/integration test 通過率達標、無 scope drift（對照 SRS）、Code Review 已通過 | Review skill + 自動化測試報告 |
| **Ship Gate** | Verify → Ship | E2E/Smoke test 通過、合規審查完成（如適用）、Rollback plan 已準備、Release evidence 齊全 | Review skill + 部署前 checklist |

### 2.2 Gate 輕重量級

| 模式 | 適用場景 | 做法 |
|------|----------|------|
| **Standard** | 正式專案、多人協作、客戶交付 | 完整 Review Agent session，產出 Gate Review Note |
| **Lite** | PoC、個人專案、內部工具 | 自動 checklist 驗證，人工確認關鍵項即可 |

### 2.3 Gate 失敗處理

Gate 未通過時：
1. 列出具體未達標項目（附證據，非主觀判斷）
2. 判斷問題出在哪一層（需求？設計？實作？測試？）
3. **退回到問題所在的上游階段修正**（T4 原則）
4. 修正完畢後重新執行 Gate

---

## 3. Agent 架構 (Agent Profiles)

### 3.1 v3.3 → v4 Agent 模型轉變

**v3.3**: 11 個固定角色（Interviewer、PM、UX、Architect、DBA、Backend、Frontend、QA、Security、DevOps、Review），每個角色有獨立的 SEED 檔案和必載 skill 清單。

**v4**: 3 個 Agent Profile + 按需 subagent 拆分。Agent 不再是「角色」，而是「能力組合」。

| Profile | 負責階段 | 涵蓋的 v3.3 角色 | 核心能力 |
|---------|----------|-------------------|----------|
| **Discovery Agent** | Discover + Plan | Interviewer, PM, UX, Architect | 需求訪談、原型設計、架構規劃、範圍定義 |
| **Build Agent** | Build | Backend, Frontend, DBA | 實作開發、TDD、DB migration、UI 實作 |
| **Verify Agent** | Verify + Ship | QA, Security, DevOps, Review | 測試、合規、部署、Gate 審查 |

### 3.2 Profile 運作方式

每個 Profile 是一個最小化的 system prompt（< 1K tokens），定義：
- 此 Profile 的職責邊界
- 此 Profile 可載入的 skill 範圍
- 此 Profile 的禁止事項

**skill 不是預先全部載入**，而是根據當前任務按需載入：

```
範例：Build Agent 接到任務「建立 GET /users endpoint」
→ 載入 skill: test-driven-development + using-git-worktrees
→ 不載入: frontend-design, webapp-testing（與此任務無關）

範例：Build Agent 接到任務「實作使用者列表頁面」
→ 載入 skill: test-driven-development + frontend-design + using-git-worktrees
→ 不載入: deep-research, brainstorming（與此任務無關）
```

### 3.3 Subagent 拆分規則

當任務需要深度專業知識，且 context 會互相干擾時，從 Profile 拆出 subagent：

```
觸發條件：
- 複雜 DB migration（需要完整 schema context）
- 安全審查（需要 OWASP/合規 reference）
- 效能優化（需要 profiling data）
- 3+ 個獨立任務可平行執行

subagent 規則（借鑑 Superpowers）：
- Controller 主動組裝 subagent 需要的最小 context
- Subagent 不繼承 controller 的 session history
- Subagent 完成後回報結果，由 controller 整合
- 使用 git worktree 做隔離開發（如涉及程式碼修改）
```

### 3.4 Agent Profile 定義檔案

取代 v3.3 的 13 個 SEED 檔案，v4 只有 3 個 Profile 檔案：

```
context-profiles/
├── PROFILE_Discovery.md    (~800 tokens)
├── PROFILE_Build.md        (~800 tokens)
└── PROFILE_Verify.md       (~800 tokens)
```

每個 Profile 檔案結構：

```markdown
# [Profile Name] Agent

## 職責
[2-3 句話描述這個 Profile 負責什麼]

## 可用 Skill
[列出此 Profile 可載入的 skill，標註「按需載入」]

## 禁止事項
[明確列出此 Profile 不該做的事]

## 完成標準
[此 Profile 的任務完成時，必須滿足什麼條件]

## 交接格式
[完成後寫入 TASKS.md 的格式]
```

---

## 4. Skill 架構 (Skill Tiers)

### 4.1 三層分類

v3.3 有 39+ 個 skill 混在一起，沒有層級區分。v4 將 skill 分為三層：

| 層級 | 定義 | 載入方式 | 數量限制 |
|------|------|----------|----------|
| **Tier 1: Core Disciplines** | 行為約束型 — 「你必須怎麼做」 | 符合條件時強制載入，不可跳過 | ≤ 10 |
| **Tier 2: Domain & Governance** | 領域/治理型 — 「這個專案的特殊規則」 | 依專案設定按需載入 | 按專案定義 |
| **Tier 3: Platform Tools** | 工具型 — 「幫你產出特定格式」 | 由平台（Cowork/Claude Code）自動處理 | 不計入框架 |

### 4.2 Tier 1: Core Disciplines（框架核心，全專案通用）

| Skill | 觸發條件 | 改動說明 |
|-------|----------|----------|
| **test-driven-development** | 寫任何新 code 時 | 保留，微調 |
| **systematic-debugging** | 遇到 bug / 非預期行為 | 保留，微調 |
| **verification-before-completion** | 任何 Agent 完成任務前 | 保留，強化 evidence 要求 |
| **brainstorming** | 探索新功能 / 不確定方向時 | 保留 |
| **writing-plans** | 開始實作前的計畫 | 新增（從 Superpowers 引入，取代 planning-with-files 的部分功能） |
| **requesting-code-review** | 提交 code review 時 | 保留 |
| **using-git-worktrees** | 開始 feature 開發時 | 保留 |
| **gate-check** | 階段結束，準備過 Gate 時 | 從 quality-gates 簡化重構 |
| **ground** | AI 修改既有程式碼前 | 保留（防止 AI 幻覺修改） |

**共 9 個 Tier 1 skill。**

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
| **retro** | Technique | 完成 milestone 後做回顧 |
| **finishing-a-development-branch** | Technique | Feature 完成，準備 merge |
| **subagent-driven-development** | Technique | 需要多 Agent 並行時 |
| **new-doc** | Technique | 需要建立新的正式文件 |

**Tier 2 skill 由專案的 `project-config.yaml` 定義啟用清單。**

### 4.4 Tier 3: Platform Tools（移出框架，由平台處理）

以下 skill 不再算框架的一部分，它們是 Cowork/Claude Code 平台自帶的能力：

| Skill | 原因 |
|-------|------|
| docx | 平台文件工具 |
| pptx | 平台文件工具 |
| xlsx | 平台文件工具 |
| pdf | 平台文件工具 |
| algorithmic-art | 平台創意工具 |
| theme-factory | 平台樣式工具 |
| web-artifacts-builder | 平台 artifact 工具 |
| mcp-builder | 開發者工具，非框架核心 |
| schedule | 平台排程工具 |
| internal-comms | 通用溝通工具，非框架核心 |
| gemini-designer | 外部 AI 工具 |
| codex | 外部 AI 工具 |

### 4.5 淘汰 / 合併清單

| 原 Skill | 處置 | 原因 |
|----------|------|------|
| pipeline-orchestrator | **淘汰** | 路由邏輯嵌入 CLAUDE.md，不再需要獨立 skill |
| planning-with-files | **合併**至 writing-plans | 功能重疊，統一為一個 planning skill |
| slice-cycle | **合併**至 Build 階段流程 | 不需要獨立 skill，是 Build 的標準做法 |
| quality-gates | **重構**為 gate-check | 簡化，只做 checklist 驗證 + evidence 收集 |
| forced-thinking | **合併**至 verification-before-completion | 思考模板整合進完成驗證流程 |
| execution-trace | **淘汰** | 過度 overhead，用 git log + TASKS.md 取代 |
| destructive-guard | **降級**為 git hook | 不需要是 skill，用 pre-commit hook 處理 |
| info-ship / info-canary / info-doc-sync | **合併**為 Ship 階段的標準步驟 | 不需要 3 個獨立 skill |
| update-dashboard | **淘汰** | Dashboard 改為從 TASKS.md 自動生成，不需要手動更新 |
| find-skills | **淘汰** | v4 skill 數量已大幅減少，不需要搜尋工具 |
| skill-creator | **保留但移出核心** | 開發者工具，不是日常使用 |
| project-init | **保留** | 初始化新專案仍需要 |
| quantitative-retro | **合併**至 retro | 一個回顧 skill 即可 |

---

## 5. 記憶體架構 (Memory System)

### 5.1 v3.3 → v4 記憶體簡化

**v3.3**: 17 個記憶檔案（STATE.md, product.md, dashboard.md, TECH_DEBT.md, decisions.md, workflow_rules.md (105KB!), gate_baseline.yaml, hotfix_log.md, glossary.md, token_budget.md, smoke_tests.md, last_task.md, context/, people/, projects/, knowledge_base/）

**v4**: 3 個核心記憶檔案 + 1 個靜態參考資料夾

### 5.2 核心記憶（Active Memory）

#### `memory/STATE.md` — 現在在哪（~200 tokens）

```yaml
stage: "Build"                    # Discover | Plan | Build | Verify | Ship
task_current: "F01-API-users"     # 當前任務 ID
task_status: "in_progress"        # todo | in_progress | blocked | in_review
blocked_by: null                  # null 或 "[原因]"
agent_profile: "Build"            # Discovery | Build | Verify
skills_loaded:                    # 當前已載入的 skill
  - test-driven-development
  - using-git-worktrees
next_action: "寫 GET /users 的 unit test"
resume_command: "繼續 Build Agent, 任務 F01-API-users"
last_updated: "2026-03-31T14:00:00+08:00"
```

#### `memory/TASKS.md` — 要做什麼（唯一任務真相來源）

```markdown
# TASKS — Single Source of Truth

## WBS: F01 使用者管理
| Task ID | Description | Status | Owner | Evidence |
|---------|-------------|--------|-------|----------|
| F01-API-users | GET /users endpoint | done | Build | test passed, PR #12 |
| F01-API-user-detail | GET /users/:id endpoint | in_progress | Build | — |
| F01-UI-list | 使用者列表頁面 | todo | Build | — |
| F01-UI-detail | 使用者詳情頁面 | blocked | Build | blocked: API 未完成 |

## Handoff Log
| Time | From | To | Summary | Artifacts | Blockers |
|------|------|----|---------|-----------|----------|
| 03-31 12:00 | Discovery | Build | SRS 完成，Gate 通過 | SRS.md, WBS | 無 |

## Open Questions
- 🔴 [阻塞] 使用者匯入格式待客戶確認
- 🟡 [待討論] 是否支援 batch delete
```

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

### 5.3 靜態參考（Reference — 不算記憶體，按需讀取）

```
context/
├── product.md          # 產品概述（名稱、類型、技術棧、階段）
├── domain/             # 領域知識（call-center-domain 等）
├── standards/          # API/DB/UI 設計標準
├── company/            # 公司/組織背景
└── people/             # 團隊成員資訊
```

這些檔案不會自動載入，只在 Agent 需要時主動讀取。

### 5.4 記憶體原則

| 原則 | 說明 |
|------|------|
| **STATE 只記現在** | 不記歷史，不記「做過什麼」，只記「現在在哪、下一步」 |
| **TASKS 是唯一任務真相** | Dashboard、報告、進度追蹤全部從 TASKS.md 衍生，不另外維護 |
| **DECISIONS 只增不改** | 決策一旦寫入就是歷史紀錄，可以被新決策 supersede，但不刪除舊的 |
| **Subagent 不繼承記憶** | Controller 從這 3 個檔案中提取 subagent 需要的最小資訊，手動傳入 |
| **Context > 60% 時存檔** | 自動將當前狀態寫入 STATE.md，確保下一個 session 可以接續 |

---

## 6. CLAUDE.md 架構（目標 < 3K tokens）

### 6.1 v3.3 → v4 對比

**v3.3 CLAUDE.md**: ~25,000 tokens，包含導航、Agent 路由表、Pipeline 定義、執行模式切換、skill 路由表、所有規則。

**v4 CLAUDE.md**: 目標 < 3,000 tokens，只包含三個區塊。

### 6.2 v4 CLAUDE.md 結構

```markdown
# [專案名稱]

## 專案概要
- 產品：[名稱]
- 技術棧：[stack]
- 當前階段：讀取 memory/STATE.md

## 行為準則
1. Evidence over Assertion — 所有宣稱附帶證據
2. Scope is Sacred — Gate 後不擅自擴範圍
3. Context is Currency — 只載入需要的 skill
4. Fix Upstream — 問題回上游修
5. Process over Guessing — 結構化解決

## 路由邏輯
1. 讀 STATE.md → 判斷 stage + task
2. blocked? → 顯示 blocker，等人工
3. 任務完成? → gate-check skill
4. Gate 過? → 更新 STATE.md，進下一階段
5. Gate 沒過? → 列未達標，回修

## Agent Profile
- Discovery: context-profiles/PROFILE_Discovery.md
- Build: context-profiles/PROFILE_Build.md
- Verify: context-profiles/PROFILE_Verify.md

## Skill 觸發索引
### Tier 1 (強制)
- 寫 code → test-driven-development
- 遇 bug → systematic-debugging
- 完成任務 → verification-before-completion
- 探索想法 → brainstorming
- 開始實作 → writing-plans
- 提交 review → requesting-code-review
- 開 feature → using-git-worktrees
- 過 Gate → gate-check
- 改既有 code → ground

### Tier 2 (按需)
見 project-config.yaml 啟用清單

## 記憶體
- 現在在哪 → memory/STATE.md
- 要做什麼 → memory/TASKS.md
- 為什麼這樣做 → memory/DECISIONS.md
- 參考資料 → context/
```

---

## 7. 交接協議 (Handoff Protocol)

### 7.1 標準交接格式

每次 Agent Profile 切換時，必須在 TASKS.md 的 Handoff Log 寫入：

```markdown
| Time | From | To | Summary | Artifacts | Blockers |
|------|------|----|---------|-----------|----------|
| [timestamp] | [Profile] | [Profile] | [1-2句完成摘要] | [產出檔案清單] | [blocker或「無」] |
```

### 7.2 同時更新 STATE.md

```yaml
stage: "[新階段]"
task_current: "[下一個任務 ID]"
agent_profile: "[新 Profile]"
skills_loaded: []    # 清空，由新 Profile 根據任務重新載入
next_action: "[下一位要做什麼]"
resume_command: "[恢復指令]"
```

### 7.3 交接必含項目

1. **完成事項** — 做了什麼（1-3 句）
2. **證據** — 產出的檔案、通過的測試、PR 連結
3. **已凍結內容** — 不可再改的東西（Gate 鎖定的文件）
4. **待決策** — 需要人工判斷的 open question
5. **風險與 blocker** — 已知的阻塞和風險
6. **下一位可動範圍** — 明確界定接手者能做和不能做的事

---

## 8. WBS 與執行監控

### 8.1 WBS 規則

- 每個 Feature 必須先拆成 WBS，再進 Build
- 每個 Task 拆到 **2-5 分鐘可完成**的粒度（借鑑 Superpowers 的任務原子化）
- 每個 Task 必須有明確的完成標準，不是「寫 API」，而是「建立 GET /users endpoint，回傳 mock data，通過 unit test」
- Task 不可含 placeholder 或 TBD

### 8.2 任務狀態

```
todo → in_progress → [blocked | needs_discussion | in_review] → done
```

- **todo**: 已定義，未開始
- **in_progress**: 正在執行（同一時間只有 1 個）
- **blocked**: 被外部依賴阻塞
- **needs_discussion**: 需要人工決策
- **in_review**: 等待 code review 或 Gate
- **done**: 完成，附帶 evidence

### 8.3 監控原則

- **TASKS.md 是唯一任務真相來源**
- Dashboard（如果需要）從 TASKS.md 自動生成，不手動維護
- 不維護獨立的 sprint board、kanban、或 Gantt — TASKS.md 就是一切

---

## 9. 設計與 Prototype 範圍控制

### 9.1 Prototype 分類

| 類型 | 用途 | 可修改範圍 |
|------|------|------------|
| **Exploration Prototype** | Discover 階段探索，不代表最終設計 | 任意修改 |
| **Approved Prototype** | Plan Gate 通過後鎖定的設計基準 | 僅限 unlocked 標記的元素 |

### 9.2 Design Baseline（Plan Gate 產出）

Plan Gate 通過時必須產出 Design Baseline，包含：
- 視覺方向（色彩、字型、間距 token）
- 元件語言（使用的 design system）
- 版面結構（layout grid）
- 互動原則（hover/click/transition）

### 9.3 Build 階段 UI 規則

**允許**：Fidelity 實作、響應式修正、可用性微調、接線必要調整

**禁止**（預設 locked，除非明確標記 `[unlocked: 原因]`）：
- 更換風格 / 視覺方向
- 更換版型 / layout 結構
- 更換主要互動模式
- 更換設計語言 / 核心元件

**超出範圍 → 退回 Plan Gate 重審**

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

測試失敗時：
1. 判斷是 code bug 還是需求/設計本身有誤
2. 如果是 code bug → 在 Build 階段修復
3. 如果是需求/設計有誤 → **退回上游文件修正**（T4 原則），不靠 patch 掩蓋

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

限制：Hotfix 不可用來偷渡新功能。修復範圍限於 incident 直接相關的 code。

---

## 12. 專案配置 (Project Config)

### 12.1 `project-config.yaml`

取代 v3.3 散落各處的設定，v4 用一個 YAML 檔案集中管理：

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
```

---

## 13. 檔案結構 (v4 Template)

```
[project-root]/
├── CLAUDE.md                      # < 3K tokens 的精簡導航
├── project-config.yaml            # 專案設定（skill 啟用、Gate 模式、測試門檻）
│
├── memory/
│   ├── STATE.md                   # 現在在哪（~200 tokens）
│   ├── TASKS.md                   # 要做什麼（唯一任務真相來源）
│   └── DECISIONS.md               # 為什麼這樣做（ADR log）
│
├── context/
│   ├── product.md                 # 產品概述
│   ├── domain/                    # 領域知識
│   ├── standards/                 # API/DB/UI 設計標準
│   │   ├── api-design.md
│   │   ├── db-schema.md
│   │   └── ui-design.md
│   ├── company/                   # 公司背景
│   └── people/                    # 團隊成員
│
├── context-profiles/
│   ├── PROFILE_Discovery.md       # Discovery Agent 定義
│   ├── PROFILE_Build.md           # Build Agent 定義
│   └── PROFILE_Verify.md         # Verify Agent 定義
│
├── context-skills/                # Tier 1 + Tier 2 skills
│   ├── test-driven-development/
│   ├── systematic-debugging/
│   ├── verification-before-completion/
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── requesting-code-review/
│   ├── using-git-worktrees/
│   ├── gate-check/
│   ├── ground/
│   └── [tier-2-skills]/           # 依 project-config.yaml 配置
│
├── docs/
│   ├── specifications/            # SRS、AC、Scope Baseline
│   ├── design/                    # Architecture、API Spec、DB Schema
│   ├── test-reports/              # Test execution results
│   └── releases/                  # Release notes、deploy records
│
├── prototypes/
│   ├── exploration/               # Discover 階段探索用
│   └── approved/                  # Plan Gate 後鎖定的設計基準
│
└── src/                           # 程式碼（依技術棧結構）
```

**v3.3 → v4 檔案對照**：

| v3.3 | v4 | 說明 |
|------|----|------|
| CLAUDE.md (25K) | CLAUDE.md (< 3K) | 大幅瘦身 |
| context-seeds/ (13 files) | context-profiles/ (3 files) | 角色合併 |
| memory/ (17 files) | memory/ (3 files) | 記憶體簡化 |
| 10_Standards/ | context/standards/ | 位置調整 |
| 01_Product_Prototype/ | prototypes/ | 分 exploration / approved |
| 02_Specifications/ | docs/specifications/ | 合併到 docs |
| 03_System_Design/ | docs/design/ | 合併到 docs |
| 04_Compliance/ | docs/design/compliance/ | 併入 design |
| 05_Archive/ | 淘汰 | 用 git history 取代 |
| 06_Interview_Records/ | docs/specifications/interviews/ | 併入 specs |
| 07_Retrospectives/ | docs/releases/retro/ | 併入 releases |
| 08_Test_Reports/ | docs/test-reports/ | 位置調整 |
| 09_Release_Records/ | docs/releases/ | 位置調整 |
| MASTER_INDEX.md | 淘汰 | TASKS.md + git ls-files 取代 |
| ETHOS.md | 併入 CLAUDE.md §0 | 設計原則 |
| PROJECT_DASHBOARD.html | 從 TASKS.md 自動生成 | 不手動維護 |
| workflow_rules.md (105KB) | 淘汰 | 規則分散到各 skill 中 |

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
   - 保留 STATE.md（調整格式）
   - TASKS.md 從 MASTER_INDEX + 舊 TASKS.md 合併
   - DECISIONS.md 從 decisions.md 直接搬移
   - 其他 memory 檔案內容併入 context/ 或淘汰
4. 遷移 skill：
   - Tier 1 skill 直接搬移到 context-skills/
   - Tier 2 skill 依 project-config.yaml 決定保留哪些
   - Tier 3 skill 移除（平台自帶）
5. 重寫 CLAUDE.md（< 3K tokens）
6. 建立 project-config.yaml
7. 建立 3 個 Profile 檔案
8. 跑一次 gate-check 驗證結構完整性
```

---

## 16. Agent Teams（第二階段）

### 16.1 導入前提

- WBS 清楚（每個 Task 有明確完成標準）
- 狀態模型清楚（TASKS.md 格式已穩定）
- Gate 清楚（gate-check skill 運作正常）
- Evidence 清楚（每個完成的 Task 有對應證據）
- 依賴與 wave 清楚（哪些任務可以平行）

### 16.2 導入方式

在以上前提滿足後：
1. 在 TASKS.md 中標記可平行的 Task 組
2. 使用 subagent-driven-development skill 分派
3. 每個 subagent 使用 git worktree 隔離
4. Controller 不做實作，只做分派和整合
5. 每個 subagent 完成後經過 spec review + code review 兩道 gate

---

## Appendix A: v3.3 → v4 Skill 完整對照表

| v3.3 Skill | v4 Tier | v4 處置 | 說明 |
|------------|---------|---------|------|
| test-driven-development | T1 | 保留 | 核心紀律 |
| systematic-debugging | T1 | 保留 | 核心紀律 |
| verification-before-completion | T1 | 保留 + 強化 | 合併 forced-thinking |
| brainstorming | T1 | 保留 | 核心紀律 |
| planning-with-files | T1 | 合併為 writing-plans | 統一 planning |
| requesting-code-review | T1 | 保留 | 核心紀律 |
| using-git-worktrees | T1 | 保留 | 核心紀律 |
| quality-gates | T1 | 重構為 gate-check | 簡化 |
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
| pipeline-orchestrator | — | 淘汰 | 路由嵌入 CLAUDE.md |
| slice-cycle | — | 合併至 Build 流程 | 不再獨立 |
| forced-thinking | — | 合併至 verification-before-completion | 整合 |
| execution-trace | — | 淘汰 | overhead 過高 |
| destructive-guard | — | 降級為 git hook | 不需要是 skill |
| info-ship | — | 合併至 Ship 階段 | 不再獨立 |
| info-canary | — | 合併至 Ship 階段 | 不再獨立 |
| info-doc-sync | — | 合併至 Ship 階段 | 不再獨立 |
| update-dashboard | — | 淘汰 | 自動生成 |
| find-skills | — | 淘汰 | skill 數量已減少 |
| skill-creator | — | 移出核心 | 開發者工具 |
| quantitative-retro | — | 合併至 retro | 統一回顧 |
| docx / pptx / xlsx / pdf | T3 | 移出框架 | 平台工具 |
| algorithmic-art | T3 | 移出框架 | 平台工具 |
| theme-factory | T3 | 移出框架 | 平台工具 |
| web-artifacts-builder | T3 | 移出框架 | 平台工具 |
| mcp-builder | T3 | 移出框架 | 開發者工具 |
| schedule | T3 | 移出框架 | 平台工具 |
| internal-comms | T3 | 移出框架 | 通用工具 |
| gemini-designer | T3 | 移出框架 | 外部 AI |
| codex | T3 | 移出框架 | 外部 AI |

**統計**：
- **T1 Core Disciplines**: 9 個
- **T2 Domain & Governance**: 13 個（依專案啟用）
- **T3 移出框架**: 12 個
- **淘汰/合併**: 11 個
- **總計從 ~45 個降至 22 個（框架內），其中強制載入僅 9 個**

---

## Appendix B: 開放議題 (Open Questions)

| # | 議題 | 影響範圍 | 建議決策時機 |
|---|------|----------|-------------|
| OQ-1 | Dashboard 自動生成的實作方式？純 script 或 skill？ | Ship 階段 | v4.1 |
| OQ-2 | Cowork 和 Claude Code 的 Skill 是否需要分開兩套？ | 全框架 | v4.0 實作前 |
| OQ-3 | project-config.yaml 的 schema 驗證機制？ | 專案初始化 | v4.0 實作時 |
| OQ-4 | 多人協作時 STATE.md 的 merge conflict 怎麼處理？ | 團隊使用 | v4.1 |
| OQ-5 | Lite mode 的 Gate checklist 具體項目？ | Lite 通道 | v4.0 實作時 |
| OQ-6 | 是否要保留 MASTER_INDEX.md 的文件成熟度追蹤能力？ | 文件管理 | Codex 審查時決定 |

---

*v0.2 — Claude Opus draft based on Codex v0.1 + Superpowers analysis*
*Pending: Codex review & 凱子 final approval*
