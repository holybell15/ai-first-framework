---
name: handoff-protocol
description: >
  Agent 間的交接標準格式。每個 Agent 完成任務後強制執行。
  觸發詞: "交接", "handoff", "完成任務", "下一個 Agent"
user-invocable: false
allowed-tools: "Read, Write, Edit"
---

# Handoff Protocol: Standard Agent Handoff Format

## Overview

The Handoff Protocol ensures **zero context loss** and **clear responsibility transfer** between agents. Every task completion triggers a mandatory handoff document that contains everything the next agent needs to succeed.

**Trigger conditions:**
- Agent completes assigned task
- Phase/specialist changes
- Drift signal detected and rerouted
- Feature transferred between teams

---

## Handoff Document Template

**Location:** `memory/handoffs/[feature-id]/[From]-to-[To].md`

**Example path:** `memory/handoffs/user-auth/Architect-to-Backend.md`

```markdown
# Handoff: [Feature Name]

## From → To
- **From Agent**: [Name] ([Role/Specialist])
- **To Agent**: [Name] ([Role/Specialist])
- **Handoff Date**: [ISO 8601, e.g., 2026-03-31]
- **Task ID**: [From TASKS.md, e.g., T001-P01-AUTH]

---

## Feature Context
- **Feature Name**: [e.g., "User Authentication Module"]
- **Feature ID**: [e.g., "user-auth"]
- **Current Phase**: [P00/P01/P02/P03/P04/P05/P06]
- **Feature Status**: [% complete, e.g., "Design phase: 80% complete"]

---

## Task Completed
- **Task Title**: [What was completed]
- **Task Description**: [1-3 sentences explaining the scope]
- **Time Spent**: [e.g., "4 hours, 2 sessions"]
- **Completion Status**: ✓ Complete | ⚠️ Partial | 🚫 Blocked

---

## Completion Summary
[2-4 sentences summarizing what was accomplished, decisions made, and why.]

### Key Decisions Made
- Decision A: [What was decided and why]
- Decision B: [What was decided and why]

### Blockers Encountered
- [If any, explain what blocked progress and status]

---

## Deliverables Table

| Artifact | Path | Type | Status | Notes |
|---|---|---|---|---|
| Architecture Decision Record | `ARTIFACTS.md#adr-001` | ADR | ✓ Final | Approved by team |
| API Schema | `ARTIFACTS.md#api-spec` | Schema | ✓ Draft | Ready for review |
| [Other] | [path] | [type] | [status] | [notes] |

**All deliverables listed here MUST be in ARTIFACTS.md.** If not, it was not completed.

---

## Context for Next Agent

### What You Need to Know
[Bullet list of key assumptions, dependencies, decisions that affect next task]

- The authentication system must integrate with OAuth provider [X]
- Database schema already supports multi-tenant architecture
- Frontend components are in `/components/auth/` directory
- API rate limits: 1000 req/min per user

### Files to Read First (in order)
1. `STATE.md` — Current project state
2. `TASKS.md` — Full task queue and your assigned task
3. This Handoff document (you are reading it)
4. Relevant Artifacts from ARTIFACTS.md (see Deliverables table)

### Optional Context (Read Only If Needed)
- `memory/findings.md` — Cumulative research findings
- `memory/progress.md` — Session-by-session progress log
- Relevant ADR documents from previous phases

---

## What Next Agent Should Do First

### Immediate Actions (First 15 minutes)
1. Read this entire Handoff document
2. Read STATE.md + TASKS.md
3. Review deliverables from Deliverables table
4. Identify any **missing information or ambiguity**

### Next Task (From TASKS.md)
- **Task Title**: [From TASKS.md]
- **Expected Duration**: [estimate, e.g., "4-6 hours"]
- **Success Criteria**: [How will this task be marked complete?]
- **Acceptance Checklist**: [Specific conditions to meet]

### Dependencies
- [If this task depends on other tasks, list them]
- [If waiting for external input, note it]
- [If requires review/approval, note who]

---

## Drift Status

### Detected Drifts
- [ ] **Scope Drift**: Original scope expanded or changed?
- [ ] **Design Drift**: Design decisions no longer valid?
- [ ] **Test Escalation**: Test failures point to upstream bug?
- [ ] **Blocker**: External dependency blocking progress?

### If Drift Detected
Explain in detail:

```markdown
## DRIFT_SIGNAL

**Type**: [scope | design | test-escalation | blocker]

**Evidence**: [What indicated the drift?]

**Impact**: [How does it affect next agent's work?]

**Recommendation**: [Should this task continue or reroute?]

**Severity**: [low | medium | high | critical]
```

If drift detected, **DO NOT PROCEED** to next phase. Task-Master routes back to source.

---

## TASKS.md Update

Before writing this Handoff, the delivering agent MUST update `TASKS.md`:

```markdown
## T001-P01-AUTH (Example)

- **Status**: ✓ COMPLETE
- **Assigned to**: [Agent Name]
- **Completed**: [ISO 8601 date]
- **Duration**: [X hours across Y sessions]
- **Next Task**: T002-P02-AUTH-DESIGN
- **Next Assigned to**: [Next Agent Name]
- **Drift**: [none | type if detected]
- **Handoff**: `memory/handoffs/user-auth/Architect-to-Backend.md`

### Subtasks
- [x] Subtask A — DONE
- [x] Subtask B — DONE
- [ ] Subtask C — NOT STARTED (pushed to next phase)
```

---

## Handoff Verification Checklist

Before submitting this Handoff, verify:

- [ ] All deliverables listed in table actually exist in ARTIFACTS.md?
- [ ] TASKS.md has been updated with completion status + next task?
- [ ] findings.md / progress.md synced with latest context?
- [ ] DRIFT_SIGNAL section completed (even if "no drift")?
- [ ] "What Next Agent Should Do First" is actionable?
- [ ] All file paths are correct and absolute?
- [ ] Next agent name/role is clearly identified?
- [ ] Key decisions are documented and reasoned?
- [ ] No sensitive data exposed in this document?
- [ ] STATE.md reflects completed work?

**Do NOT submit Handoff if any item is unchecked.**

---

## Routing After Handoff

Once Handoff is written:

1. **Deliver Agent** signals Task-Master:
   > "Handoff ready. Task T001-P01-AUTH complete. Next agent: Backend. Handoff path: `memory/handoffs/user-auth/Architect-to-Backend.md`"

2. **Task-Master** reads Handoff + TASKS.md:
   - Verifies all deliverables exist
   - Checks for drift signals
   - Identifies next specialist from project-config.yaml
   - Loads skill loadout for next specialist

3. **Next Agent** begins:
   - Reads STATE.md + TASKS.md + Handoff
   - Checks Deliverables table for artifacts
   - Confirms no ambiguities; asks if needed
   - Starts work on assigned task

---

## Anti-Patterns to Avoid

### Handoff Anti-Patterns

❌ **Do NOT:**
- Write Handoff with only one sentence ("Done. See code.")
- Skip the DRIFT_SIGNAL section (always fill it, even with "none")
- Leave deliverables path empty ("will add later")
- Update TASKS.md without updating this Handoff
- Forget to list the next agent's name
- Include code snippets in Handoff (code goes in ARTIFACTS.md)
- Mix multiple features' handoffs in one document
- Skip "What You Need to Know" section (critical for continuity)

❌ **Do NOT skip Handoff entirely:**
- Even if task was "small" or "quick," still write Handoff
- Even if you worked alone and no one reads it, still write Handoff
- Handoff must be written before Task-Master is called

### Synchronization Anti-Patterns

❌ **Do NOT:**
- Update TASKS.md but forget Handoff
- Write Handoff but forget TASKS.md update
- Sync findings.md but not progress.md
- List deliverables in Handoff that don't exist in ARTIFACTS.md
- Mark task "COMPLETE" in TASKS.md but mark "Partial" in Handoff (contradictory)

### Context Anti-Patterns

❌ **Do NOT:**
- Assume next agent knows your domain context ("they're the backend team")
- Skip listing files they should read ("just check the repo")
- Omit dependencies ("it depends on some stuff we discussed")
- Leave ambiguous next task ("do whatever the code needs")

---

## Example Handoff (Full)

```markdown
# Handoff: User Authentication Module

## From → To
- **From Agent**: Sarah (Architect)
- **To Agent**: Alex (Backend)
- **Handoff Date**: 2026-04-15
- **Task ID**: T001-P01-AUTH

---

## Feature Context
- **Feature Name**: User Authentication Module
- **Feature ID**: user-auth
- **Current Phase**: P01 - Plan
- **Feature Status**: 80% complete (Design phase ready for implementation)

---

## Task Completed
- **Task Title**: Architecture Design for Authentication System
- **Task Description**: Designed multi-tenant OAuth2/OIDC authentication architecture supporting social login, MFA, and session management.
- **Time Spent**: 8 hours across 2 sessions
- **Completion Status**: ✓ Complete

---

## Completion Summary
Completed architecture design for the authentication module. Decided on OAuth2 with OpenID Connect for federated auth, using Auth0 as provider. Session management via secure HTTP-only cookies. MFA optional, triggered by risk assessment. Database schema supports multi-tenant isolation at row level.

### Key Decisions Made
- **Auth Provider**: Auth0 (better than in-house due to compliance/scalability)
- **Session Storage**: HTTP-only cookies (more secure than localStorage)
- **MFA Strategy**: Risk-based (triggered on suspicious activity)
- **Database Isolation**: Row-level security (tenant column in auth_sessions table)

### Blockers Encountered
- None. Timeline on track.

---

## Deliverables Table

| Artifact | Path | Type | Status | Notes |
|---|---|---|---|---|
| Architecture Decision Record | `ARTIFACTS.md#adr-001-auth` | ADR | ✓ Final | Approved by team lead |
| Database Schema (Auth) | `ARTIFACTS.md#schema-auth-sessions` | Schema | ✓ Draft | Ready for DBA review |
| API Endpoint Spec | `ARTIFACTS.md#api-auth-endpoints` | OpenAPI | ✓ Draft | Covers /login, /logout, /refresh |
| Sequence Diagram | `ARTIFACTS.md#seq-auth-flow` | Diagram | ✓ Final | OAuth2 flow + session creation |

---

## Context for Next Agent

### What You Need to Know
- Auth0 tenant ID: `auth0.us` (stored in .env)
- Session expiry: 24 hours (refresh token valid 7 days)
- User role structure: admin, user, guest (stored in JWT claims)
- Frontend redirect after login: `/dashboard` (no hardcoding)
- CSRF tokens required for state-changing requests
- MFA via TOTP only (SMS not in MVP)

### Files to Read First (in order)
1. `STATE.md` — Current project status
2. `TASKS.md` — Your task: Implement Auth backend endpoints
3. This Handoff document
4. `ARTIFACTS.md#adr-001-auth` — Architecture decision record
5. `ARTIFACTS.md#api-auth-endpoints` — API spec you'll implement

### Optional Context
- `memory/findings.md#auth-provider-evaluation` — Why Auth0 was chosen
- `memory/progress.md` — Session notes on design discussions

---

## What Next Agent Should Do First

### Immediate Actions (First 15 minutes)
1. Read this entire Handoff
2. Read STATE.md + TASKS.md
3. Review ADR + API spec from Deliverables table
4. Confirm Auth0 credentials in `.env.example`

### Next Task (From TASKS.md)
- **Task Title**: Implement Authentication Backend Endpoints
- **Expected Duration**: 6-8 hours
- **Success Criteria**:
  - `/api/auth/login` returns JWT + refresh token
  - `/api/auth/logout` invalidates session
  - `/api/auth/refresh` validates refresh token and issues new JWT
  - All endpoints tested with Playwright
- **Acceptance Checklist**:
  - All endpoints covered in API spec
  - Unit tests for token validation
  - Integration test with Auth0
  - No hardcoded secrets

### Dependencies
- Auth0 account provisioned ✓ (already done)
- Frontend team implementing login UI (parallel task, not blocking)
- Database schema applied to dev environment ✓ (ready)

---

## Drift Status

### Detected Drifts
- [x] **Scope Drift**: No
- [x] **Design Drift**: No
- [x] **Test Escalation**: No
- [x] **Blocker**: No

**No drift detected. Proceed to next phase.**

---

## Handoff Verification Checklist

- [x] All deliverables exist in ARTIFACTS.md?
- [x] TASKS.md updated with completion status?
- [x] findings.md + progress.md synced?
- [x] DRIFT_SIGNAL section completed?
- [x] "What Next Agent Should Do" is clear?
- [x] File paths are absolute and correct?
- [x] Next agent identified (Alex, Backend)?
- [x] Key decisions reasoned and explained?
- [x] No sensitive data exposed?
- [x] STATE.md reflects this work?

✓ All verified. Ready for handoff.
```

---

## Summary

The Handoff Protocol is **mandatory** for every task completion. It ensures:

✓ Zero context loss between agents
✓ Clear responsibility transfer
✓ Drift detection and routing
✓ Synchronization across STATE/TASKS/ARTIFACTS
✓ Complete traceability of decisions

**When in doubt, write a more detailed Handoff rather than a sparse one.**
