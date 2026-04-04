---
name: gate-check
description: >
  **Use this skill when reviewing completed pipeline milestones for readiness to advance.**

  Triggered by: "Gate 1 verification", "Ready for Gate 2?", "G4-ENG review starting", "Pre-delivery Gate 3 audit",
  or when a Pipeline completes and you need to verify all outputs meet quality standards before unlocking the next phase.

  Each Gate is a checkpoint that prevents defective output cascading downstream (wrong requirements → wasted design time,
  unclear API spec → Backend coding delays, untested code → production incidents).

source: levnikolaevich/claude-code-skills (adapted for workflow_rules §31.7)
---

# Quality Gates Skill: Structured Review Checkpoints

## Why Gate Reviews?
- **Separates concerns**: Writing code and reviewing code require different mindsets; same person is biased
- **Prevents cascade failures**: Gate 1 miss = requirements are vague → Gate 2 design is guesswork → Gate 3 can't fix it
- **Enforces standards**: Each Gate has specific criteria; no subjective "looks good to me"
- **Creates audit trail**: Signature lines in SignoffLog prove who verified what

**Golden Rule: Gate Review must run in a separate session (§31.7). Writer ≠ Reviewer.**

**⏱️ Gate SLA**：Gate 1/2/3 建議 24 小時內完成；G4-ENG 建議 48 小時內完成；Hotfix 審查 30 分鐘內。超時需通知 Feature Owner / Decision Owner。

---

## Gate 分級機制（v4.1 — 降低人工阻塞）

> 不是所有 Gate 都需要人坐在旁邊確認。依風險和變更規模分為三級。

### 三級分類

| 級別 | 名稱 | 條件 | 人工介入 | 機制 |
|------|------|------|---------|------|
| **L1** | Auto-Pass | 測試全綠 + 無 drift signal + diff < 200 行 + 非外部串接 | 不需要 | AI 自動通過，產出 Gate 報告通知人 |
| **L2** | Review-Pass | 測試全綠 + （有架構變更 OR diff ≥ 200 行 OR 涉及共用元件） | 看摘要確認 | AI 產出摘要 + 風險評估，人確認即通過 |
| **L3** | Full-Gate | 測試有失敗 / scope drift / 跨 Feature 影響 / 外部串接 / 合規 | 完整 Review | 走完整 Gate Checklist |

### 分級判定流程

```
Gate 觸發
  ↓
讀取 gate_policy（project-config.yaml）
  ↓
收集信號：
  - tests_green?          ← 跑測試結果
  - drift_signals?        ← 有無 DRIFT_SIGNAL
  - diff_lines?           ← git diff --stat 行數
  - has_arch_change?      ← 修改了 ARCH / ADR / Schema
  - shared_component?     ← 修改了共用元件
  - external_integration? ← .gates/F##/.integration 存在
  - compliance_required?  ← COMP_Checklist 有更新
  ↓
匹配級別（最嚴格者優先）：
  L3 條件符合 → Full-Gate
  L2 條件符合 → Review-Pass
  都不符合   → Auto-Pass
```

### L1: Auto-Pass 行為

```markdown
## 🟢 Gate [X] Auto-Pass Report — F[XX]

**級別**: L1 Auto-Pass
**時間**: [ISO timestamp]
**判定依據**:
- 測試: ✅ 全綠 ([N] passed / [N] total)
- Drift Signal: 0
- Diff: [N] 行（< 200）
- 架構變更: 無
- 外部串接: 無

**變更摘要**: [1-3 句話描述做了什麼]
**檔案清單**: [列出修改的檔案]

> ℹ️ 此 Gate 已自動通過。如需完整 Review，回覆「升級為 L3」。
```

- 自動寫入 `.gates/F##/gate[X]-auto-passed.log`
- 通知人（但不阻塞）
- 人可隨時回覆「升級為 L3」要求完整 Review

### L2: Review-Pass 行為

```markdown
## 🟡 Gate [X] Review-Pass Report — F[XX]

**級別**: L2 Review-Pass
**時間**: [ISO timestamp]
**升級原因**: [架構變更 / diff ≥ 200 行 / 共用元件修改]

**變更摘要**: [3-5 句話，重點在「為什麼這樣改」]
**風險評估**:
- 影響範圍: [列出受影響的 Feature / 元件]
- 破壞風險: [低/中/高 + 理由]
- 回滾難度: [低/中/高]

**AI 建議**: [通過 / 需要注意 X]

**檔案清單** (按風險排序):
- 🔴 [高風險檔案] — [修改說明]
- 🟡 [中風險檔案] — [修改說明]
- 🟢 [低風險檔案] — [修改說明]

> 回覆「通過」或「升級為 L3」或「需要修改 [具體項目]」
```

- 人只需看摘要 + 風險評估
- 回覆「通過」即可（不需逐項勾 checklist）
- 回覆「升級為 L3」走完整 Review

### L3: Full-Gate 行為

走原有的完整 Gate Checklist（Gate 1 / Gate 2 / G4-ENG / Gate 3），無變化。

### 特殊規則

| 規則 | 說明 |
|------|------|
| **Gate 1 / Gate 2 強制 L3** | 需求和架構 Gate 風險高，永遠走 Full-Gate |
| **G4-ENG-D 可降級** | 如果 Slice 的設計變更 < 50 行且不涉及新 API → L2 |
| **G4-ENG-R 可降級** | 測試全綠 + diff < 200 行 + 無共用元件 → L1 |
| **Gate 3 可降級** | 測試全綠 + 合規無變更 + 非首次部署 → L2 |
| **人可隨時升級** | 任何 L1/L2 都可回覆「升級為 L3」 |
| **連續 Auto-Pass ≥ 5 次** | 第 6 次強制升級為 L2（防止慣性盲區） |

### Gate 分級設定

```yaml
# project-config.yaml → gate_policy
gate_policy:
  enabled: true
  
  # L1 Auto-Pass 條件（全部滿足才 Auto-Pass）
  auto_pass:
    tests_green: true
    drift_signals: 0
    max_diff_lines: 200
    no_arch_change: true
    no_shared_component: true
    no_external_integration: true
    no_compliance_change: true
  
  # 強制 Full-Gate 的情境
  force_full_gate:
    - "gate-1"              # 需求 Gate 永遠 Full
    - "gate-2"              # 架構 Gate 永遠 Full
    - "first_deployment"    # 首次部署永遠 Full
    - "compliance_change"   # 合規變更永遠 Full
  
  # 安全閥：連續 Auto-Pass 上限
  auto_pass_streak_limit: 5
```

---

## Review Staleness Detection（強制）

> 靈感來源：gstack review staleness — 防止 ship 已被改動但未重新 review 的程式碼。

Gate Review 開始時，**必須**先執行 Staleness Check：

### 檢查項目

```bash
# 取得上次 Gate Review 的 commit hash（從 GRN 報告或 gate_baseline.yaml）
REVIEW_COMMIT=$(cat memory/gate_baseline.yaml | grep last_review_commit | awk '{print $2}')

# 計算自上次 review 以來的 code commit 數
CODE_COMMITS=$(git log --oneline $REVIEW_COMMIT..HEAD -- src/ | wc -l)

# 計算天數
REVIEW_DATE=$(cat memory/gate_baseline.yaml | grep last_review_date | awk '{print $2}')
DAYS_SINCE=$(( ($(date +%s) - $(date -d $REVIEW_DATE +%s)) / 86400 ))
```

### 判定規則

| 條件 | 結果 | 處理 |
|------|------|------|
| code commit = 0 且 < 7 天 | 🟢 Fresh | 正常 Review |
| code commit 1-3 且 < 7 天 | 🟡 Stale | Review 但必須重點看新 commit |
| code commit ≥ 4 | 🔴 Expired | Review 無效，必須重新 Review |
| > 7 天 | 🔴 Expired | Review 無效，必須重新 Review |

### Review 報告中標記

```markdown
## Review Staleness Check
狀態：🟢 Fresh / 🟡 Stale / 🔴 Expired
上次 Review commit：[hash]
當前 HEAD：[hash]
間隔 commit 數：[N]
間隔天數：[N]
```

**🔴 Expired 時**：停止當前 Gate Review，通知 PM 安排重新 Review。

---

## Gate Progression & Unlock Chain

| Gate | Triggered After | Purpose | Blocks Until | Output |
|------|-----------------|---------|------------|--------|
| **Gate 1** | P01 (Interview + PM + UX) complete | Verify requirements are complete, testable, and achievable | P02 start | `F##-GATE1-RVW.md` + confirmation to proceed |
| **Gate 2** | P02 (Architecture + DB Schema) complete | Verify technical design is sound, feasible, and handles stated requirements | P03 start | `F##-GATE2-RVW.md` + ADR review |
| **G4-ENG** | P03 (API Spec + TC design) complete | Verify engineering specs are detailed enough to implement | P04 start (HARD BLOCK) | `F##-ENG-RVW.md` + `G4_SignoffLog.yaml` (Architect + DBA + Review) |
| **Gate 3** | P04 (Implementation + Tests) complete | Verify code is tested, secure, and ready to deploy | P05/P06 release | `F##-GATE3-RVW.md` + deployment readiness |

---

## Gate 1 — Requirements Completeness

**Review Agent: Verify requirements are clear, testable, and achievable before design begins.**

### Checklist

**Interview Records (06_Interview_Records/IR-*.md)**
- [ ] All customer/stakeholder concerns captured (no vague "sounds good")
- [ ] Assumptions documented (e.g., "customer assumes ≤100 users initially")
- [ ] Open questions logged with resolution path (e.g., "TBD: notification frequency preference — PM to confirm by 2026-03-20")

**User Stories (02_Specifications/US_F##_*.md)**
- [ ] Each story has ≥3 Acceptance Criteria (AC)
- [ ] Each AC is testable — no "User is happy", only "Login succeeds in <2s"
- [ ] AC doesn't prescribe HOW (no "use React" or "implement via webhook" in AC)
- [ ] Story point/effort estimate included
- [ ] Each AC has Nyquist Verification Tips (QA checklist of how to verify)
  - Example: "AC-3: User uploads CSV with ≤5000 rows in <1min" → Tip: "Manual test on 5000-row file; measure; check memory"
- [ ] US map to interview concerns (traceability: IR → US)

**Prototype (01_Product_Prototype/\*.html)**
- [ ] Loads without errors, responsive on mobile/desktop
- [ ] Core user flows complete (happy path for each key feature)
- [ ] Prototype-to-Code traceability (PTC) marked:
  - Each AC maps to wireframe element(s)
  - Example: "AC-2: User filters by date" → PTC-02: `<input type="date" class="filter-date">`
- [ ] PTC-04 declaration filled: "Prototype covers AC 1–5, 8–10; AC 6–7 out of scope"
- [ ] Design system compliance: colors, typography, button sizes match `comp_design_system.html`

**UX Cognitive Pattern Validation（v2.7 新增）**
- [ ] Prototype 每個畫面都有 6 Interaction States 定義（Empty / Loading / Error / Overflow / First-time / Permission）
- [ ] 每條 AC 至少對應一個 state（無隱含 state）
- [ ] UX 流程圖顯示系統邊界（不只是 UI 畫面）

**PM 強制思考驗證（v2.7 新增）**
- [ ] 需求思考紀錄（RT-01~07）每個功能都已完成（嵌入 US 文件頂部）
- [ ] PM 已選擇 Scope Mode（Expansion / Selective / Hold / Reduction）並記錄
- [ ] Implementation Alternatives（至少 2 條路徑）已產出

**RS 功能規格品質檢查（v2.8 新增 — 基準：AICC-II v4.0.4）**
- [ ] 每個功能包含完整 7 區塊（功能說明/操作角色/操作流程/情境描述/欄位規格/條件限制/AC）
- [ ] 操作流程：每步有「使用者做 X → 系統做 Y」（抽查 3 個功能）
- [ ] 情境描述：每個功能 ≥ 4 種情境（正常/錯誤/邊界/降級）
- [ ] 欄位規格：每個欄位有型別 + 必填 + 限制條件（不只是名稱）
- [ ] AC 表格：每個功能 ≥ 5 條 AC，含「前置條件 + 操作 + 預期結果」三段式
- [ ] 無模糊用語：搜尋「適當」「合理」「良好」→ 如有，退回修正
- [ ] Phase 標記：Phase 2 功能有完整規格但明確標記

**Coverage & Readiness**
- [ ] All planned features have stories (no hidden features to add later)
- [ ] AC count reasonable for timeline (e.g., 2-week sprint = 20–30 AC, not 100)
- [ ] No conflicting stories ("User can upload CSV" AND "System doesn't accept uploads" → contradiction)

### 真人審核項目（人工確認，不可由 AI 替代）

- [ ] 📋 需求方向是否符合專案目標與商業策略？
- [ ] 📋 功能優先順序是否合理？是否超出本期可交付範圍？
- [ ] 📋 關鍵假設是否已與客戶/利害關係人確認？
- [ ] 📋 是否有政策、法規、合規因素影響需求方向？
- [ ] 📋 需求思考紀錄（RT-01~07）是否每個功能都有實質回答？

### Pass/Block Criteria

**PASS** if: All stories testable, prototype complete, ≥3 AC per story, no unanswered questions blocking UX, **真人確認項全勾**
**BLOCK** if: Stories lack AC, AC are untestable ("user experience is better"), prototype incomplete, open questions without timeline, **真人確認項有未勾選**

---

## Gate 2 — Technical Feasibility

**Review Agent: Verify architecture choices are sound, documented, and dependencies clear.**

### Checklist

**Architecture Documents (03_System_Design/F##-SW-ARCH.md, F##-HW-ARCH.md)**
- [ ] System diagram shows components and data flow
- [ ] Technology choices justified (not just "we like X")
- [ ] Scalability plan documented (how does this handle 10x load?)
- [ ] Tech stack documented: languages, frameworks, databases, deployment platform, key libraries
- [ ] Non-functional requirements addressed: latency SLA, throughput, storage, cost budget

**Architecture Decision Records (ADR in memory/decisions.md)**
- [ ] ≥1 ADR per major choice (notification transport, authentication, database, caching)
- [ ] Each ADR has: context, decision, rationale, alternatives considered, pros/cons, follow-up
- [ ] Dependency graph complete: each ADR has `depends_on` and `depended_by` fields
  - Example: ADR-3 (SSE for notifications) depends_on ADR-1 (HTTP-first); depended_by F##-API, F##-FE-PLAN
- [ ] No orphaned ADRs (all decisions in ARCH appear in decisions.md)

**Database Schema (03_System_Design/F##-DB.md)**
- [ ] All tables defined with column types, nullability, indexes
- [ ] Multi-tenant isolation enforced: every data table has `tenant_id` (if applicable)
- [ ] Foreign key constraints included
- [ ] Migrations versioned sequentially (v001, v002, v003 — no gaps or out-of-order)
- [ ] Migration SQL is reversible (includes rollback)
- [ ] Scalability considered (partitioning strategy if table >100M rows)

**API Contract (03_System_Design/F##-API.md) — High Level Review**
- [ ] Every endpoint documented: method, path, request/response schema
- [ ] Error codes defined (not just "500 error")
- [ ] Rate limits, pagination, auth requirements clear
- [ ] Matches ARCH decisions (if ADR says SSE, API uses event streams; if REST, uses REST verbs)

**Data Consistency**
- [ ] AC from P01 → ARCH design (are all requirements addressed in architecture?)
- [ ] ARCH → API contract (do endpoint signatures match architectural layers?)
- [ ] ARCH → DB schema (do table names/relationships match architecture diagrams?)

**Slice Backlog 審查（v2.9 新增）**
- [ ] Slice Backlog 存在（`F##-SLICE-BACKLOG.md`）且每 slice 有 Entry/Exit Criteria
- [ ] Slice 依賴順序無循環（拓撲排序合理）
- [ ] 每 slice 修改檔案預估 ≤ 8（Complexity Smell）
- [ ] MVP slice 和 Phase 2 slice 明確分離
- [ ] Slice 切法為垂直切片（不是水平分層）

**Slice 分類與治理審查（v3.0 新增）**
- [ ] 每個 Slice 已標示分類標籤（🦴 骨幹 / 📋 一般業務 / 🔗 高外部依賴 / 🧩 可 Partial Design / 📞 需 Vendor Confirmation）
- [ ] 骨幹 slice 排在依賴順序最前面
- [ ] 高外部依賴 slice 已識別哪些需要 Wave 設計模式
- [ ] 需 Vendor Confirmation 的 slice 已準備 Vendor Confirmation 文件框架
- [ ] 可 Partial Design 的 slice 已標示 Wave 1 / Wave 2 可拆分的 deliverables
- [ ] 外部依賴可能阻塞的 slice 已有替代路徑（Wave 或重新排序）

**Architect Cognitive Pattern Validation（v2.7 新增）**
- [ ] Complexity Smell 檢查：預計修改幾個檔案？（1-4 ✅ / 5-8 🟡 / 9+ 🔴 BLOCK）
- [ ] Existing Code Leverage：已搜尋 context-skills / 10_Standards / 現有 codebase / npm?
- [ ] Failure Scenario：每個新 API / 模組有「生產環境失敗場景」描述
- [ ] 設計思考紀錄（DT-01~08）每個功能已完成

**DBA Cognitive Pattern Validation（v2.7 新增）**
- [ ] Shadow Path Tracing：每個新表/欄位有 4 路徑追蹤（happy / NULL / empty / upstream error）
- [ ] Temporal Depth：Schema 能承受 5x 資料量成長？

**Scope Baseline（範圍定版文件）**
- [ ] `SCB_F##_*.md` 已建立（模板：`TEMPLATE_Scope_Baseline.md`）
- [ ] 本期範圍 / 不含範圍已明確
- [ ] 假設條件已列出且標記確認狀態
- [ ] 限制條件已列出
- [ ] 驗收基準已定義（功能 + 非功能）

**系統設計確認書（v3.0 新增）**
- [ ] `SD_Confirm_F##_*.md` 已建立（模板：`TEMPLATE_SD_Confirm.md`）
- [ ] 架構方案摘要完整（技術選型 + 資料設計 + API 設計）
- [ ] 風險評估已完成（每項有 mitigation）
- [ ] 外部依賴已識別且標記狀態
- [ ] 設計文件清單完整（SW-ARCH / DB / ADR / Slice Backlog 全部存在）
- [ ] **已取得簽核**（系統分析 + PM + 工程師代表）

**開發計畫確認書（v3.0 新增）**
- [ ] `WBS_Confirm_F##_*.md` 已建立（模板：`TEMPLATE_WBS_Confirm.md`）
- [ ] Slice 切法總覽 + 依賴關係圖完整
- [ ] 開發順序 + 里程碑已定義
- [ ] 外部依賴 + Wave 計畫已規劃（若有）
- [ ] Blocker 初始識別已完成（DES-xx / IMP-xx）
- [ ] 資源配置已確認
- [ ] 品質控制計畫（7 步循環 + Cross-Slice Check 時機）已確認
- [ ] **已取得簽核**（PM + 工程師 + 系統分析）

### 真人審核項目（人工確認，不可由 AI 替代）

- [ ] 📋 架構方案是否符合團隊技術能力？
- [ ] 📋 主要技術風險是否已有 mitigation 方案？
- [ ] 📋 資料設計方向是否合理？是否考慮擴展性？
- [ ] 📋 外部系統依賴是否已確認介面與 SLA？
- [ ] 📋 設計思考紀錄（DT-01~08）是否每個功能都有實質回答？
- [ ] 📋 範圍定版文件已簽核（PM + 系統分析）？
- [ ] 📋 **系統設計確認書已簽核**（系統分析 + PM + 工程師代表）？
- [ ] 📋 **開發計畫確認書已簽核**（PM + 工程師 + 系統分析）？
- [ ] 📋 Slice 切法是否合理（垂直切，非水平分層）？
- [ ] 📋 Slice 依賴順序是否正確（骨幹先行）？
- [ ] 📋 哪些 Slice 可能受外部依賴阻塞？Wave 模式是否合理？

### Pass/Block Criteria

**PASS** if: ARCH complete with diagrams, ≥1 ADR per major choice, DB schema sound, no circular dependencies, decisions documented, **範圍定版文件已簽核**, **SD_Confirm + WBS_Confirm 已簽核**, **真人確認項全勾**
**BLOCK** if: Missing ARCH diagram, ADRs lack context, DB schema incomplete, unresolved design questions, **範圍未定版**, **真人確認項有未勾選**

---

## G4-ENG — 拆為雙層：G4-ENG-D（設計審查）+ G4-ENG-R（實作後審查）

> v2.9：G4-ENG 拆為兩個獨立 Gate，在每個 Slice Cycle 中各執行一次。
> G4-ENG-D 擋在 Design → Code 之間。G4-ENG-R 擋在 Code → Stabilization 之間。

---

### G4-ENG-D — Design Gate（設計審查，⛔ 未通過不得寫 code）

**Review Agent: 審查本 Slice 的設計是否完整到可以直接實作。**

**⚠️ 這是 Slice 級的 Gate，每個 slice 都要過一次。**

#### G4-ENG-D Checklist

| # | 檢查項 | 阻塞？ |
|---|--------|--------|
| D-01 | Feature Pack 範圍內/外明確定義 | 🔴 |
| D-02 | Entry Criteria 全部滿足（前序 slice 已成為基線） | 🔴 |
| D-03 | API Contract 每個 endpoint 有 request/response/error code | 🔴 |
| D-04 | Domain Design 有 state machine（如適用） | 🔴 |
| D-05 | Test Design 覆蓋 happy + validation + permission + edge | 🟡 |
| D-06 | 無「自行假設」— Open Issues 都已標記為 OI-NNN | 🔴 |
| D-07 | 和前序 Slice 的介面一致（Cross-Slice 相容） | 🔴 |
| D-08 | Complexity Smell：修改檔案預估 ≤ 8 | 🟡 |

**PASS → 進入 Code。BLOCK → 回 Design 修正。**

---

### G4-ENG-R — Review Gate（實作後審查，⛔ 未通過不得成為基線）

**Review Agent: 審查本 Slice 的實作品質、範圍一致性、穩定度。**

#### G4-ENG-R Checklist

| # | 檢查項 | 阻塞？ |
|---|--------|--------|
| R-01 | 範圍比對：實際修改 vs Feature Pack 一致 | 🔴 |
| R-02 | Scope Drift 清單（超出範圍的實作，必須解釋原因） | 🔴 若有未說明的 |
| R-03 | 自行假設清單（應為 0，全部走 Open Issue） | 🔴 若有 |
| R-04 | Design vs Code 一致性（API / State / Error Code） | 🔴 |
| R-05 | 測試覆蓋：AC 的 Test Case 全部存在 | 🔴 |
| R-06 | 編譯通過 | 🔴 |
| R-07 | 無 P0 阻塞（啟動失敗 / 安全漏洞 / 主流程壞） | 🔴 |
| R-08 | Open Issues 更新 | 🟡 |
| R-09 | 檔案異動清單（新增 / 修改 / 刪除） | 🟡 |
| R-10 | 需要人工決策的 Open Issues | 🟡 |
| R-11 | Mock 驗證 vs 真實整合已正確標記（mock verified / real integration pending） | 🟡 |
| R-12 | Source of Truth 定義清楚（複合 Slice 必填：Redis / DB / WS / Scheduler 的 SSOT + 一致性策略） | 🔴（若適用）|

**G4-ENG-R 正式輸出物（12 項）**：見 `slice-cycle/SKILL.md` Step 5 正式輸出模板。每次 G4-ENG-R 必須產出完整 12 項報告。

**複合 Slice 額外輸出**（涉及 Redis / DB / WebSocket / Scheduler / External Adapter）：
- [ ] 一致性策略已文件化
- [ ] Sequence Flow 已輸出（文字版即可）
- [ ] 失敗補償 / Rollback 分析已完成

**PASS → 進入 Stabilization。BLOCK → 依回退規則回到對應步驟。**

#### 回退規則（5 級）

| 問題類型 | 回退到 | 說明 |
|---------|--------|------|
| 範圍漂移 / 偷補需求 | G4-ENG-R | 刪除超出範圍實作，重新 Review |
| 設計與實作不一致 | Design（P03 本 slice） | 修正設計或修正 code |
| 啟動 / 安全 / 主流程 | Stabilization | P0 等級，先修到能跑 |
| 邏輯語意 / 邊界測試 | Hardening | 補測試、修邏輯 |
| 架構邊界錯誤 | **P02 / Gate 2（升級）** | slice 切法有誤 |

---

### Cross-Slice Integration Check（整合檢查）

**觸發規則**：
- 第 3 個骨幹 slice 完成後：第一次整合檢查
- 之後每 2 個 slice 完成後觸發
- 任何 slice 修改共用模組（auth / state machine / event bus / 共用 schema）時強制觸發

| # | 檢查項 | 阻塞？ |
|---|--------|--------|
| IC-01 | 各 Slice 間 API 調用正常（無 contract 不一致） | 🔴 |
| IC-02 | 共用 State Machine 行為一致 | 🔴 |
| IC-03 | 共用 DB Schema 無衝突（migration 順序正確） | 🔴 |
| IC-04 | 共用 Event/Message 格式一致 | 🔴 |
| IC-05 | Auth / Permission 跨 slice 一致 | 🔴 |
| IC-06 | 多租戶隔離在所有已完成 slice 中正確 | 🔴 |
| IC-07 | 跨 slice 整合測試可跑 | 🟡 |
| IC-08 | 效能無明顯退化 | 🟡 |

---

## G4-ENG（舊版相容 — 以下為原始 checklist，適用於非 Slice Cycle 的簡單功能）

**Review Agent: Verify engineering specs are detailed enough to implement without questions.**

**⚠️ CRITICAL: This Gate must pass before P04 starts. No exceptions. Failures here mean months of wasted development.**

### Checklist

**Specification Completeness (§35 Nyquist Dense AC)**

- [ ] **Acceptance Criteria (AC) Density**: API Spec + DB Schema contain ≥5 Guided Acceptance criteria per 1000 words
  - Guided AC = specific, measurable, traceable to code
  - Count tool: Search for `[GA]` markers; expect ≥5 per 1000 words
  - Example: "API returns `{ id, name, email }` on GET /users/123" ✅ (specific); "API returns user data" ❌ (vague)

- [ ] **API Spec** (`F##-API.md`) covers all AC from P01:
  - 15 AC from user stories → ≥15 endpoint specs (or composite endpoints)
  - Example: AC "User filters orders by date" → documents GET /orders?date_from=X&date_to=Y with response schema
  - Every request/response schema matches DB schema (field names, types)

- [ ] **DB Schema** (`F##-DB.md`) covers all AC data requirements:
  - Columns required for each AC present
  - Example: AC "Track order creation time" → table has `created_at TIMESTAMP` column

**Design Graph (DDG) Completeness (§39 Wave Analysis)**

- [ ] **Dependency Map**: ADR depends_on / depended_by fully populated
  - Example: ADR-7 (SSE for notifications) depends_on ADR-1 (HTTP-first) ✓ shows why (HTTP required for SSE)
  - DDG path is acyclic (no circular: A depends B, B depends C, C depends A)
  - All depended_by links are real (if F##-API depends ADR-7, does F##-API exist and reference it? Yes/no)

- [ ] **Wave Dependencies Identified**: If 2+ components are parallel (Architect + DBA), dependency marked
  - Example: "DBA Wave 1 on F##-DB, Architect Wave 1 on F##-ARCH → both parallel, no blocking" ✓

**Cross-Layer Consistency (SSOT - Single Source of Truth)**

- [ ] **Field Names Match Across Layers**:
  - User story says "email"; API spec says "email_address"; DB schema says "user_email" → ❌ BLOCK
  - Fix: All three use "email"; glossary.md confirms single definition

- [ ] **Data Types Align**:
  - AC: "Order ID is unique identifier"; API says `id: string`; DB says `id INTEGER PRIMARY KEY` → ❌ Conflict
  - Fix: Decide on one (usually `id: UUID` or `id: INTEGER`); update API + DB

- [ ] **Nullability Consistent**:
  - API says `phone: string` (required); DB schema says `phone VARCHAR NULL` → ❌ Mismatch
  - Fix: Either make API allow null, or DB NOT NULL, not mixed

- [ ] **Enums Defined**:
  - If API says `status: enum(pending, approved, rejected)`, DB schema and Frontend both use same enum values ✓

**Backend Cognitive Pattern Validation（v2.7 新增）**
- [ ] Test Coverage Diagram：每個 API endpoint 有 ASCII 覆蓋圖（✅ 已覆蓋 / 🟡 待補 / ❌ 缺失）
- [ ] Spec Review Loop：API Spec 已通過 5 維自我審查（完整性 / 一致性 / 可行性 / 可測性 / 安全性）

**Prototype Traceability (PTC-01~05) Verification**

- [ ] PTC-01：每個功能有 PTC 宣告（覆蓋範圍 + 排除）
- [ ] PTC-02：每個 AC 至少有一個對應 Prototype 元素
- [ ] PTC-03：偏差處有說明（Prototype 和 AC 不一致的地方）
- [ ] PTC-04 Spot Check：抽 3-5 個 UI 元素 → 追溯到 AC → 追溯到 API endpoint
  - At least 3/5 sampled elements have clear traceability
- [ ] PTC-05：Prototype 版本和 RS 版本一致（無 stale）

**Signature & Signoff**

- [ ] **SignoffLog** file created: `G4_{F##}_SignoffLog_v1.yaml`
  ```yaml
  gate: G4-ENG
  project: F##
  date: 2026-03-20
  signoffs:
    - role: Architect
      name: Claude Architect Agent
      verified:
        - "ARCH and ADR complete and internally consistent"
        - "No circular dependencies in DDG"
      signature: ✅ Approved
    - role: DBA
      name: Claude DBA Agent
      verified:
        - "DB Schema matches API contract (field names, types, nullability)"
        - "Migration scripts are reversible"
      signature: ✅ Approved
    - role: Review
      name: Claude Review Agent
      verified:
        - "Nyquist AC density ≥5/1000 words"
        - "PTC traceability confirmed on 5 spot checks"
      signature: ✅ Approved
  blockers: []  # If any: list them here; Gate fails if non-empty
  ```

### Pass/Block Criteria

### 真人審核項目（人工確認，不可由 AI 替代）

- [ ] 📋 API 是否明確到可直接實作（不需再問 SA）？
- [ ] 📋 畫面互動是否明確到可直接開發（不需再問 UX）？
- [ ] 📋 資料異動是否明確（不需再問 DBA）？
- [ ] 📋 測試情境是否完整（工程師讀完知道要測什麼）？
- [ ] 📋 功能設計思考表（DT-01~08）是否每項都已回答？

**PASS** if: AC density ≥5/1000, DDG acyclic, SSOT consistent, PTC valid, all 3 signatures, **真人確認項全勾**
**BLOCK** if: AC density <5/1000, DDG circular, SSOT conflicts, PTC missing, unsigned, **真人確認項有未勾選**

---

## Gate 3 — Pre-Launch Readiness

**Review Agent: Verify code is tested, secure, and deployment-ready.**

### Checklist

**Test Coverage & Execution**

- [ ] P0 tests (must-pass-to-ship) all pass
  - Example: Login flow, checkout flow, permission checks
- [ ] Overall coverage ≥80% of AC (15 AC → ≥12 have test coverage)
- [ ] Test execution logs clean (no flaky tests, no timeouts)
- [ ] Regression test for any bugs found and fixed (Phase 4 of systematic-debugging)

**Security Review**

- [ ] OWASP Top 10 checklist completed and signed off (Security Agent)
  - Injection, auth bypass, XSS, CSRF, broken access control, sensitive data exposure, etc.
  - Each marked ✅ secure or ⚠️ mitigated [with details]
- [ ] PII handling verified: where is personal data stored? encrypted? logged? sanitized?
- [ ] Secrets not in code (API keys, passwords in env vars or secrets manager, not source)

**Data Security Verification (DSV)**

- [ ] Multi-tenant isolation verified (tenant_id enforced at all data access points)
- [ ] Audit log complete: all state-changing operations logged with user, timestamp, action
- [ ] Backup/restore procedure tested

**Code Quality**

- [ ] Code review (PR review or gate checklist) passed
- [ ] No obvious tech debt introduced (if added, documented in TECH_DEBT)
- [ ] Performance tested (API response time <2s for listed above-mentioned scenarios, etc.)

**Deployment Readiness**

- [ ] Infrastructure provisioned (database, cache, load balancer, CDN if needed)
- [ ] Deployment script tested (can deploy to staging without manual steps)
- [ ] Rollback plan documented (how to undo if things go wrong)
- [ ] Monitoring/alerts configured (know when things break in production)

**Carry-Forward from Earlier Gates**

- [ ] L1 Gate Review: Were any Gate 1 or Gate 2 open items resolved?
  - Example: Gate 1 had "TBD: notification frequency" → Did P04 implement a choice? Document resolution.
  - Example: Gate 2 had "DDG incomplete for caching strategy" → Was ADR-N added? Link it.

### Pass/Block Criteria

### 真人審核項目（人工確認，不可由 AI 替代）

- [ ] 📋 功能完成度是否符合本期範圍承諾？
- [ ] 📋 缺陷是否已收斂（無 P0 未解 bug）？
- [ ] 📋 回歸風險是否可接受？
- [ ] 📋 提交前檢查紀錄（PC-01~06）是否完整？
- [ ] 📋 缺陷學習紀錄（DL-01~04）是否已完成？
- [ ] 📋 是否可安全進入發佈？

**PASS** if: P0 tests pass, coverage ≥80%, OWASP signed, DSV complete, deployment tested, open items resolved, **真人確認項全勾**
**BLOCK** if: P0 tests failing, coverage <80%, security unsigned, DSV gaps, deployment untested, open items unresolved, **真人確認項有未勾選**

---

## Gate Review Independent Session Protocol (§31.7)

### Why Separate Session?
- Writing team has discussion momentum; reviewing in same session means missing obvious issues
- True code review separates "what I wrote" from "is this correct?" mindsets
- Protects team: independent reviewers can push back without social friction

### Cowork (Collaborative Work) Session Steps

1. **Open new Cowork task** in same project folder
2. **First message** (copy-paste):
   ```
   你是 Review Agent。請讀取 CLAUDE.md，然後執行 Gate [1/2/G4-ENG/3] 驗收。

   驗收範圍：
   - 讀取 TASKS.md 了解目前進度
   - 讀取 context-skills/quality-gates/SKILL.md 取得 checklist
   - 逐項檢查對應的產出文件
   - 產出 Review 報告到 07_Retrospectives/F##-GATE[N]-RVW.md
   ```
3. Review Agent independently reads:
   - `CLAUDE.md` (project overview)
   - `TASKS.md` (who did what, handoff notes)
   - `memory/decisions.md` (prior ADRs, context)
   - All output documents for the phase being reviewed
4. Review runs checklist; produces `F##-GATE[N]-RVW.md` with findings
5. Result: ✅ PASS (unlock next phase) or 🔴 BLOCK (return to writers for fixes)

### Claude Code (Terminal) Steps

1. **Open new terminal window** (don't use the one running active development)
2. `cd [project-path]` → `claude`
3. First message same as above
4. Review Agent proceeds as in Cowork

### What Review Agent Sees (No Manual Context Needed)

Because both sessions point to same project directory:

| File | Review Agent Gets |
|------|------------------|
| `CLAUDE.md` | Full project scope, Agent roles, Pipeline definitions |
| `TASKS.md` | Who completed what, handoff summary, current phase |
| `memory/decisions.md` | All ADRs (technical context) |
| `memory/last_task.md` | Previous phase summary (if multi-session project) |
| Output documents | Actual specs, designs, code to review |

**No manual explanation needed.** Review Agent has full context from file system.

---

## Result Handling

### PASS
- Update `memory/STATE.md`: "Gate [N] passed [date] → unlocks [next phase]"
- Update `PROJECT_DASHBOARD.html`: Mark gate as ✅ (automated if available)
- Notify original team: "Gate [N] passed; ready for [next Agent/phase]"
- Archive review report to `07_Retrospectives/F##-GATE[N]-RVW.md`

### BLOCK
- Return to writing team with explicit list of blockers (not vague "redo this")
  - Example: "BLOCK-1: AC density is 3/1000, need ≥5. Add detail to API spec responses."
  - Example: "BLOCK-2: DDG has circular dependency: ADR-3 → ADR-7 → ADR-3. Resolve."
- Archive review report with blockers to `07_Retrospectives/F##-GATE[N]-RVW.md`
- Writing team fixes and re-runs verification before re-submitting (no second Gate Review needed if fixes are trivial; full Gate Review if structural changes)

---

## Tool Switching Guide (After Gate Pass)

### Gate 1 Pass → Cowork to Claude Code

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Gate 1 Passed — Requirements Phase Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cowork (P01 Interview + PM + UX) is done. P02 (technical design)
requires real development environment (file system, git, terminal).

👉 Open a terminal and run:
   cd [project-path]
   claude

In Claude Code, say:
   「讀取 CLAUDE.md，執行 Pipeline: 技術設計」

Cowork outputs to keep:
   ✓ 06_Interview_Records/IR-*.md
   ✓ 02_Specifications/US_F##_*.md
   ✓ 01_Product_Prototype/*.html
   ✓ TASKS.md (latest progress)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Gate 2 / G4-ENG / Gate 3 Pass

These typically already run in Claude Code. Simply output:

```
✅ [Gate Name] Passed

Unlocks: [Next Pipeline/Phase]
Next: Run Pipeline: [name] or proceed to [phase]
```

---

## Multi-Model Second Opinion（多模型交叉驗證，可選）

Gate 2、G4-ENG、Gate 3 中涉及安全或合規的檢查項，Review Agent 可啟用 Second Opinion 機制。
詳細操作見 `context-seeds/SEED_Review.md`「多模型交叉驗證」章節。

啟用條件（任一符合即建議啟用）：
- 安全相關檢查項（OWASP、PII、多租戶隔離）
- 審查中出現模稜兩可的判定
- 高風險架構變更（跨模組、資料結構）

---

## Gate Staleness Detection（Commit Hash 過期偵測）

> 靈感來源：gstack Review Readiness Dashboard — 用 commit hash 追蹤 Gate 結果是否仍然有效。

### 機制

Gate 通過時，Review Agent 必須記錄當下的 commit hash：

```yaml
# 寫入 Gate Review 報告末尾
gate_commit_baseline:
  gate: Gate [N]
  passed_at: 2026-03-20T14:30:00
  commit_hash: abc1234  # git rev-parse --short HEAD
  branch: feature/F02-incoming-call
```

### 過期判定規則

| 情境 | 狀態 | 處理 |
|------|------|------|
| Gate 通過後無新 commit | ✅ 有效 | 正常推進 |
| Gate 通過後有新 commit，但只改文件（.md/.yaml） | 🟡 輕微過期 | 下個 Gate 時附帶確認即可 |
| Gate 通過後有新 commit，改了 src/ 或 spec 文件 | 🔴 過期 | 必須重跑該 Gate 的受影響檢查項 |
| Gate 通過後超過 7 天無動作 | 🟡 時間過期 | 建議重新確認，非強制 |

### 執行方式

每次 Gate Review 開始前，Review Agent 先執行：

```bash
# 取得上一個 Gate 的 commit baseline
LAST_GATE_HASH=$(grep 'commit_hash' 07_Retrospectives/F##-GATE[N-1]-RVW.md | awk '{print $2}')

# 比對是否有新 commit
git log --oneline $LAST_GATE_HASH..HEAD

# 檢查新 commit 是否涉及 src/ 或規格文件
git diff --name-only $LAST_GATE_HASH..HEAD | grep -E '(src/|02_Specifications/|03_System_Design/)'
```

若偵測到過期：

```
⚠️ Gate Staleness Warning

上次 Gate [N-1] 通過時的 commit: abc1234 (2026-03-18)
目前 HEAD commit: def5678
新增 commit 數：3
涉及變更：
  - src/modules/auth/login.ts (🔴 程式碼變更)
  - 02_Specifications/F02-API.md (🔴 規格變更)

建議：重新執行 Gate [N-1] 的以下檢查項：
  - G[N]-03: 前後端驗證規則語意等價
  - G[N]-04: API Response 欄位未超出 Spec
```

---

## Before Signing Off on Gate

- [ ] All checklist items for this Gate reviewed
- [ ] Spot checks/samples completed (not just skimmed)
- [ ] Findings documented in review report
- [ ] Decision clear: PASS or BLOCK (no wishy-washy "mostly OK")
- [ ] If BLOCK, blockers explicitly listed with remediation guidance
- [ ] Signature filled (if SignoffLog applicable)
- [ ] Review report filed to 07_Retrospectives/
- [ ] **Commit hash baseline recorded**（`gate_commit_baseline` 寫入報告末尾）

**Anti-Sycophancy Rules（v2.7 新增）**
- [ ] 每個 🟢 判定都有證據支持（不是「我覺得沒問題」）
- [ ] 每個 🔴 判定指名具體阻塞項（不是「感覺不太對」）
- [ ] Review 不因上游 Agent 的權威而放行（「Architect 說了所以 OK」不算理由）
- [ ] 不使用：「看起來不錯」「基本上沒問題」「大致通過」— 用具體描述代替
