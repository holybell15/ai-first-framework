# V4 Workflow Blueprint — Supplement v1.1

> **Status**: Draft — 待凱子確認後併入 Blueprint
> **Date**: 2026-03-31
> **Base**: V4 Blueprint v1.0
> **Purpose**: 解決 10 個已知痛點 + GStack 借鏡 + 舊專案遷移策略
> **Source**: GStack (garrytan/gstack)、Superpowers (obra/superpowers) 分析

---

## 變更摘要

| 編號 | 類別 | 變更 | 優先級 |
|------|------|------|--------|
| S-01 | WBS / 項目分解 | 新增 WBS Template + Estimation Protocol | P1 |
| S-02 | 架構設計 | 新增 SD Checklist + Architecture Lock-in | P1 |
| S-03 | 監控看板 | 新增 Task Board + Gate Readiness 視覺化 | P1 |
| S-04 | SD 確認流程 | 新增 SD Confirm Session + 簽核流程 | P2 |
| S-05 | 測試治理 | 新增 Test Pyramid 5 層定義 + Test Matrix | P1 |
| S-06 | Brownfield / Hotfix | 新增 Brownfield Onboarding Protocol + Hotfix Protocol 增強 | P2 |
| S-07 | UI/UX 範圍控制 | 新增 DESIGN.md 鎖定 + 修改分級 + Design Variant 流程 | P0 |
| S-08 | Agent×Skill 配置 | 新增 Agent×Skill Matrix + Domain Skill 規劃 + project-config.yaml | P0 |
| S-09 | Agent 通訊 / 交接 | 新增 Handoff Protocol 標準格式 + 路由邏輯 | P0 |
| S-10 | 記憶管理 | 新增 LEARNINGS.md（第 5 個 memory 文件） | P2 |
| S-11 | Agent Teams | Phase 2 規劃（暫不採用） | Later |
| S-12 | 舊專案遷移 | v3.3 → v4 遷移策略 + 自動化腳本規格 | P0 |

---

## S-01：WBS 結構化（痛點 #1）

### 問題
V4 §1 只定義 Discover 產出 WBS，但沒有格式、分解規則、估算方法。

### 借鏡
- **GStack** `/plan-eng-review`：精確到檔案路徑的任務分解 + test matrix
- **Superpowers** `writing-plans`：每個 task 2-5 分鐘、附完整驗證步驟

### 方案

#### WBS 分解層級

| Level | 名稱 | 說明 | 例子 |
|-------|------|------|------|
| L1 | Epic | 業務功能群 | 用戶管理 |
| L2 | Feature | 可獨立交付的功能，對應 `F-XXX` | F-001 用戶登入 |
| L3 | Task | 可在一個 session 完成的工作單元 | T-001 實作 /api/auth/login endpoint |

#### Task 定義格式

```yaml
- id: T-001
  feature: F-001-user-auth
  title: "實作 /api/auth/login endpoint"
  size: M                      # S (<30min) / M (30-120min) / L (2-4hr)
  assigned: Backend
  depends_on: [T-000]          # 前置依賴
  files:                       # 精確到檔案路徑
    - src/api/auth/login.ts
    - src/api/auth/login.test.ts
  verification:                # 完成驗證步驟
    - "unit test 全通過"
    - "API 回傳正確 JWT"
  status: pending              # pending → in_progress → blocked → done
  blocked_by: ""
  notes: ""
```

#### 估算規則

| Size | 時間 | LOC | 說明 |
|------|------|-----|------|
| S | < 30 min | < 200 | 單一函數、config 修改、文字調整 |
| M | 30-120 min | 200-800 | 一個完整 endpoint、一個 component |
| L | 2-4 hr | 800-2000 | 跨模組功能、複雜商業邏輯 |
| XL | > 4 hr | > 2000 | ⚠️ 強制拆成多個 M 或 S |

#### Dependency Graph

每個 Feature 標記 `depends_on: [F-XXX]`。Task-Master 根據依賴圖決定可並行 / 必須序列。

---

## S-02：架構設計深化（痛點 #2）

### 問題
Plan 階段對架構、模組邊界、API、DB、資料流討論不足。

### 借鏡
- **GStack** `/plan-eng-review`：ASCII diagrams + data flow + state machines + error paths + test matrices → 全部 lock-in 後才進 Build

### 方案

#### SD (System Design) Checklist — Plan Gate 出口必要條件

| # | 項目 | 格式 | 驗收標準 |
|---|------|------|---------|
| SD-1 | 架構圖 | Mermaid / ASCII | 標明所有模組 + 模組間介面 |
| SD-2 | 資料流圖 | Mermaid sequence | 每個核心 API 的 request → processing → response |
| SD-3 | DB Schema | ERD + DDL | 所有 table + relation + index strategy |
| SD-4 | 狀態機圖 | Mermaid state | 有狀態變遷的每個核心實體 |
| SD-5 | 錯誤處理策略 | Table | Error code 分類 + HTTP status + fallback 路徑 |
| SD-6 | 測試矩陣 | Table | Feature × 測試層級 的覆蓋規劃 |
| SD-7 | ADR 清單 | 每個至少 Context/Decision/Consequences | 所有架構決策有記錄 |

#### Architecture Lock-in

Plan Gate 通過後：
1. SD 文件 → ARTIFACTS.md 標記為 `Baselined`
2. 之後修改 → 強制觸發 CIA
3. CIA 批准後 → 文件降級為 Draft → 修改 → 重走 Plan Gate 相關項

---

## S-03：Task Board 監控（痛點 #3）

### 問題
無法清楚知道哪些 Task 待執行 / 進行中 / 卡住 / 待討論。

### 借鏡
- **GStack** Review Readiness Dashboard + `/retro` 儀表板

### 方案

#### TASKS.md 結構化

從自由文字改為固定 YAML 結構（見 S-01 Task 定義格式），支援以下狀態：

```
pending → in_progress → done
                ↓
            blocked → (解除後) → in_progress
```

#### Dashboard 新增 Task Board Tab

| 欄 | 內容 | 視覺 |
|----|------|------|
| Backlog | status: pending 的 Task | 灰色卡片 |
| In Progress | status: in_progress | 藍色卡片 + Agent 名稱 |
| Blocked | status: blocked | 紅色卡片 + blocked_by 原因 |
| Done | status: done | 綠色卡片 |

#### Gate Readiness Panel

每個 Gate 前顯示：
- 通過 X/N 項出口條件
- 未通過的項目用紅色標示
- 「可以進 Gate」或「尚有 N 項未完成」的狀態燈

---

## S-04：SD 確認流程（痛點 #4）

### 問題
SD 文件寫完沒有結構化的確認流程。

### 方案

#### SD Confirm Session

```
Architect 完成 SD
    ↓
ARTIFACTS.md: SD 狀態 → In Review
    ↓
Review Agent: 跑 SD Checklist（S-02 的 7 項）
    ↓
Task-Master: 整理 Review 結果 → 產出 SD_CONFIRM_[feature-id].md
    ↓
凱子確認: ✅ 核准 / 🔄 修改 / ❌ 駁回
    ↓
核准 → ARTIFACTS.md: SD 狀態 → Baselined → 進入 Plan Gate
```

#### SD Confirm 文件內容

```markdown
# SD Confirm — [Feature ID]

**文件**: [SD 文件路徑]
**Review 日期**: [YYYY-MM-DD]
**Reviewer**: Review Agent

## 架構選型摘要
[1-3 句話說明為什麼選這個方案]

## 核心決策
| # | 決策 | 原因 | Trade-off |
|---|------|------|-----------|

## 風險
| 風險 | 可能性 | 影響 | 緩解 |
|------|--------|------|------|

## 確認
- [ ] ✅ 核准 — SD 進入 Baselined
- [ ] 🔄 修改 — 列出修改要求：___
- [ ] ❌ 駁回 — 原因：___

**決策者**: ___
**日期**: ___
```

---

## S-05：測試治理（痛點 #5）

### 問題
測試項目模糊，不確定要測什麼、怎麼測、覆蓋率是否足夠。

### 借鏡
- **GStack**：多層測試（`/review` + `/qa` + `/cso` + `/canary`）、每個 bug fix 自動附 regression test
- **Superpowers**：強制 TDD、code-before-test 自動刪除

### 方案

#### Test Pyramid — 5 層定義

| 層 | 名稱 | 範圍 | 覆蓋率目標 | 負責 Agent | 時機 |
|----|------|------|-----------|-----------|------|
| L1 | Unit | 函數/方法 | ≥ 80% | Backend / Frontend | Build 中持續 |
| L2 | Integration | API + DB | 每個 endpoint 至少 happy + error | Backend | Build 中持續 |
| L3 | E2E | 使用者操作流程 | 每個 critical journey | QA | Build Gate 前 |
| L4 | Security | OWASP Top 10 + STRIDE | auth/payment 全覆蓋 | Security | Ship Gate 前 |
| L5 | Smoke | 部署後健康 | 核心路徑 100% | DevOps | Ship 後 |

#### Test Matrix Template（Plan Gate 出口條件）

| Feature | L1 Unit | L2 Integration | L3 E2E | L4 Security | 狀態 |
|---------|---------|---------------|--------|-------------|------|
| F-001   | 0/? | 0/? | 0/? | — | 規劃中 |

- Plan Gate：Matrix 必須存在且每個 Feature 有規劃數量
- Build Gate：L1+L2 達標
- Ship Gate：L3+L4+L5 達標

#### Bug Fix = Regression Test（強制規則）

借鏡 GStack `/qa`：任何 bug fix 必須附帶一個自動化 regression test，確保同樣的 bug 不再復發。未附 test 的 fix 不允許合併。

---

## S-06：Brownfield / Hotfix 增強（痛點 #6）

### 問題
接手舊專案或處理 hotfix 時不知道從哪開始。

### 借鏡
- **GStack** `/investigate`：auto-freeze + max 3 fix attempts + regression test
- **GStack** `/careful` + `/guard`：destructive command protection

### 方案

#### Brownfield Onboarding Protocol（新 skill：`brownfield-onboard`）

```
Step 1: Codebase Snapshot（自動化）
├── 語言/框架偵測
├── 依賴分析（package.json / requirements.txt / pom.xml）
├── 目錄結構掃描
└── → 產出 CODEBASE_MAP.md

Step 2: Baseline 建立（自動化）
├── 跑既有測試 → pass/fail 記錄
├── 靜態分析 → lint error/warning 數量
├── DB schema dump → table 清單
└── → 產出 BASELINE_SNAPSHOT.md

Step 3: Gap Report（分析）
├── 比對 Baseline vs. 框架標準
├── 缺少什麼：test? CI? docs? type safety?
└── → 產出 GAP_REPORT.md

Step 4: First Safe Change（最小改動建立信心）
├── 加一個 test / 修一個 lint warning
├── 確認不破壞既有功能
└── → 併入主流程 Build 階段
```

#### Hotfix Protocol 增強

```
Incident 通報
    ↓
Step 1: Freeze — 鎖定受影響模組（只能修改該目錄）
    ↓
Step 2: Investigate — systematic-debugging skill
         最多 3 次修復嘗試，每次記 findings.md
    ↓
Step 3: Minimal Fix — 只修根因，不加功能
    ↓
Step 4: Regression Test — fix 必附 test
    ↓
Step 5: Rollback Plan — 寫明回滾步驟
    ↓
Step 6: Smoke Test — 部署後驗證
    ↓
Step 7: Follow-up Issue — 建後續改進 ticket
    ↓
Unfreeze — 解鎖模組
```

---

## S-07：UI/UX 範圍控制（痛點 #7）

### 問題
每次修改 prototype 風格都不一樣，AI 隨意改 Design Token。

### 借鏡
- **GStack** Design Pipeline：`/design-consultation` → `/design-shotgun` → `/design-html` → `/design-review`
- **GStack** DESIGN.md + 80 項 design review checklist

### 方案

#### DESIGN.md — Design Token 鎖定文件

在 Discover 階段由 UX Agent 產出，內容包含：

```markdown
# Design System — [專案名稱]

## 🔒 Lock Status: Baselined（修改需走 CIA）

## Color Palette
Primary: #1a73e8
Secondary: #34a853
Background: #ffffff
Surface: #f8f9fa
Text: #202124
Error: #d93025

## Typography
Font: 'Inter', -apple-system, sans-serif
H1: 28px/700  H2: 22px/600  Body: 14px/400  Caption: 12px/400

## Spacing: xs:4 sm:8 md:16 lg:24 xl:32

## Component Tokens
Button: 36/44/52px height
Input: 40px height
Card: 16px padding, shadow 0 1px 3px rgba(0,0,0,.12)
Border-radius: sm:4 md:8 lg:12
```

#### 修改分級

| 等級 | 可修改範圍 | 審批 |
|------|-----------|------|
| **Free** | 文字內容、圖片/icon 替換、組件內部微調 | 不需要 |
| **Review** | 新增/刪除頁面元件、改變佈局結構、修改互動流程 | Review Agent 確認 |
| **CIA** | 改顏色、字體、間距系統、組件基本尺寸 | CIA 流程 + 凱子核准 |
| **禁止** | 引入新 CSS framework、改 navigation 結構、使用未定義 token | 不允許 |

#### Design Variant 流程（Discover 階段）

```
UX Agent 調研 → 產出 3 個方案（A/B/C）
    ↓
並排對比板（HTML）讓凱子選
    ↓
選定方案 → 鎖入 DESIGN.md → Baselined
    ↓
後續所有修改只能在 DESIGN.md token 範圍內
```

---

## S-08：Agent×Skill Matrix + Domain Skill（痛點 #8）

### 問題
沒有事先定義每個 Agent 帶哪些 skill，Domain Skill 也沒規劃。

### 方案

#### 完整 Agent×Skill Matrix

| Agent | Group 定義 | Tier 1 必載 | Tier 1 可選 | 專用 Context |
|-------|-----------|-------------|-------------|-------------|
| **Task-Master** | — | task-master, verification-before-completion | — | STATE.md, TASKS.md |
| **Interviewer/PM** | Discovery | brainstorming, writing-plans, planning-with-tasks, verification-before-completion | deep-research, doc-coauthoring | GROUP_Discovery.md |
| **UX** | Discovery | brainstorming, frontend-design, planning-with-tasks, verification-before-completion | screenshot-to-code | GROUP_Discovery.md, DESIGN.md |
| **Architect** | Discovery | writing-plans, deep-research, planning-with-tasks, verification-before-completion | — | GROUP_Discovery.md |
| **Backend** | Build | writing-plans, TDD, systematic-debugging, planning-with-tasks, using-git-worktrees, requesting-code-review, verification-before-completion | ground, validate-contract | GROUP_Build.md |
| **Frontend** | Build | writing-plans, TDD, systematic-debugging, frontend-design, planning-with-tasks, using-git-worktrees, requesting-code-review, verification-before-completion | ground, screenshot-to-code | GROUP_Build.md, DESIGN.md |
| **DBA** | Build | writing-plans, planning-with-tasks, verification-before-completion | ground, validate-contract | GROUP_Build.md, DB Standards |
| **QA** | Verify | webapp-testing, systematic-debugging, planning-with-tasks, verification-before-completion | — | GROUP_Verify.md |
| **Security** | Verify | deep-research, verification-before-completion | — | GROUP_Verify.md |
| **DevOps** | Verify | systematic-debugging, verification-before-completion | — | GROUP_Verify.md |
| **Review** | 跨階段 | gate-check, cia, quality-gates, verification-before-completion | retro | ROLE_Review.md |

#### Domain Skill 配置（project-config.yaml）

```yaml
# project-config.yaml

project:
  name: "[專案名稱]"
  type: "SaaS B2B"
  tech_stack: "Vue 3 / Spring Boot / MySQL + MSSQL / GCP"

domain:
  name: "call-center"
  skill_path: "context-skills/call-center-domain"
  load_for:    # 需要業務知識的 Agent
    - Interviewer
    - PM
    - UX
    - Architect
    - DBA
    - Backend
    - Frontend
    - QA
    - Review
  exclude:     # 不需要業務知識的 Agent
    - Task-Master   # 純 dispatcher
    - DevOps        # 純基礎設施
    - Security      # 通用安全（除非是合規類 domain）

tier2_skills:  # 專案級啟用的 Tier 2 skill
  - call-center-domain
  - doc-coauthoring
  - deep-research
  - screenshot-to-code
  - validate-contract
  - ground

modes:
  execution: "copilot"    # autopilot / copilot / manual
  gate_weight: "standard" # standard / lite
```

---

## S-09：Agent 通訊 / 交接協議（痛點 #9）

### 問題
Agent 之間怎麼溝通？是否要交接手冊？

### 核心原則
**Agent 之間不直接溝通。全部透過 Artifact + Task-Master 中轉。**

Claude Code 每個 session 獨立，Agent A 無法直接跟 Agent B 對話。

### Handoff Protocol 標準格式

```markdown
# HANDOFF — [From Agent] → [To Agent]

**Date**: [YYYY-MM-DD HH:MM]
**Feature**: [F-XXX]
**Task**: [T-XXX → T-YYY]

## 完成摘要
[1-3 句]

## 產出文件
| 文件 | 路徑 | ARTIFACTS 狀態 |
|------|------|----------------|

## 下一位需要知道的事
- [關鍵假設/決策]
- [已知風險/限制]
- [需特別注意之處]

## 下一位需要做的事
1. [具體任務]
2. [具體任務]

## DRIFT（如果有）
[無 / 有 — 已送 DRIFT_SIGNAL]
```

### Handoff 存放位置

```
memory/handoffs/
├── F-001-user-auth/
│   ├── PM-to-UX.md
│   ├── UX-to-Architect.md
│   └── Architect-to-Backend.md
└── F-002-payment/
    └── PM-to-Architect.md
```

### 路由流程

```
Agent 完成 → 寫 Handoff + 更新 TASKS.md
    ↓
Task-Master 讀 TASKS.md → 看到狀態變更
    ↓
Task-Master 讀 Handoff → 判斷下一個 Agent
    ↓
Task-Master 更新 STATE.md → 標記新 Agent
    ↓
新 Agent 啟動 → 讀 STATE.md + Handoff + 相關 Artifact
```

---

## S-10：記憶管理增強（痛點 #10）

### 問題
4 個 memory 文件缺少「教訓/模式/偏好」的持久記憶。

### 借鏡
- **GStack** `/learn`：review / search / prune 三種操作

### 方案

#### 新增第 5 個 Memory 文件：LEARNINGS.md

```markdown
# LEARNINGS.md

## 技術模式（有效的做法）
| 日期 | 模式 | 上下文 | 效果 |
|------|------|--------|------|

## 踩坑記錄（無效的做法）
| 日期 | 踩坑 | 上下文 | 正確做法 |
|------|------|--------|---------|

## 凱子偏好
| 日期 | 偏好 | 說明 |
|------|------|------|

## 工具/環境備忘
| 日期 | 備忘 | 說明 |
|------|------|------|
```

#### Token 預算：≤ 800 tokens

#### Prune 規則
- 每個 Gate 結束時，移除 > 30 天且未再引用的條目
- 超出 800 tokens 時，移除最舊的條目
- 「凱子偏好」永不自動刪除（手動 prune）

#### Memory System 總覽（v4.1 更新後）

| 文件 | Token 上限 | 用途 | 讀取者 |
|------|-----------|------|--------|
| STATE.md | 400 | 即時狀態 | Task-Master（必讀） |
| TASKS.md | — | 任務追蹤 | Task-Master（必讀） |
| ARTIFACTS.md | — | 文件登記 | Task-Master（drift 時讀） |
| DECISIONS.md | — | 架構決策 | Architect / Review |
| **LEARNINGS.md** | **800** | **教訓/模式/偏好** | **各 Agent 按需讀** |

---

## S-11：Agent Teams（Phase 2 規劃）

### 決定：Phase 1 暫不採用

### 理由
1. 目前單一專案並行 Feature 量 2-3 個，Agent Teams overhead > benefit
2. Subagent-driven-development skill 已可處理特定並行場景
3. Handoff Protocol（S-09）+ TASKS.md 結構化（S-01）已能支撐序列協作

### Phase 2 啟用條件
- 同時並行 > 5 個 Feature
- 多人團隊各自操作不同 Agent
- CI/CD pipeline 穩定、Gate 自動化程度高

### Phase 2 預留設計
- 每個 Feature Team = Task-Master + N specialists + 獨立 worktree
- Team 間透過 ARTIFACTS.md 和 DECISIONS.md 共享狀態
- conductor.json 擴展支援 multi-team conflict detection

---

## S-12：舊專案遷移策略（v3.3 → v4）

### 遷移原則

1. **非破壞性**：遷移過程中保留所有既有文件，不刪除任何內容
2. **漸進式**：可以先遷 memory + 角色定義，再逐步遷 skill
3. **可回滾**：遷移前建立 git tag，隨時可以回到 v3.3
4. **不中斷進行中工作**：進行中的 Feature 在當前流程完成後再切到 v4

### 結構差異對照

| 面向 | v3.3 | v4 | 遷移動作 |
|------|------|-----|---------|
| 主導航 | CLAUDE.md (61KB, ~15K tokens) | CLAUDE.md (≤5K tokens) | **重寫**：抽出內容到 GROUP/ROLE/skill |
| 角色定義 | 11 個 SEED_*.md | 3 GROUP + 1 ROLE_Review | **合併**：按 Group 整併，specialist 區塊保留差異 |
| Memory 文件 | 17+ 個 | 5 個 | **整併**：多數內容歸入 LEARNINGS 或移至 docs/ |
| Skill 目錄 | context-skills/ (40+) | Tier 1/2/3 分層 | **分類**：標記 Tier，非核心移除或降為 Tier 3 |
| 任務追蹤 | TASKS.md (自由格式) | TASKS.md (YAML 結構) | **改格式**：保留內容，改為結構化格式 |
| 文件登記 | MASTER_INDEX.md | ARTIFACTS.md | **重命名 + 簡化**：保留 F-code + maturity |
| 團隊協作 | TEAM.md | project-config.yaml + Handoff | **拆分**：config 歸 yaml，交接歸 handoff/ |
| 流程定義 | P00-P06 in CLAUDE.md | Discover→Plan→Build→Verify→Ship | **對映**：P00+P01→Discover, P02→Plan, P03+P04→Build, P05→Verify, P06→Ship |
| Dashboard | PROJECT_DASHBOARD.html | 同 + Task Board tab | **擴展**：新增 tab，保留既有 |
| 設計系統 | 無 | DESIGN.md | **新建** |

### Step-by-Step 遷移流程

#### Phase 0：準備（5 分鐘）

```bash
# 1. 建立遷移起點標記
cd [專案根目錄]
git tag v3.3-pre-migration
git push origin v3.3-pre-migration

# 2. 建立遷移分支
git checkout -b migration/v3.3-to-v4
```

#### Phase 1：Memory 整併（15 分鐘）

**v3.3 的 17 個 memory 文件 → v4 的 5 個**

| v3.3 文件 | → v4 去向 | 動作 |
|-----------|----------|------|
| `memory/STATE.md` | `memory/STATE.md` | **保留**，精簡到 ≤400 tokens |
| `memory/product.md` | `memory/product.md` | **保留**（不計入 4 file，參考用） |
| `memory/decisions.md` | `memory/DECISIONS.md` | **改名大寫** |
| `memory/workflow_rules.md` | → skill 或 GROUP file | **拆分**：規則歸入對應的 skill/GROUP |
| `memory/glossary.md` | `memory/glossary.md` | **保留**（參考用） |
| `memory/dashboard.md` | **移除**（Dashboard 自含） | **歸檔** → `docs/archive/v3.3/` |
| `memory/token_budget.md` | → `project-config.yaml` | **合併** |
| `memory/gate_baseline.yaml` | → `quality-gates` skill | **合併** |
| `memory/hotfix_log.md` | `memory/hotfix_log.md` | **保留**（獨立記錄） |
| `memory/smoke_tests.md` | → `webapp-testing` skill | **合併** |
| `memory/TECH_DEBT.md` | → TASKS.md（backlog 區） | **合併** |
| `memory/last_task.md` | → STATE.md | **合併** |
| `memory/domain_*.md` | → `context-skills/[domain]/` | **移動** |
| `memory/context/company.md` | `memory/company.md` | **保留** |
| `memory/knowledge_base/*.md` | → `LEARNINGS.md` | **轉移**精華 |
| `memory/people/` | **保留** | — |
| `memory/projects/` | **保留** | — |

**新建**：
- `TASKS.md`（結構化重寫）
- `ARTIFACTS.md`（從 MASTER_INDEX.md 轉化）
- `LEARNINGS.md`（新建，從 knowledge_base 遷入精華）

#### Phase 2：角色定義轉換（20 分鐘）

**v3.3 的 11 SEED → v4 的 3 GROUP + 1 ROLE**

```bash
mkdir -p context-roles
```

| v3.3 SEED | → v4 GROUP | 動作 |
|-----------|-----------|------|
| SEED_Interviewer.md | GROUP_Discovery.md §Interviewer/PM | 合併 |
| SEED_PM.md | GROUP_Discovery.md §Interviewer/PM | 合併 |
| SEED_UX.md | GROUP_Discovery.md §UX | 合併 |
| SEED_Architect.md | GROUP_Discovery.md §Architect | 合併 |
| SEED_Backend.md | GROUP_Build.md §Backend | 合併 |
| SEED_Frontend.md | GROUP_Build.md §Frontend | 合併 |
| SEED_DBA.md | GROUP_Build.md §DBA | 合併 |
| SEED_QA.md | GROUP_Verify.md §QA | 合併 |
| SEED_Security.md | GROUP_Verify.md §Security | 合併 |
| SEED_DevOps.md | GROUP_Verify.md §DevOps | 合併 |
| SEED_Review.md | ROLE_Review.md | 獨立 |

**GROUP 檔案結構**（每個 ≤ 2K tokens）：

```markdown
# GROUP_[Name].md

## 通用行為（本 Group 所有 specialist 共享）
[交接格式、可用 skill 範圍、與其他 Group 介面]

## §[Specialist Name]
**職責**: [1-2 句]
**必載 Skill**: [清單]
**禁止事項**: [清單]
**完成標準**: [清單]
```

#### Phase 3：CLAUDE.md 瘦身（30 分鐘）

**v3.3: 61KB (~15K tokens) → v4: ≤5K tokens**

保留在 CLAUDE.md 的內容（只有框架級指令）：
- 設計原則 T1-T5
- Pipeline 概覽（一句話 × 5 stages）
- Gate 名稱與觸發條件（簡表）
- Task-Master 啟動指令
- project-config.yaml 引用
- Token budget 總表

搬出 CLAUDE.md 的內容：

| 原 CLAUDE.md 區塊 | → 搬到哪裡 |
|-------------------|----------|
| 完整 Pipeline 定義 (P00-P06) | → `pipeline-orchestrator` skill |
| Agent 路由表 | → `task-master` skill |
| Skill 路由表 | → `project-config.yaml` |
| 執行模式 (autopilot/copilot/manual) | → `project-config.yaml` |
| Handoff 格式 | → Handoff Protocol (S-09) |
| Gate checklist | → `quality-gates` skill |
| Brownfield / Hotfix 流程 | → 對應 skill |

#### Phase 4：Skill 分層（15 分鐘）

```bash
# 保留 context-skills/ 目錄結構不變
# 在 project-config.yaml 中標記 Tier
```

| Tier | 分類標準 | 動作 |
|------|---------|------|
| Tier 1 | 每個專案都用的核心紀律 | 保持，確認 ≤ token budget |
| Tier 2 | 專案配置啟用的 domain/governance | 標記，在 config 中管理 |
| Tier 3 | 平台工具（docx/pptx/pdf/xlsx） | 不動，由 Cowork 平台管理 |

#### Phase 5：新增 v4 專屬文件（10 分鐘）

```bash
# 新建
touch DESIGN.md              # S-07
touch project-config.yaml    # S-08
touch memory/LEARNINGS.md    # S-10
mkdir -p memory/handoffs     # S-09

# 從 MASTER_INDEX.md 轉化
cp MASTER_INDEX.md ARTIFACTS.md
# 手動編輯：簡化成 artifact registry 格式
```

#### Phase 6：Dashboard 升級（15 分鐘）

```bash
# 保留既有 tab
# 新增 Task Board tab（S-03）
# 新增 Gate Readiness panel
# 更新 Risks tab 反映最新狀態
```

#### Phase 7：驗證 + Token Budget 檢查（5 分鐘）

```bash
# 跑 token budget 驗證
bash context-skills/project-init/scripts/validate-token-budget.sh \
  --project "$(pwd)"

# 確認所有檔案存在
ls -la CLAUDE.md TASKS.md ARTIFACTS.md DESIGN.md project-config.yaml
ls -la context-roles/GROUP_Discovery.md context-roles/GROUP_Build.md
ls -la context-roles/GROUP_Verify.md context-roles/ROLE_Review.md
ls -la memory/STATE.md memory/DECISIONS.md memory/LEARNINGS.md

# 確認 CLAUDE.md ≤ 5K tokens
wc -c CLAUDE.md  # 應 ≤ 20000 bytes (5K × 4)
```

#### Phase 8：提交 + 清理（2 分鐘）

```bash
# 歸檔 v3.3 遺留
mkdir -p docs/archive/v3.3
mv context-seeds/SEED_*.md docs/archive/v3.3/  # 保留備份
mv MASTER_INDEX.md docs/archive/v3.3/
mv TEAM.md docs/archive/v3.3/

git add -A
git commit -m "migration: v3.3 → v4 framework restructure"
```

### 遷移 Checklist

```markdown
## v3.3 → v4 Migration Checklist

### Phase 0: 準備
- [ ] git tag v3.3-pre-migration
- [ ] git checkout -b migration/v3.3-to-v4

### Phase 1: Memory 整併
- [ ] STATE.md 精簡到 ≤400 tokens
- [ ] DECISIONS.md 改名
- [ ] workflow_rules 拆入 skill/GROUP
- [ ] LEARNINGS.md 新建
- [ ] 過時 memory 歸檔到 docs/archive/v3.3/

### Phase 2: 角色轉換
- [ ] GROUP_Discovery.md 建立（Interviewer/PM + UX + Architect）
- [ ] GROUP_Build.md 建立（Backend + Frontend + DBA）
- [ ] GROUP_Verify.md 建立（QA + Security + DevOps）
- [ ] ROLE_Review.md 建立
- [ ] 每個 GROUP ≤ 2K tokens
- [ ] ROLE_Review ≤ 1K tokens

### Phase 3: CLAUDE.md 瘦身
- [ ] 搬出 Pipeline 定義 → pipeline-orchestrator skill
- [ ] 搬出 Agent 路由表 → task-master skill
- [ ] 搬出 Gate checklist → quality-gates skill
- [ ] CLAUDE.md ≤ 5K tokens

### Phase 4: Skill 分層
- [ ] project-config.yaml 建立
- [ ] Tier 1/2/3 標記完成
- [ ] Domain Skill load_for 配置

### Phase 5: 新文件
- [ ] DESIGN.md 建立
- [ ] ARTIFACTS.md（從 MASTER_INDEX 轉化）
- [ ] memory/handoffs/ 目錄建立
- [ ] project-config.yaml 完成

### Phase 6: Dashboard
- [ ] Task Board tab 新增
- [ ] Gate Readiness panel 新增

### Phase 7: 驗證
- [ ] Token Budget 驗證全 PASS
- [ ] 所有核心文件存在
- [ ] Git commit 成功

### Phase 8: 清理
- [ ] v3.3 遺留歸檔
- [ ] migration branch 可合併
```

### 遷移時間估算

| Phase | 預估時間 | 自動化程度 |
|-------|---------|-----------|
| Phase 0 準備 | 5 min | 手動 |
| Phase 1 Memory | 15 min | 半自動（腳本可輔助） |
| Phase 2 角色 | 20 min | 手動（需要判斷內容取捨） |
| Phase 3 CLAUDE.md | 30 min | 手動（最關鍵步驟） |
| Phase 4 Skill | 15 min | 半自動 |
| Phase 5 新文件 | 10 min | 模板化 |
| Phase 6 Dashboard | 15 min | 半自動 |
| Phase 7 驗證 | 5 min | 自動 |
| Phase 8 清理 | 2 min | 手動 |
| **Total** | **~2 小時** | |

### 進行中專案的處理

| 情況 | 建議 |
|------|------|
| Feature 在 P04 實作中 | 等 Feature 完成 + Gate 3 通過後再遷移 |
| Feature 在 P01/P02 | 可以先遷移框架，文件內容不受影響 |
| Hotfix 進行中 | 完成 Hotfix 後再遷移 |
| 專案剛開始 | 直接用 v4 template 開新專案（project-init skill） |
| 專案已交付 | 不需要遷移，歸檔即可 |

---

## 附錄：Pipeline 階段對映表

| v3.3 Pipeline | v4 Stage | 備註 |
|--------------|----------|------|
| P00 需求建立 | Discover | 合併 P00+P01 前半 |
| P01 需求細化+Prototype | Discover | 合併 P00+P01 |
| P02 技術設計 | Plan | 直接對映 |
| G4-ENG | Plan Gate | 融入 Plan Gate 出口條件 |
| P03 開發準備 | Plan (尾段) | API/Component spec 歸入 Plan 產出 |
| P04 實作開發 | Build | 直接對映 |
| P05 合規安全 | Verify | 直接對映 |
| P06 部署發佈 | Ship | 直接對映 |
| Gate 1 | Discover Gate | 對映 |
| Gate 2 | Plan Gate (前半) | 合併 |
| G4-ENG | Plan Gate (後半) | 合併 |
| Gate 3 | Build Gate | 對映 |
| (無) | Ship Gate | v4 新增 |
