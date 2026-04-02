---
name: info-canary
description: >
  部署後持續健康監控，抓到 smoke test 漏掉的回歸問題。

  遇到「部署後監控」、「canary」、「info-canary」、「上線後檢查」、「持續監控」
  或 P06 部署完成後自動觸發。

  **為什麼？** Smoke test 只跑一次，但有些問題需要時間才會浮現：
  記憶體洩漏、連接池耗盡、快取失效、非同步 job 失敗。
  Canary 持續監控 N 分鐘，用 baseline 對比而非絕對閾值，抓住這些隱性回歸。

  靈感來源：gstack /canary — baseline-relative monitoring + transient filtering

  **Pipeline 整合**：P06 部署 + smoke test 通過後，自動觸發 5-10 分鐘 canary。
---

# info-canary Skill：部署後持續健康監控

## 核心原則：Baseline 對比，不用絕對閾值

每個應用的「正常」不同。不設「LCP 必須 < 2s」這種絕對標準，
而是拿**部署前的快照**當 baseline，監控**變化量**。

```
部署前（baseline）：LCP = 1.8s, Console Error = 0, Bundle = 420KB
部署後（canary）：  LCP = 2.4s, Console Error = 3, Bundle = 480KB
                    ↑ +33%      ↑ 新增        ↑ +14%
```

---

## 執行流程

### Step 1 — Baseline 快照（部署前）

在部署指令執行前，自動收集 baseline：

```bash
# Playwright baseline 收集
npx playwright test tests/canary/baseline.spec.ts
```

```typescript
// tests/canary/baseline.spec.ts
import { test } from "@playwright/test";

test("capture baseline", async ({ page }) => {
  const pages = ["/", "/dashboard", "/login"];
  const baseline = {};

  for (const url of pages) {
    await page.goto(`${process.env.APP_URL}${url}`);
    await page.waitForLoadState("networkidle");

    baseline[url] = {
      screenshot: await page.screenshot({ fullPage: true }),
      consoleErrors: [],
      performance: await page.evaluate(() => {
        const nav = performance.getEntriesByType("navigation")[0];
        return {
          ttfb: nav.responseStart - nav.requestStart,
          fcp: performance.getEntriesByName("first-contentful-paint")[0]?.startTime,
          lcp: performance.getEntriesByType("largest-contentful-paint").pop()?.startTime,
          domComplete: nav.domComplete,
        };
      }),
      resourceCount: await page.evaluate(() => performance.getEntriesByType("resource").length),
    };
  }

  // 儲存 baseline
  require("fs").writeFileSync(
    "test-results/canary-baseline.json",
    JSON.stringify(baseline, null, 2)
  );
});
```

### Step 2 — 部署

正常執行 P06 部署流程。

### Step 3 — Canary 監控（部署後）

```
╔═══════════════════════════════════════════╗
║  🐦 Canary Monitor — 啟動                ║
║  監控時長：10 分鐘                         ║
║  檢查間隔：60 秒                           ║
║  監控頁面：/ , /dashboard , /login         ║
╚═══════════════════════════════════════════╝
```

每 60 秒執行一次健康檢查：

```typescript
// tests/canary/monitor.spec.ts
async function canaryCheck(page, url, baseline) {
  await page.goto(url);
  await page.waitForLoadState("networkidle");

  const current = {
    consoleErrors: [], // 收集 console.error
    performance: await page.evaluate(() => { /* 同 baseline */ }),
    screenshot: await page.screenshot({ fullPage: true }),
    timestamp: new Date().toISOString(),
  };

  // 對比 baseline
  const issues = [];

  // Performance 回歸（> 20% 惡化）
  if (current.performance.lcp > baseline.performance.lcp * 1.2) {
    issues.push({
      severity: "HIGH",
      type: "PERFORMANCE",
      detail: `LCP 惡化 ${Math.round((current.performance.lcp / baseline.performance.lcp - 1) * 100)}%`,
    });
  }

  // 新增 Console Error
  if (current.consoleErrors.length > baseline.consoleErrors.length) {
    issues.push({
      severity: "CRITICAL",
      type: "CONSOLE_ERROR",
      detail: `新增 ${current.consoleErrors.length - baseline.consoleErrors.length} 個 console error`,
    });
  }

  return { url, issues, timestamp: current.timestamp };
}
```

### Step 4 — 暫態過濾（Transient Filtering）

> 問題必須連續 2 次檢查都出現才算真正的問題。一次性的波動不報警。

```
Check 1 (T+60s):  LCP +30% → 🟡 疑似問題，等待確認
Check 2 (T+120s): LCP +28% → 🔴 確認為持續性問題，報告
Check 3 (T+180s): Console Error 1 → 🟡 疑似
Check 4 (T+240s): Console Error 0 → ✅ 暫態，自動忽略
```

### Step 5 — 即時報告

每 60 秒更新監控面板：

```
🐦 Canary Monitor — T+5:00 / 10:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Page: /
  Performance:  ✅ LCP 1.9s (+5% vs baseline)
  Console:      ✅ 0 errors
  Visual:       ✅ Screenshot match 98%

Page: /dashboard
  Performance:  🔴 LCP 3.2s (+78% vs baseline)  ← 連續 3 次
  Console:      🔴 2 new errors (TypeError, NetworkError)
  Visual:       🟡 Screenshot diff 15%

Page: /login
  Performance:  ✅ LCP 0.8s (-2% vs baseline)
  Console:      ✅ 0 errors
  Visual:       ✅ Screenshot match 99%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall: 🔴 2 persistent issues found
Action: 建議 rollback 或調查 /dashboard 回歸
```

### Step 6 — 自動決策

| 狀態 | 條件 | 行為 |
|------|------|------|
| 🟢 All Clear | 全部頁面無持續性問題 | 結束監控，標記部署成功 |
| 🟡 Warning | 有 MEDIUM 級問題但無 CRITICAL | 繼續監控，延長 5 分鐘觀察 |
| 🔴 Alert | 有 CRITICAL 或 HIGH 持續問題 | 停止監控，提出 rollback 建議 |

---

## Severity 判定

| 類型 | Baseline Δ | Severity |
|------|-----------|----------|
| Performance | LCP +50%+ | CRITICAL |
| Performance | LCP +20-50% | HIGH |
| Performance | LCP +10-20% | MEDIUM |
| Console Error | 新增 error | CRITICAL |
| Console Warning | 新增 warning | LOW |
| Visual | Screenshot diff > 30% | HIGH |
| Visual | Screenshot diff 10-30% | MEDIUM |
| HTTP | 新增 4xx/5xx | CRITICAL |
| Resource | Bundle size +20%+ | HIGH |

---

## 產出

```
08_Test_Reports/F##-canary-report.md
08_Test_Reports/F##-canary-screenshots/
  ├── baseline/           ← 部署前快照
  ├── canary-T060/        ← T+60s 快照
  ├── canary-T120/        ← T+120s 快照
  └── diff/               ← 差異高亮截圖
```

---

## Pipeline 整合

| 時機 | 行為 |
|------|------|
| P06 smoke test 通過後 | 自動觸發 canary（預設 10 分鐘） |
| Hotfix 部署後 | 自動觸發 canary（預設 5 分鐘） |
| 手動 | `info-canary` 或 `部署後監控` |

### 與其他 Skill 的關係

```
P06 部署 → smoke test ✅
  ↓
info-canary（10 min baseline 對比監控）
  ↓ 🟢 All Clear
info-doc-sync（文件同步）→ retro L2（量化回顧）
  ↓ 🔴 Alert
提出 rollback 建議 → DevOps Agent 執行 rollback
```

---

## 配置

在 `conductor.json` 或 `memory/product.md` 設定：

```json
{
  "canary": {
    "duration_minutes": 10,
    "check_interval_seconds": 60,
    "pages": ["/", "/dashboard", "/login"],
    "performance_threshold_pct": 20,
    "screenshot_diff_threshold_pct": 15,
    "transient_filter_count": 2
  }
}
```
