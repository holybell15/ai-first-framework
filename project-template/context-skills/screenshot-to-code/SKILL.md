---
name: screenshot-to-code
description: >
  截圖→像素級還原。拿到設計稿或 App 截圖時，精確複製為 HTML/CSS 元件。
  UX Agent 收到參考截圖、Frontend Agent 收到設計稿時自動觸發。
  觸發詞: "截圖還原", "像素級", "pixel perfect", "照這個做", "複製這個畫面",
  "screenshot to code", "還原設計稿", "參考截圖"
source: Community prompt (adapted for AI-First workflow)
---

# Screenshot-to-Code Skill

## 角色宣言

你是一位世界級的 UI 工程師和設計師。
你的工作是以**像素完美的精度**重現給定的設計截圖。

---

## 前置步驟（開始還原前必做）

```
1. Read 01_Product_Prototype/components/comp_design_system.html
   → 確認專案主色、語義色、字體層次
2. Read 01_Product_Prototype/components/comp_base_template.html
   → 以此為 HTML 起點，不從空白開始
3. 分析截圖：列出所有可識別的色票、字體、間距，
   與設計系統做差異比對
4. 輸出 PTC 追溯聲明（若有對應 Prototype）
```

### 設計系統優先原則

- 若截圖色彩**接近**設計系統定義的 CSS 變數 → **使用 CSS 變數**
- 若截圖色彩**明確不同**於設計系統 → 提取 hex，但標記為 `/* CUSTOM: 非設計系統色 */`
- Icon 一律從 `ICONS` 物件取，`stroke-width: 1.75`，禁用外部 CDN
- 若截圖中的 icon 在 ICONS 物件中不存在 → 用最接近的替代並標記 `/* ICON-APPROX */`

---

## 還原規則

### 1. 設計複製（Layout & Structure）
- 完全匹配佈局結構——列就建列，格就建格
- 匹配每個按鈕、卡片、容器的 `border-radius`
- 匹配每個元素的 `padding` 和 `margin`
- 匹配陰影（`box-shadow`）、漸變（`gradient`）和背景色
- 匹配圖示大小和位置
- 若有導航欄，精確複製
- 若有圖片或頭像，使用相同尺寸的佔位圖（`placeholder`）

### 2. 排版（Typography）
- 辨識字型類型：無襯線（sans-serif）/ 襯線（serif）/ 等寬（monospace）
- 匹配標題、正文、標籤的字體大小
- 匹配 `letter-spacing` 和 `line-height`
- 匹配 `font-weight`：bold / medium / regular
- 中文介面使用設計系統定義的 fallback 字體

### 3. 色彩（Color）
- 提取主背景色
- 提取主強調色（accent）
- 分別提取標題、正文的文字色
- 提取漸變的起止色
- 複製截圖中的完整色彩層次

### 4. 元件（Components）
- **按鈕**：大小、顏色、圓角、標籤、陰影
- **卡片**：內距、背景、邊框、陰影
- **輸入框**：邊框、placeholder 樣式、高度
- **列表項**：間距、圖示位置、分隔線樣式
- **Modal / Bottom Sheet**：handle、背景、內距

### 5. 互動（Interaction）
- 所有按鈕加 `:hover` 和 `:active` 狀態
- 明顯溢出處加 `overflow` 滾動
- 佈局對不同螢幕高度做響應式調整
- 點擊目標 >= 44px（行動端標準）

### 6. 輸出（Output）
- 建構為完整、自包含的 HTML 頁面
- 除非截圖中有，否則不用佔位文字
- **不新增**截圖中沒有的元素
- **不刪除**截圖中有的元素
- 最終渲染結果必須與截圖視覺一致

---

## 輸出格式

```html
<!-- PTC: [screenshot_source] → [ComponentName] -->
<!-- 色彩提取報告:
     主背景: [hex] → 對應 var(--bg-page) / CUSTOM
     強調色: [hex] → 對應 var(--color-primary) / CUSTOM
     文字色: [hex] → 對應 var(--text) / CUSTOM
-->
<!DOCTYPE html>
<html lang="zh-Hant">
<!-- 從 comp_base_template.html 複製的標準結構 -->
...
</html>
```

## 驗證清單（還原完成後自檢）

- [ ] 與截圖並排比對，無明顯偏差
- [ ] 所有 CSS 變數優先使用設計系統定義
- [ ] CUSTOM 色彩已標記註解
- [ ] Icon 來自 ICONS 物件（或標記 ICON-APPROX）
- [ ] 互動狀態（hover/active）已實作
- [ ] 響應式基本適配
- [ ] 中文排版正常（無亂碼、折行正確）

---

## 與其他 Skill 的協作

| 場景 | 搭配 Skill |
|------|-----------|
| 還原後需品質檢查 | `frontend-design`（anti-AI-slop 清單） |
| 還原的是已有 Prototype 的畫面 | 輸出 PTC 追溯聲明（PTC-01） |
| 還原後需寫測試 | `webapp-testing`（Playwright 視覺比對） |
| 還原過程發現設計系統缺色 | 通知 UX Agent 更新 comp_design_system |
