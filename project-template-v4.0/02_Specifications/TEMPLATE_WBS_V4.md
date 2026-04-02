# Work Breakdown Structure (WBS) — V4 AI-First Framework

**Version**: V4.0 | **Last Updated**: 2026-03-31 | **Template Status**: Active

---

## Overview

This WBS decomposes the project into **3 levels**:
1. **L1: Epic** — Major capability or release goal
2. **L2: Feature (F-XXX)** — Deliverable feature with clear acceptance criteria
3. **L3: Task (T-XXX)** — Atomic development task for a single Agent

Each task includes size estimation, assignments, dependencies, and verification steps to enable **parallel execution** across AI Agents.

---

## Size Estimation Guidelines

| Size | Time Est. | LOC Est. | Parallelizable | When to Split |
|------|-----------|----------|---|---|
| **S** (Small) | < 30 min | < 200 | ✓ Single Agent | — |
| **M** (Medium) | 30–120 min | 200–800 | ✓ 2–3 Agents | Rare; only if truly independent |
| **L** (Large) | 2–4 hrs | 800–2,000 | ⚠ Requires careful orchestration | If blocked by many dependencies |
| **XL** (Extra Large) | > 4 hrs | > 2,000 | ✗ **MUST NOT EXIST** | Split into 2–3 subtasks immediately |

**Rule**: No task is ever L or XL without verification steps and clear acceptance criteria. XL tasks are **forbidden** — always split.

---

## Task Definition Format (YAML-Like)

```yaml
id: T-XXX
feature: F-YYY
title: "Clear, imperative task title"
size: S|M|L
assigned_agent: Backend|Frontend|DevOps|QA|Security|Architect|DBA
depends_on: [T-001, T-002]  # Task IDs this task waits for
files:
  - path: "/project/src/module/file.ts"
    action: "create|modify|delete"
  - path: "/project/tests/module/file.test.ts"
    action: "create"
verification_steps:
  - "Step 1: [Testable acceptance criterion]"
  - "Step 2: [Testable acceptance criterion]"
  - "Step 3: [Testable acceptance criterion]"
status: "Pending|In Progress|Review|Completed"
notes: "Any blockers, assumptions, or context"
```

---

## Example Epic & Feature Breakdown

### Epic: E-001 — User Authentication & Profile

#### Feature: F-001-user-auth — User Registration & Login

**Feature Brief**: Enable users to register with email/password, login, receive JWT token, and access protected routes.

**Acceptance Criteria**:
- User can register with email + password (frontend form validation)
- Backend validates email uniqueness, hashes password with bcrypt
- User receives JWT token on login success
- Login persists session for 24 hours
- Invalid credentials return HTTP 401 with error message
- All endpoints protected with middleware authentication check

---

##### Task: T-001-backend-auth-api

```yaml
id: T-001
feature: F-001-user-auth
title: "Implement backend auth API (register, login, token refresh)"
size: M
assigned_agent: Backend
depends_on: []
files:
  - path: "/project/src/api/auth/auth.controller.ts"
    action: "create"
  - path: "/project/src/api/auth/auth.service.ts"
    action: "create"
  - path: "/project/src/api/auth/jwt.strategy.ts"
    action: "create"
  - path: "/project/src/db/migrations/001_create_users_table.sql"
    action: "create"
verification_steps:
  - "POST /api/auth/register accepts {email, password} and returns user_id + token"
  - "POST /api/auth/login returns JWT token with exp claim (24h)"
  - "GET /api/me with Authorization header returns current user profile"
  - "Invalid credentials return HTTP 401 with error_code=INVALID_CREDENTIALS"
  - "Email uniqueness constraint enforced; duplicate signup returns HTTP 409"
  - "Password hashed with bcrypt (cost=10); plaintext never stored"
```

---

##### Task: T-002-frontend-auth-forms

```yaml
id: T-002
feature: F-001-user-auth
title: "Build frontend registration & login forms with validation"
size: M
assigned_agent: Frontend
depends_on: [T-001]
files:
  - path: "/project/src/components/auth/RegisterForm.vue"
    action: "create"
  - path: "/project/src/components/auth/LoginForm.vue"
    action: "create"
  - path: "/project/src/services/auth.service.ts"
    action: "create"
  - path: "/project/src/stores/auth.store.ts"
    action: "create"
verification_steps:
  - "RegisterForm displays email/password fields with live validation (email format, password strength ≥8 chars)"
  - "LoginForm submits credentials to /api/auth/login and stores JWT in localStorage"
  - "On successful login, user redirected to /dashboard; on failure, error message displayed"
  - "Token persists across page reload; logout clears localStorage"
  - "Unauthenticated users redirected to /login when accessing protected routes"
```

---

##### Task: T-003-auth-e2e-tests

```yaml
id: T-003
feature: F-001-user-auth
title: "Write E2E tests: register → login → access protected route"
size: L
assigned_agent: QA
depends_on: [T-001, T-002]
files:
  - path: "/project/tests/e2e/auth.spec.ts"
    action: "create"
  - path: "/project/tests/e2e/fixtures/auth.fixture.ts"
    action: "create"
verification_steps:
  - "E2E test: user registers with new email, receives confirmation"
  - "E2E test: user logs in with registered email/password, JWT stored"
  - "E2E test: accessing /dashboard without token redirects to /login"
  - "E2E test: accessing /dashboard with valid token shows user profile"
  - "E2E test: logout clears token and redirects to /login"
  - "All 5 tests pass in Playwright runner"
```

---

## Dependency Graph

```
T-001 (Backend Auth API)
  ↓
T-002 (Frontend Forms) ────┐
  ↓                        │
T-003 (E2E Tests) ◄────────┘

Legend:
→ Dependency (must complete first)
│ Sequential flow
◄ Joins/merges
```

**Parallel Opportunities**:
- T-001 (Backend) can start immediately
- T-002 (Frontend) starts after T-001 API is stubbed (mock endpoints available)
- T-003 (QA) waits for both T-001 & T-002 complete

**Critical Path**: T-001 → T-003 (Backend + Frontend + Tests) ≈ 4–5 hours

---

## Task Health Checklist

Before marking any feature as **Ready for Build**, verify:

- [ ] All tasks have **explicit size** (S, M, or L)
- [ ] **No XL tasks** remain (split immediately if > 4 hrs)
- [ ] All **L+ tasks** have ≥ 3 verification steps
- [ ] All **dependencies marked** in `depends_on` array
- [ ] All **file paths are absolute** and project-relative
- [ ] Each task **assigned to exactly one Agent**
- [ ] **Blockers documented** in `notes` field
- [ ] No circular dependencies (T-A depends on T-B, T-B depends on T-A)
- [ ] Feature-level acceptance criteria written and linked to task verification
- [ ] Code owner identified (who will review this task's PR?)

---

## WBS Governance

| Phase | Responsibility | Gate |
|-------|---|---|
| **Drafting** | Architect + PM | None (pre-Plan Gate) |
| **Sizing & Assignment** | Architect + Agent Leads | Plan Gate: sizes approved |
| **Execution** | Agents (parallel) | Build Gate: all tasks ≥ In Progress or Completed |
| **Verification** | QA + Code Reviewers | Gate 2/Gate 3: all tasks Completed + verified |
| **Updates** | Architect (CIA required) | Any change to Baselined WBS needs Change Impact Assessment |

---

## Tips for AI Agents

1. **Keep tasks atomic**: Each task should compile/run independently if possible
2. **Document assumptions**: If your task assumes another task's API exists, list it in `depends_on`
3. **Verification is non-negotiable**: Don't mark complete without checking every step
4. **Ask for help early**: If a task looks L/XL, ping Architect before starting
5. **Link to ADRs**: If task involves tech choice, reference the ADR in `notes`

---

## Template Version History

| Version | Date | Change | Author |
|---------|------|--------|--------|
| V4.0 | 2026-03-31 | Initial V4 template with 3-level hierarchy and Agent-oriented sizing | Architect |
