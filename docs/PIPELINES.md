# Pipeline Guide

> AI-First Framework contains 6 pipelines that take a product from raw idea to deployed software.
> Each pipeline is a structured sequence of agent handoffs, with a mandatory Quality Gate before moving forward.

---

## How Pipelines Work

**Starting a pipeline:**
```
執行 Pipeline: 需求訪談
```
The Pipeline Orchestrator (`context-skills/pipeline-orchestrator/SKILL.md`) takes over:
1. Runs a **CIC Grounding** check (confirms current state, files in scope, model profile)
2. Evaluates **Quick Mode** — can this be done faster without the full pipeline?
3. Activates each agent in sequence
4. After each agent completes, writes a handoff summary to `TASKS.md`
5. Asks: "✅ [Agent] 完成，繼續執行下一步嗎？"

**You only need to say "繼續" or "停" to control the flow.**

> 初次導入、1-2 人小團隊、或第一個 feature 建議先走 [Lite Mode](./LITE_MODE.md)。Lite Mode 保留核心控制點，但減少早期文件與 Agent 切換成本。

---

## Pipeline Overview

```
【新專案】
P01 需求訪談  →  Gate 1  →  P02 技術設計  →  Gate 2
                                                    ↓
P06 部署上線  ←  P05 合規審查  ←  Gate 3  ←  P04 實作開發

【舊專案首次接入】
Pipeline: 舊專案接入（一次性，Lite / Standard 雙軌）
  Lite: 現況盤點 → baseline 建立 → codebase 掃描 → GAP 報告 → 選第一個接入功能
  Standard: map-codebase → F-code 分配 → ADR 補記 → 技術債登記 → GAP 評估 → CI 整合
  → 接入完成，之後的新工作走正常 P01-P06
                                                    ↑
                              G4-ENG  ←  P03 開發準備
```

---

## P01 — 需求訪談

**Purpose:** Turn a vague product idea into structured, testable requirements with a visual prototype. Includes 3 stakeholder confirmation points and 2 entry modes.

**Entry Modes:**
| Mode | Description | When to use |
|------|-------------|-------------|
| A — Import | Stakeholder provides existing RFP/spec/email → Interviewer extracts into RFP Brief format | Already have a written document |
| B — Interview | Interviewer asks 5 focused questions → generates RFP Brief | Starting from scratch |

**Flow:**
```
Entry Mode (A/B) → RFP Brief → ✅ Confirm 0
    → Interviewer SDP → IR + Scope Map → ✅ Confirm 1
    → PM → RS (US + AC) → ✅ Confirm 2
    → UX → Prototype → Gate 1
```

**Stakeholder Confirmation Points:**
| Point | After | Who confirms | Reject action |
|-------|-------|-------------|---------------|
| ✅ Confirm 0 | RFP Brief | Stakeholder | Modify + re-confirm |
| ✅ Confirm 1 | IR + Scope Map | Stakeholder | Back to Interviewer |
| ✅ Confirm 2 | RS (US + AC) | Stakeholder | Back to PM (scope change → back to Interviewer) |

**Agents:** Interviewer (RFP Brief + Deep Interview) → PM → UX

**Outputs:**
| File | Location | Produced by |
|------|----------|-------------|
| `RFP_Brief_[功能].md` | `02_Specifications/` | Interviewer |
| `IR-[日期].md` | `06_Interview_Records/` | Interviewer |
| `US_F##_[功能名].md` | `02_Specifications/` | PM |
| `F##-UX.md` | `02_Specifications/` | UX |
| `F##_Prototype.html` | `01_Product_Prototype/` | UX |

**GSD active:** CHC §32 · Discuss Phase §33 · LPC §34 · NYQ §35 · STATE.md §38

**Gate 1** (open new session):
```
你是 Review Agent。執行 Gate 1 驗收。
```
Checks: RFP Brief exists + confirmed · IR completeness · Confirm 0/1/2 all ✅ · User Story coverage · AC testability · Prototype · USL-01 style lock

**After Gate 1 passes:** Switch from Cowork → Claude Code for P02 onwards.

---

## P02 — 技術設計

**Purpose:** Translate requirements into a concrete technical architecture with documented decisions.

**Agents:** Architect + DBA (parallel W1) → Backend API Spec + Frontend Plan (parallel W2) → Review (W3)

**Wave analysis applies** — Architect and DBA can start as soon as any single feature's UX is confirmed.

**Outputs:**
| File | Location | Produced by |
|------|----------|-------------|
| `F##-SW-ARCH.md` | `03_System_Design/` | Architect |
| `F##-HW-ARCH.md` | `03_System_Design/` | Architect |
| `F##-DB.md` | `03_System_Design/` | DBA |
| `F##-SLICE-BACKLOG.md` | `03_System_Design/` | Architect |
| `F##-ARCH-RVW.md` | `03_System_Design/` | Review |

**Slice Backlog 必須包含：**
- 每 slice 標示分類標籤：🦴 骨幹 / 📋 一般業務 / 🔗 高外部依賴 / 🧩 可 Partial Design / 📞 需 Vendor Confirmation
- 每 slice 有 Entry/Exit Criteria
- DES-xx / IMP-xx Blocker 初始識別
- 🧩 標籤 slice 已標示 Wave 1 / Wave 2 可拆分的 deliverables

**Special:** If `src/` already has code → run **map-codebase §41** first before any architecture work.

**GSD active:** map-codebase §41 · Wave §39 · CHC §32 · LPC §34 · Model Profiles §40 · STATE.md §38

**Gate 2** (new terminal window):
```
你是 Review Agent。執行 Gate 2 驗收。
```
Checks: Architecture viability · ADR completeness · DB Schema + tenant_id · Migration runnable · No unresolved Blocks · **Slice 分類/切法/依賴順序合理** · **Wave 模式適用性** · **外部依賴阻塞識別**

---

## P03+P04 — Slice Cycle（垂直切片開發循環）

> Gate 2 通過後，P03 和 P04 合併為以 Slice 為單位的循環。詳見 `context-skills/slice-cycle/SKILL.md`。

**Purpose:** Design + implement + stabilize + harden one vertical slice at a time.

**Agents per slice:** Backend → Frontend → QA → Review

**7-Step Loop per Slice:**

| Step | Name | Output | Gate |
|------|------|--------|------|
| 1 | Feature Pack | Scope + Blockers (DES-xx/IMP-xx) + External Dependencies | — |
| 2 | Design | Domain + API + Sequence + Test Design + Correlation Strategy (if applicable) | — |
| 3 | G4-ENG-D | Design review (⛔ blocks code if fails) | G4-ENG-D |
| 4 | Code | Implementation (scope-locked) | — |
| 5 | G4-ENG-R | Implementation review (12-item formal output) | G4-ENG-R |
| 6 | Stabilization | Can compile, can start, main flow works | — |
| 7 | Hardening | Reliable + baseline decision | — |

**Wave Design Mode** (for slices with external dependencies):
- 🔗🧩 slices → Wave 1 (independent deliverables) → Fixed vs Placeholder list → Vendor Confirmation
- Wave 2 (after external dependency resolved) → finalize design → normal Code step
- ⚠️ Partial design must NOT reverse-infer external dependency answers

**Baseline Discipline:**
- Slice must pass full G4-ENG-R → Stabilization → Hardening before next slice can start
- Backbone slices (🦴) get priority hardening over business slices
- AI-generated prototype/placeholder/mock verification ≠ formal signoff

**Cross-Slice Integration Check:** Triggers after 3rd backbone slice, then every 2 slices, after high-dependency slice groups, and at least once before Gate 3.

**5-Level Rollback Rules:**
- Scope drift → back to G4-ENG-R
- Design mismatch → back to Design (Step 2)
- Startup/security failure → back to Stabilization
- Logic/testing issues → back to Hardening
- Architecture boundary error → escalate to P02/Gate 2

**Outputs per Slice:**
| File | Location | Produced by |
|------|----------|-------------|
| `S[N]-FP.md` | `02_Specifications/` | Feature Pack |
| `S[N]-API.md` | `02_Specifications/` | Backend |
| `S[N]-DESIGN.md` | `03_System_Design/` | Backend + Frontend |
| `S[N]-TC.md` | `08_Test_Reports/` | QA |
| `S[N]-TR.md` | `08_Test_Reports/` | QA |
| `S[N]-REVIEW.md` | `07_Retrospectives/` | Review (G4-ENG-D + G4-ENG-R) |
| `S[N]-FVP.md` | `02_Specifications/` | Fixed vs Placeholder (Wave mode) |
| `S[N]-VC.md` | `02_Specifications/` | Vendor Confirmation (📞 slices) |

**GSD active:** Quick Mode §37 · AFL §36 · NYQ §35 · STATE.md §38 · Wave §39

**Gate 3** (new terminal window, after ALL slices complete):
```
你是 Review Agent。執行 Gate 3 驗收。
```
Checks: P0 test coverage ≥ 80% · E2E pass · DSV audit complete · Security review · L1 Gate retro · Cross-Slice Integration Check passed · All baselines stable

---

## P05 — 合規審查

**Purpose:** Verify security posture and regulatory compliance before release.

**Agents:** Security → Review

**Outputs:**
| File | Location |
|------|----------|
| `F##-SEC.md` | `04_Compliance/` |
| `F##-COMPLY-RVW.md` | `04_Compliance/` |

**Recommended:** Run Review Agent in a separate session.

---

## P06 — 部署上線

**Purpose:** Configure CI/CD, deploy to production, create release record.

**Agents:** DevOps → Review

**Outputs:**
| File | Location |
|------|----------|
| `F##-DEPLOY.md` | `03_System_Design/` |
| `F##-DEPLOY-RVW.md` | `09_Release_Records/` |

After P06: trigger **L2 Module Retro** (`/retro` command).

---

## File Naming Convention

```
F##        — Feature code (e.g. F01, F02)
[TYPE]     — Document type (US, API, DB, ARCH, TC, TR, SEC, DEPLOY, ...)
v[N]       — Version number

Examples:
  US_F01_Login.md           ← User Stories for F01 Login
  F01-API-v1.md             ← API Spec for F01, version 1
  F01-SW-ARCH.md            ← Software Architecture for F01
  G4_F01_SignoffLog_v1.yaml ← G4-ENG SignoffLog for F01
```

---

## Pipeline: Hotfix（Critical / High 線上問題專用）

> 觸發方式：`執行 Hotfix: [問題描述]`
> 不經過正常 P01-P03，從根因分析直達部署。

**先選模式：**

| 模式 | 何時使用 | 特徵 |
|------|----------|------|
| Lite Hotfix | 小團隊、無 staging、無 rollback script、無 feature flag | 保留事故控制點，但接受較簡單的基礎設施現況 |
| Standard Hotfix | 有明確 release branch、staging、rollback 能力、多人分工 | 使用完整理想 hotfix runbook |

```
輸入：線上問題描述 + 初步現象

Step 1 — 開案（< 15 min）
  Review Agent：評估嚴重度 → 若 Critical/High 才進 Hotfix Pipeline
  → 建立 memory/hotfix_log.md 條目（HF-YYYY-NNN）
  → 確認實際 production branch（預設 main；若不是，記錄真實分支）
  → git checkout -b hotfix/HF-YYYY-NNN（從 production branch 切出）

Step 2 — 根因分析（< 1 hr）
  Backend / Frontend Agent：systematic-debugging skill
  → 確認根本原因（有 evidence 才進 Step 3）
  → 記錄根因、影響範圍、暫時避險方式到 hotfix_log.md

Step 3 — 最小化修復（< 2 hr）
  Backend / Frontend Agent
  → 只動必要 code，≤ 2 架構層（SC-01）
  → 執行回歸測試（至少 smoke；有 unit 就補 unit）

Step 4 — Rollback / Safety 準備
  Lite:
    → 至少確認 1 種可執行回滾方案：git revert / 上一版 artifact / 手動回復步驟
    → 若有 Schema 變動，需記錄回退方案，不強制已有 down-migration 模板
  Standard:
    → rollback 腳本可執行
    → DB down-migration 已寫（若有 Schema 變動）
    → Feature Flag 可緊急關閉

Step 5 — 快速審查（< 30 min）
  ⚠️ 新 session 執行 Review Agent
  → HF-01~06 快速審查清單（見 SEED_Review.md）
  → 🔴 Critical：加跑 Security Agent 快速掃描

Step 6 — 驗證與部署
  Lite:
    → 無 staging 時，先執行 production 前 smoke checklist
    → 留下驗證證據後部署
  Standard:
    → Staging 冒煙測試通過 → 部署 Production
  → 更新 hotfix_log.md resolved 狀態

Step 7 — 補件（48hr 內）
  Lite 最小補件：
    → hotfix_log.md 補齊根因 / 修復摘要 / 驗證結果
    → 建立 1 條 follow-up backlog（避免重演）
    → 若變更需求或行為，補最小 RS 更新
  Standard 完整補件：
    → 更新 RS 對應章節
    → 補 Gate Review 文件（GRN）
    → Merge hotfix branch → production branch + develop（若有 develop）
  → hotfix_log.md 標記 ✅ 已結案

輸出：
  memory/hotfix_log.md（HF-YYYY-NNN 條目）
  修復 commit（hotfix/HF-YYYY-NNN branch）
  [48hr 補件] 最小事故紀錄或完整 RS + GRN 文件
```

**命名規範**
```
Branch:  hotfix/HF-YYYY-NNN
Commit:  hotfix(F##): [一行描述根因和修復]
Log ID:  HF-YYYY-NNN（寫入 memory/hotfix_log.md）
```

**鐵則**
- 🚫 根因未確認前禁止動 code（Step 2 必須完成才進 Step 3）
- 🚫 沒有任何可執行 rollback 方案不得上線（Lite 也至少要有 1 種）
- 🚫 禁止順帶重構，範圍最小化
- ✅ 48hr 內補件，hotfix_log.md 追蹤到結案

---

## Pipeline: 舊專案接入（Brownfield Onboarding）

> 觸發方式：`執行 Pipeline: 舊專案接入`
> 目標不是一次補全所有 legacy 文件，而是先建立可持續維護的 baseline。

**先選模式：**

| 模式 | 何時使用 | 特徵 |
|------|----------|------|
| Lite 接入 | 1-2 人團隊、首次導入、希望先開始做真實需求 | 先補入口與 GAP，避免 onboarding 成本過高 |
| Standard 接入 | 需要完整治理、多人接手、準備長期演進 legacy 系統 | 補齊 feature mapping、ADR、技術債與 CI 治理 |

### Lite 接入

```
Stage 0 — 現況盤點
  → 確認 production branch、部署方式、測試現況、CI 是否存在
  → 建立 memory/adoption_gap_report.md 初版

Stage 1 — 建立 baseline
  → 補齊 CLAUDE.md / TASKS.md / MASTER_INDEX.md / memory/STATE.md
  → 不覆蓋既有程式碼與既有規範

Stage 2 — 單次 codebase 掃描
  → 建立 memory/codebase_snapshot.md
  → 只要求畫出主要模組、資料流、外部依賴、風險點

Stage 3 — GAP 報告
  → 標出缺少的 standards / CI / 文件 / 測試
  → 分成 now / next / later，不要求一次補完

Stage 4 — 選第一個接入功能
  → 從真實需求挑 1 個功能或修復作為接入起點
  → 後續修改舊功能走「四步法」，新功能再決定是否升級到完整 P01-P06
```

### Standard 接入

```
Stage 1 — 技術全景掃描（map-codebase）
Stage 2 — Feature 盤點 + F-code 分配
Stage 3 — 架構決策補記（ADR）
Stage 4 — 技術債顯性登記
Stage 5 — 標準差距評估（GAP Report）
Stage 6 — 環境 + CI 整合
Stage 7 — 接入宣告 commit
```

### 接入後修改舊功能的四步法

| 步驟 | 最低要求 |
|------|----------|
| 理解現況 | 在 `TASKS.md` 或對應工作文件補 1 段現況摘要 |
| 補最小 RS | 只補本次修改涉及的行為與驗收條件 |
| 補測試 | 優先補 1 個能鎖住回歸風險的測試或手動驗證腳本 |
| 執行驗證 | 跑現有自動化；沒有自動化時留手動驗證紀錄 |

---

## Pipeline Quick Reference

| 觸發指令 | 路徑 |
|---------|------|
| `執行 Pipeline: 需求訪談` | Interviewer → PM → UX → Gate 1 |
| `執行 Pipeline: 技術設計` | Architect + DBA → Gate 2 |
| `執行 Pipeline: 開發準備` | Backend + Frontend + QA → G4-ENG |
| `執行 Pipeline: 實作開發` | Backend + Frontend + QA → Gate 3 |
| `執行 Pipeline: 合規審查` | Security → Review |
| `執行 Pipeline: 部署上線` | DevOps → Review → L2 回顧 |
| `執行 Hotfix: [問題]` | Review（嚴重度）→ Debug → Fix → Rollback → Deploy → 補件 |
| Gate Review | 開新 session → `你是 Review Agent。執行 Gate [N] 驗收。` |
