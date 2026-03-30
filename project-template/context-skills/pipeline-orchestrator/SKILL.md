---
name: pipeline-orchestrator
description: >
  **Use this skill whenever you're ready to start a multi-Agent Pipeline or continue a partially-completed one.**

  Triggered by: "我要開始做需求", "來做技術設計", "繼續 P04", "我想執行需求訪談", "開始下一個 pipeline",
  "執行 Pipeline: 技術設計", "Pipeline: 開發準備", or when transitioning between phases (P01 → P02 → P03, etc.).
  Also triggered by: "使用 Lite Mode 啟動 F01", "先走 Lite Mode", "用最小流程開始", "第一個 feature 先簡化跑".

  This skill orchestrates multi-step Pipelines (Interviewer → PM → UX → Architect → DBA, etc.), manages Agent handoffs,
  tracks state across sessions, and prevents context loss between phases.

source: levnikolaevich/claude-code-skills (adapted for workflow_rules §38-41)
---

# Pipeline Orchestrator Skill

## 啟動前 — CIC Grounding
```markdown
## CIC Grounding Declaration
讀取的上游文件:
- [ ] [文件1] — 摘要: [1句]
- [ ] [文件2] — 摘要: [1句]
繼承決策: [ADR-XXX 摘要]
本 Pipeline 目標: 輸入 → 輸出 → Agent 順序
```

## Lite Mode Routing

當使用者明確提到 `Lite Mode`，或符合以下條件時，優先建議 Lite Mode：

- 第一次使用框架
- 目前只有 1-2 人推進
- 正在做第一個 feature
- 功能沒有高風險外部依賴或嚴格合規要求

### Lite Mode 啟動格式

```
讀取 CLAUDE.md，使用 Lite Mode 啟動 F01
```

### Orchestrator 在 Lite Mode 中的責任

1. 讀取 `docs/LITE_MODE.md`
2. 確認最小必備文件是否存在
3. 引導使用者先完成：
   - F-code 登記
   - 最小需求文件
   - 最小設計文件
   - 最小測試與 Lite Review
4. 若複雜度升高，明確建議升級回完整 Pipeline

### 升級回完整模式的觸發條件

- 第二個以上 feature 開始並行
- 需要正式 Gate
- 出現外部依賴或高整合風險
- 涉及資料模型、架構邊界或上線合規

## Autopilot 自動駕駛模式（v2.8 核心升級）

> 目標：人只在「品味決策」和「Gate BLOCK」時介入，其餘全自動。

### 三種執行模式

| 模式 | 說明 | 人工介入頻率 |
|------|------|------------|
| **Autopilot** | Agent DONE → 自動續行下一個 Agent，不問人 | 只在 BLOCKED / 品味決策 / Gate 真人審核項 |
| **Copilot** | Agent DONE → 顯示摘要 + 「繼續？」，等確認 | 每個 Agent 結束時 |
| **Manual** | 每步都等指令 | 每個操作都等 |

**模式選擇規則**：
```
Solo Mode（1-2 人）→ 預設 Autopilot
Team Mode（3+ 人）→ 預設 Copilot
首次使用框架      → 預設 Copilot（讓人觀察流程）
```

切換指令：`切換 Autopilot` / `切換 Copilot` / `切換 Manual`

### Autopilot 自動續行規則

```
Agent 完成 → 檢查 Completion Status：

  ✅ DONE
    → Type 2 決策（可逆）？ → 自動續行下一個 Agent
    → Type 1 決策（不可逆）？ → AskUserQuestion 確認後續行

  ⚠️ DONE_WITH_CONCERNS
    → 記錄 concerns → 自動續行（Gate 時會審查 concerns）

  🔴 BLOCKED
    → 停止 → 顯示 BLOCKED 報告 → 等人工介入

  ❓ NEEDS_CONTEXT
    → 停止 → AskUserQuestion 格式提問 → 收到回答後自動續行
```

### Gate 自動 Dispatch

**Solo Mode**：Gate Review 不需要開新 session，用 subagent 在同 session 執行：
```
Pipeline 最後一個 Agent DONE
  → 自動 spawn Review subagent（獨立 context）
  → Review subagent 讀取 quality-gates + 產出文件
  → 產出 Gate Report
  → PASS → 自動觸發下一個 Pipeline
  → BLOCK → 停止，顯示 BLOCK 項目
```

**Team Mode**：維持「開新 session」規則（§31.7），但自動生成可複製的啟動指令：
```
✅ P01 完成。Gate 1 Review 需要獨立 session。

複製以下指令到新終端機：
────────────────────────
你是 Review Agent。請讀取 CLAUDE.md，
然後執行 Gate 1 驗收。範圍：F02 來電彈屏。
────────────────────────

Gate 通過後回到此 session 說「Gate 1 通過」即可自動繼續 P02。
```

### Pipeline 串聯自動觸發

```
Gate 1 PASS → 自動：Plan Challenge PC-S01~05 → 觸發 P02
Gate 2 PASS → 自動：觸發 P03
G4-ENG PASS → 自動：Freeze Mode + 觸發 P04
Gate 3 PASS → 自動：觸發 P05
P05 DONE → 自動：觸發 P06
P06 smoke → 自動：info-canary → info-doc-sync → retro L2
```

**用戶只需要說一句話**：「做 F02 來電彈屏」
→ Orchestrator 自動偵測需要哪個 Pipeline → 開始 → 串聯到底

### 意圖偵測（Smart Routing）

用戶說的話 → Orchestrator 自動判斷執行什麼：

| 用戶意圖 | 偵測方式 | 自動執行 |
|---------|---------|---------|
| 「使用 Lite Mode 啟動 F01」 | 明確提到 Lite Mode | 讀取 `docs/LITE_MODE.md`，以最小流程引導開始 |
| 「做 F02 來電彈屏」 | F02 無 RS → 需要 P01 | 觸發 P01，從 Interviewer 開始 |
| 「繼續 F02」 | 讀 STATE.md，F02 停在 P02 | 從 P02 的下一個 Agent 繼續 |
| 「F02 上線」 | F02 有 Gate 3 PASS | 觸發 P05 → P06 |
| 「F02 有 bug」 | 問嚴重度 | Critical/High → Hotfix；Medium/Low → 排入 Sprint |
| 「開始新功能 F03」 | F03 不存在 | 登記 F-code + 觸發 P01 |

## Agent 交接
每個 Agent 完成後寫入 TASKS.md:
```
| [ID] | [Agent] 完成 | [Agent] | 完成 | 交接: [下一Agent] 需知→ [摘要] |
```

**Autopilot 模式**：不顯示「繼續嗎？」，直接續行 + 一行摘要：
```
✅ Interviewer → PM（自動續行）| 產出：RFP Brief + IR | 下一步：PM 寫 RS
```

**Copilot 模式**：
```
✅ Interviewer 完成。
交接：產出 RFP Brief + IR → PM 需要寫 RS
繼續？（Y / 停 / 切換 Autopilot）
```

## 防幻覺
每個 Agent 結束前報告:
```
目前理解確認:
1. [需求是...]
2. [輸出包含...]
3. [下一步是...]
以上正確嗎？
```

## Pipeline 對照表

| Pipeline | Agent 順序 | Gate |
|---------|-----------|------|
| Lite Mode | Task-Master → 最小需求 → 最小設計 → 實作/驗證 → Lite Review | Lite Review |
| P00 需求建立 | aicc-interviewer → aicc-pm（SRS + 確認書簽核） | C0 → C1 → C2 |
| P01 精煉+Prototype | aicc-pm 精修 AC → aicc-ux Prototype | Gate 1 |
| P02 技術設計 | Wave 1: aicc-architect ∥ aicc-dba → aicc-review（Slice Backlog） | Gate 2 |
| P03+P04 Slice Cycle | Wave 1: aicc-backend ∥ aicc-frontend → aicc-qa → aicc-review（每 slice 循環） | G4-ENG-D + G4-ENG-R |
| Gate 3 | 所有 slice 完成後的總審查 | Gate 3 |
| P05 合規審查 | aicc-security → aicc-review | — |
| P06 部署上線 | aicc-devops → aicc-review | L2 |

### Slice Cycle 自動化

Gate 2 通過後，Orchestrator 自動進入 Slice Cycle 模式：

```
Gate 2 PASS
  ↓ 讀取 P02 Slice Backlog
  ↓ 依序選擇 Slice（按依賴順序）
  ↓
  ┌─ Slice [N] ────────────────────────┐
  │ Step 1: Feature Pack → 確認範圍     │
  │ Step 2: Design → ⛔ 不寫 code      │
  │ Step 3: G4-ENG-D → 設計審查         │
  │ Step 4: Code → 只做本 slice         │
  │ Step 5: G4-ENG-R → 實作後審查       │
  │ Step 6: Stabilization → 能跑        │
  │ Step 7: Hardening → 可靠 + 基線判定  │
  └────────────────────────────────────┘
  ↓ 基線通過 → 下一個 Slice
  ↓ Cross-Slice Integration Check（第 3 個骨幹 slice 後 + 每 2 slice）
  ↓ 所有 Slice 完成
Gate 3
```

**Autopilot 在 Slice Cycle 中的行為**：
- Step 1~2（Feature Pack + Design）：Copilot 模式（每步確認，因為設計需要判斷）
- Step 3（G4-ENG-D）：自動 dispatch Review subagent
- Step 4（Code）：Autopilot（DONE 自動續行）
- Step 5（G4-ENG-R）：自動 dispatch Review subagent（產出 12 項正式報告）
- Step 6~7（Stabilize + Harden）：Autopilot（自動修復 + 自動判定）
- Cross-Slice：自動觸發，FAIL 時停止

**基線紀律強制執行**：
- Step 7 Hardening 未通過 → **禁止**進入下一個 Slice（Orchestrator 強制攔截）
- 骨幹 Slice 未成為基線 → 其依賴的業務 Slice 不可啟動
- 可編譯/可啟動 ≠ 基線通過 — 必須完成完整的 G4-ENG-R → Stabilization → Hardening

**Wave 模式協調**：
```
Feature Pack 發現外部依賴
  → 檢查 Slice 分類標籤（🔗🧩📞）
  → 自動建議進入 Wave 模式
  ↓
Wave 1: Design 不受阻塞的 deliverables
  → G4-ENG-D（Wave 1 範圍）
  → 產出 Fixed vs Placeholder 清單
  → 產出 Vendor Confirmation 文件
  → ⏸️ 等待外部回覆
  ↓
外部依賴解除
  → Wave 2: 定稿受阻塞的 deliverables
  → G4-ENG-D（完整範圍）
  → 正常進入 Step 4 Code
```

**Vendor Confirmation 自動觸發**：
- Wave 1 完成後自動提示：「Wave 1 完成。請產出 Vendor Confirmation 文件（完整版 + 會議版精簡確認單）」
- 廠商回覆後自動提示：「外部依賴已解除。建議啟動 Wave 2 設計。」

## 自動觸發規則（Auto-Triggers）

| 時機 | 自動觸發 |
|------|---------|
| **任何 Pipeline 啟動時** | **planning-with-files（建立 task_plan.md / findings.md / progress.md）** |
| 任何 Agent 修改程式碼前 | code-grounder（ground skill） |
| 新增欄位 / API 異動後 | data-contract-validator（validate-contract skill） |
| 文件內容有重複疑慮時 | ssot-guardian |
| Pipeline 完成後 | gate-reviewer（quality-gates skill） |
| Gate 通過後 | retrospective-facilitator（retro skill） |

## Brownfield Pipeline（舊專案引入）

觸發詞: "Brownfield", "舊專案", "brownfield", "引入現有專案", "既有系統", "legacy"

| 步驟 | Agent | 說明 |
|------|-------|------|
| 1. 架構盤點 | aicc-architect | 掃描現有架構，產出 codebase_snapshot.md |
| 2. DB 反推 Schema | aicc-dba | 從現有 DB 反推 Schema，建立 field_registry |
| 3. 規格補齊 | aicc-pm | 補齊 RS / US / AC |
| 4. 合規審查 | aicc-review | 確認現有實作符合框架規範 |
| 5. 部署標準化 | aicc-devops | 建立 CI/CD 和部署文件 |

## 錯誤處理
| 情境 | 處理 |
|------|------|
| Lite Mode 不再適用 | 升級到完整 Pipeline，並指出下一個 Gate / Agent |
| 模糊需求 | 暫停，觸發 brainstorming |
| 產出不合格 | 退回，觸發 verification |
| Gate 不通過 | 退回對應 Pipeline |
| 需要並行 | 觸發 subagent-driven-development |
| Agent 報告 BLOCKED | 顯示 BLOCKED 報告，升級到指定 Agent 或人工 |
| Agent 報告 NEEDS_CONTEXT | 用 AskUserQuestion 標準格式向用戶提問 |

## Completion Status 整合
每個 Agent 交接時，Orchestrator **必須**：
1. 確認交接摘要包含 Completion Status（DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT）
2. BLOCKED → 停止 Pipeline，顯示升級報告
3. DONE_WITH_CONCERNS → 繼續但在 Gate Review 時必須審查 concerns
4. NEEDS_CONTEXT → 用 AskUserQuestion 格式提問

## Dashboard 自動更新
Agent 完成 → pipelineLog 新增 + inProgress 更新 + documents 新增
Pipeline 完成 → pipelineCompletion = done
Gate 通過 → gateStatus = done

## Pipeline 結束自動觸發（Auto-Triggers）

> 靈感來源：gstack /ship + /land-and-deploy + /document-release — 在 Pipeline 里程碑自動觸發下游 skill。

| 里程碑 | 自動觸發 | 說明 |
|--------|---------|------|
| P01 PM 寫 US 前 | `forced-thinking` RT-01~07 | 自動提示讀取需求思考 7 問 |
| P01→P02 銜接 | `forced-thinking` PC-S01~05 | 自動提示讀取 Plan Challenge 5 問 |
| P02 Architect 設計前 | `forced-thinking` DT-01~08 | 自動提示讀取設計思考 8 問 |
| P04 開始 | Freeze Mode | 自動寫入 `.claude-freeze-scope`，鎖定到 Feature 對應目錄 |
| P04 每次 commit 前 | `forced-thinking` PC-01~06 | 自動提示讀取提交前檢查 6 問 |
| P04 QA 完成 | `/info-ship` | 一鍵 Pre-Merge：test→review→version→CHANGELOG→PR |
| Gate 3 通過 | Review Staleness Check | 確認 review 未過期（< 7 天 且 < 4 code commit） |
| P05 完成 | — | 正常流轉 P06 |
| P06 smoke 通過 | `/info-canary` | 部署後持續監控 10 分鐘（baseline 對比） |
| P06 canary 通過 | `/info-doc-sync` | 自動掃描並同步過時文件 |
| P06 doc-sync 完成 | `/retro`（L2 量化回顧） | 自動執行 git 統計 + 8 大指標 + friction log 彙整 |
| Hotfix 部署後 | `/info-canary`（5 min） | 縮短版 canary 監控 |
| Hotfix Step 4 | `/info-doc-sync` | 48hr 補件自動觸發文件同步 |
| 每個 Agent 交接 | Analytics 記錄 | 自動追加到 `memory/analytics.jsonl` |

Orchestrator 在對應里程碑時主動提示：
```
✅ P04 QA 完成。
自動觸發：/info-ship（一鍵 Pre-Merge）
執行嗎？（繼續 / 跳過手動處理）
```

---

## Repo Ownership Mode（Solo / Team 自動適配）

> 靈感來源：gstack repo ownership mode — solo 模式簡化儀式，team 模式完整流程。

### 模式偵測

```
檢查 TEAM.md 成員數量：
  - 1-2 人 → Solo Mode
  - 3+ 人 → Team Mode
  - 未設定 → 預設 Team Mode（更安全）
```

### 模式差異

| 機制 | Solo Mode | Team Mode |
|------|-----------|-----------|
| Gate Review | 同 session 輕量自檢 | 必須開新 session（§31.7） |
| 確認點 | 自動通過，除非有 🔴 | 每步需用戶確認「繼續」 |
| Cross-Model Review | 僅 Gate 3 安全項強制 | 符合條件全部強制 |
| info-ship | 自動執行所有步驟 | 每步顯示結果等確認 |
| Commit Review | 自動 lint fix + commit | 顯示 diff 等確認 |
| Fix-First | Agent 可直接修復非判斷性問題 | 標記問題 + 提出建議，等確認 |

### 切換指令
```
用戶說：「切換 Solo Mode」或「切換 Team Mode」
→ 更新 memory/team_mode.md
→ 所有 Agent 下次讀取時自動適配
```

---

## Autoplan 原則自動決策

> 靈感來源：gstack /autoplan — 區分「機械決策」和「品味決策」，機械決策自動處理。

### 機械決策（自動處理，不問人）

| 決策類型 | 自動規則 |
|---------|---------|
| Lint/Format 問題 | 自動修正 |
| 未使用 import | 自動移除 |
| 測試檔名不符規範 | 自動重命名 |
| console.log 殘留 | 自動移除 |
| 文件路徑引用過時 | 自動更新（info-doc-sync） |
| 版本號 PATCH | 自動 bump |

### 品味決策（必須問人）

| 決策類型 | 提問方式 |
|---------|---------|
| 架構方案選型 | AskUserQuestion + ADR |
| 功能取捨 | AskUserQuestion + 完成度分數 |
| 版本號 MINOR/MAJOR | AskUserQuestion |
| 敘事性文件修改 | info-doc-sync 問人 |
| 設計方向 | AskUserQuestion + 截圖 |

### 6 條自動決策原則

1. **完整 > 捷徑**（Boil the Lake）：能做完整的就做完整
2. **修復影響範圍最小化**：bug fix 不順帶重構
3. **務實簡潔**：能用 3 行解決的不用 30 行
4. **DRY**：重複出現 3 次以上才抽取
5. **明確 > 聰明**：看不懂的 one-liner 換成看得懂的 3 行
6. **行動偏向**：能立即做的不拖到下個 Sprint

---

## 🔀 工具環境感知

Pipeline 執行時需感知當前所在的工具環境，並在適當時機提示切換：

### 環境判斷
| 環境 | 判斷方式 | 適合的 Pipeline |
|------|---------|---------------|
| **Cowork** | 在 VM 沙盒中，無 Git repo | P01 需求訪談 |
| **Claude Code** | 在用戶機器上，有 Git repo | P02～P06 所有技術階段 |

### 切換規則
| 時機 | 動作 |
|------|------|
| P01 完成 + Gate 1 通過 | 觸發 quality-gates 的切換指引，提示用戶開終端機 |
| P02～P06 在 Cowork 中被觸發 | 輸出警告：「⚠️ 此 Pipeline 建議在 Claude Code 中執行，以便進行技術驗證。請先切換到終端機。」 |
| 用戶堅持在 Cowork 執行 P02+ | 允許，但在交接摘要中標記：`⚠️ 未經開發環境驗證` |
