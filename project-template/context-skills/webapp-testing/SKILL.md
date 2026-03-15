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

## 測試結構

```
tests/
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
