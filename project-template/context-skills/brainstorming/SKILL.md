---
name: brainstorming
description: >
  **Use this skill whenever you're exploring ideas, weighing design options, or uncertain about feature direction.**

  Triggered by: "我有個想法想聊聊", "這樣設計好嗎", "我在考慮兩個方案", "我不確定怎麼做這個功能", "我想討論一下",
  "有沒有更好的方式", "應該用什麼架構", "這個流程對不對", or when Interviewer/PM/Architect role needs to explore options
  before committing to specs or system designs.

  This skill structures messy thinking into clear decisions, preventing thrashing later and creating ADR audit trail.

source: obra/superpowers (adapted for AI-First workflow)
---

# Brainstorming Skill: Structure Exploration → Decision → Record

## Why Use This?
- **Prevents decision fatigue**: Messy brainstorming leads to second-guessing. Structured exploration locks in reasoning.
- **Creates ADR audit trail**: Every decision gets recorded in `memory/decisions.md`, not lost in chat history.
- **Accelerates team alignment**: Clear trade-off analysis means Architect/PM/QA can all buy in upfront.
- **Avoids late-stage pivots**: Exploring 3 options now saves rewriting 5 Agent outputs later.

---

## Phase 1 — Clarify the Problem (Understand Scope)

**Goal**: Ensure you're solving the right problem, not debating solutions to vague questions.

**5W1H Questions**:
- **What** exactly are we trying to solve? (Be specific — not "improve checkout", but "reduce checkout steps from 5 to 3")
- **Who** is affected? (End users? Admins? API consumers?)
- **Why** does this matter? (Business goal, user pain, tech debt?)
- **When** do we need it? (Urgency changes options — 1-week sprint vs. 3-month project)
- **Where** in the product? (New feature, existing page, separate module?)
- **How** will success be measured? (Metrics, user behavior, technical KPI?)

**Scope Boundary**: Explicitly state **what we're NOT doing**. This prevents option explosion on out-of-scope ideas.

**Example**:
```
❌ Vague: "How should we design the notification system?"

✅ Clear: "We need in-app notifications (not push/email yet) for order status.
          Success = 80%+ read rate within 24h.
          Scope: single tenant MVP.
          NOT doing: notification history >7 days, notification preferences,
          real-time multiplayer sync."
```

---

## Phase 2 — Diverge (Generate ≥3 Options)

**Goal**: Capture multiple valid approaches; no filtering yet. Diversity of options reveals hidden trade-offs.

For each option, document:
1. **Name/Label** — catchy, memorable
2. **Core approach** — 1-2 sentences on how it works
3. **Pros** — genuine strengths; ≥3 per option
4. **Cons** — honest weaknesses; ≥2 per option
5. **Effort estimate** — hours/days/weeks (be realistic)
6. **Tech debt/risk** — maintenance burden, scaling risk, team ramp-up, lock-in

**Example** (choosing between notification transport architectures):

| Option | Approach | Pros | Cons | Effort | Risk |
|--------|----------|------|------|--------|------|
| **Polling** | Client asks server every 5s | Simple; no WebSocket complexity; works behind corporate proxies | 5s latency; battery drain; scales poorly >1000 concurrent users | 4h | Unacceptable for real-time expectations |
| **WebSocket** | Bi-directional TCP connection | <100ms latency; handles 10K+ concurrent; true real-time | Server memory per connection; sticky session complexity; deployment complexity | 3d | Requires DevOps expertise; harder rollback |
| **Server-Sent Events** | Server pushes via HTTP/1.1 streams | <2s latency; simpler than WS; less memory; auto-reconnect | Max 6 connections/browser; IE11 unsupported; requires HTTP/1.1+ | 2d | Browser limit acceptable? Verify analytics |

---

## Phase 3 — Converge (Evaluate & Pick)

**Decision Framework** (pick one that fits your context):

### Option A: Scoring Matrix (multi-dimensional trade-offs)
- Rows: options
- Columns: decision criteria (performance, maintainability, team skill, cost, timeline, risk)
- Weight each criterion based on context (e.g., timeline-critical = 40%, performance = 30%, maintainability = 30%)
- Score each option 1–5 per criterion
- → Winner is highest weighted score

**Example weights** for "2-week delivery, small team":
- Timeline fit: 40%
- Maintainability: 35%
- Performance: 25%

**Example scores**:
- Polling: (4 × 0.40) + (3 × 0.35) + (2 × 0.25) = 3.15
- WebSocket: (2 × 0.40) + (5 × 0.35) + (5 × 0.25) = 3.70
- SSE: (5 × 0.40) + (4 × 0.35) + (4 × 0.25) = 4.25 ← Winner

### Option B: Reversed Risk List (when risk dominates)
- For each option, list "what could go wrong"
- Map to likelihood (5=likely, 1=rare) and impact (5=catastrophic, 1=minor)
- Risk score = likelihood × impact
- Pick option with lowest total risk

### Option C: Time Horizon Split (when context is genuinely uncertain)
- **Option A**: Fast to ship, higher tech debt (good for MVP, 2-week sprint)
- **Option B**: Slower, clean architecture (good for 6-month platform)
- → Pick A if shipping in 2 weeks, pivot to B later if needed; pick B if you know this is long-term

---

## Phase 4 — Decide & Record

**DO THIS IMMEDIATELY** (don't delay ADR writing):

1. **Document the decision in `memory/decisions.md`**

   ```markdown
   ### ADR-[#] Notification Transport: SSE over Polling/WebSocket

   - **Date**: 2026-03-15
   - **Context**: Need <5s latency, 2-week timeline, Node.js team, ~500 concurrent users MVP
   - **Decision**: Server-Sent Events (HTTP/1.1 event streams)
   - **Rationale**: Scored 4.25 vs. WebSocket 3.70 on timeline-weight matrix
                    Fits 2-week delivery; team can maintain without DevOps specialist

   - **Pros**:
     - <2s latency (meets requirement)
     - Low server memory (1 connection ≈ 2KB vs. WS 10KB)
     - Simple heartbeat keep-alive (built-in HTTP mechanism)
     - Team familiar with HTTP

   - **Cons**:
     - Max 6 connections per browser (acceptable for single-tab assumption)
     - IE11 unsupported (2% of users; acceptable for 2026)
     - Requires HTTP/1.1+ (all modern browsers)

   - **Alternatives Considered**:
     - Polling: Too slow (5s), bad UX
     - WebSocket: Over-engineered for MVP, 3-day dev time risk

   - **Follow-up Actions**:
     - Monitor browser compatibility in analytics after launch
     - Document fallback plan (Polling) if SSE issues surface
     - Plan WebSocket migration ADR if concurrent users exceed 5000

   - **depends_on**: [none yet, or earlier ADRs if applicable]
   - **depended_by**: F##-API (notification endpoints), F##-FE-PLAN (client-side event handling)
   ```

2. **Clarify downstream implications** (ask each team):
   - **Architect**: "Does SSE affect multi-tenant message isolation? Any schema changes?"
   - **Backend**: "Need API endpoints for /subscribe by 2026-03-20 for Frontend integration?"
   - **Frontend**: "Does SSE client library exist? Browser compatibility concern?"
   - **DBA**: "Do we need message queue, or direct DB polling? Connection pooling impact?"
   - **QA**: "How do we test SSE reconnection, message ordering, edge cases?"

3. **Update STATE.md** (if P02+ underway):
   ```markdown
   ## Notification Transport Decided
   - **Decision**: SSE (ADR-N)
   - **Impact**: Unblocks Backend (API endpoints) and Frontend (client integration)
   - **Next**: Backend writes F##-API.md by 2026-03-20
   ```
   This saves 10–15 min ramp-up for next session.

---

## Common Failure Modes

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| "Let's pick the coolest tech" | Mismatch with timeline/team skill; thrashing later | Use scoring matrix; weight effort heavily |
| "This will never need to change" | Famous last words before rewrite | Document assumptions; plan extension points |
| "Everyone agrees, so skip ADR" | Lose context in 3 months; new team member confused | Write ADR anyway; it's future-you's insurance |
| "We'll decide this in code" | Debate moves to PR, blocks development for days | Decide here; explain in PR why |
| "Option A is obviously best" | Might be wrong; you filtered too fast | Always generate ≥3 options before evaluating |
| "We don't have time for this" | Picking wrong option costs 5 days of rework | 30 min of brainstorming saves 5 days of development |

---

## GSD Integration

After locking a decision:

- **§33 Discuss Phase**: Use this skill to align on technical preferences before Agent work begins (P01→P02 handoff, P03→P04 handoff)
- **§34 LPC (Lightweight Plan Check)**: Review Agent output against decisions — is Architect respecting ADR-N?
- **§38 STATE.md**: Before handing off to next Agent, update: "Decided SSE (ADR-N) → Backend can start API spec"
- **§39 Wave Analysis**: If 2+ options have different team owners (Frontend + Backend), plan Wave 1 and 2 to respect dependency

---

## Before Saying "Decision Locked"

- [ ] Problem is crystal clear (5W1H answered)
- [ ] Scope boundary explicitly stated (what we're NOT doing)
- [ ] ≥3 options explored with honest pros/cons and effort estimates
- [ ] Decision criteria weighted and options scored (matrix or risk list completed)
- [ ] Winner clearly justified (not "gut feeling", but scoring or risk analysis)
- [ ] ADR written in `memory/decisions.md` with full context (someone reading in 3 months should understand why)
- [ ] Downstream impact identified (which Agent/task is unblocked?)
- [ ] Team alignment confirmed (or next step to align assigned)
- [ ] STATE.md updated if mid-project (saves ramp-up next session)
