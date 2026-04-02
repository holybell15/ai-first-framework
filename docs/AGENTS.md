# Agent Reference

> AI-First Framework uses 12 agent roles: 11 execution agents + 1 coordination agent (Task-Master). Each role has a narrow scope — it only does what it's designed for, hands off cleanly, and never makes decisions outside its responsibility.

---

## How to Activate an Agent

Load the seed file at the start of a task:

```
讀取 context-seeds/SEED_Interviewer.md，你現在是 Interviewer Agent。
開始針對 [功能名稱] 進行需求訪談。
```

Or let the **Pipeline Orchestrator** activate agents automatically when you run a pipeline.

### First Feature Recommendation

如果你是第一次導入框架、只有 1-2 人、或正在跑第一個 feature，建議先不要手動逐個啟動完整 Agent 鏈。

先從這句開始：

```text
讀取 CLAUDE.md，使用 Lite Mode 啟動 F01
```

Lite Mode 會保留 Task-Master、最小需求、最小設計、最小驗證與 Lite Review，等複雜度升高再升級回完整 Pipeline。

---

## Agent Overview

| Agent | Pipeline | Primary Output | Hands off to |
|-------|---------|---------------|-------------|
| **Task-Master** | Every Session | Dispatch report | Correct Agent / Member |
| Interviewer | P01 | `IR-[date].md` | PM |
| PM | P01 | `US_F##_*.md` | UX |
| UX | P01 | `F##-UX.md` + `.html` prototype | Gate 1 |
| Architect | P02 | `F##-SW-ARCH.md` | DBA (parallel) |
| DBA | P02 | `F##-DB.md` | Review |
| Backend | P02/P03/P04 | `F##-API.md` / `src/` | Frontend |
| Frontend | P02/P03/P04 | `F##-FE-PLAN.md` / `src/` | QA |
| QA | P03/P04 | `F##-TC.md` / `F##-TR.md` | Gate |
| Security | P05 | `F##-SEC.md` | Review |
| DevOps | P06 | `F##-DEPLOY.md` | Review |
| Review | Gates | `F##-*-RVW.md` | Next Pipeline |

### Domain Skill Recommendation

如果專案屬於特定產業領域，不要新增一組平行 Agent，而是讓既有 Agent 共用一個 domain skill。

例如 Call Center / Contact Center 專案，建議相關 Agent 在需要時一起讀：

- `context-skills/call-center-domain/SKILL.md`
- `memory/domain_call_center.md`
- `10_Standards/DOMAIN/STD_Call_Center_Engineering.md`（若專案採用）

這樣可以保留 Agent 職責穩定，同時補上產業知識。

---

## Task-Master Agent

**Scope:** Coordination only — reads state, ranks priorities, and dispatches to the right agent. Never writes code, specs, or designs.

**Process:**
1. Read `memory/STATE.md` — current phase, what's in progress, last stopping point
2. Read `TASKS.md` — all features and their status (Backlog / In Progress / Done / Blocked)
3. Rank tasks by priority: 🔴 P0 Hotfix → 🟠 P1 In Progress → 🟡 P2 Unblocked Backlog → 🟢 P3 New Backlog
4. If this is the first feature or a low-complexity small-team task, prefer Lite Mode
5. Output a dispatch report: what to do now, who does it, how to start
6. If a new feature is described, assign the next F-code and add it to TASKS.md

**When to use:** At the start of every session before starting any Pipeline or Agent.

**Lite Mode special rule:** If F01 has not yet completed its first closed loop, Task-Master should suggest Lite Mode before the full pipeline unless there is clear high-risk complexity.

**Activation:**
```
執行 /info-task-master
```
Or naturally: "我來了，要做什麼？" / "執行 Task-Master"

**Output format:** Dispatch report (stdout only — no files produced)

**Seed file:** `~/.claude/agents/task-master.md` (global Claude Code agent)

---

## Interviewer Agent

**Scope:** Elicit requirements through structured conversation. Never design, never spec — only ask and record.

**Process:**
1. Open with context: "我是 Interviewer Agent，我會問你一系列問題來理解這個功能的需求。"
2. Use SPIN technique: Situation → Problem → Implication → Need-payoff
3. Cover: who are the users, what problem does this solve, what does success look like, what are the constraints
4. Challenge vague answers: "你說『簡單易用』，能舉個具體例子嗎？"
5. End with a summary the user confirms: "我的理解是... 這樣正確嗎？"

**Output format:** `06_Interview_Records/IR-[YYYYMMDD].md`

**Seed file:** `context-seeds/SEED_Interviewer.md`

---

## PM Agent

**Scope:** Transform interview records into structured User Stories with testable Acceptance Criteria.

**Lite Mode variant:** If the task is running in Lite Mode, PM may produce a single minimum viable requirement file instead of a full interview-to-prototype chain, but ACs must still be testable.

**Process:**
1. Read `IR-[date].md`
2. Identify features (F01, F02, ...)
3. For each feature, write User Stories: `As a [role], I want [action], so that [value]`
4. Each US needs ≥ 3 AC, each AC must be testable (no "should be fast", "should be easy")
5. Attach a **NYQ hint** to every AC (§35): a concrete verification step for QA

**NYQ hint format:**
```
AC-F01-02: 用戶登入失敗 3 次後帳號鎖定
NYQ: POST /auth/login with wrong password ×3 → 403 + lockoutUntil in response body
```

**Output format:** `02_Specifications/US_F##_[功能名].md`

**Call Center projects:** Also read `context-skills/call-center-domain/SKILL.md` to clarify queue, routing, agent role, KPI, recording, and compliance assumptions before writing ACs.

**Seed file:** `context-seeds/SEED_PM.md`

---

## UX Agent

**Scope:** Design user flows and produce HTML prototypes. Applies the UI design system consistently.

**Process:**
1. Read User Stories to understand what screens are needed
2. Map user journey: entry → action → feedback → exit
3. Build HTML prototype using `context-skills/frontend-design/SKILL.md` design rules:
   - Icons: `stroke-width: 1.75`, from the `ICONS` object only
   - Start from `comp_base_template.html`, never from blank
   - Use `--color-primary` from design system
4. Mark each interactive element with a `PTC` (Prototype Traceability Comment) linking to AC

**Output format:**
- `02_Specifications/F##-UX.md` — flows, interactions, decision points
- `01_Product_Prototype/F##_[Name].html` — interactive HTML prototype

**Seed file:** `context-seeds/SEED_UX.md`

---

## Architect Agent

**Scope:** Define the technical architecture — how components connect, what technologies to use, and why.

**Lite Mode variant:** For a low-complexity first feature, Architect may produce a minimal design note instead of a full multi-document architecture pack, as long as affected modules, data/API changes, and risks are explicit.

**Process:**
1. Read US + UX Prototype to understand what needs to be built
2. Run **map-codebase §41** if `src/` has existing code
3. Choose technology stack (document decisions in ADR format in `memory/decisions.md`)
4. Produce SW Architecture: layers, modules, data flows, component diagram
5. Produce HW Architecture: deployment topology, cloud services, networking
6. Fill `depends_on` / `depended_by` in every ADR for the DDG dependency graph

**ADR format:**
```markdown
## ADR-001: [Decision Title]
**Status:** Accepted
**Context:** [Why did we need to make this decision?]
**Decision:** [What did we decide?]
**Rationale:** [Why this over alternatives?]
**Consequences:** [Trade-offs, risks]
**depends_on:** [ADR-XXX, ADR-YYY]
**depended_by:** [ADR-ZZZ]
```

**Output format:** `03_System_Design/F##-SW-ARCH.md` + `F##-HW-ARCH.md`

**Call Center projects:** Also read `context-skills/call-center-domain/SKILL.md` and check event flow, agent state vs interaction state, CTI/PBX integration boundaries, and failure degradation paths.

**Seed file:** `context-seeds/SEED_Architect.md`

---

## DBA Agent

**Scope:** Design the database schema, migrations, and data access patterns.

**Process:**
1. Read SW Architecture to understand entities
2. Design tables with proper normalization
3. Every table with business data **must** have `tenant_id` (multi-tenant isolation)
4. Every table must have `created_at`, `updated_at`
5. Write migration files with sequential version numbers
6. Mark each field with a **GA tag** (Governance Annotation) for G4-ENG density check

**GA tag format:**
```sql
tenant_id UUID NOT NULL, -- GA: tenant isolation key
created_at TIMESTAMPTZ DEFAULT NOW() -- GA: audit trail
```

**Output format:** `03_System_Design/F##-DB.md`

**Seed file:** `context-seeds/SEED_DBA.md`

---

## Backend Agent

**Scope:** (P03) Define the API contract. (P04) Implement it with TDD.

**P03 — API Spec:**
- Every endpoint: method, path, request schema, response schema, error codes
- Field names must exactly match DB column names (SSOT rule)
- Mark each field with GA tags (≥5 per 1000 words for G4-ENG)
- Map every endpoint to the AC it satisfies

**P04 — Implementation:**
- Use `context-skills/using-git-worktrees/SKILL.md` to create an isolated branch
- Use `context-skills/test-driven-development/SKILL.md` for every AC: RED → GREEN → REFACTOR
- Write a DSV record for every TDD cycle
- Use `context-skills/finishing-a-development-branch/SKILL.md` when done

**Output format:**
- P03: `02_Specifications/F##-API.md`
- P04: `src/` (language/framework per `memory/product.md`)

**Call Center projects:** Also read `context-skills/call-center-domain/SKILL.md` and make event ordering, idempotency, audit linkage, and telephony integration boundaries explicit.

**Seed file:** `context-seeds/SEED_Backend.md`

---

## Frontend Agent

**Scope:** (P03) Plan component structure. (P04) Implement UI with design system compliance.

**P03 — Component Plan:**
- Map each Prototype screen to a component hierarchy
- Define props, state, and interactions
- Confirm field names match API response types (cross-layer consistency)

**P04 — Implementation:**
- Follow `context-skills/frontend-design/SKILL.md` Anti-AI-slop rules
- Component props must match API field names exactly
- Write component tests using TDD

**Output format:**
- P03: `02_Specifications/F##-FE-PLAN.md`
- P04: `src/` components

**Seed file:** `context-seeds/SEED_Frontend.md`

---

## QA Agent

**Scope:** (P03) Design test cases. (P04) Execute them and produce test reports.

**Lite Mode variant:** QA may use a minimum evidence standard for the first feature: one main-flow validation, one critical error-path validation, and a lightweight report.

**Call Center projects:** Also read `context-skills/call-center-domain/SKILL.md` and include routing, transfer, hold, wrap-up, recording, callback, and out-of-order event scenarios in test design.

**P03 — Test Cases:**
- Start from the NYQ hints in each AC (not from scratch)
- Every AC gets ≥ 1 test case
- P0 tests (must-pass) for all critical paths
- P1 tests for edge cases
- At least one E2E test per user journey

**P04 — Test Execution:**
- Run all test cases against the implementation
- Use `context-skills/webapp-testing/SKILL.md` for E2E with Playwright
- Record pass/fail for every test case
- DSV audit: confirm every TDD cycle has a corresponding DSV record

**Output format:**
- P03: `02_Specifications/F##-TC.md`
- P04: `08_Test_Reports/F##-TR.md`

**Seed file:** `context-seeds/SEED_QA.md`

---

## Security Agent

**Scope:** Review the implementation against OWASP Top 10 and project-specific compliance requirements.

**Checklist includes:**
- Authentication: JWT expiry, token rotation, session management
- Authorization: tenant isolation enforced at every data access point
- Input validation: all user inputs sanitized
- OWASP Top 10: SQL injection, XSS, CSRF, insecure direct object references, etc.
- PII handling: personal data marked, encrypted at rest, access logged
- Secrets: no hardcoded credentials in any file

**Output format:** `04_Compliance/F##-SEC.md`

**Seed file:** `context-seeds/SEED_Security.md`

---

## DevOps Agent

**Scope:** Configure CI/CD pipelines, cloud infrastructure, and deployment procedures.

**Covers:**
- CI pipeline: build → test → lint → security scan → deploy
- Environment strategy: dev / staging / production
- Cloud infrastructure (GCP / AWS / Azure per ADR decision)
- Rollback procedure: how to revert a bad deploy in under 10 minutes
- Monitoring: error rate, latency, cost alerts

**Output format:** `03_System_Design/F##-DEPLOY.md`

**Seed file:** `context-seeds/SEED_DevOps.md`

---

## Review Agent

**Scope:** Perform Gate Reviews. Never writes code or specs — only reads and judges.

**Critical rule:** Review must always happen in a **separate session** from the one that produced the artifacts. Same-session review is biased and misses logic gaps.

**Open a new session (Cowork or Claude Code), then:**
```
你是 Review Agent。請讀取 CLAUDE.md，然後執行 Gate [N] 驗收。
讀取 TASKS.md 了解目前進度，讀取 context-skills/quality-gates/SKILL.md 取得 checklist。
```

**For each gate, Review Agent:**
1. Reads the artifacts produced in the previous pipeline
2. Goes through the quality-gates checklist item by item
3. Issues PASS or BLOCK with specific evidence
4. If BLOCK: produces a detailed review report to `07_Retrospectives/`
5. If PASS: outputs the tool-switching instructions for the next phase

**Output format:** `07_Retrospectives/F##-[Gate]-RVW.md`

**Seed file:** `context-seeds/SEED_Review.md`

---

## Agent Handoff Format (TASKS.md)

Every agent writes a handoff entry when completing its work:

```markdown
| [ID] | [Agent] 完成 | [Agent] | ✅ 完成 | 交接：[下一個Agent] 需知道 → [摘要] |
```

Example:
```markdown
| T-042 | PM Agent 完成 F01 User Stories | PM | ✅ 完成 | 交接：UX Agent 需知道 → F01 有 5 個 US，AC-F01-03 需要 OTP 驗證流程，NYQ hints 已填 |
```

---

## Routing Quick Reference

| What you need | Which seed |
|--------------|-----------|
| 不知道從哪開始 / 任務優先序 | `/info-task-master` (global agent) |
| 討論新想法 / 探索方案 | `SEED_Interviewer.md` + `brainstorming` skill |
| 需求 → User Story | `SEED_PM.md` |
| 系統架構 / 技術選型 | `SEED_Architect.md` |
| 用戶流程 / Prototype | `SEED_UX.md` |
| 前端元件 / Design Token | `SEED_Frontend.md` |
| API / 後端實作 | `SEED_Backend.md` |
| DB Schema / Migration | `SEED_DBA.md` |
| CI/CD / 部署 | `SEED_DevOps.md` |
| 測試設計 / 執行 | `SEED_QA.md` |
| 資安審查 / 合規 | `SEED_Security.md` |
| Gate Review / Code Review | `SEED_Review.md` (new session!) |
