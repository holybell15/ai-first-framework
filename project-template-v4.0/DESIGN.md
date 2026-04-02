# Design System — [專案名稱]

> **Status**: Draft
> **Created**: [YYYY-MM-DD]
> **Owner**: UX Agent
> **Lock Rule**: Baselined 後修改需走 CIA 流程

---

## Color Palette

| Token | Value | 用途 |
|-------|-------|------|
| `--color-primary` | #1a73e8 | 主色，CTA 按鈕、連結 |
| `--color-secondary` | #34a853 | 輔助色，成功狀態 |
| `--color-background` | #ffffff | 頁面底色 |
| `--color-surface` | #f8f9fa | 卡片/容器底色 |
| `--color-text` | #202124 | 主文字 |
| `--color-text-muted` | #5f6368 | 次要文字 |
| `--color-error` | #d93025 | 錯誤/危險 |
| `--color-warning` | #f9ab00 | 警告 |

---

## Typography

| Token | Value | 用途 |
|-------|-------|------|
| `--font-family` | 'Inter', -apple-system, sans-serif | 全站字體 |
| `--font-h1` | 28px / 700 / line-height 1.2 | 頁面標題 |
| `--font-h2` | 22px / 600 / line-height 1.3 | 區塊標題 |
| `--font-h3` | 18px / 600 / line-height 1.4 | 子標題 |
| `--font-body` | 14px / 400 / line-height 1.6 | 正文 |
| `--font-caption` | 12px / 400 / line-height 1.4 | 輔助說明 |
| `--font-code` | 13px / 400 / 'JetBrains Mono', monospace | 程式碼 |

---

## Spacing Scale

| Token | Value |
|-------|-------|
| `--space-xs` | 4px |
| `--space-sm` | 8px |
| `--space-md` | 16px |
| `--space-lg` | 24px |
| `--space-xl` | 32px |
| `--space-2xl` | 48px |

---

## Border & Radius

| Token | Value | 用途 |
|-------|-------|------|
| `--radius-sm` | 4px | Tag, Badge |
| `--radius-md` | 8px | Card, Input |
| `--radius-lg` | 12px | Modal, Dialog |
| `--radius-full` | 9999px | Avatar, Pill |
| `--border-default` | 1px solid #dadce0 | 一般邊框 |
| `--border-focus` | 2px solid var(--color-primary) | Focus 狀態 |

---

## Component Tokens

| Component | Token | Value |
|-----------|-------|-------|
| Button (sm) | `--btn-h-sm` | 32px |
| Button (md) | `--btn-h-md` | 40px |
| Button (lg) | `--btn-h-lg` | 48px |
| Input | `--input-h` | 40px |
| Card | `--card-padding` | 16px |
| Card | `--card-shadow` | 0 1px 3px rgba(0,0,0,0.12) |
| Sidebar | `--sidebar-w` | 256px |
| Header | `--header-h` | 56px |

---

## Breakpoints

| Token | Value | 用途 |
|-------|-------|------|
| `--bp-sm` | 640px | Mobile |
| `--bp-md` | 768px | Tablet |
| `--bp-lg` | 1024px | Desktop |
| `--bp-xl` | 1280px | Wide |

---

## 修改規則

| 等級 | 可修改範圍 | 審批 |
|------|-----------|------|
| **Free** | 文字內容、圖片/icon 替換、組件內部微調 | 不需要 |
| **Review** | 新增/刪除頁面元件、改變佈局結構、修改互動流程 | Review Agent 確認 |
| **CIA** | 改顏色、字體、間距、組件尺寸（本文件中的任何 token） | CIA 流程 + 凱子核准 |
| **禁止** | 引入新 CSS framework、改 navigation 結構、使用未定義 token | 不允許 |

---

## Design Variant 流程

```
Discover 階段
    ↓
UX Agent 調研 → 產出 3 個方案（A / B / C）
    ↓
並排對比（HTML）→ 凱子選擇
    ↓
選定方案 → 填入本文件 → Status 改為 Baselined
    ↓
後續所有修改只能在此文件定義的 token 範圍內
```

---

## 版本記錄

| 版本 | 日期 | 變更摘要 |
|------|------|---------|
| Draft | [建立日期] | 初始 Design Token 定義 |
