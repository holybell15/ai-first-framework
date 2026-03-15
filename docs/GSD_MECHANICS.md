# GSD Mechanics Reference (§32–§41)

> These 10 mechanisms are woven into every agent and pipeline. You don't activate them manually — they run automatically. This doc explains the WHY behind each one.

---

## §32 — Context Health Check (CHC)

**Problem it solves:** In long sessions, Claude's understanding of the codebase gradually drifts. It starts making assumptions that were true 50 messages ago but aren't anymore.

**How it works:** Before every agent handoff, the outgoing agent does a brief "do I still understand the current state correctly?" sanity check. If context health is degraded, it flags it rather than silently passing bad assumptions forward.

**You'll see it as:** A short confirmation like "目前理解的是... 這樣正確嗎？" at the end of agent outputs.

---

## §33 — Discuss Phase

**Problem it solves:** At major pipeline transitions (P01→P02, P03→P04), the team's technical preferences are often unspoken. Engineers just proceed with assumptions that turn out to be wrong.

**How it works:** At transition points, the Pipeline Orchestrator asks a brief set of preference questions before starting the next phase. For P01→P02: "前後端框架確認了嗎？雲端平台偏好？" For P03→P04: "TDD 強制嗎？並行執行還是順序？"

**You'll see it as:** A "Discuss Phase" question block before P02 or P04 starts.

---

## §34 — Lightweight Plan Check (LPC)

**Problem it solves:** Agents ship work that looks complete but has subtle gaps — missing error cases, undefined terms, untestable acceptance criteria.

**How it works:** After producing output, agents self-review across 5 dimensions:
1. **完整性** — Are all deliverables present?
2. **可行性** — Is the proposed solution technically viable?
3. **一致性** — Does this align with earlier decisions?
4. **可驗證性** — Can every AC be tested?
5. **範圍控制** — Did we scope-creep beyond the task?

Max 3 rounds. Unresolved issues get marked `UNRESOLVED` rather than silently ignored.

---

## §35 — Nyquist Validation Layer

**Problem it solves:** "The login works" is not an acceptance criterion. It's a hope. Tests written against vague ACs don't actually prove anything.

**How it works:** Every Acceptance Criterion that PM writes includes a brief verification hint:
```
AC-F01-02: 用戶輸入錯誤密碼 3 次後帳號鎖定 15 分鐘
NYQ: POST /auth/login with wrong password 3× → 403 + lockoutUntil timestamp; subsequent login before 15 min → same 403
```
QA agents start test case design from the NYQ hints, not from scratch.

---

## §36 — Auto-Fix Loop (AFL)

**Problem it solves:** Implementation fails verify, agent tries a random fix, that fails too, tries another, etc. Three random attempts with no systematic analysis.

**How it works:**
1. Step 4 Verify fails
2. Trigger `systematic-debugging` skill for root cause analysis
3. Apply targeted fix
4. Re-verify
5. If still failing after 3 rounds → record as `AFL-UNRESOLVED`, surface the blocker

**Key rule:** You never move on with a known broken state.

---

## §37 — Quick Mode

**Problem it solves:** Running a full Pipeline for a 2-line typo fix is absurd overhead.

**How it works:** Before starting any work, evaluate:
- ≤3 files affected?
- No new functionality?
- Verifiable in under 5 minutes?

If yes → Quick Mode: skip Pipeline, go directly to the change, verify, done.

---

## §38 — STATE.md Cross-Session Memory

**Problem it solves:** You close the session. Next time you open it, Claude has no idea where you were. You spend 10 minutes re-explaining context.

**How it works:** Before ending any session, agents write a YAML snapshot to `memory/STATE.md`:

```yaml
session_snapshot:
  date: 2026-03-15
  last_agent: Backend
  pipeline_stage: P03
  last_completed: "F01-API.md 完成"
  current_focus: "等待 G4-ENG Gate 驗收"
  next_action: "開新 session → Gate Review"
  open_questions:
    - "JWT token expiry 要多長？（等 Product Owner 確認）"
```

New sessions start with: "讀取 CLAUDE.md 和 memory/STATE.md" — and pick up exactly where they left off.

---

## §39 — Wave-Based Parallel Execution

**Problem it solves:** Running agents sequentially when they could run in parallel wastes time. But running them in parallel without dependency analysis causes conflicts.

**How it works:** Before launching multiple agents, do a dependency wave analysis:

```
W1: [Architect, DBA] — both need only: US + Prototype
W2: [Backend API Spec, Frontend Plan] — need: W1 outputs
W3: [Review] — needs: all W2 outputs
```

Launch W1 in parallel, wait for both, then launch W2 in parallel. Never launch an agent before its dependencies are ready.

---

## §40 — Model Profiles

**Problem it solves:** Using the most expensive model for every task, including simple ones like "update TASKS.md."

**Three profiles:**

| Profile | Model | Use when |
|---------|-------|---------|
| `quality` | Claude Opus | Architecture decisions, Gate Reviews, Security |
| `balanced` | Claude Sonnet | Most agents (default) |
| `budget` | Claude Haiku | Simple tasks: docs, TASKS.md updates, formatting |

Switch with: `切換 Profile: quality` (or `balanced` / `budget`)

Configure default in `memory/product.md`.

---

## §41 — map-codebase

**Problem it solves:** Starting an AI agent on an existing codebase without understanding it first guarantees hallucination and broken changes.

**How it works:** Before the first meaningful change to any existing codebase, run a 4-agent parallel scan:

| Agent | Analyzes |
|-------|---------|
| Stack Agent | Languages, frameworks, package versions, build tools |
| Architecture Agent | Module boundaries, data flow, key abstractions |
| Conventions Agent | Naming, patterns, testing style, commit format |
| Concerns Agent | Known tech debt, security issues, scale risks |

Output: `memory/codebase_snapshot.md` — a structured summary all subsequent agents reference.

**Trigger condition:** First entry into a codebase that has existing code in `src/`.
