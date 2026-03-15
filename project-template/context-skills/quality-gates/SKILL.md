---
name: quality-gates
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

**Coverage & Readiness**
- [ ] All planned features have stories (no hidden features to add later)
- [ ] AC count reasonable for timeline (e.g., 2-week sprint = 20–30 AC, not 100)
- [ ] No conflicting stories ("User can upload CSV" AND "System doesn't accept uploads" → contradiction)

### Pass/Block Criteria

**PASS** if: All stories testable, prototype complete, ≥3 AC per story, no unanswered questions blocking UX
**BLOCK** if: Stories lack AC, AC are untestable ("user experience is better"), prototype incomplete, open questions without timeline

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

### Pass/Block Criteria

**PASS** if: ARCH complete with diagrams, ≥1 ADR per major choice, DB schema sound, no circular dependencies, decisions documented
**BLOCK** if: Missing ARCH diagram, ADRs lack context, DB schema incomplete, unresolved design questions (e.g., "TBD: caching strategy")

---

## G4-ENG — Engineering Design Verification (P03 Completion Gate - HARD BLOCK for P04)

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

**Prototype Traceability (PTC-04) Spot Check**

- [ ] Pick 3–5 UI elements from prototype; trace to AC:
  - Example: Prototype has blue "Confirm Order" button → maps to which AC? "AC-8: User confirms order" → API has POST /orders/confirm? ✓
  - At least 3/5 sampled elements have clear traceability

- [ ] Every prototype element has a backing API endpoint or DB column
  - "User sees order history" → requires GET /orders + orders table ✓

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

**PASS** if: AC density ≥5/1000, DDG acyclic, SSOT consistent (fields/types/nullability match), PTC sampled and valid, all 3 signatures present
**BLOCK** if: AC density <5/1000, DDG circular, SSOT conflicts (API says string but DB says integer), PTC traceability missing, unsigned

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

**PASS** if: P0 tests pass, coverage ≥80%, OWASP checklist signed, DSV complete, deployment tested, earlier open items resolved
**BLOCK** if: P0 tests failing, coverage <80%, security issues unsigned, DSV gaps, deployment untested, open items from Gate 1/2 still unresolved

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

## Before Signing Off on Gate

- [ ] All checklist items for this Gate reviewed
- [ ] Spot checks/samples completed (not just skimmed)
- [ ] Findings documented in review report
- [ ] Decision clear: PASS or BLOCK (no wishy-washy "mostly OK")
- [ ] If BLOCK, blockers explicitly listed with remediation guidance
- [ ] Signature filled (if SignoffLog applicable)
- [ ] Review report filed to 07_Retrospectives/
