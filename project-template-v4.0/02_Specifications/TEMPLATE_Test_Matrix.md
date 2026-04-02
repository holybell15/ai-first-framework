# Test Matrix — V4 AI-First Framework

**Version**: V4.0 | **Last Updated**: 2026-03-31 | **Governance**: Gate-linked

---

## Overview

The **Test Matrix** is a **feature × test level** grid that defines:
- What gets tested at each level (Unit, Integration, E2E, Security, Smoke)
- Minimum coverage targets and pass/fail criteria
- Tools, ownership, and timing per level
- Gate requirements (Plan, Build, Ship)

This ensures **no feature ships** without appropriate testing across all 5 levels.

---

## Test Pyramid: Levels, Targets & Ownership

```
                  ▲
                 ╱│╲
                ╱ │ ╲
               ╱  │  ╲  L5: Smoke Tests
              ╱   │   ╲  DevOps/QA | 5–10 happy paths | 1–2 hours
             ╱ ╱──┼──╲ ╲
            ╱ ╱   │   ╲ ╲ L4: Security Tests
           ╱╱     │     ╲╲ Security/QA | OWASP + STRIDE | 4–8 hours
          ╱──────────────╲ L3: E2E Tests
         │ QA + Playwright│ Critical journeys | 2–4 hours
         │  ≥ Critical    │
         ╱────────────────╲
        │ L2: Integration │
        │  Backend/DBA    │
        │ ≥ 60–80% happy  │
        │   + error paths │
        ╱──────────────────╲
       │  L1: Unit Tests   │
       │ Backend/Frontend  │
       │  ≥ 80% coverage   │
       │  (methods, logic) │
       └──────────────────┘
```

### L1: Unit Tests

| Attribute | Details |
|-----------|---------|
| **Scope** | Individual functions/methods, pure logic |
| **Target Coverage** | Backend: ≥80% | Frontend: ≥75% |
| **Owner** | Backend Engineer + Frontend Engineer |
| **Tools** | Jest, Vitest (frontend); Jest, Pytest (backend) |
| **Time per Feature** | S: 30 min | M: 1–1.5 hrs | L: 2–3 hrs |
| **What's Tested** | Input validation, business logic, edge cases (null, empty, boundary values), error paths |
| **What's NOT Tested** | Database queries, HTTP calls, UI rendering (those are L2/L3) |
| **Pass Criteria** | All tests pass, coverage ≥ target, no skipped tests |

**Example (Node.js/Jest)**:
```javascript
// auth.service.test.ts
describe("AuthService.validateEmail", () => {
  it("should accept valid email", () => {
    expect(validateEmail("user@example.com")).toBe(true);
  });

  it("should reject invalid email", () => {
    expect(validateEmail("not-an-email")).toBe(false);
  });

  it("should handle null input", () => {
    expect(validateEmail(null)).toBe(false);
  });
});

describe("AuthService.hashPassword", () => {
  it("should return different hash for same password", async () => {
    const pwd = "password123";
    const hash1 = await hashPassword(pwd);
    const hash2 = await hashPassword(pwd);
    expect(hash1).not.toBe(hash2); // salted
  });
});
```

**Example (Vue/Vitest)**:
```javascript
// LoginForm.test.ts
import { mount } from "@vue/test-utils";
import LoginForm from "@/components/auth/LoginForm.vue";

describe("LoginForm", () => {
  it("should disable submit button when email is empty", async () => {
    const wrapper = mount(LoginForm);
    const submitBtn = wrapper.find("button[type='submit']");
    expect(submitBtn.attributes("disabled")).toBe("");
  });

  it("should show error message on invalid email", async () => {
    const wrapper = mount(LoginForm);
    const emailInput = wrapper.find("input[type='email']");
    await emailInput.setValue("not-an-email");
    expect(wrapper.text()).toContain("Invalid email");
  });
});
```

---

### L2: Integration Tests

| Attribute | Details |
|-----------|---------|
| **Scope** | Multiple modules working together (API → Service → DB) |
| **Target Coverage** | Happy paths: ✓ | Error paths: ✓ (at least main errors) |
| **Owner** | Backend Engineer + DBA |
| **Tools** | Jest + Supertest (Node.js); Pytest + pytest-mock; testcontainers (DB in Docker) |
| **Time per Feature** | S: 30 min | M: 1–1.5 hrs | L: 2–3 hrs |
| **What's Tested** | API endpoint → service logic → database; transaction rollback; cache invalidation; job queue enqueuing |
| **What's NOT Tested** | Frontend interactions, security (see L4), cross-service communication over network |
| **Pass Criteria** | All happy-path tests pass; all critical error paths tested; no database state leaks between tests |

**Example (Node.js/Jest + Supertest)**:
```javascript
// auth.integration.test.ts
import request from "supertest";
import app from "@/app";
import db from "@/db";

describe("POST /api/auth/register (Integration)", () => {
  beforeEach(async () => {
    // Clear users table before each test
    await db.query("TRUNCATE TABLE users CASCADE");
  });

  it("should register new user and return JWT token", async () => {
    const res = await request(app)
      .post("/api/auth/register")
      .send({ email: "test@example.com", password: "password123" });

    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.email).toBe("test@example.com");

    // Verify user in database
    const user = await db.query(
      "SELECT * FROM users WHERE email = ?",
      ["test@example.com"]
    );
    expect(user).toHaveLength(1);
    expect(user[0].password_hash).not.toBe("password123"); // hashed
  });

  it("should reject duplicate email with 409 Conflict", async () => {
    // Insert first user
    await db.query(
      "INSERT INTO users (email, password_hash) VALUES (?, ?)",
      ["existing@example.com", "somehash"]
    );

    // Try to register same email
    const res = await request(app)
      .post("/api/auth/register")
      .send({ email: "existing@example.com", password: "password123" });

    expect(res.status).toBe(409);
    expect(res.body.error_code).toBe("EMAIL_ALREADY_REGISTERED");
  });

  it("should handle database connection failure gracefully", async () => {
    jest.spyOn(db, "query").mockRejectedValueOnce(new Error("DB connection lost"));

    const res = await request(app)
      .post("/api/auth/register")
      .send({ email: "test@example.com", password: "password123" });

    expect(res.status).toBe(500);
    expect(res.body.error_code).toBe("INTERNAL_SERVER_ERROR");
  });
});
```

---

### L3: End-to-End (E2E) Tests

| Attribute | Details |
|-----------|---------|
| **Scope** | Full user journey from browser to database and back |
| **Target Coverage** | All critical/happy paths; key error scenarios |
| **Owner** | QA Engineer |
| **Tools** | Playwright, Cypress, Selenium; runs against staging env |
| **Time per Feature** | S: 20 min | M: 45 min | L: 1.5–2 hrs |
| **What's Tested** | User clicks form → submits → API call → DB update → page re-renders; navigation flows; state persistence |
| **What's NOT Tested** | Performance/load (see L5); security vulnerabilities (see L4) |
| **Pass Criteria** | All critical journeys pass on staging env; no timeouts or flakes (< 1% flake rate) |

**Example (Playwright)**:
```typescript
// auth.e2e.spec.ts
import { test, expect } from "@playwright/test";

test.describe("User Registration & Login E2E", () => {
  test.beforeEach(async ({ page }) => {
    // Reset database before each test
    await fetch("http://localhost:3000/api/test/reset", { method: "POST" });
    await page.goto("http://localhost:5173/register");
  });

  test("should register new user, login, and view dashboard", async ({ page }) => {
    // Step 1: Register
    await page.fill("input[name='email']", "newuser@example.com");
    await page.fill("input[name='password']", "SecurePass123!");
    await page.click("button:has-text('Register')");

    // Verify: token in localStorage, redirect to dashboard
    await expect(page).toHaveURL(/\/dashboard/);
    const token = await page.evaluate(() =>
      localStorage.getItem("auth_token")
    );
    expect(token).toBeTruthy();

    // Step 2: Verify user profile displayed
    await expect(page.locator("text=newuser@example.com")).toBeVisible();
  });

  test("should show error when registering with duplicate email", async ({
    page,
    request,
  }) => {
    // Pre-populate database with a user
    await request.post("http://localhost:3000/api/test/seed", {
      data: { email: "existing@example.com", password: "pass123" },
    });

    // Try to register same email
    await page.fill("input[name='email']", "existing@example.com");
    await page.fill("input[name='password']", "password123");
    await page.click("button:has-text('Register')");

    // Verify error message
    await expect(
      page.locator("text=Email already registered")
    ).toBeVisible();
    await expect(page).not.toHaveURL(/\/dashboard/);
  });

  test("should persist session across page reload", async ({ page }) => {
    // Register and login
    await page.fill("input[name='email']", "user@example.com");
    await page.fill("input[name='password']", "SecurePass123!");
    await page.click("button:has-text('Register')");
    await expect(page).toHaveURL(/\/dashboard/);

    // Reload page
    await page.reload();

    // Verify: still on dashboard (session persisted)
    await expect(page).toHaveURL(/\/dashboard/);
    await expect(page.locator("text=user@example.com")).toBeVisible();
  });

  test("should logout and clear token", async ({ page }) => {
    // Login flow
    await page.goto("http://localhost:5173/login");
    await page.fill("input[name='email']", "existing@example.com");
    await page.fill("input[name='password']", "pass123");
    await page.click("button:has-text('Login')");
    await expect(page).toHaveURL(/\/dashboard/);

    // Logout
    await page.click("button:has-text('Logout')");

    // Verify: redirected to login, token cleared
    await expect(page).toHaveURL(/\/login/);
    const token = await page.evaluate(() =>
      localStorage.getItem("auth_token")
    );
    expect(token).toBeNull();
  });
});
```

---

### L4: Security Tests

| Attribute | Details |
|-----------|---------|
| **Scope** | Vulnerability scanning, attack simulation, compliance checks |
| **Target Coverage** | OWASP Top 10; STRIDE threat model; industry compliance (SOC2, GDPR, etc.) |
| **Owner** | Security Engineer + QA |
| **Tools** | OWASP ZAP, Burp Suite, SonarQube (SAST), Trivy (dependency scanning), custom penetration tests |
| **Time per Feature** | Security-sensitive (auth, payment): 2–4 hrs | Others: 30 min |
| **What's Tested** | SQL injection, XSS, CSRF, rate limiting, authentication bypass, authorization flaws, password strength, data leakage |
| **Pass Criteria** | No high-severity vulnerabilities; OWASP ZAP scan passes; secrets scanning clean (no API keys in code) |

**Example (Security Checklist)**:
```markdown
## L4 Security Tests — User Auth Feature

### OWASP Top 10 Checks
- [ ] **A01:2021 – Broken Access Control**: Test auth bypass, privilege escalation
  - Can unauthenticated user access /api/me? → Should 401
  - Can user access another user's profile? → Should 403
- [ ] **A02:2021 – Cryptographic Failures**: Password hashing, data encryption
  - Password hashed with bcrypt (cost ≥ 10)? → Check DB
  - Sensitive data over HTTPS? → Check all endpoints
- [ ] **A03:2021 – Injection**: SQL injection, command injection
  - Can attacker inject SQL via email field? → Test email = "' OR '1'='1"
  - Are all queries parameterized? → Code review
- [ ] **A07:2021 – Cross-Site Scripting (XSS)**: User input sanitization
  - Can attacker inject <script> in full_name field? → Test and verify CSP headers
- [ ] **A09:2021 – Using Components with Known Vulnerabilities**
  - npm audit clean? → Run `npm audit` pre-ship

### STRIDE Threat Model
- [ ] **Spoofing**: Can attacker forge JWT token? → Validate signature
- [ ] **Tampering**: Can attacker modify email in token? → Verify immutability
- [ ] **Repudiation**: Are login attempts logged? → Check audit logs
- [ ] **Information Disclosure**: Are error messages too verbose? → Check for info leakage
- [ ] **Denial of Service**: Rate limiting on /api/auth/login? → Test 1000 requests/sec
- [ ] **Elevation of Privilege**: Can regular user become admin? → Test JWT scope claims

### Compliance Checks
- [ ] GDPR: User can export/delete personal data? → Endpoints exist
- [ ] SOC2: Password reset flow uses time-limited tokens? → Validate token expiry
- [ ] Industry: PCI-DSS if handling payments (not applicable for this feature)

### Test Results
- OWASP ZAP scan: **PASS** (no high/medium findings)
- SonarQube: **PASS** (no security hotspots)
- npm audit: **PASS** (0 vulnerabilities)
- Penetration test: **PASS** (no privilege escalation found)
```

---

### L5: Smoke Tests

| Attribute | Details |
|-----------|---------|
| **Scope** | Quick validation that core paths work after deployment |
| **Target Coverage** | 5–10 happy-path scenarios per feature |
| **Owner** | DevOps / QA |
| **Tools** | Custom shell scripts, simple HTTP requests, or lightweight test framework |
| **Time per Feature** | S: 5 min | M: 10 min | L: 15 min |
| **What's Tested** | Can user login? Can API return data? Is database reachable? |
| **What's NOT Tested** | Edge cases, error handling (tested in L1–L3) |
| **Pass Criteria** | All smoke tests pass within 5 minutes; no 5xx errors |

**Example (Shell Script)**:
```bash
#!/bin/bash
# smoke-test.sh

BASE_URL="https://api.example.com"
EMAIL="smoketest@example.com"
PASSWORD="SmokeTest123!"

echo "Running smoke tests..."

# Health check
echo "1. Health check..."
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
[ "$HEALTH" -eq 200 ] && echo "✓ Health check passed" || exit 1

# Register user
echo "2. Register user..."
REGISTER=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")
TOKEN=$(echo "$REGISTER" | jq -r '.token')
[ -n "$TOKEN" ] && echo "✓ User registered, token received" || exit 1

# Access protected route
echo "3. Access protected route..."
ME=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/me")
USER_EMAIL=$(echo "$ME" | jq -r '.email')
[ "$USER_EMAIL" = "$EMAIL" ] && echo "✓ Protected route accessible" || exit 1

# Get posts (empty list)
echo "4. Fetch posts..."
POSTS=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/api/posts")
COUNT=$(echo "$POSTS" | jq '.length')
[ "$COUNT" -ge 0 ] && echo "✓ Posts endpoint working" || exit 1

echo "All smoke tests passed!"
```

---

## Test Matrix: Features × Levels

### Instructions
1. **Copy this table** to your project
2. **Fill in each cell** with:
   - ✓ = Tests planned/written
   - — = Not applicable (explain why)
   - ✗ = Tests needed but not written (flag as blocker)
3. **Update coverage %** after each run
4. **Gate requirements** (see below) control promotion

### Template

| Feature | L1 Unit (Target: ≥80%) | L2 Integration | L3 E2E (Critical Paths) | L4 Security | L5 Smoke | Owner | Status |
|---------|---|---|---|---|---|---|---|
| **User Auth** | ✓ 82% | ✓ (register, login, errors) | ✓ (register → login → protected) | ✓ (auth bypass, injection, rate limit) | ✓ (register, login, access /me) | Backend/Frontend/QA | In Progress |
| **Create Post** | ✓ 75% | ✓ (API → DB, cache) | ✓ (form → submit → list) | — (no secrets) | ✓ (create, list) | Backend/Frontend | Pending |
| **Search Posts** | ✓ 78% | ✓ (full-text search) | ✓ (keyword → results) | — | ✓ (search, pagination) | Backend/Frontend | Pending |
| **User Profile** | ✓ 71% | ✓ (get, update) | ✓ (edit → save → display) | ✓ (authorization, data leak) | ✓ (get profile, update) | Frontend/QA | Not Started |
| **Logout** | ✓ 90% | ✓ (token revocation) | ✓ (logout → redirected) | — | ✓ (logout clears session) | Backend/Frontend | Completed |

---

## Gate Requirements

### Plan Gate (Before Development)
**Requirement**: Test Matrix exists and targets are defined.

- [ ] Test Matrix has all features listed
- [ ] Coverage targets per level are **realistic** (not arbitrary)
- [ ] Tools chosen for each level
- [ ] Ownership assigned (who writes tests?)
- [ ] Timeline for each feature's L1/L2/L3 tests mapped to sprints

**Gate Action**:
- **PASS**: Proceed to Build
- **FAIL**: Add test strategy to WBS before Architect approval

---

### Build Gate (After P03/P04 Development)
**Requirement**: L1 (Unit) + L2 (Integration) tests passing.

- [ ] L1: All unit tests pass, coverage ≥ 80% (backend) / 75% (frontend)
- [ ] L2: All integration tests pass; database state clean between tests
- [ ] No **skipped tests** (skip tests = hidden debt)
- [ ] Code coverage tracked (publish to Codecov or similar)

**Gate Action**:
- **PASS**: Code review + merge to main
- **FAIL**: Fix failing tests; coverage too low → revise feature scope

---

### Ship Gate (Before Production Deploy)
**Requirement**: L3 (E2E) + L4 (Security) + L5 (Smoke) all passing.

- [ ] L3: All critical E2E tests pass on staging; flake rate < 1%
- [ ] L4: OWASP ZAP scan clean (no high-severity findings); security review passed
- [ ] L5: All smoke tests pass (< 5 min); health checks green
- [ ] No known bugs in production hotlist
- [ ] Deployment runbook tested (DevOps can execute without errors)

**Gate Action**:
- **PASS**: Deploy to production
- **FAIL**: Hold release; fix blockers and re-test

---

## Bug Fix Rule

**Every bug fix MUST include a regression test.**

When a bug is reported:

1. **Investigate**: Root cause analysis (RCA)
2. **Write failing test**: Reproduce bug in test before fixing code
3. **Fix code**: Make test pass
4. **Add regression test**: Prevent reoccurrence
5. **Document**: Link test to bug ticket

**Example**:
```markdown
## Bug: User can access another user's profile (Privilege Escalation)

### Regression Test (L2 Integration)
```javascript
it("should return 403 Forbidden when accessing another user's profile", async () => {
  // User A's token
  const userA = await createTestUser("a@example.com");
  const tokenA = await loginAndGetToken("a@example.com", "password");

  // User B's ID
  const userB = await createTestUser("b@example.com");
  const userBId = userB.id;

  // User A tries to GET /api/users/:id where id = User B's ID
  const res = await request(app)
    .get(`/api/users/${userBId}`)
    .set("Authorization", `Bearer ${tokenA}`);

  expect(res.status).toBe(403); // Not 200!
  expect(res.body.error_code).toBe("UNAUTHORIZED_ACCESS");
});
```

### Fix
```typescript
// Check authorization in controller
async getUser(req: Request, res: Response) {
  const requestedUserId = req.params.id;
  const currentUserId = req.user.id; // From JWT

  if (requestedUserId !== currentUserId) {
    return res.status(403).json({
      error_code: "UNAUTHORIZED_ACCESS",
      message: "You can only access your own profile"
    });
  }
  // ... rest of logic
}
```

### Test Result
- Regression test now passes ✓
- Bug will not reoccur (test is permanent)
```

---

## Coverage Tracking Table

**How to Use**: Update after each gate or weekly. Track progress across all features.

| Date | Feature | L1 Coverage | L2 Status | L3 Status | L4 Status | L5 Status | Notes |
|------|---------|---|---|---|---|---|---|
| 2026-04-05 | User Auth | 82% | ✓ Passing | ✓ 4/4 cases | ✓ ZAP clean | ✓ 5 tests | Ready for Ship Gate |
| 2026-04-05 | Create Post | 75% | ✓ Passing | ✓ 3/3 cases | — Not sensitive | ✓ 2 tests | Awaiting L3 flake fix |
| 2026-04-05 | Search | 78% | ✓ Passing | ⏳ In progress | — | ⏳ Pending | E2E: pagination test flaky |
| 2026-04-05 | Profile | 71% | ⏳ In progress | — | ⏳ Pending | — | Blocked: needs auth middleware |

---

## Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **Flaky E2E tests** | L3 tests fail randomly | Use explicit waits (`waitForSelector`), avoid `sleep(1000)`, use fixtures for data setup |
| **Low coverage** | L1 coverage < 70% | Audit uncovered code: is it dead code? Missing tests? If untestable, refactor |
| **Too many L4 findings** | OWASP ZAP report > 20 issues | Prioritize high-severity; false positives can be marked as such in ZAP config |
| **L2 tests slow** | Integration tests take > 5 min | Use test database (lightweight), mock external APIs, parallelize tests |
| **Smoke tests timeout** | L5 exceeds 5 min on prod | Reduce test count, focus on critical paths, scale API replicas |

---

## Template Version History

| Version | Date | Change | Author |
|---------|------|--------|--------|
| V4.0 | 2026-03-31 | V4 Test Matrix with 5 levels, gate requirements, bug fix rule, and coverage tracking | QA Lead |
