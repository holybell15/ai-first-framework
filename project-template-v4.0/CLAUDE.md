# [專案名稱]

> AI-First Framework v4.1 | Mode: {{mode}}

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
| **TDD GREEN 失敗** | **`self-healing-build`（v4.1 — 自動修復迴圈）** |
| 遇到 bug | `systematic-debugging` |
| 完成任務前 | `verification-before-completion` |
| 探索想法 | `brainstorming` |
| 開始實作計畫 | `planning-with-tasks` |
| 提交 review | `requesting-code-review` |
| 開 feature branch | `using-git-worktrees` |
| 過 Gate | `gate-check`（v4.1 — **三級分類 L1/L2/L3**） |
| Feature 進入 Build | `ground`（Mode A: Build Grounding） |
| **Build 前查已有 pattern** | **`pattern-library`（v4.1 — 已驗證模式複用）** |
| 改既有 code | `ground`（Mode B: Code Grounding） |
| Agent 交接 | `handoff-protocol` |
| 修改 Baselined 文件 | `cia` |
| 串接外部 SDK/API/WS | `external-integration` |
| **Build Gate 前** | **`validate-contract`（v4.1 — 升級為 Tier 1，Contract 雙向驗證）** |
| **拆 Feature 為 BE/FE 並行** | **`concurrent-build`（v4.1 — Specialist 並行協調）** |

### Tier 2 — 按需（依 project-config.yaml）

見 `project-config.yaml` → `tier2_skills`

## Quality Gates

| Gate | 位於 | 必須滿足 |
|------|------|----------|
| **Discover Gate** | Discover → Plan | SRS 完整、AC 可測試、WBS 已拆、MVP 邊界確認 |
| **Plan Gate** | Plan → Build | SD Checklist 7 項全過、Design Baseline locked、Test Matrix 存在、**Tech Spec 已確認**、**外部系統串接有介面契約摘要** |
| **Build Gate** | Build → Verify | 所有 Slice 完成、L1+L2 test 達標、無 scope drift、Code Review 通過、**Contract 雙向驗證**、**Mock/Real 標記達標**、**Config 環境驗證** |
| **Ship Gate** | Verify → Ship | L3+L4+L5 test 達標、合規審查完成、Rollback plan 準備好 |
| **Smoke Test** | Merge 後 | **部署到目標環境 + Health Check + 每個 endpoint 打真實 request + Console 無 error**（v4.1） |

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

### 多人/多 Agent 協作模式（Dual-Track / Multi-Track）

當多人或多個 sub-agent 協作時，按 Feature 依賴關係分為多條 Track：

```
Track-A: F[x] → F[y] → ...（一條依賴鏈）
Track-B: F[m] → F[n] → ...（另一條依賴鏈）
```

**協作規則：**
- 每條 Track 內部維持垂直切片（一次一個 Feature）
- **跨 Track 可同時各有 1 個 Feature 在 Build**（改的 Code 範圍不同）
- **Integration Gate**：跨 Track 有依賴的 Feature 完成後，需做整合驗證
- **Interface Contract**：跨 Track 依賴的 API/Schema 在 Tech Spec 中預先約定，修改走 CIA
- 禁止直推 main，所有變更透過 Feature Branch → merge

### 並行 Build 必須用 Worktree 隔離（強制）

**多個 Feature 同時 Build 時，每個 Feature 必須在獨立的 git worktree 中開發。**

原因：Hook 強制執行機制（`.tests-dirty`、`.gates/`、`.findings-counter`）是目錄級的。
如果兩個 agent 共用同一目錄，一個 agent 的 dirty flag 會擋住另一個 agent。

```bash
# 建立 worktree（每個 Feature 一個）
bash scripts/parallel-feature.sh start F02
bash scripts/parallel-feature.sh start F03
```

```
main/                              ← 不直接開發，只做 merge
├── .worktrees/f02/               ← Agent A 的工作目錄
│   ├── .gates/F02/.enabled        ← 只有 F02 的 gate
│   ├── .tests-dirty               ← 只影響 F02
│   └── src/...
└── .worktrees/f03/               ← Agent B 的工作目錄
    ├── .gates/F03/.enabled        ← 只有 F03 的 gate
    ├── .tests-dirty               ← 只影響 F03
    └── src/...
```

**Worktree 隔離帶來的效果：**
- `.tests-dirty` — 各自獨立，互不干擾
- `.gates/` — 各自獨立，gate 狀態不互相卡死
- `.findings-counter` — 各自獨立，提醒頻率正確
- `.plan-history/` — 各自獨立，plan 備份不混亂
- Hook scripts — 從 main 複製到 worktree，行為一致

**完成後的 merge 流程：**
```bash
bash scripts/parallel-feature.sh merge F02
bash scripts/parallel-feature.sh merge F03
```

**單人單 Feature 開發不需要 worktree**（直接在 main 目錄工作即可）。

### Specialist 並行：同一 Feature 內 Backend ∥ Frontend（v4.1）

Tech Spec 確認後，一個 Feature 可拆為 Backend 和 Frontend 兩個 Agent 同時開發。

```bash
# 拆為兩個 specialist worktree
bash scripts/parallel-feature.sh split F03

# 產出：
# .worktrees/f03-be/     ← Backend Agent（Terminal 1）
# .worktrees/f03-fe/     ← Frontend Agent（Terminal 2）
# .coordination/f03/     ← Signal Bus + Ownership + Sync Points
```

**啟動條件**（全部滿足）：
1. Tech Spec 已 Baselined（含 §2.3 Executable Contract）
2. API Contract 每個 endpoint 的 request/response 都定義了
3. DB Schema 已確認
4. 共用型別已定義

**協調機制**：
- **File Ownership**：`.coordination/f03/ownership.yaml` 定義誰能寫哪些目錄
- **Signal Bus**：`.coordination/f03/signals.jsonl` — `ENDPOINT_READY` / `BLOCKED` / `CONTRACT_CHANGE`
- **Sync Points**：`.coordination/f03/sync-points.yaml` — 哪些 endpoint 已可串接

**Merge 順序**：永遠 Backend 先 merge → Frontend 再 merge → 整合測試
```bash
bash scripts/parallel-feature.sh merge-specialist F03 backend
bash scripts/parallel-feature.sh merge-specialist F03 frontend
```

**Frontend 不等 Backend 的策略**：Phase 1 靜態 UI（40%）→ Phase 2 Mock API（30%）→ Phase 3 真實串接（30%）

### 跨 Feature 依賴協調（v4.1）

多 Feature 同時推進時，依賴追蹤和共享資源管理：
- **依賴圖**：`.coordination/cross-feature/dependency-map.yaml`
- **共享資源衝突**：`.coordination/cross-feature/shared-resources.yaml`
- **Integration Checkpoint**：每 3 個 Feature merge 後強制跨 Feature 整合測試

詳見 `context-skills/concurrent-build/SKILL.md`。

### 併發上限（安全閥）

| 限制 | 值 |
|------|---|
| 同時 Build 的 Feature | ≤ 3 |
| 每個 Feature 的 Specialist worktree | ≤ 2（BE + FE） |
| CONTRACT_CHANGE signal | 立即停工，雙方暫停 → CIA |
| 連續 3 個 Feature merge 後 | 強制 Cross-Feature Integration Test |

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

## Autonomous Build 機制（v4.1）

> 目標：降低 Build 階段的人工介入頻率，從「每次失敗都需要人」變成「只有頑固問題需要人」。

### Self-Healing Build Loop

TDD GREEN 失敗時自動觸發 `self-healing-build` skill：
1. **Attempt 1 (Quick Fix)** — 比對 Known Bug Pattern，自動修復 typo/import/型別
2. **Attempt 2 (Root Cause)** — 觸發 systematic-debugging，找根因修復
3. **Attempt 3 (Alternative)** — 換實作策略或檢查測試本身
4. **Escalate** — 3 次都失敗才升級給人，附完整報告

記錄：`healing-log.md` | 設定：`project-config.yaml → self_healing`

### Gate 三級分類

| 級別 | 條件 | 人工介入 |
|------|------|---------|
| **L1 Auto-Pass** | 測試全綠 + 無 drift + diff < 200 行 | 不需要（通知人） |
| **L2 Review-Pass** | 測試全綠 + 有架構/共用元件變更 | 看摘要確認 |
| **L3 Full-Gate** | 測試失敗 / drift / 外部串接 / 合規 | 完整 Review |

Gate 1 和 Gate 2 永遠 L3。G4-ENG-R 和 Build Gate 可依條件降級。設定：`project-config.yaml → gate_policy`

### Executable Contract（Tech Spec 增強）

Tech Spec 新增：
- **§2.3 OpenAPI Snippet** — 關鍵 endpoint 的 schema contract，AI 從 contract 生成 code
- **§9.1 Executable AC (Given/When/Then)** — AC 直接對應 test case
- **§9.2 Testability Mapping** — UI 元素 ↔ data-testid 對應表

### Code Pattern Library

`verified-patterns/` — 已通過測試的可複用 code 片段。Build 前查詢、Build 後回饋。
管理 skill：`pattern-library` | 索引：`verified-patterns/README.md`

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
10. **架構遷移原子化**: 改變通訊層、事件來源、元件職責分界等架構級變更，必須在同一個 Feature/Task 內完成。禁止「先改一半，之後再補」——半成品架構比舊架構更危險。未完成的遷移必須 revert 到上一個一致狀態
11. **事後架構驗證**: 架構變更完成後，必須驗證 claimed state = actual state。具體做法：(1) code 註解描述的行為必須與 code 實際行為一致 (2) 測試的 mock 假設必須與 production code path 一致 (3) 不一致 = Build Gate 失敗
12. **Integration Test = Production Path**: 整合測試必須走 production code path。如果測試中 mock 了 `X.register()`，production 也必須呼叫 `X.register()`。測試綠但 production 不呼叫 = 測試無效，視同未測試
13. **Build Grounding**: Feature 進入 Build 前，必須實際讀取 RS + Prototype + Tech Spec（用 Read 工具，不是靠記憶），產出 Build Checklist 並用戶確認。**禁止靠記憶描述 UI** — 必須讀 Prototype HTML 檔案後描述看到的佈局和元件。由 `gate-checkpoint.sh` + `.gates/<feature>/build-grounded.confirmed` 強制執行
14. **Mock ≠ Real**（v4.1）: 每個測試必須標記 `@mock` 或 `@real`。每個 API endpoint 至少 1 個 `@real` integration test。全部只有 `@mock` = Build Gate BLOCK。Mock 全綠不代表功能正常
15. **Contract 雙向驗證**（v4.1）: 前端定義的 API endpoint 後端必須有 Controller；後端新增的 endpoint 前端必須有呼叫。Build Gate 前強制執行 `validate-contract`
16. **Merge 後 Smoke Test**（v4.1）: Feature merge 後必須部署到目標環境，Backend health check + 每個新 endpoint 打一次真實 request + 前端 console 無 error。未通過不能標記 Feature Done
17. **Config 必須有保護**（v4.1）: 外部系統 Config（DataSource / Redis / MQ）必須用 `@ConditionalOnProperty` 保護。無條件載入的外部 Config = Build Gate BLOCK

## ⚠️ Hook 強制執行機制

**紀律不靠 AI 自覺，靠系統攔截。** 配置見 `.claude/settings.json`。

### Hook 清單

| Hook | 類型 | 用途 |
|------|------|------|
| `plan-backup.sh` | PreToolUse | 覆寫 TASKS.md / task_plan.md / findings.md / progress.md 前自動備份到 `.plan-history/` |
| `gate-checkpoint.sh` | PreToolUse | **硬攔截**：Gate checkpoint 不存在時阻擋（Build Grounding / Integration / **Debug Grounding**） |
| `test-before-continue.sh` | PreToolUse | **硬攔截**：測試未跑 → 不能繼續改 code / 標記完成 |
| `freeze-hook.sh` | PreToolUse | Freeze Mode 目錄鎖定 |
| `destructive-guard-hook.sh` | PreToolUse | 攔截破壞性指令（rm -rf / DROP / force push） |
| `test-on-change.sh` | PostToolUse | production code 變更 → 標記 dirty；測試失敗 → 標記 `.healing-required`；測試通過 → 清除 |
| `auto-state-update.sh` | PostToolUse | Pipeline 產出物寫入後更新 STATE.md 時間戳 |
| `findings-reminder.sh` | PostToolUse | 每 10 次有意義操作提醒更新 findings.md |

### Dirty Flag 測試強制機制（硬攔截）

改了 production code 就**必須**跑測試，不跑就不能繼續。

```
改 code → .tests-dirty 建立 → 想再改 code → ⛔ 阻擋「先跑測試」
                              → 跑測試通過 → .tests-dirty 清除 → ✅ 可以繼續
                              → 跑測試失敗 → .healing-required 建立（v4.1）
                                             → 想再改 code → ⛔ 阻擋「先走 Self-Healing」
                                             → Self-Healing 修復 → 跑測試通過 → 清除 → ✅
                                             → 3 次都失敗 → ⛔ 阻擋「產出 Escalation Report」

改前端  → .playwright-required 建立 → 想標記完成 → ⛔ 阻擋「先跑 Playwright」
                                    → 跑 Playwright 通過 → 清除 → ✅ 可以完成
```

**手動清除**（僅在 hook 誤判時使用）：`rm .tests-dirty .playwright-required .healing-required`

### Pattern Check Gate + Contract Gate（v4.1 硬攔截）

Build Grounding 通過後、寫 code 前，必須查 Pattern Library 和定義 API Contract。

```
Build Grounding ✅ → 想寫 code → ⛔「先查 Pattern Library」
  → pattern-checked.confirmed ✅ → 想寫 code → ⛔「先定義 API Contract YAML」
  → contract-defined.confirmed ✅ → 可以寫 code
```

Gate 鏈（新 Feature）：`build-grounded → pattern-checked → contract-defined → 可以寫 code`

### Debug Grounding Gate（v4.1 硬攔截 — Hotfix / Bug Fix）

Bug fix 修 code 前，必須先收集證據 + 讀 Prototype。

```bash
# 建立 debug gate
mkdir -p .gates/HOTFIX-xxx && touch .gates/HOTFIX-xxx/.enabled .gates/HOTFIX-xxx/.debug
# UI 問題額外加
touch .gates/HOTFIX-xxx/.ui-bug
```

```
想修 bug → ⛔「先 SSH 看 log + 收集證據」→ debug-evidence.confirmed
  → UI 問題 → ⛔「先讀 Prototype 逐行比對」→ debug-prototype.confirmed
  → 可以改 code → 改完 → .deploy-verify-required 自動建立
  → 想再改 code → ⛔「先自己部署 + SSH 驗證 + curl API」
  → 驗證通過 → .deploy-verify-required 自動清除 → 繼續下一個修復
```

### Gate Checkpoint 機制（硬攔截）

兩種模式，依 Feature 性質選擇：

```bash
# ── 模式 A：一般 Feature（Build Grounding）──
mkdir -p .gates/F03 && touch .gates/F03/.enabled

# 讀完 RS + Prototype + Tech Spec → Build Checklist → 用戶確認後
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F03/build-grounded.confirmed

# ── 模式 B：外部系統串接 Feature ──
mkdir -p .gates/F02 && touch .gates/F02/.enabled .gates/F02/.integration

# Gate 0: 讀 Spec + 介面契約摘要 → 用戶確認後
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F02/gate0-spec.confirmed

# Gate 1: 架構設計確認 → 用戶確認後
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F02/gate1-arch.confirmed

# Gate 2: Contract Test 全綠後
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F02/gate2-contract.confirmed
```

**效果：** checkpoint 不存在 → AI 物理上無法寫入 `src/` 下的 production code。

### Plan History（自動備份）

每次 TASKS.md / task_plan.md 被覆寫前，舊版自動備份到 `.plan-history/`。
commit / PR 產出時**必須**先讀 `.plan-history/INDEX.md` 回溯完整脈絡。
