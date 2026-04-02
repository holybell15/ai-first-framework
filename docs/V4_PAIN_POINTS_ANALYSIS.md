# V4 Blueprint — 痛點分析與 GStack 借鏡報告

> **Date**: 2026-03-31
> **Context**: 凱子提出 10 個痛點 + 要求分析 GStack 可借鏡之處
> **Reference**: GStack v1 (garrytan/gstack), Superpowers (obra/superpowers), V4 Blueprint v1.0

---

## Part A：GStack 可借鏡的設計

在分析痛點之前，先整理 GStack 的設計亮點，因為很多痛點的解法可以直接從 GStack 抄作業。

### A1. 角色即 Slash Command，不是抽象描述

GStack 把 9 個角色做成 `/office-hours`、`/plan-ceo-review`、`/plan-eng-review` 等 slash command。每個 command 的 SKILL.md 裡寫死了：輸入是什麼、輸出是什麼、要讀哪些文件、產出存在哪裡。

**借鏡**：我們的 GROUP_Discovery / GROUP_Build / GROUP_Verify 目前只有角色定義，缺少「每個角色啟動時要讀什麼 + 產出什麼 + 存在哪裡」的明確規格。

### A2. 設計管線（Design Pipeline）

GStack 有 4 個設計階段 skill：
- `/design-consultation` → 調研 + 創意風險 + mockup
- `/design-shotgun` → 多方案對比板（3 variants）
- `/design-html` → 核准方案轉 production HTML
- `/design-review` → 80 項 checklist + 自動修復 + before/after 截圖

**借鏡**：我們的 V4 只有一個 UX Agent + frontend-design skill，沒有分階段控制。這直接導致你的痛點 #7（每次改風格都不一樣）。

### A3. `/autoplan` — 自動化 Pipeline 串接

GStack 的 `/autoplan` 自動跑 CEO → Design → Eng Review 三步。每一步的輸出自動成為下一步的輸入。

**借鏡**：我們的 Pipeline 目前是「人工在 TASKS.md 標記 → Task-Master 讀取 → 分派」，缺少「自動串接」的概念。

### A4. `/learn` — 學習記憶系統

GStack 有 `/learn` 指令：review（檢視已學到的東西）、search（搜尋過去的教訓）、prune（清理過時的知識）。這是 project-level 的知識累積，跨 session 保留。

**借鏡**：我們的 4-file memory system（STATE / TASKS / ARTIFACTS / DECISIONS）偏重「狀態追蹤」，缺少「教訓/模式/偏好」的持久記憶。

### A5. `/freeze` + `/guard` — 範圍鎖定

GStack 的 `/freeze` 鎖定編輯到單一目錄，`/guard` = `/careful` + `/freeze`。Debug 時自動凍結到受影響模組。

**借鏡**：我們的 CIA skill 在「文件級」有保護，但在「程式碼目錄級」沒有。可以結合。

### A6. Review Readiness Dashboard

GStack 在 ship 前有一個 Review Readiness Dashboard，顯示哪些 review 完成了、哪些還沒。

**借鏡**：我們的 PROJECT_DASHBOARD.html 追蹤 Pipeline 進度，但沒有「Gate 前的 readiness checklist 視覺化」。

---

## Part B：10 個痛點逐項分析

---

### 痛點 #1：WBS / 項目安排不明確

**問題描述**：在 Discover 階段雖然有 WBS 的概念，但實際上不知道整個專案的項目要怎麼拆解、排序、估時。缺乏傳統 PM 的工作分解結構。

**V4 現狀缺口**：Blueprint v1.0 §1 寫 Discover 產出 WBS，但沒有定義 WBS 的格式、分解規則、估算方法。

**可以解決嗎**：✅ 可以。

**解法**：

建立 `writing-plans` skill 的 WBS 子模板，借鏡 GStack 的 `/plan-eng-review`（鎖定 architecture + 產出 test matrix + 精確到檔案路徑的任務分解）和 Superpowers 的 `writing-plans`（每個 task 2-5 分鐘、附完整驗證步驟）。

**具體交付**：

1. **WBS Template**（新增到 `02_Specifications/TEMPLATE_WBS_V4.md`）：
   - Level 1: Epic（業務功能群）
   - Level 2: Feature（F-XXX，對應 src/[feature-id]/）
   - Level 3: Task（可在一個 session 完成的工作單元）
   - 每個 Task 包含：精確檔案路徑、預估 token 成本、驗證步驟、前置依賴

2. **Estimation Protocol**：
   - S (< 30 min, < 200 LOC)
   - M (30-120 min, 200-800 LOC)
   - L (2-4 hr, 800-2000 LOC)
   - XL (> 4 hr, 需切成多個 M 或 S) → 強制再分解

3. **Dependency Graph**：每個 Feature 標記 `depends_on: [F-XXX]`，Task-Master 根據依賴關係決定並行或序列。

---

### 痛點 #2：程式架構 / 系統設計討論太少

**問題描述**：原始流程在 Plan 階段對架構、模組邊界、API 設計、DB Schema、資料流的討論幾乎沒有。

**V4 現狀缺口**：Blueprint §1 只寫「Plan 產出 System Design、Slice Backlog」，但沒有定義 System Design 要包含什麼、用什麼格式、誰 review。

**可以解決嗎**：✅ 可以。

**解法**：

借鏡 GStack `/plan-eng-review` 的「Architecture Lock-in」概念：在 Plan Gate 前，必須產出完整的技術設計，且由 Architect + Review 雙重確認後才能 lock。

**具體交付**：

1. **SD (System Design) Checklist**（Plan Gate 出口條件之一）：
   - [ ] 架構圖（ASCII / Mermaid，標明模組邊界）
   - [ ] 資料流圖（每個 API endpoint 的 request→processing→response）
   - [ ] DB Schema（所有 table + relation + index strategy）
   - [ ] 狀態機圖（有狀態變遷的核心實體）
   - [ ] 錯誤處理策略（error code 分類 + fallback 路徑）
   - [ ] 測試矩陣（每個 feature × 測試類型的覆蓋表）

2. **Architecture Decision Record (ADR)** 模板，借鏡 GStack 的 design doc：
   - Context / Decision / Consequences / Alternatives Considered

3. **Design Lock 機制**：Plan Gate 通過後，System Design 文件進入 `Baselined` 狀態。之後修改必須走 CIA。

---

### 痛點 #3：缺乏清楚的項目監控視圖

**問題描述**：不知道現在有哪些項目待執行、接續執行、待討論、卡住。TASKS.md 是純文字，沒有可視化。

**V4 現狀缺口**：有 PROJECT_DASHBOARD.html 追蹤 Pipeline 級別的進度，但沒有 Task 級別的看板。

**可以解決嗎**：✅ 可以。

**解法**：

借鏡 GStack 的 Review Readiness Dashboard + `/retro` 儀表板概念，在 PROJECT_DASHBOARD.html 新增 Task Board tab。

**具體交付**：

1. **TASKS.md 結構化改造**（從自由格式改成固定 YAML-like 結構）：

```yaml
- id: T-001
  feature: F-001-user-auth
  title: "實作登入 API endpoint"
  status: in_progress | blocked | waiting_review | done
  assigned: Backend
  blocked_by: ""          # 空 = 沒卡住；填 T-XXX = 等待另一個 task
  depends_on: [T-000]
  size: M
  started: 2026-04-01
  notes: ""
```

2. **Dashboard 新增 Task Board tab**：
   - 4 欄看板：Backlog → In Progress → Blocked/Waiting → Done
   - 每張卡片顯示 Task ID、Feature、Assigned Agent、Size
   - Blocked 卡片用紅色標記 + 顯示 blocked_by 原因
   - 從 TASKS.md 自動讀取渲染（update-dashboard skill 負責同步）

3. **Gate Readiness Checklist**（借鏡 GStack Review Readiness Dashboard）：
   - 每個 Gate 前顯示：通過 0/N 項，明確列出哪些卡片還沒完成

---

### 痛點 #4：SD 文件沒有規劃確認流程

**問題描述**：傳統的 System Design 文件寫完就放著，沒有「給人確認」的結構化流程。

**V4 現狀缺口**：template 裡有 `TEMPLATE_SD_Confirm.md` 和 `TEMPLATE_SD_Confirm.docx`，但 Blueprint 沒有定義何時觸發、誰確認、確認項是什麼。

**可以解決嗎**：✅ 可以。

**解法**：

在 Plan 階段結尾，加入「SD Confirm Session」作為 Plan Gate 的前置步驟。

**具體交付**：

1. **SD Confirm 流程**：

```
Architect 產出 SD 文件
    ↓
Review Agent 跑 SD Review Checklist（技術面）
    ↓
Task-Master 整理 Review 結果 → 產出 SD_Confirm 文件
    ↓
凱子確認（核准 / 要求修改 / 駁回）
    ↓
核准 → SD 文件進入 Baselined → 進入 Plan Gate
```

2. **SD Confirm 文件內容**：
   - 架構選型摘要（為什麼選這個方案）
   - 核心設計決策清單（每個附帶 trade-off）
   - 風險清單 + 緩解策略
   - 測試策略概覽
   - 「✅ 確認 / ❌ 駁回 / 🔄 修改」簽核區

3. **SD Confirm 觸發條件**：Architect 完成 SD 後自動觸發（ARTIFACTS.md 中 SD 文件狀態從 Draft → In Review 時）。

---

### 痛點 #5：測試策略模糊

**問題描述**：不確定要測什麼、怎麼測、測的對不對。測試項目定義不清，缺乏覆蓋率概念。

**V4 現狀缺口**：有 TDD skill，但只處理 unit test 的 RED-GREEN-REFACTOR。沒有定義 integration test、E2E test、security test 的範圍和驗收標準。

**可以解決嗎**：✅ 可以。

**解法**：

借鏡 GStack 的多層測試架構（`/review` 找 production bug → `/qa` 開瀏覽器測 user flow → `/cso` 跑 OWASP + STRIDE → `/canary` 部署後監控）和 Superpowers 的強制 TDD。

**具體交付**：

1. **Test Pyramid 定義**（寫入 Plan 階段的測試矩陣）：

| 層級 | 範圍 | 工具 | 覆蓋率目標 | 誰負責 |
|------|------|------|-----------|--------|
| L1 Unit | 每個函數/方法 | Jest / pytest | ≥ 80% | Backend / Frontend |
| L2 Integration | API endpoint + DB | Supertest / httpx | 每個 endpoint 至少 happy + error path | Backend |
| L3 E2E | 使用者操作流程 | Playwright | 每個 critical user journey | QA |
| L4 Security | OWASP Top 10 + STRIDE | /cso 概念 | 所有 auth/payment 相關 | Security |
| L5 Smoke | 部署後基本健康 | curl + health endpoint | 100% 核心路徑 | DevOps |

2. **Test Matrix Template**（Plan Gate 出口條件之一）：

```markdown
| Feature ID | L1 Unit | L2 Integration | L3 E2E | L4 Security | 備註 |
|-----------|---------|---------------|--------|-------------|------|
| F-001     | ✅ 12/12 | ✅ 4/4       | ✅ 2/2 | ✅ Pass    |      |
| F-002     | 🔄 8/10 | ⏳ 0/3       | ⏳     | ⏳         | L1 差 2 個 edge case |
```

3. **QA Agent skill 增強**：
   - 每個 bug fix 必須附帶 regression test（借鏡 GStack `/qa`）
   - Build Gate 出口條件加入覆蓋率門檻
   - Ship Gate 出口條件加入 Smoke Test 通過證據

---

### 痛點 #6：Brownfield / Hotfix 接入薄弱

**問題描述**：接手舊專案或處理 hotfix 時，常常不知道要做什麼、從哪裡開始。

**V4 現狀缺口**：Blueprint §12 有 Brownfield 和 Hotfix 的概念描述，但太高層次，缺乏 step-by-step 指引。

**可以解決嗎**：✅ 可以。

**解法**：

借鏡 GStack 的 `/investigate`（auto-freeze to affected module + max 3 fix attempts + regression test）和 `/careful` + `/guard` safety guardrails。

**具體交付**：

1. **Brownfield Onboarding Protocol**（新 skill：`brownfield-onboard`）：

```
Step 1: Codebase Snapshot
  - 語言/框架偵測
  - 依賴分析（package.json / requirements.txt / pom.xml）
  - 目錄結構掃描 → 產出 CODEBASE_MAP.md

Step 2: Baseline 建立
  - 跑既有測試（有的話）→ 記錄 pass/fail 數量
  - 靜態分析 → 記錄 lint error / warning 數量
  - DB schema dump → 記錄 table 清單
  → 產出 BASELINE_SNAPSHOT.md

Step 3: Gap Report
  - 比對 Baseline vs. 我們框架的標準
  - 缺少什麼（test？CI？documentation？type safety？）
  → 產出 GAP_REPORT.md

Step 4: First Safe Change
  - 選一個最小的改動（例如加一個 test、修一個 lint warning）
  - 確認改動不破壞既有功能
  - 建立信心 → 併入主流程的 Build 階段
```

2. **Hotfix Protocol**（增強現有 Hotfix 通道）：

```
Incident 通報
    ↓
Step 1: Freeze — 鎖定受影響模組（借鏡 GStack /freeze）
    ↓
Step 2: Investigate — 結構化除錯（systematic-debugging skill）
    - 最多 3 次修復嘗試（借鏡 GStack 的 Iron Law）
    - 每次嘗試記錄在 findings.md
    ↓
Step 3: Minimal Fix — 只修根本原因，不做額外改進
    ↓
Step 4: Regression Test — 每個 fix 附帶自動化測試
    ↓
Step 5: Rollback Plan — 寫明如何回滾
    ↓
Step 6: Smoke Test — 部署後驗證
    ↓
Step 7: Follow-up Issue — 建立後續改進 ticket
    ↓
Unfreeze — 解鎖受影響模組
```

---

### 痛點 #7：UI/UX Prototyping 風格不一致

**問題描述**：每次請 AI 改 prototype，第一次是 A 風格、第二次是 B 風格。無法限制範圍，也無法防止 AI 亂改。

**V4 現狀缺口**：有 `frontend-design` skill 但只有「Anti-AI-slop」概念，沒有實際的 Design Token 鎖定和修改範圍控制。

**可以解決嗎**：✅ 可以。這是 GStack 做得最好的地方。

**解法**：

完整借鏡 GStack 的 Design Pipeline 四階段 + DESIGN.md 鎖定機制。

**具體交付**：

1. **DESIGN.md — Design Token 鎖定文件**（Discover 階段產出，Baselined 後不可隨意修改）：

```markdown
# Design System — [專案名稱]

## Color Palette
- Primary: #1a73e8
- Secondary: #34a853
- Background: #ffffff
- Surface: #f8f9fa
- Text: #202124
- Text Muted: #5f6368
- Error: #d93025
- Warning: #f9ab00

## Typography
- Font Family: 'Inter', -apple-system, sans-serif
- H1: 28px / 700 / 1.2
- H2: 22px / 600 / 1.3
- Body: 14px / 400 / 1.6
- Caption: 12px / 400 / 1.4

## Spacing Scale
- xs: 4px, sm: 8px, md: 16px, lg: 24px, xl: 32px

## Border Radius
- sm: 4px, md: 8px, lg: 12px, full: 9999px

## Component Tokens
- Button height: 36px (sm) / 44px (md) / 52px (lg)
- Input height: 40px
- Card padding: 16px
- Card shadow: 0 1px 3px rgba(0,0,0,0.12)

## 🔒 Lock Status: Baselined
修改需走 CIA 流程。
```

2. **UX Agent 修改範圍控制**（寫入 frontend-design skill）：

```markdown
## Prototype 修改規則

### 允許修改（不需審批）
- 文字內容更新
- 圖片/icon 替換
- 組件內部佈局微調（不改變整體結構）

### 需要 Review（Review Agent 確認）
- 新增/刪除頁面元件
- 改變頁面佈局結構
- 修改互動流程

### 需要 CIA（改 Baselined Design Token）
- 改顏色
- 改字體
- 改間距系統
- 改組件基本尺寸

### 絕對禁止
- 未經核准引入新的 CSS framework
- 改變已確認的 navigation 結構
- 使用 DESIGN.md 中未定義的顏色/字體
```

3. **Design Variant 流程**（借鏡 GStack `/design-shotgun`）：
   - 在 Discover 階段，一次產出 3 個設計方案（不是 1 個）
   - 用並排對比板讓凱子選
   - 選定後鎖入 DESIGN.md → Baselined
   - 後續所有 prototype 修改必須遵循 DESIGN.md

---

### 痛點 #8：Agent × Skill 配置未預先定義 + Domain Skill 未規劃

**問題描述**：每個 Agent 應該帶哪些 skill 沒有事先定義好，Domain Skill 也沒有規劃進去。

**V4 現狀缺口**：Blueprint §4 定義了 GROUP file 的概念，但沒有定義每個 specialist 的 skill loadout。Tier 2 Domain Skill 提到「project-configured」但沒有具體映射表。

**可以解決嗎**：✅ 可以。

**解法**：

建立 **Agent × Skill Matrix**，預先定義每個 Agent 啟動時自動載入的 Tier 1 + Tier 2 skill 組合。

**具體交付**：

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Agent        │ Auto-Load Skills                                        │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Interviewer  │ T1: brainstorming, writing-plans, planning-with-tasks   │
│              │ T2: [domain-skill], deep-research                       │
│              │ Read: GROUP_Discovery.md                                │
├──────────────┼──────────────────────────────────────────────────────────┤
│ PM           │ T1: writing-plans, planning-with-tasks                  │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Discovery.md                                │
├──────────────┼──────────────────────────────────────────────────────────┤
│ UX           │ T1: frontend-design, writing-plans                      │
│              │ T2: [domain-skill], screenshot-to-code                  │
│              │ Read: GROUP_Discovery.md, DESIGN.md                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Architect    │ T1: writing-plans, deep-research                        │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Build.md                                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ DBA          │ T1: writing-plans                                       │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Build.md, DB Schema Standards               │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Backend      │ T1: TDD, systematic-debugging, planning-with-tasks      │
│              │ T1: verification-before-completion, using-git-worktrees  │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Build.md                                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Frontend     │ T1: TDD, frontend-design, planning-with-tasks           │
│              │ T1: verification-before-completion, using-git-worktrees  │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Build.md, DESIGN.md                         │
├──────────────┼──────────────────────────────────────────────────────────┤
│ QA           │ T1: TDD, systematic-debugging, webapp-testing           │
│              │ T1: planning-with-tasks                                 │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Verify.md                                    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Security     │ T1: deep-research, verification-before-completion       │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Verify.md                                    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ DevOps       │ T1: systematic-debugging                                │
│              │ T2: [domain-skill]                                      │
│              │ Read: GROUP_Verify.md                                    │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Review       │ T1: requesting-code-review, quality-gates, cia          │
│              │ T1: verification-before-completion                      │
│              │ T2: [domain-skill]                                      │
│              │ Read: ROLE_Review.md（跨階段）                           │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Task-Master  │ T1: task-master（dispatcher 邏輯）                      │
│              │ Read: STATE.md, TASKS.md（只在 drift 時讀 ARTIFACTS.md）│
└──────────────┴──────────────────────────────────────────────────────────┘
```

**Domain Skill 配置**：

在 `project-config.yaml` 中定義：

```yaml
domain:
  name: call-center
  skill: call-center-domain
  load_for:
    - Interviewer
    - PM
    - UX
    - Architect
    - DBA
    - Backend
    - Frontend
    - QA
    - Review
  # 不載入給 Task-Master（它不需要 domain 知識）
  # 不載入給 DevOps（純基礎設施）
  # 不載入給 Security（通用安全，不需要業務知識...除非是合規類 domain）
```

---

### 痛點 #9：Agent 之間如何溝通 / 交接手冊

**問題描述**：Agent 跟 Agent 之間怎麼自己溝通？是否需要交接手冊？

**V4 現狀缺口**：Blueprint §8 只提到「Handoff Protocol」概念，但沒有定義具體格式。

**可以解決嗎**：✅ 可以。

**核心結論：Agent 之間不直接溝通，全部透過 Artifact + Task-Master 中轉。**

原因：Claude Code 的每個 session 是獨立的，Agent A 無法直接跟 Agent B 對話。所有溝通必須透過「寫入文件 → Task-Master 讀取 → 分派給下一個 Agent → 下一個 Agent 讀取文件」。

**具體交付**：

1. **Handoff Protocol 標準格式**（每個 Agent 完成時必須寫）：

```markdown
# HANDOFF — [From Agent] → [To Agent]

**Date**: [YYYY-MM-DD HH:MM]
**Feature**: [F-XXX]
**Task**: [T-XXX]

## 完成了什麼
- [1-3 句話摘要]

## 產出的文件
| 文件 | 路徑 | 狀態 |
|------|------|------|
| [名稱] | [路徑] | Draft / In Review / Approved |

## 下一個 Agent 需要知道的事
- [關鍵假設或決策]
- [已知的風險或限制]
- [需要特別注意的地方]

## 下一個 Agent 需要做的事
1. [具體任務 1]
2. [具體任務 2]

## DRIFT（如果有）
- [有無 scope/design/test drift？]
```

2. **Handoff 寫入位置**：`memory/handoffs/[feature-id]/[from-agent]-to-[to-agent].md`

3. **Task-Master 路由邏輯**：
   - Agent 完成 → 寫 Handoff 文件 → 更新 TASKS.md
   - Task-Master 讀 TASKS.md → 看到 Task 狀態變更
   - Task-Master 讀 Handoff 文件 → 判斷下一個 Agent
   - Task-Master 更新 STATE.md → 標記新 Agent 為 active
   - 新 Agent 啟動 → 讀 STATE.md + Handoff 文件 + 相關 artifact

4. **GStack 與 Superpowers 的差異選擇**：
   - GStack 用 Conductor 跑 10-15 個並行 session，靠 artifact 共享
   - Superpowers 用 subagent + git worktree 隔離
   - **我們的選擇**：Artifact-mediated handoff（GStack 的路線），因為 Cowork / Claude Code 的 session 模型就是這樣

---

### 痛點 #10：記憶管理是否需要借鏡

**問題描述**：現在 4 個 memory 文件夠不夠？有沒有需要加的？

**V4 現狀**：STATE.md（400 token）、TASKS.md、ARTIFACTS.md、DECISIONS.md

**分析**：

| 面向 | V4 現狀 | GStack 做法 | Superpowers 做法 | 缺口 |
|------|---------|------------|-----------------|------|
| 即時狀態 | STATE.md ✅ | — | — | 無 |
| 任務追蹤 | TASKS.md ✅ | Sprint Board | Task Plan | 無（痛點 #3 的改造後更好）|
| 文件登記 | ARTIFACTS.md ✅ | — | — | 無 |
| 決策記錄 | DECISIONS.md ✅ | Design Doc | ADR | 無 |
| **教訓/模式/偏好** | ❌ 缺失 | `/learn` ✅ | — | **需要新增** |
| **交接記錄** | ❌ 缺失 | Artifact 隱式 | Subagent 隔離 | **需要新增（痛點 #9 解決）** |

**解法**：

新增第 5 個 memory 文件：**`LEARNINGS.md`**（借鏡 GStack `/learn`）

```markdown
# LEARNINGS.md — 專案學習記錄

## 技術模式（什麼方法有效）
| 日期 | 模式 | 上下文 | 效果 |
|------|------|--------|------|
| 2026-04-01 | API 用 cursor-based pagination | 大量資料查詢 | 比 offset 快 10x |

## 踩坑記錄（什麼方法無效）
| 日期 | 踩坑 | 上下文 | 正確做法 |
|------|------|--------|---------|
| 2026-04-02 | JWT 放 localStorage | Auth 實作 | 改用 httpOnly cookie |

## 凱子偏好（用戶的特定要求）
| 日期 | 偏好 | 說明 |
|------|------|------|
| 2026-04-01 | 用 composition API | Vue 3 不要用 Options API |

## 工具/環境備忘
| 日期 | 備忘 | 說明 |
|------|------|------|
| 2026-04-01 | Node 22 + pnpm | 專案標準 |
```

**Token 預算**：LEARNINGS.md ≤ 800 tokens（定期 prune，超出時移除最舊的條目）

**生命週期**：
- 每個 Agent 完成任務後，如果有新的 learning，寫入 LEARNINGS.md
- 每個 Sprint/Gate 結束時做一次 prune（`/retro` 觸發）
- Task-Master 啟動時可選讀（不是必讀，只在「之前踩過類似坑」時載入）

---

### 補充：痛點 #7 — Agent Teams 是否適合？

**我的判斷**：⚠️ Phase 1 暫不採用，Phase 2 再考慮。

**原因**：

1. **GStack 的 Conductor 模式**（10-15 並行 session）需要足夠的任務量和穩定的基礎設施。如果一個專案同時只有 2-3 個可並行的 feature，Agent Teams 的 overhead > benefit。

2. **Superpowers 的 subagent 模式**（fresh agent per task）更適合當前情況 — 已經在 V4 的 `subagent-driven-development` skill 中支援。

3. **建議的漸進路徑**：
   - Phase 1（現在）：單一 session，Task-Master 序列分派，subagent 用於特定並行場景（例如同時跑 Backend + Frontend 切片）
   - Phase 2（穩定後）：引入 Agent Teams，按 Feature 分 team，每個 team 有自己的 worktree

---

## Part C：優先級排序

| 優先級 | 痛點 | 預估投入 | 效益 |
|--------|------|---------|------|
| P0 | #8 Agent×Skill Matrix + Domain Skill | 中 | 整個框架的基礎配置 |
| P0 | #9 交接手冊 / Handoff Protocol | 中 | Agent 能正常協作的前提 |
| P0 | #7 DESIGN.md 鎖定 + 修改範圍控制 | 中 | 直接解決最常見的 AI slop |
| P1 | #2 System Design 深化 + SD Checklist | 中 | Plan Gate 品質大幅提升 |
| P1 | #5 Test Pyramid + Test Matrix | 中 | Build/Ship Gate 品質提升 |
| P1 | #1 WBS Template + Estimation Protocol | 小 | 排程可預期 |
| P1 | #3 Task Board 視覺化 | 中 | 隨時知道進度 |
| P2 | #4 SD Confirm 確認流程 | 小 | 加入 Plan Gate 即可 |
| P2 | #6 Brownfield / Hotfix Protocol | 中 | 接手舊專案時才用到 |
| P2 | #10 LEARNINGS.md | 小 | 長期累積效益 |
| Later | Agent Teams (Phase 2) | 大 | 等基礎穩定再引入 |

---

## Part D：下一步建議

如果凱子認可以上分析，建議的實作順序：

1. **先建骨架**：Agent×Skill Matrix 寫入 `project-config.yaml` schema + Handoff Protocol template
2. **鎖設計**：建立 DESIGN.md template + UX Agent 修改規則
3. **補流程**：WBS template + SD Checklist + Test Matrix template
4. **加視覺**：Task Board tab 加入 Dashboard
5. **補記憶**：LEARNINGS.md + prune 規則
6. **強化通道**：Brownfield onboarding protocol + Hotfix protocol 增強
