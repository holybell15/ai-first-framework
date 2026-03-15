# Design Token 速查表 — [專案名稱]

> **SSOT**：`01_Product_Prototype/components/comp_design_system_v2.html`
> 本文件為可讀摘要，實際 CSS 變數以 comp_design_system_v2.html 為準

---

## 色彩 Token

### 主色（Primary）
| Token | 用途 |
|-------|------|
| `--color-primary-50` | 極淺背景（hover 區域）|
| `--color-primary-100` | 淺色標籤背景 |
| `--color-primary-500` | 主要按鈕、連結、active 狀態 |
| `--color-primary-600` | 按鈕 hover |
| `--color-primary-700` | 按鈕 pressed |

### 語意色
| Token | 用途 | 對應情境 |
|-------|------|---------|
| `--color-success` | 成功 | 案件已結案、通話接通 |
| `--color-success-light` | 成功淺色背景 | 成功提示框 |
| `--color-warning` | 警告 | 待確認、需注意 |
| `--color-warning-light` | 警告淺色背景 | 警告提示框 |
| `--color-error` | 錯誤 | 驗證失敗、高風險 |
| `--color-error-light` | 錯誤淺色背景 | 錯誤提示框 |
| `--color-info` | 資訊 | 一般提示 |

### 中性色（Neutral）
| Token | 用途 |
|-------|------|
| `--color-gray-900` | 主要文字 |
| `--color-gray-700` | 次要標題 |
| `--color-gray-600` | 次要文字、label |
| `--color-gray-400` | Placeholder、disabled 文字 |
| `--color-gray-200` | 邊框、分隔線 |
| `--color-gray-100` | 輸入框背景 |
| `--color-gray-50` | 卡片背景、hover 背景 |
| `--color-white` | 主要背景 |

### 特殊用途色
| Token | 用途 |
|-------|------|
| `--color-overlay` | Modal 遮罩（rgba）|
| `--color-focus-ring` | focus 外框（Accessibility）|

---

## 字型 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--font-family` | 系統字型 + 中文 fallback | 全站 |
| `--font-size-xs` | 12px | 標籤、角標 |
| `--font-size-sm` | 14px | 次要文字、說明 |
| `--font-size-base` | 16px | 正文（預設）|
| `--font-size-lg` | 18px | 次標題 |
| `--font-size-xl` | 20px | 卡片標題 |
| `--font-size-2xl` | 24px | 頁面標題 |
| `--font-size-3xl` | 30px | 大標題 |
| `--font-weight-normal` | 400 | 正文 |
| `--font-weight-medium` | 500 | 強調文字 |
| `--font-weight-semibold` | 600 | 小標題 |
| `--font-weight-bold` | 700 | 標題 |
| `--line-height-tight` | 1.25 | 標題 |
| `--line-height-base` | 1.5 | 正文（中文建議）|
| `--line-height-loose` | 1.75 | 說明文字 |

---

## 間距 Token

| Token | 值 | 常見用途 |
|-------|-----|---------|
| `--spacing-0.5` | 2px | 極小間距 |
| `--spacing-1` | 4px | icon 與文字間距 |
| `--spacing-2` | 8px | 元件內部間距 |
| `--spacing-3` | 12px | 小型元件 padding |
| `--spacing-4` | 16px | 標準 padding |
| `--spacing-5` | 20px | 中型間距 |
| `--spacing-6` | 24px | 卡片 padding |
| `--spacing-8` | 32px | 區塊間距 |
| `--spacing-10` | 40px | 大型區塊間距 |
| `--spacing-12` | 48px | Section 間距 |
| `--spacing-16` | 64px | 頁面級間距 |

---

## 圓角 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--radius-sm` | 4px | 小標籤、tooltip |
| `--radius-base` | 6px | 輸入框、按鈕 |
| `--radius-md` | 8px | 卡片 |
| `--radius-lg` | 12px | Modal、大型卡片 |
| `--radius-xl` | 16px | 特殊元件 |
| `--radius-full` | 9999px | 膠囊按鈕、頭像 |

---

## 陰影 Token

| Token | 用途 |
|-------|------|
| `--shadow-sm` | 輕微浮起（hover 效果）|
| `--shadow-base` | 卡片預設陰影 |
| `--shadow-md` | Dropdown、Tooltip |
| `--shadow-lg` | Modal、側邊欄 |
| `--shadow-none` | 移除陰影 |

---

## 動畫 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--duration-fast` | 100ms | 微互動（hover）|
| `--duration-base` | 200ms | 一般過渡 |
| `--duration-slow` | 300ms | 展開/收起 |
| `--easing-default` | ease-in-out | 標準緩動 |
| `--easing-bounce` | cubic-bezier(0.34,1.56,0.64,1) | 彈跳效果（謹慎使用）|

> 所有動畫必須支援 `@media (prefers-reduced-motion: reduce)` → `duration: 0.01ms`

---

## Z-index Token

| Token | 值 | 層級 |
|-------|-----|------|
| `--z-base` | 0 | 一般元素 |
| `--z-dropdown` | 100 | Dropdown、Select |
| `--z-sticky` | 200 | Sticky header |
| `--z-overlay` | 300 | Modal 遮罩 |
| `--z-modal` | 400 | Modal 內容 |
| `--z-toast` | 500 | Toast 通知 |
| `--z-tooltip` | 600 | Tooltip |

<!-- STD-SIG: Design Token Reference v1.0 | 2026-03-15 -->
