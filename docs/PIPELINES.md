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

---

## Pipeline Overview

```
【新專案】
P01 需求訪談  →  Gate 1  →  P02 技術設計  →  Gate 2
                                                    ↓
P06 部署上線  ←  P05 合規審查  ←  Gate 3  ←  P04 實作開發

【舊專案首次接入】
Pipeline: 舊專案接入（一次性，約 1~2 天）
  Stage 1 map-codebase → Stage 2 F-code 分配 → Stage 3 ADR 補記
  → Stage 4 技術債登記 → Stage 5 GAP 評估 → Stage 6 CI 整合
  → 接入完成，之後的新工作走正常 P01-P06
                                                    ↑
                              G4-ENG  ←  P03 開發準備
```

---

## P01 — 需求訪談

**Purpose:** Turn a vague product idea into structured, testable requirements with a visual prototype.

**Agents:** Interviewer → PM → UX

**Outputs:**
| File | Location | Produced by |
|------|----------|-------------|
| `IR-[日期].md` | `06_Interview_Records/` | Interviewer |
| `US_F##_[功能名].md` | `02_Specifications/` | PM |
| `F##-UX.md` | `02_Specifications/` | UX |
| `F##_Prototype.html` | `01_Product_Prototype/` | UX |

**GSD active:** CHC §32 · Discuss Phase §33 · LPC §34 · NYQ §35 · STATE.md §38

**Gate 1** (open new session):
```
你是 Review Agent。執行 Gate 1 驗收。
```
Checks: IR completeness · User Story coverage · AC testability · Prototype · USL-01 style lock

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
| `F##-ARCH-RVW.md` | `03_System_Design/` | Review |

**Special:** If `src/` already has code → run **map-codebase §41** first before any architecture work.

**GSD active:** map-codebase §41 · Wave §39 · CHC §32 · LPC §34 · Model Profiles §40 · STATE.md §38

**Gate 2** (new terminal window):
```
你是 Review Agent。執行 Gate 2 驗收。
```
Checks: Architecture viability · ADR completeness · DB Schema + tenant_id · Migration runnable · No unresolved Blocks

---

## P03 — 開發準備

**Purpose:** Produce detailed engineering specs that implementation agents can execute without ambiguity.

**Agents:** Backend → Frontend → QA

**Outputs:**
| File | Location | Produced by |
|------|----------|-------------|
| `F##-API.md` | `02_Specifications/` | Backend |
| `F##-FE-PLAN.md` | `02_Specifications/` | Frontend |
| `F##-TC.md` | `02_Specifications/` | QA |

**QA starts from the NYQ hints** in each AC (not from scratch). This is the `§35 Nyquist Validation Layer`.

**GSD active:** CHC §32 · LPC §34 · NYQ-02 §35 · STATE.md §38

**G4-ENG** — Engineering Design Gate (HARD BLOCK, new terminal window):
```
你是 Review Agent。執行 G4-ENG 工程設計驗收。
```

This gate **must pass before P04 can start.** It checks:
- GA density ≥ 5 markers per 1000 words in API Spec + DB Schema
- DDG dependency graph completeness (acyclic)
- Cross-layer consistency: API fields ↔ DB columns ↔ Frontend types (names + types must match)
- PTC-04 traceability: 3–5 Prototype UI elements traced to implementation intent
- Three-party SignoffLog: Architect + DBA + Review sign off

**Outputs:** `F##-ENG-RVW.md` + `G4_{F碼}_SignoffLog_v1.yaml`

---

## P04 — 實作開發

**Prerequisite:** `F##-ENG-RVW.md` must exist with no unresolved Blocks.

**Purpose:** Write production code, test-first, with full audit trail.

**Agents:** Backend → Frontend → QA

**Workflow per feature:**
1. Open worktree: `git worktree add ../feature-F01-login feature/F01-login` (`using-git-worktrees` skill)
2. For each AC: RED → GREEN → REFACTOR + DSV record (`test-driven-development` skill)
3. Finish branch: tests pass, self-review, merge/PR (`finishing-a-development-branch` skill)

**GSD active:** Quick Mode §37 · AFL §36 · NYQ Smoke Test §35 · STATE.md §38 · Wave §39

**Gate 3** (new terminal window):
```
你是 Review Agent。執行 Gate 3 驗收。
```
Checks: P0 test coverage ≥ 80% · E2E pass · DSV audit complete · Security review · L1 Gate retro

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

```
輸入：線上問題描述 + 初步現象

Step 1 — 開案（< 15 min）
  Review Agent：評估嚴重度 → 若 Critical/High 才進 Hotfix Pipeline
  → 建立 memory/hotfix_log.md 條目（HF-YYYY-NNN）
  → git checkout -b hotfix/HF-YYYY-NNN（從 main 切出）

Step 2 — 根因分析（< 1 hr）
  Backend / Frontend Agent：systematic-debugging skill
  → 確認根本原因（有 evidence 才進 Step 3）
  → 記錄根因到 hotfix_log.md

Step 3 — 最小化修復（< 2 hr）
  Backend / Frontend Agent
  → 只動必要 code，≤ 2 架構層（SC-01）
  → 執行回歸測試（smoke + unit）

Step 4 — Rollback 準備
  DevOps Agent
  → 確認 rollback 腳本可執行
  → 確認 DB down-migration 已寫（若有 Schema 變動）
  → 確認 Feature Flag 可緊急關閉

Step 5 — 快速審查（< 30 min）
  ⚠️ 新 session 執行 Review Agent
  → HF-01~06 快速審查清單（見 SEED_Review.md）
  → 🔴 Critical：加跑 Security Agent 快速掃描

Step 6 — 部署
  DevOps Agent
  → Staging 冒煙測試通過 → 部署 Production
  → 更新 hotfix_log.md resolved 狀態

Step 7 — 補件（48hr 內）
  → 更新 RS 對應章節
  → 補 Gate Review 文件（GRN）
  → Merge hotfix branch → main + develop
  → hotfix_log.md 標記 ✅ 已結案

輸出：
  memory/hotfix_log.md（HF-YYYY-NNN 條目）
  修復 commit（hotfix/HF-YYYY-NNN branch）
  [48hr 補件] RS 更新 + GRN 文件
```

**命名規範**
```
Branch:  hotfix/HF-YYYY-NNN
Commit:  hotfix(F##): [一行描述根因和修復]
Log ID:  HF-YYYY-NNN（寫入 memory/hotfix_log.md）
```

**鐵則**
- 🚫 根因未確認前禁止動 code（Step 2 必須完成才進 Step 3）
- 🚫 沒有 rollback 方案不得上線（Step 4 必須完成才進 Step 6）
- 🚫 禁止順帶重構，範圍最小化
- ✅ 48hr 內補件，hotfix_log.md 追蹤到結案

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
