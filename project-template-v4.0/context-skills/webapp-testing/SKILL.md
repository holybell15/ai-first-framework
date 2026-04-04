---
name: webapp-testing
description: >
  自動測試 HTML Prototype 和前端元件的功能正確性。

  遇到「幫我測試這個 Prototype」、「UI 有沒有問題」、「Playwright 測試」、「自動化測試」、
  「這個按鈕功能正確嗎」或任何「測試...」的要求，就該用這個。

  **為什麼？** HTML Prototype 測試越早越多，後期 P04 改 code 時才不會一直破功能。
  Playwright 可以自動抓 UI 錯誤（數量、狀態、截圖漂移），遠快於手工點擊。

  **何時自動觸發？** QA Agent 更新 Prototype 或 P04 前端完成時；Gate 3 前會跑完整測試。
---

# Webapp Testing Skill (Playwright)

## 為什麼用 Playwright

- **快** — 一行指令全部測試，秒出報告，無需手工巡查每個狀態
- **準** — 能抓截圖漂移、元件計數錯誤、狀態轉換問題，人工肉眼容易遺漏
- **可重複** — 同一組測試跑 100 次結果相同，建立信心
- **GSD 友善** — 可與 AFL 自動修復迴圈搭配（Step 4 Verify 失敗時自動跑 Playwright，判斷修復有無破東西）

不適用場景：Prototype 只改視覺細節（顏色、padding），可用 frontend-design skill 肉眼檢查就好。

## 安裝

```bash
npm install -D @playwright/test
npx playwright install
```

## ⚠️ 執行效率鐵規（違反會讓測試從秒級變成 40 分鐘）

### 規則 1：共用登入 Session（禁止每個 test 重新登入）

```typescript
// ✅ 正確：全域 setup 登入一次，所有 test 共用
// playwright.config.ts
export default defineConfig({
  projects: [
    // 先跑 setup：登入一次，存 storageState
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
    },
    // 所有 test 使用 setup 產出的 session
    {
      name: 'e2e',
      dependencies: ['setup'],
      use: {
        storageState: '.auth/user.json',
      },
    },
  ],
})
```

```typescript
// tests/auth.setup.ts — 只跑一次
import { test as setup, expect } from '@playwright/test'

setup('login', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('帳號').fill(process.env.TEST_USER!)
  await page.getByLabel('密碼').fill(process.env.TEST_PASS!)
  await page.getByRole('button', { name: '登入' }).click()
  await expect(page).toHaveURL(/console/)
  
  // 存 session，後續所有 test 自動帶入
  await page.context().storageState({ path: '.auth/user.json' })
})
```

```typescript
// ❌ 錯誤：每個 test 都登入 → 5 個 test = 5 次登入 = 多花 2-3 分鐘
test.beforeEach(async ({ page }) => {
  await page.goto('/login')
  await page.fill('#username', 'admin')  // 每次都跑
  await page.fill('#password', 'pass')   // 每次都跑
  await page.click('button[type=submit]') // 每次都跑
})
```

### 規則 2：禁止 waitForTimeout（用 Playwright 內建等待）

```typescript
// ❌ 禁止：固定等待 = 浪費時間 + 不可靠
await page.waitForTimeout(3000)  // 等 3 秒「希望」頁面載完
await page.waitForTimeout(1000)  // 等 1 秒「希望」按鈕出現
await page.waitForTimeout(5000)  // 等 5 秒「希望」API 回來

// ✅ 正確：等具體條件滿足
await page.waitForSelector('.data-table')                        // 等元素出現
await page.waitForResponse('**/api/v1/customers')                // 等 API 回應
await expect(page.getByTestId('save-btn')).toBeEnabled()         // 等按鈕可按
await expect(page.locator('.loading')).toBeHidden()              // 等 loading 消失
await page.waitForLoadState('networkidle')                       // 等網路靜止
```

**唯一允許使用 waitForTimeout 的場景**：測試動畫或計時器行為，且必須加註解說明原因。

### 規則 3：Playwright 必須前台執行（禁止背景跑）

```bash
# ✅ 正確：前台直接執行，看到完整輸出
npx playwright test

# ✅ 正確：指定 test 檔案
npx playwright test tests/e2e/customer.spec.ts

# ❌ 禁止：丟到背景（看不到輸出、無法判斷狀態、佔用資源）
npx playwright test &
nohup npx playwright test &
```

**AI 使用 Bash 工具時**：不加 `run_in_background`，不加 `&`，直接前台跑。
如果測試太久（> 5 分鐘），拆分 test 檔案分開跑，不要用背景規避。

### 效率 Checklist（每次寫 E2E test 前過一遍）

```
□ 登入用 storageState 共用，不是 beforeEach 重複登入
□ 沒有任何 waitForTimeout（搜尋確認）
□ 所有等待都用 waitForSelector / waitForResponse / expect
□ Playwright 前台執行，不丟背景
□ 單個 test 檔案執行時間 < 30 秒（超過就拆分）
```

---

## 測試結構

```
tests/
├── auth.setup.ts  # 登入 setup（只跑一次）
├── e2e/           # 完整流程測試（跨頁面狀態轉移）
├── prototype/     # Prototype 靜態測試（單頁面元件驗證）
└── playwright.config.ts
```

## Prototype 測試範例

```typescript
import { test, expect } from "@playwright/test";

test.describe("主控台 Prototype", () => {
  test.beforeEach(async ({ page }) => {
    // 改成真實的 Prototype 路徑
    await page.goto("file:///path/to/01_Product_Prototype/dashboard.html");
  });

  test("左側工具列圖示數量正確（預期 8 個）", async ({ page }) => {
    const icons = page.locator(".tool-icon");
    await expect(icons).toHaveCount(8);
  });

  test("點擊 [新增按鈕] 後會出現 modal", async ({ page }) => {
    await page.click("button:has-text('新增')");
    const modal = page.locator(".modal");
    await expect(modal).toBeVisible();
  });

  test("截圖比對（檢查像素是否意外漂移）", async ({ page }) => {
    await expect(page).toHaveScreenshot("main-baseline.png");
  });

  test("表格有 5 列資料", async ({ page }) => {
    const rows = page.locator("table tbody tr");
    await expect(rows).toHaveCount(5);
  });
});
```

**為什麼分類？**
- `prototype/` 測試單一頁面的靜態元件（能點嗎？出現了嗎？），P02-P03 持續跑
- `e2e/` 測試跨頁面完整流程（登入 → 建立 → 確認），P04 才有完整程式碼

## 執行

```bash
# 跑所有測試
npx playwright test

# 只測試 Prototype（P02-P03 用）
npx playwright test tests/prototype/

# UI 互動模式（debug 用）
npx playwright test --ui

# 產出 HTML 報告
npx playwright show-report
```

## GSD 自動修復迴圈（AFL）整合

當 P04 實作某功能時，觸發流程如下：

1. **實作完成** → 跑 `npx playwright test` 確認沒破舊功能
2. **若失敗** → AFL 觸發 debug，找出改動的程式碼位置
3. **修復後** → 再跑一次 Playwright
4. **若通過** → 併入 commit

這樣確保新功能改動不會無意間弄壞其他功能。

## QA Agent 執行時機

| 時機 | 範圍 | 說明 |
|------|------|------|
| UX 更新 Prototype 版本 | `tests/prototype/` | 檢查互動邏輯是否正確 |
| P04 前端實作完成 | `tests/prototype/` + `tests/e2e/` | 新功能 + 迴歸測試 |
| Gate 3 交付前 | 全部 + 截圖報告 | 確保沒有遺漏 |

**你的責任**：
- 寫 Playwright test 時，測試的是「功能」，不是「美學」
- 美學用 frontend-design skill 的視覺檢查清單
- 功能包括：點擊後狀態改變、元件出現/消失、表單驗證、跨頁面狀態保留

---

## Health Score 量化健康分數

> 靈感來源：gstack /qa — 每次 QA 產出量化健康分數，追蹤品質趨勢。

每次 QA 執行完畢，產出 Health Score：

```
📊 QA Health Score: 82/100

計算方式：
  通過測試數 / 總測試數 × 70 分（功能分）
  + 無 console error × 10 分
  + 截圖比對通過 × 10 分
  + 效能指標達標（LCP < 2.5s）× 10 分

趨勢：
  上次 (v1.2): 75/100
  本次 (v1.3): 82/100  ↑ +7
```

**分數閾值**：

| 分數 | 狀態 | 處理 |
|------|------|------|
| ≥ 90 | 🟢 健康 | 可安心推進 |
| 70-89 | 🟡 待改善 | 記錄已知問題，不阻塞但追蹤 |
| < 70 | 🔴 不健康 | Gate 3 阻塞，必須修復 |

Health Score 寫入 `08_Test_Reports/F##-TR.md` 頂部，供 Gate 3 Review 參考。

---

## 8 維加權健康分數（進階）

> 靈感來源：gstack /qa — 8 個維度加權計分 + severity 扣分，比簡化版更精確。

### 計分公式

```
Health Score = Σ(維度權重 × 維度分數) - Σ(severity 扣分)
```

### 8 個維度

| # | 維度 | 權重 | 滿分條件 | 0 分條件 |
|---|------|------|---------|---------|
| 1 | Console Error | 15% | 0 個 console error/warning | ≥ 5 個 error |
| 2 | Functional | 20% | 所有功能測試通過 | 核心流程無法完成 |
| 3 | Accessibility | 15% | WCAG 2.1 AA 全通過 | 對比度/鍵盤導航失敗 |
| 4 | Visual | 10% | 截圖比對 0 差異 | 明顯 layout 破損 |
| 5 | Performance | 10% | LCP < 2.5s, CLS < 0.1 | LCP > 5s |
| 6 | Responsive | 10% | 3 個斷點（mobile/tablet/desktop）通過 | 任一斷點破版 |
| 7 | State Management | 10% | 所有狀態轉移正確 | 狀態遺失或錯亂 |
| 8 | Error Handling | 10% | 錯誤場景有適當 UI 回饋 | 無 error state 處理 |

### Severity 扣分

| 嚴重度 | 扣分 | 定義 |
|--------|------|------|
| Critical | -25 | 核心流程完全失效 |
| High | -15 | 功能失效但有替代路徑 |
| Medium | -8 | 體驗問題、非阻塞 |
| Low | -3 | 視覺微調、文字問題 |

### 計分範例

```
📊 QA Health Score: 72/100

維度明細：
  Console Error    15% × 80  = 12.0
  Functional       20% × 90  = 18.0
  Accessibility    15% × 70  = 10.5
  Visual           10% × 100 = 10.0
  Performance      10% × 85  =  8.5
  Responsive       10% × 100 = 10.0
  State Mgmt       10% × 75  =  7.5
  Error Handling   10% × 60  =  6.0
                              ──────
  小計：                       82.5

Severity 扣分：
  1 × High (-15)  = -15.0
  1 × Low  (-3)   =  -3.0
                    ──────
  扣分合計：        -10.5 (cap at -10)

最終分數：82.5 - 10 = 72.5 → 72/100 🟡
```

---

## 截圖測試報告（給人看的報告）

> 測試報告不只給機器看，更要給人看。每次 QA 產出 HTML 格式的視覺化報告。

### 截圖策略

| 測試階段 | 截圖時機 | 用途 |
|---------|---------|------|
| 測試前 | 頁面初始載入完成 | 基線截圖（baseline） |
| 操作中 | 每個關鍵互動後 | 狀態變化記錄 |
| 測試後 | 最終狀態 | 結果驗證 |
| 失敗時 | 自動截圖 | Bug 重現證據 |

### Playwright 截圖配置

```typescript
import { test, expect } from "@playwright/test";

// playwright.config.ts 中啟用截圖
// use: {
//   screenshot: 'on',           // 每個測試都截圖
//   video: 'on-first-retry',    // 失敗重試時錄影
//   trace: 'on-first-retry',    // 失敗重試時記錄 trace
// }

test("來電彈屏 — 已知客戶來電", async ({ page }) => {
  // 1. 初始狀態截圖
  await page.goto("file:///path/to/prototype.html");
  await page.screenshot({
    path: "test-results/screenshots/F02-TC01-01-initial.png",
    fullPage: true
  });

  // 2. 觸發來電事件
  await page.click('[data-testid="simulate-call"]');
  await page.waitForSelector('.call-popup');

  // 3. 彈屏出現後截圖
  await page.screenshot({
    path: "test-results/screenshots/F02-TC01-02-popup.png",
    fullPage: true
  });

  // 4. 驗證內容
  await expect(page.getByTestId('caller-name')).toBeVisible();
  await expect(page.getByTestId('caller-history')).toBeVisible();

  // 5. 最終狀態截圖
  await page.screenshot({
    path: "test-results/screenshots/F02-TC01-03-verified.png",
    fullPage: true
  });
});
```

### HTML 報告生成

```bash
# Playwright 內建 HTML 報告（含截圖、trace、影片）
npx playwright test --reporter=html

# 開啟報告
npx playwright show-report
```

### 報告輸出格式

每次 QA 完成後，產出以下結構：

```
08_Test_Reports/
├── F##-TR.md                          ← 文字測試報告（含 Health Score）
├── F##-QA-Report.html                 ← 視覺化 HTML 報告（給人看）
└── F##-screenshots/                   ← 截圖目錄
    ├── TC01-01-initial.png
    ├── TC01-02-popup.png
    ├── TC01-03-verified.png
    ├── TC02-01-initial.png
    ├── TC02-FAIL-error-state.png      ← 失敗截圖
    └── baseline/                      ← 基線截圖（用於比對）
        ├── main-baseline.png
        └── popup-baseline.png
```

### HTML 報告模板

QA Agent 在測試完成後產出 HTML 報告（`F##-QA-Report.html`），包含：

```
┌─────────────────────────────────────────────────────────┐
│  [功能名稱] QA 測試報告                                   │
│  日期：YYYY-MM-DD | Health Score: 85/100 🟢              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📊 8 維健康分數雷達圖                                    │
│     （Console / Functional / A11y / Visual / ...）        │
│                                                         │
│  📈 趨勢圖（vs 上次測試）                                 │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🧪 測試案例明細                                         │
│  ┌──────┬──────┬──────┬──────────────────────┐         │
│  │ TC-ID │ 結果  │ 耗時  │ 截圖                │         │
│  ├──────┼──────┼──────┼──────────────────────┤         │
│  │ TC-01 │ ✅    │ 1.2s │ [初始] [操作] [結果] │         │
│  │ TC-02 │ ❌    │ 0.8s │ [初始] [失敗截圖]   │         │
│  └──────┴──────┴──────┴──────────────────────┘         │
│                                                         │
│  每個截圖可點擊放大，失敗截圖高亮顯示                       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  🐛 Bug 清單（附截圖證據）                                │
│  BUG-001: [描述] — 截圖：[附圖]                          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  📋 Severity 扣分明細                                    │
│  1 × Critical(-25) + 2 × Low(-3) = -31                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Gate 3 Review 時的報告使用

Review Agent 在 Gate 3 審查時：
1. 打開 `F##-QA-Report.html` 查看視覺化測試結果
2. 檢查失敗截圖確認是否為真正的 bug（排除環境問題）
3. 確認 Health Score 趨勢是否改善
4. 8 維分數中低於 70 分的維度需要特別說明

---

## Ref 系統（元素引用）

> 靈感來源：gstack browse ref system — 用 accessibility tree 生成穩定引用，避免脆弱的 CSS selector。

### 問題

CSS selector 容易因為 class 名稱或 DOM 結構變動而失效：

```typescript
// ❌ 脆弱：class 改名就壞
page.locator('.btn-primary.submit-form');

// ❌ 脆弱：DOM 層級變動就壞
page.locator('div > div:nth-child(3) > button');
```

### 建議做法

優先使用語意化 locator（Playwright 內建），等效於 ref 系統：

```typescript
// ✅ 穩定：基於 accessibility role + 文字
page.getByRole('button', { name: '新增' });
page.getByRole('textbox', { name: '搜尋' });
page.getByLabel('電子郵件');
page.getByTestId('order-table');  // data-testid 屬性

// ✅ 穩定：ARIA label
page.locator('[aria-label="關閉對話框"]');
```

### Locator 優先順序

| 優先級 | 方法 | 適用情境 |
|--------|------|---------|
| 1 | `getByRole()` | 按鈕、連結、表單元素 |
| 2 | `getByLabel()` | 表單輸入欄位 |
| 3 | `getByTestId()` | 複雜元件（需在 HTML 加 `data-testid`） |
| 4 | `getByText()` | 靜態文字內容 |
| 5 | CSS selector | 最後手段，需註解說明為什麼用 |

**規則**：每個 Prototype HTML 的互動元素，必須有 `aria-label` 或 `data-testid`，確保測試穩定性。

---

## QA Session 修復上限

> 靈感來源：gstack /qa 的 50 fixes/session 上限 — 防止無限修 bug 迴圈。

### 規則

| 限制 | 數值 | 理由 |
|------|------|------|
| 單次 QA session 最大修復數 | **30 個** | 超過代表問題太多，應退回上游 |
| 單個 bug 最大修復嘗試 | **3 次**（AFL §36） | 超過代表根因未找到，觸發 systematic-debugging |
| 單次 session 最大截圖比對 | **50 張** | 效能考量 |

### 超過上限時的處理

```
⚠️ QA Session 修復上限達到

已修復 bug 數：30/30（上限）
剩餘未修復：5 個

處理方式：
1. 將未修復的 bug 記錄到 08_Test_Reports/F##-TR.md
2. 標記為 🔴 BLOCK（若為 P0 bug）或 🟡 DEFER（若為 P1/P2）
3. 退回對應 Agent（Backend/Frontend）修復後重新進入 QA
4. 不要在本 session 繼續嘗試修復
```

### Bug 分類優先級

| 優先級 | 定義 | QA 行為 |
|--------|------|---------|
| P0 | 核心流程無法完成 | 立即修復，計入 30 修復額度 |
| P1 | 功能異常但有替代方案 | 嘗試修復，計入額度 |
| P2 | 體驗問題 / 邊界案例 | 記錄但不在本 session 修復 |

**額度花完後只做 P0，P1/P2 一律 DEFER。**
