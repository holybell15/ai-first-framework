---
name: verification-before-completion
description: >
  **Use this skill before saying "I'm done", handing off to the next Agent, or marking a task complete.**

  Triggered by: "Verification before handoff", "Should I hand off now?", "Is this Agent output ready?",
  "About to write the summary", or simply when an Agent finishes their work phase and needs to confirm readiness.

  This skill catches mistakes that would otherwise cascade down-stream (next Agent wastes 2h on unclear requirements,
  or Gate Review bounces a design document back for missing diagrams). 5 min of verification saves days of rework.

source: obra/superpowers (adapted for AI-First workflow)
---

# Verification Before Completion: Self-Check Before Handoff

## Why Use This?
- **Prevents downstream waste**: A typo in API spec costs Backend 2h to debug; a missing diagram costs QA 1h to ask for clarification
- **Stops rework loops**: Gate Review will bounce incomplete outputs; verification catches them here
- **Protects credibility**: Verified output = team trust; rushed output = scrutiny on every handoff
- **Keeps parallel work flowing**: If Backend is waiting for API spec and you hand off incomplete, they're blocked

---

## Universal Checklist (All Agents)

**BEFORE writing the handoff summary, run through these:**

### ✅ Deliverable Completeness
- [ ] All promised output files exist
- [ ] Files in correct folder (02_Specifications/, 03_System_Design/, 08_Test_Reports/, etc.)
- [ ] Naming follows convention: `F##-[TYPE]-v[VERSION].md` (e.g., `F01-API-v1.md`, `F02-DB-v2.md`)
- [ ] No placeholder text (`[XXX]`, `TODO`, `TBD`, `FIXME`, `[FILL IN]`)
- [ ] All diagrams/tables have captions and legends (reviewers shouldn't have to guess)

### ✅ Upstream Consistency
- [ ] Output respects decisions from `memory/decisions.md` (ADRs)
  - Example: If ADR-3 decided "SSE for notifications", is the API spec using SSE or WebSocket?
- [ ] Output aligns with parent document (if building on requirements, do specs match?):
  - **PM output** aligns with Interview Records (`06_Interview_Records/IR-*.md`)
  - **Architect output** aligns with selected ADRs and tech stack from `memory/product.md`
  - **Backend output** aligns with Architect's API contract
- [ ] Terminology matches glossary (`memory/glossary.md`) — no synonyms within same doc
- [ ] Cross-references are valid (if you say "see F01-DB.md", that file exists)

### ✅ Documentation Quality
- [ ] Formatting is clean (consistent headers, lists, code blocks)
- [ ] Readability: Can someone unfamiliar pick this up and understand it in 15 min?
- [ ] Assumptions are called out (e.g., "assumes single-tenant", "requires Node 18+")
- [ ] Gotchas/risks are flagged (e.g., "⚠️ max 6 WebSocket connections per browser")

### ✅ Cross-Agent Handoff
- [ ] TASKS.md updated with handoff summary
- [ ] Handoff summary answers "What does next Agent need to know to unblock?"
  - Example: "ADR-7 decided to use SSE, so Backend API needs /notify/subscribe endpoint by 2026-03-20"
- [ ] Any "back-dependency" noted (if next Agent's output will feed back into yours, say so)
  - Example: "DBA will finalize schema; update API responses if new fields added"

### ✅ STATE.md & GSD Readiness
- [ ] If mid-P##, is `memory/STATE.md` updated with key decisions/blockers for next session?
  - Example: "Decided on 3-tier architecture (ADR-5) → ready for DBA Wave"
- [ ] Any unresolved flags documented (§34 LPC unresolved items, if any):
  - Example: "UNRESOLVED-1: Architect says multi-tenant schema TBD pending DBA input"

---

## Agent-Specific Checklists

### **Interviewer Agent**
Before handing to PM:
- [ ] Interview record (`06_Interview_Records/IR-[DATE].md`) captures all discussion points
- [ ] No jargon in IR that customer didn't use (direct quotes preferred over paraphrasing)
- [ ] Decision log: If customer said "we prefer X over Y", it's recorded with reasoning
- [ ] Ambiguities flagged: "Customer unclear on notification frequency — PM to clarify"

### **PM Agent**
Before handing to UX:
- [ ] Each User Story has ≥3 Acceptance Criteria (AC)
- [ ] Each AC is testable (not "user is happy" — "login completes in <2s")
- [ ] Nyquist Verification Tips (§35) added to each AC (QA checklist of how to verify):
  - Example AC: "User can upload CSV with ≤5000 rows in <1min"
  - Verification tip: "Manual test on 5000-row CSV file; measure time; check for memory leaks"
- [ ] Story point or effort estimate included (for timeline planning)
- [ ] Acceptance Criteria **don't** prescribe HOW (no "use React" or "use WebSocket" in AC)

### **UX Agent**
Before handing to Architect:
- [ ] Prototype (`01_Product_Prototype/*.html`) loads without errors
- [ ] User flow document (`F##-UX.md`) traces every AC to a wireframe/interaction
- [ ] Prototype-to-Code traceability (PTC) marked (§35): which HTML elements map to which AC
  - Example: "AC-2: User filters by date" → PTC-02: points to `<input type="date">` in prototype
- [ ] PTC declaration filled: "This prototype covers F##-US.md AC 1–5 and 8–10; AC 6–7 TBD (out of scope)"

### **Architect Agent**
Before handing to DBA/Backend:
- [ ] Architecture Decision Record (ADR) entries written in `memory/decisions.md` for each major choice:
  - Includes: decision, rationale, alternatives considered, impacts on downstream teams
- [ ] Dependency graph complete: Each ADR has `depends_on` and `depended_by` fields populated
  - Example: ADR-7 (SSE) depends_on ADR-3 (HTTP-first); depended_by: F##-API, F##-FE-PLAN
- [ ] HW/SW architecture diagrams included (system diagram, component relationships, data flow)
- [ ] Tech stack documented: language, frameworks, databases, deployment platform, key libraries
- [ ] Non-functional requirements addressed (scalability, latency, storage, cost SLA)

### **DBA Agent**
Before handing to Backend:
- [ ] All tables have `tenant_id` for multi-tenant isolation (if applicable)
- [ ] Schema migrations versioned sequentially (v001, v002, v003 — no gaps or out-of-order)
- [ ] Every column typed and nullable status clear (NOT NULL vs. DEFAULT NULL)
- [ ] Indexes defined for query performance (all WHERE clauses in queries have indexes on those columns)
- [ ] Foreign key constraints included (referential integrity)
- [ ] Data contract (`contracts/` folder) documents field types, enums, SSOT (single source of truth) rules

### **Backend Agent**
Before handing to Frontend:
- [ ] API spec (`F##-API.md`) documents every endpoint:
  - Method, path, request schema, response schema, error codes
- [ ] Each AC from PM maps to ≥1 endpoint or database operation
  - "AC: User can upload CSV" → maps to POST /upload endpoint + async job tracking
- [ ] Error handling complete:
  - All 4xx and 5xx codes documented with example responses
  - No generic "500 Server Error" without specifics
- [ ] Example requests/responses included (copy-paste ready for Frontend)
- [ ] Rate limits, pagination, auth requirements documented

### **Frontend Agent**
Before handing to QA:
- [ ] Design System compliance verified:
  - All colors from `comp_design_system.html`
  - All icons from ICONS object (stroke-width 1.75, proper SVG attributes)
  - Button sizes from design tokens
- [ ] Component hierarchy clear (page → sections → components)
- [ ] Prototype-to-Code traceability (PTC) filled (maps HTML elements to AC)
  - Example: "PTC-03: Login form submit button implements AC-3 'Form validation' via onClick handler"
- [ ] Accessibility basics checked:
  - ARIA labels on form inputs
  - Tab order logical
  - Color contrast ≥4.5:1 for text

### **QA Agent**
Before handing to Review:
- [ ] Test Case design (`F##-TC.md`) covers ≥80% of ACs
  - Example: 15 ACs → ≥12 must have TC (exception: "User is happy" AC can't be tested, exclude)
- [ ] P0 test cases automated (all critical-path, must-pass-to-ship tests)
- [ ] TC references Nyquist Verification Tips from AC (§35):
  - AC says "verify X"; TC explains *how* to measure/verify X
- [ ] Edge cases included (boundary conditions, happy path + unhappy path)
- [ ] Performance/load assumptions documented (e.g., "assumes ≤100 concurrent users")

### **Security Agent**
Before handing to Review:
- [ ] OWASP Top 10 checklist run for each item (injection, broken auth, XSS, etc.)
  - Each checked with ✅ secure or ⚠️ mitigated with [explanation]
- [ ] Multi-tenant isolation verified (if applicable): tenant_id enforced at every data boundary
- [ ] PII (personally identifiable info) identified and marked:
  - Where is email stored? Database encrypted? Logs sanitized?
  - Credit card handling? (Must be PCI-DSS compliant or use payment processor)
- [ ] Secrets (API keys, passwords) never in source code
  - Check: env vars, .env files, secrets manager configured

### **Review Agent (Gate 1/2/G4-ENG/Gate 3)**
Before signing off:
- [ ] All Block-level issues from checklist resolved (not just opened as UNRESOLVED)
- [ ] SignoffLog filed: `G4_{F##}_SignoffLog_v1.yaml` with signatures from Architect/DBA/PM
  - Example: "Architect sign-off: SQL schema matches F##-API contract ✅"
- [ ] Spot checks completed (5 random items from checklist verified manually)
- [ ] Recommendation clear: "✅ PASS" or "🔴 BLOCK with reasons" (no wishy-washy "mostly OK")

---

## LPC: Lightweight Plan Check (Self-Review §34)

**If you're unsure if your output is ready, run LPC** — a 5-dimension self-check:

| Dimension | Question | Red Flag | Green Light |
|-----------|----------|----------|------------|
| **Completeness** | Are all promised deliverables present? | Missing files, incomplete tables, TBD placeholders | All files exist, no placeholders, 100% populated |
| **Feasibility** | Can downstream Agent execute this? | Ambiguous requirements, "TBD by [other team]", circular dependencies | Clear, actionable, unblocks next Agent |
| **Consistency** | Does this contradict earlier documents? | Conflicts with ADR, specs change mid-way, terminology shifts | Aligned with decisions.md, glossary, upstream requirements |
| **Verifiability** | Can QA/Review verify this is done? | No acceptance criteria, untestable statements, "should work" | Metrics defined, testable, reviewable |
| **Scope Control** | Did you stay in lane or over-reach? | Added features not in requirements, redesigned components not in scope | Feature-complete per AC, didn't solve other problems |

**If any dimension is RED**: Step back, fix it, run LPC again. Don't hand off RED output.

---

## Reality-Check Ritual (防幻覺 §34)

**Before writing summary, complete this sentence aloud/in writing**:

```
"I understand that my output is:

1. PURPOSE: [One sentence on what this Agent produces and why]
   Example: "PM output translates customer needs into testable AC for UX to design flow"

2. INPUTS: [What documents/context did I read?]
   Example: "IR-2026-03-15.md (customer interview), TASKS.md (previous PM work), memory/product.md"

3. OUTPUTS: [What files do I produce?]
   Example: "F01-US.md (User Stories with AC), F01-PLAN.md (sprint roadmap)"

4. DOWNSTREAM USERS: [Who reads this next and what do they do with it?]
   Example: "UX Agent reads F01-US.md to design wireframes; PM uses AC to set sprint velocity"

5. READINESS: [Why is this output ready for handoff?]
   Example: "All 12 US have 3+ AC each; all AC are testable (no 'user is happy'); links to Interview Records present"
"
```

**If you can't complete this honestly**, your output isn't ready yet.

---

## Gate Review Integration

- **Gate 1 (Requirements)**: Uses this checklist to verify IR + US + Prototype completeness
- **Gate 2 (Technical)**: Uses Architect checklist to verify ADR coverage and schema rigor
- **G4-ENG (Engineering)**: Uses Backend/Frontend/QA checklists to verify API contract, DB schema, and TC coverage
- **Gate 3 (Pre-Launch)**: Uses QA + Security checklists to verify all tests pass and no security blockers

---

## Before Writing the Handoff Summary

- [ ] All universal checklist items passing (green)
- [ ] Agent-specific checklist for my role completed
- [ ] LPC 5-dimensions all GREEN
- [ ] Reality-check ritual completed and honest
- [ ] TASKS.md handoff row filled in (what next Agent needs to know)
- [ ] STATE.md updated if mid-project (for next session ramp-up)
- [ ] No dependencies on external work that's not yet started
- [ ] Reviewed by upstream Agent (if applicable) for consistency
