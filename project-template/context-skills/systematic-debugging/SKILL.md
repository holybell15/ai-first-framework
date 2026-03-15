---
name: systematic-debugging
description: >
  **Use this skill whenever something isn't working as expected — your code, or code you're reviewing.**

  Triggered by: "This function doesn't work", "why is this error happening", "這個一直掛", "API keeps returning 500",
  "测试突然失败了", "我不知道為什麼壞了", or when test output shows non-zero exit codes, unexpected behavior, or
  "it worked yesterday but not today" scenarios. Even if the user doesn't use the word "debug", this is the skill for it.

  This skill prevents the thrashing cycle of "try fix → fail → try different fix → fail → luck out". Root cause first.

source: obra/superpowers (adapted for AI-First workflow)
---

# Systematic Debugging Skill: Root Cause Before Fix

## Why Use This?
- **Prevents thrashing**: Guessing at fixes costs 5× longer than finding the real issue
- **Stops recurring bugs**: Most "fixed" bugs come back because you fixed the symptom, not the cause
- **Saves test writing**: Once you know root cause, you write the right regression test
- **Protects team trust**: Code with unknown bugs is a liability; code with known causes can be defended

**Golden Rule: No fix without root cause verification. If you've tried 3 times, you don't understand the problem yet.**

---

## Phase 1 — Observe & Reproduce (Understand the Symptom)

**Goal**: Distinguish symptom from cause. "The API returns 500" is a symptom; "database connection pool is exhausted" is the cause.

**Step 1a: Describe Exact Behavior**
```
SYMPTOM: User clicks "submit", button shows loading spinner for 5s then disappears
EXPECTED: Button shows success checkmark, form data cleared
ACTUAL: Button spinner disappears, form data still there, no success message
```

NOT good enough: "The form doesn't work"

**Step 1b: Minimum Repro Steps** (can you trigger it consistently?)
```
1. Open form at /checkout
2. Fill email field
3. Leave phone field empty
4. Click Submit
5. Wait 5s → observe: spinner disappears, error not shown
```

If **not reproducible**:
- Don't guess. Add logging:
  - `console.log('form submitted with:', formData)`
  - `console.log('API response:', response)`
  - Check browser Network tab for actual XHR response
- Run with detailed logs and wait for failure
- Only theorize once you have data

**Step 1c: Collect Evidence** (stack trace, logs, environment)
```
Environment:
- Node 18.x, npm 9.5.0
- React 18.2, Browser: Chrome 125
- Database: PostgreSQL 14, pool size 10

Complete Error Stack:
```
Error: ECONNREFUSED 127.0.0.1:5432
  at Client._connect (/app/node_modules/pg/lib/client.js:123:45)
  at async Server.route.post (/app/src/routes/checkout.js:42:15)
```

Log snippet:
```
[2026-03-15 14:22:10] POST /api/checkout
[2026-03-15 14:22:11] DB query started
[2026-03-15 14:22:15] ERROR: connect ECONNREFUSED
```

**Step 1d: Handoff Summary**
```
❌ BEFORE: "The checkout API is broken"
✅ AFTER: "Checkout form submits → backend returns 500 on DB.query() →
          ECONNREFUSED on port 5432 → suggests DB connection pool issue,
          reproducible 100% with empty phone field."
```

---

## Phase 2 — Hypothesize & Verify (Find Root Cause)

**Goal**: Generate hypotheses in priority order, then test each. Stop when one is confirmed.

**Step 2a: List ≤3 Hypotheses** (ranked by likelihood)

```
H1: Database connection pool exhausted (HIGH likelihood because:
    - Error is ECONNREFUSED on port 5432
    - Happens after waiting 5s (timeout signature)
    - No connection timeout logs visible)

H2: Malformed DB query due to empty phone field (MEDIUM likelihood because:
    - Form validation allows empty phone
    - Query might expect phone NOT NULL)

H3: Environment variable DB_HOST points to wrong server (LOW likelihood because:
    - Other endpoints work fine
    - Would affect all requests, not just /checkout)
```

**Step 2b: Design One Test Per Hypothesis**

```
H1 Test: Add logging to connection pool
  → Code: console.log(pool.availableObjectsCount) before query
  → Expected if H1 true: logs show 0 available
  → Expected if H1 false: logs show 5+ available

H2 Test: Check query string for NULL constraints
  → Code: console.log('INSERT INTO orders (email, phone) VALUES ($1, $2)', email, phone)
  → Expected if H2 true: see phone = null/undefined in log
  → Expected if H2 false: query looks valid

H3 Test: Check DB_HOST env var
  → Code: console.log('Connecting to DB:', process.env.DB_HOST)
  → Expected if H3 true: see wrong host (e.g., wrong IP)
  → Expected if H3 false: see correct local or production host
```

**Step 2c: Run Tests in Order**

```
H1 Test Result: ✅ CONFIRMED
  pool.availableObjectsCount = 0 every time error occurs
  Pool is misconfigured to size=0 or leak not releasing connections

New Discovery: Found in src/db.js:42
  const pool = new Pool({ max: 0 }) ← SHOULD BE 10!
```

**Stop here.** You found root cause. Don't test H2/H3 (waste of time).

---

## Phase 3 — Repair & Validate (Fix With Confidence)

**Goal**: Make minimal fix, verify it solves the problem, check for siblings.

**Step 3a: Make Minimal Fix**

```javascript
// BEFORE (src/db.js:42)
const pool = new Pool({ max: 0 })

// AFTER
const pool = new Pool({ max: 10 })
```

NOT: "Let me refactor the entire connection pooling" — that's a separate task.

**Step 3b: Verify Bug Is Gone**

```
1. Restart server (necessary if connection state is held)
2. Repro steps: Click submit → observe: ✅ form now succeeds
3. Check logs: pool.availableObjectsCount = 9 after query (1 in use, 9 available)
```

**Step 3c: Defense in Depth** (search for siblings)

Ask: "What other files might have `new Pool({ max: 0 })`?"

```bash
grep -r "new Pool" src/
# Found:
# src/db.js:42 ← ALREADY FIXED
# tests/unit/db.test.js:15 ← Also has max: 0 (test fixture, intentional? CHECK)
# src/workers/queue.js:8 ← Also has max: 0 (DEFECT!)
```

Fix src/workers/queue.js too before moving on.

**Step 3d: Run Test Suite**

```bash
npm test
# ✅ All 156 tests pass
# ✅ No new failures introduced
```

**Step 3e: Commit With Root Cause In Message**

```bash
git commit -m "fix: restore database connection pool size to 10

Root cause: Pool({ max: 0 }) was set in src/db.js, rendering connection pool
completely disabled. Bug manifests as ECONNREFUSED on any query after the
first in-flight request fills the exhausted pool.

Also fixed src/workers/queue.js which had same misconfiguration.

Regression test: See tests/integration/checkout-flow.test.js line 22
(verifies pool size > 0 at startup).
"

git commit -m "test: add regression test for zero-size connection pool

Catch future incidents where Pool({ max: 0 }) silently disables connections.
Test checks pool.options.max > 0 at server startup."
```

---

## Phase 4 — Review & Document (Prevent Recurrence)

**Step 4a: Why Did This Slip?**

```
Q: How did max: 0 get committed?
A: Found in code review: no one checked Pool options at startup
   Suggestion: Add 'poolConfig validation' to deployment checklist

Q: Why no test caught this?
A: Integration tests didn't mock pool failures
   Suggestion: Add test that verifies pool is initialized with size > 0
```

**Step 4b: Update Living Documentation**

If root cause points to a broader pattern:

| File | Why | What to Update |
|------|-----|--------|
| `03_System_Design/F##-DB.md` | Pool config is architectural | Add section: "Connection Pool: minimum size 10 in production" |
| `memory/knowledge_base/db-best-practices.md` | Prevent future devs from same mistake | Add: "Always verify Pool({ max: N }) where N > 0; max: 0 disables pooling" |
| Test suite | Prevent regression | Add startup health check: `assert(pool.options.max > 0)` |

**Step 4c: Open Tech Debt If Systemic**

If this is a sign of larger issues:
```markdown
### TECH_DEBT-N: Connection Pool Configuration Not Validated

- **Severity**: High (silently disables DB)
- **Impact**: Any mistaken Pool({ max: 0 }) breaks app without clear error
- **Fix**: Implement startup health checks (pool, Redis, message queue)
- **Effort**: 4h
- **Owner**: Backend lead to review by next sprint
```

---

## Common Failure Modes

| Anti-Pattern | Why It Fails | Fix |
|--------------|-------------|-----|
| "See error → change code" | 90% of first guesses are wrong | Slow down; run Phase 1 first |
| "I tried 3 fixes, none worked" | You're treating symptoms, not cause | Go back to Phase 1; add logs |
| "The fix works locally but fails CI" | Unvetted env difference | Phase 1 includes *environment*; verify CI env matches |
| "Fixed bug, no regression test" | Bug will come back in 2 months | Write regression test before closing issue |
| "Can't reproduce" → "Must be Heisenbug" | Lazy diagnostics | Add logging; run against production data; wait longer |
| "That's not my module" (ignore sister bugs) | Bugs hide in clusters | Always Phase 3c: search for siblings |

---

## GSD Integration

After confirming root cause and fix:

- **§36 Auto-Fix Loop (AFL)**: If Phase 4 Verify fails 3+ times, you haven't found root cause yet — consult AFL for systematic retrace
- **§34 LPC**: If bug required >1h to debug, check if ARCH.md was unclear about this component
- **§38 STATE.md**: Update if this is blocking Agent work: "DB pool bug fixed (ADR-N), Backend can resume /checkout endpoint"

---

## Before Closing the Issue

- [ ] Symptom vs. cause clearly documented
- [ ] Root cause verified with test (not guessed)
- [ ] Fix is minimal, not refactoring
- [ ] Bug no longer reproduces with exact repro steps
- [ ] Related code searched for similar bugs (Phase 3c)
- [ ] Full test suite passes (no new failures)
- [ ] Regression test written and passing
- [ ] Commit message includes root cause explanation
- [ ] If systemic, TECH_DEBT or ARCH.md updated
- [ ] Team notified if fix affects deployment / configuration
