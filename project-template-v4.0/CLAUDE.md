# [專案名稱]

> AI-First Framework v4.0 | Mode: {{mode}}

## 專案概要

- 產品：[名稱]
- 類型：[web-app | api | mobile | library]
- 技術棧：[stack]
- 模式：[standard | lite]
- 當前階段：讀取 `memory/STATE.md`
- 配置：`project-config.yaml`

## 設計原則

| # | 原則 | 說明 |
|---|------|------|
| T1 | **Evidence over Assertion** | 所有宣稱附帶可驗證的證據，不是 checklist 打勾 |
| T2 | **Scope is Sacred** | Gate 通過後需求文件是唯一範圍基準，不擅自擴範圍 |
| T3 | **Context is Currency** | Agent 只載入當前任務需要的最小 context |
| T4 | **Fix Upstream** | 發現上游問題回上游文件修正，不在下游硬修 |
| T5 | **Process over Guessing** | 遇到問題用結構化流程解決 |

## Pipeline

```
Discover → Plan → Build → Verify → Ship
```

| 階段 | 目的 | 出口 Gate |
|------|------|-----------|
| **Discover** | 收集需求、釐清範圍、確認 MVP 邊界 | Discover Gate |
| **Plan** | 架構設計、模組邊界、API/DB/UI baseline | Plan Gate |
| **Build** | 垂直切片實作、TDD、Code Review | Build Gate |
| **Verify** | 整合測試、回歸測試、合規審查 | Ship Gate |
| **Ship** | 部署、Smoke Test、監控、Retrospective | — |

特殊通道：**Lite**（小型需求/PoC）、**Brownfield**（接手既有 code）、**Hotfix**（線上事件）

## Task-Master Dispatcher

### 分派邏輯

1. 讀 `memory/STATE.md` → 判斷 stage + current task
2. 根據 stage 判斷 Group → 根據 task 性質判斷 specialist
3. 根據 specialist 載入必載 skill（見 `project-config.yaml`）+ 依任務加載可選 skill
4. 移交給 specialist 執行

### Signal Routing

Specialist 發現問題 → 發 DRIFT_SIGNAL → Task-Master 路由：
- **scope_drift** → 退回 Discover，重過 Discover Gate
- **design_drift** → 退回 Plan，重過 Plan Gate
- **test_escalation** → 判斷是 code bug（留 Build）還是上游問題（退回）
- **blocked** → 判斷轉交或等待
- **handoff** → 執行交接協議（`context-skills/handoff-protocol/`）

### 回退規則

- 需求層問題 → 退回 Discover
- 設計層問題 → 退回 Plan
- 實作層問題 → 在 Build 內修復
- 合規層問題 → 在 Verify 內修復

### Task-Master 不做的事

不主動偵測 drift、不載入完整技術 context、不寫 code、不做設計、不做 Gate 審查

## Specialist Role Index

| Group | Specialist | Role File |
|-------|------------|-----------|
| Discovery | Interviewer/PM, UX, Architect | `context-roles/GROUP_Discovery.md` |
| Build | Backend, Frontend, DBA | `context-roles/GROUP_Build.md` |
| Verify | QA, Security, DevOps | `context-roles/GROUP_Verify.md` |
| 跨階段 | Review | `context-roles/ROLE_Review.md` |

## Skill 觸發索引

### Tier 1 — 強制（符合條件時必須載入）

| 觸發條件 | Skill |
|----------|-------|
| session 開始 / handoff | `task-master` |
| 寫任何 code | `test-driven-development` |
| 遇到 bug | `systematic-debugging` |
| 完成任務前 | `verification-before-completion` |
| 探索想法 | `brainstorming` |
| 開始實作計畫 | `planning-with-tasks` |
| 提交 review | `requesting-code-review` |
| 開 feature branch | `using-git-worktrees` |
| 過 Gate | `gate-check` |
| 改既有 code | `ground` |
| Agent 交接 | `handoff-protocol` |
| 修改 Baselined 文件 | `cia` |

### Tier 2 — 按需（依 project-config.yaml）

見 `project-config.yaml` → `tier2_skills`

## Quality Gates

| Gate | 位於 | 必須滿足 |
|------|------|----------|
| **Discover Gate** | Discover → Plan | SRS 完整、AC 可測試、WBS 已拆、MVP 邊界確認 |
| **Plan Gate** | Plan → Build | SD Checklist 7 項全過、Design Baseline locked、Test Matrix 存在、**Tech Spec 已確認** |
| **Build Gate** | Build → Verify | 所有 Slice 完成、L1+L2 test 達標、無 scope drift、Code Review 通過 |
| **Ship Gate** | Verify → Ship | L3+L4+L5 test 達標、合規審查完成、Rollback plan 準備好 |

Gate 失敗 → 列具體未達標項（附證據）→ 判斷問題層 → 退回修正（T4）→ 重過 Gate

## 記憶體

| 用途 | 檔案 | Token 上限 |
|------|------|-----------|
| 現在在哪 | `memory/STATE.md` | 400 |
| 要做什麼 | `TASKS.md` | — |
| 正式產出 | `memory/ARTIFACTS.md` | — |
| 為什麼這樣做 | `memory/DECISIONS.md` | — |
| 教訓與偏好 | `memory/LEARNINGS.md` | 800 |
| 技術規格 | `02_Specifications/TS_F[XX]_*.md` | — |
| 設計系統 | `DESIGN.md` | — |

## Token Budget

| 檔案 | 上限 |
|------|------|
| CLAUDE.md | ≤ 5K tokens |
| task-master SKILL.md | ≤ 2K tokens |
| GROUP_*.md (each) | ≤ 2K tokens |
| ROLE_Review.md | ≤ 1K tokens |
| STATE.md | ≤ 400 tokens |
| LEARNINGS.md | ≤ 800 tokens |

## ⚠️ 範圍鎖定規則（Scope Baseline）

**Scope Baseline 文件（專案初始化時指定，不可擴張）：**
- 需求確認書（REQ_CONFIRM / SRS）
- Product Prototype（UI 原型）

**強制規則：**
1. RS/SSD/Code 的每一段必須追溯到 Scope Baseline 中的功能編號
2. 如果某個需求在 Scope Baseline 中找不到出處 → 發 DRIFT_SIGNAL → 等用戶批准才能加入
3. Prototype 定義的畫面佈局、元件位置、互動行為 = UI 基準，不可自行重新設計
4. 禁止以「業界最佳實踐」為由自動擴張範圍，對標結果必須先呈報再決定是否採納

## ⚠️ 垂直切片實作規則（Vertical Slice）

**一次只做一個 Feature，做完驗收再做下一個。**

- 切片順序依 Scope Baseline 的功能編號，於 Plan Gate 時確定
- 每個切片交付流程：`寫 RS（追溯 REQ）→ 用戶確認 RS → 寫 Tech Spec → 用戶確認 Tech Spec → Build 實作 → 用戶驗收畫面與行為 → ✅ 下一個 Feature`
- 禁止同時開工 2 個以上的 Feature（除非用戶明確批准並行）
- 禁止跨 Feature 汙染（在 F-A 的 RS 裡加入 F-B 的需求）
- 每個 Feature 完成後必須在 TASKS.md 記錄驗收結果

### 流水線重疊（Pipeline Overlap）

Feature 之間允許階段重疊以提升效率：
```
F01: [Discover] [Plan] [====Build====] [Verify]
F02:                   [Discover] [Plan] [====Build====] [Verify]
F03:                                     [Discover] [Plan] [Build]...
```

**規則：**
- 當 F(N) 進入 Build 後，用戶可啟動 F(N+1) 的 Discover
- **單人模式：禁止同時有 2 個 Feature 在 Build 階段**
- Discover / Plan 是文件層工作，可與其他 Feature 的 Build 並行
- 每個 Feature 的 Gate 仍然獨立驗證，不因並行而降低標準

### 多人協作模式（Dual-Track / Multi-Track）

當多人協作時，按 Feature 依賴關係分為多條 Track，每人負責一條：

```
Track-A: F[x] → F[y] → ...（一條依賴鏈）
Track-B: F[m] → F[n] → ...（另一條依賴鏈）
```

**協作規則：**
- 每條 Track 內部維持垂直切片（一次一個 Feature）
- **跨 Track 可同時各有 1 個 Feature 在 Build**（改的 Code 範圍不同）
- Git 分支策略：每個 Feature 開 `track-[x]/f[XX]` 分支，完成後 merge 回 main
- **Integration Gate**：跨 Track 有依賴的 Feature 完成後，需做整合驗證
- **Interface Contract**：跨 Track 依賴的 API/Schema 在 Tech Spec 中預先約定，修改走 CIA
- 禁止直推 main，所有變更透過 Feature Branch → merge

## ⚠️ 技術規格書規則（Tech Spec）

**每個 Feature 在 Plan 階段必須產出 Tech Spec，Baselined 後作為 Build 的技術基準。**

- 模板：`02_Specifications/TEMPLATE_Tech_Spec.md`
- 命名：`TS_F[XX]_[名稱]_v[X.X].md`
- 時機：Plan 階段，RS 確認後、進入 Build 前產出
- 狀態：Tech Spec 需用戶確認後 Baseline，與 RS 同等權威
- 內容涵蓋：API Contract、Data Model、前端架構、共用元件依賴、技術決策
- **共用元件繼承**：新 Feature 的 Tech Spec 必須讀取所有已 Baselined 的 Tech Spec，標註依賴與共用元件
- **修改已有 Tech Spec**：走 CIA 流程（影響所有依賴方 Feature）

### Plan Gate 新增出口標準
- Tech Spec 已完成且用戶確認
- Tech Spec 中的 API / Schema / 共用元件與既有 Feature 的 Tech Spec 不衝突
- Tech Spec 的每個技術項目都能追溯到 REQ 功能編號

## 關鍵規則速查

1. **Scope Baseline**: REQ_CONFIRM + Prototype = 唯一範圍基準，超出必須 DRIFT_SIGNAL
2. **Vertical Slice**: 一次一個 Feature，做完驗收再做下一個（允許流水線重疊）
3. **Tech Spec**: 每個 Feature 必須在 Plan 階段產出技術規格書，Baselined 後為 Build 的技術基準
4. **Handoff Protocol**: Agent 之間不直接溝通，全部透過 Artifact + Task-Master 中轉 → `context-skills/handoff-protocol/`
5. **CIA**: 修改 Baselined 文件（含 Tech Spec）必須走 Change Impact Assessment → `context-skills/cia/`
6. **DESIGN.md 鎖定**: Design Token 修改分 4 級（Free/Review/CIA/禁止）
7. **Bug Fix = Regression Test**: 任何 bug fix 必須附帶自動化 regression test
8. **XL Task 拆分**: 估算 > 4hr 的 Task 強制拆成多個 M 或 S
9. **Context > 60%**: 自動將狀態寫入 STATE.md，確保下一個 session 可接續
