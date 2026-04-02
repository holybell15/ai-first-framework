# UI 設計規範 — [專案名稱]

> **版本**：v1.0 | **Design System SSOT**：`01_Product_Prototype/components/comp_design_system_v2.html`
> **適用對象**：ux-agent、frontend-agent、review-agent

---

## 1. 設計系統使用規則（強制）

| 規則 | 說明 |
|------|------|
| 新元件起點 | 從 `comp_base_template.html` 複製，**禁止**從空白 HTML 開始 |
| Design Token | 所有視覺值引用 CSS 變數（見 `Design_Token_Reference.md`），**禁止** hardcode hex / px magic number |
| Icon | `stroke-width: 1.75`，從 ICONS 物件取，**禁止**外部 CDN（Font Awesome、Material 等）|
| 色票 | 只使用 `comp_design_system_v2.html` 定義的色票，不得自行新增顏色 |
| 字型 | 系統字型 stack，中文 fallback 必填，行高 1.4~1.6 |

---

## 2. 元件狀態完整性（Prototype 交付標準）

每個 UI 元件必須包含以下狀態，缺漏 = Prototype Review 🟡 黃燈：

| 狀態 | 說明 |
|------|------|
| Default | 正常顯示 |
| Hover | 滑鼠懸停 |
| Active / Focus | 點擊中 / 鍵盤 focus |
| Disabled | 不可操作 |
| Loading | 資料讀取中 |
| Empty | 無資料 |
| Error | 驗證失敗 / 系統錯誤 |

---

## 3. 佈局規範

```
視覺層次：F-pattern（列表）/ Z-pattern（登陸頁）
留白系統：使用 --spacing-* 變數，禁止 magic number
響應式斷點：
  Mobile：< 768px
  Tablet：768px ~ 1199px
  Desktop：≥ 1200px
點擊目標：最小 44×44px（WCAG 2.1 AA）
```

---

## 4. Accessibility 強制規則（WCAG 2.1 AA）

| 規則 | 標準 | 驗證 |
|------|------|------|
| 色彩對比度 | 一般文字 ≥ 4.5:1，大文字 ≥ 3:1 | Lighthouse / axe-core |
| 鍵盤導航 | 所有功能可用 Tab/Enter/Escape 完成 | 手動測試 |
| 互動元素 aria | 按鈕/連結/表單必須有 `aria-label` 或可見文字 | axe-core |
| 表單 label | 必須有對應 `<label>`，禁止 placeholder 替代 | axe-core |
| 圖片 alt | 內容圖片必填，裝飾性用 `alt=""` | axe-core |
| 動態內容 | 更新需通知 screen reader（`aria-live` / `role="status"`）| 手動測試 |
| 動畫 | 支援 `prefers-reduced-motion`，動畫時長 < 300ms | CSS 實作 |

**CI 整合**：Playwright + axe-core，Critical/Serious 違規 = 阻擋 PR merge

---

## 5. 禁止清單（AI Slop 防範）

| 禁止 | 正確做法 |
|------|---------|
| 過度圓角 + 大陰影 | 符合 Design System 規範 |
| 全頁漸層背景 | 扁平為主，CTA 按鈕才用漸層 |
| 裝飾性 SVG 插圖 | 從 ICONS 物件取語意圖示 |
| 外部 CDN icon | comp_design_system_v2.html ICONS 物件 |
| hardcode `#3B82F6` | `var(--color-primary-500)` |
| `v-html` / `innerHTML` | 資料綁定 / DOMPurify 過濾 |
| `v-if="user.role === 'admin'"` | `usePermission(action, resource)` |

---

## 6. 元件開發流程

```
1. 讀取 comp_design_system_v2.html（確認色票/字體/icon）
2. 複製 comp_base_template.html 作為起點
3. 輸出 PTC 追溯聲明：PTC: [prototype_file]#[Section] → [ComponentName]
4. 實作所有狀態（§2 元件狀態完整性）
5. 執行 axe-core 掃描（Accessibility）
6. 輸出 DSV-01 Diff Scope Declaration
7. 修改完成後執行 DSV-02 Post-Diff Audit
```

---

## 7. Design Token 速查

> 完整清單見 `Design_Token_Reference.md`

```css
/* 主色 */
--color-primary-500    /* 主要按鈕、連結 */
--color-primary-600    /* Hover 狀態 */
--color-primary-100    /* 淺色背景 */

/* 語意色 */
--color-success        /* 成功、已完成 */
--color-warning        /* 警告、待確認 */
--color-error          /* 錯誤、高風險 */

/* 中性色 */
--color-gray-900       /* 主要文字 */
--color-gray-600       /* 次要文字 */
--color-gray-200       /* 邊框 */
--color-gray-50        /* 卡片背景 */

/* 間距 */
--spacing-1: 4px    --spacing-2: 8px
--spacing-3: 12px   --spacing-4: 16px
--spacing-6: 24px   --spacing-8: 32px
```

---

## 8. Gate Review 驗收項目

G4-ENG / Gate 3 前 UX / Frontend 必須確認：
- [ ] 所有元件從 comp_base_template.html 複製起點
- [ ] 無 hardcode hex / magic number（全用 CSS 變數）
- [ ] 無外部 CDN icon
- [ ] 7 種元件狀態齊全
- [ ] axe-core 掃描：Critical/Serious = 0
- [ ] 鍵盤導航測試通過
- [ ] 色彩對比度 ≥ 4.5:1
- [ ] PTC 追溯聲明已輸出（G4-ENG 抽查 3~5 個）

<!-- STD-SIG: UI Design Standard v1.0 | 2026-03-15 -->
