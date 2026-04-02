---
name: frontend-design
description: >
  設計前端 UI 元件時的質量把關。避免 AI 樣板感，確保每個設計決策都有理由。

  遇到「做一個按鈕元件」、「設計這個畫面」、「Prototype 長什麼樣」、「UI 看起來怎樣」、
  「component 設計」或任何前端視覺相關的要求，都該用這個。

  **為什麼？** 自動生成的 UI 往往超大圓角、漸層疊疊樂、色彩不協調。這個 skill 用檢查清單
  確保不會出現「看起來很 AI」的廉價感。另外，設計決策要寫進文件，GSD 時好檢查。
---

# Frontend Design Skill

## 核心原則：每個決策都要有理由

不是「什麼都圓角陰影」或「漸層用到底」。而是問：
- 這個顏色為什麼比那個更好？
- 為什麼圓角 8px 不是 12px？
- 為什麼要這樣排版？

**答不出來** → 重新設計。**答得出來** → 紀錄在註解裡，3 個月後新成員看得懂。

---

## 開始前必讀

```
讀取：01_Product_Prototype/components/comp_design_system.html
讀取：01_Product_Prototype/components/comp_base_template.html
```

**為什麼？**
- `comp_design_system.html` 定義了色票、按鈕尺寸、icon 規範 — 這是「語言」，所有元件必須用同一套語言
- `comp_base_template.html` 是新元件的起點，已內建 HTML 骨架 + ICONS 物件 + svg() 工具函式，直接複製起點，省時且避免重複發明

**新元件流程**：
1. 複製 `comp_base_template.html` → 改檔名 → 改 `<title>`
2. 在 HTML 中編寫元件邏輯
3. 用設計系統的色票、icon、字型規格
4. 完成後跑這個 Skill 的檢查清單

---

## UI 檢查清單

### 佈局（Layout）

- [ ] **視覺層次清楚** — F-pattern（文章）或 Z-pattern（表單）是否符合使用者掃描路徑？

  *例*：主 CTA 按鈕在右下（眼睛最後會到的地方），次要操作在左上

- [ ] **留白足夠** — 擁擠感？應該加間距

  *例*：相鄰元件間距最少 16px，卡片內部 padding 最少 12px

- [ ] **響應式斷點已定義** — 在 CSS 或文件裡明確寫出何時換版本

  *例*：`@media (max-width: 640px) { /* 手機版 */ }`

### 色彩（Color）

- [ ] **必須用 comp_design_system.html 的色票** — 不准自造顏色

  定義好的色系：primary (藍) / success (綠) / warning (黃) / error (紅) + light 淡化版

- [ ] **對比度 WCAG AA 標準** — 文字與背景對比比例 >= 4.5:1

  工具：https://webaim.org/resources/contrastchecker/

  *常見錯誤*：淺灰文字放淺灰背景 → 讀不清

- [ ] **語義色彩** — 色彩有意思，不是裝飾

  | 含義 | 顏色 |
  |------|------|
  | 成功/確認 | 綠 |
  | 警告/待注意 | 黃 |
  | 錯誤/危險 | 紅 |
  | 中立/資訊 | 藍 |

### 字型（Typography）

- [ ] **大小層次清楚** — 最少 3 個層級（標題 > 副標 > 正文）

  *例*：H1 = 32px、H2 = 24px、body = 14px、small = 12px

- [ ] **行高 1.4~1.6** — 太緊密（< 1.4）易疲勞，太寬鬆（> 1.6）閱讀卡頓

- [ ] **中文字型有 fallback**
  ```css
  font-family: "Noto Sans TC", "Microsoft YaHei", sans-serif;
  ```
  （Noto Sans TC 專為中文優化，不會出現豆腐塊）

### 元件狀態（Component States）

每個互動元素都要有 4 個狀態：

- [ ] **Hover** — 滑鼠懸停時變色/升起/底線出現（視覺反饋「能點」）
- [ ] **Active** — 點下去的瞬間
- [ ] **Disabled** — 不能點時（灰色 + cursor: not-allowed）
- [ ] **Focus ring** — Tab 鍵聚焦時有框線（鍵盤使用者需要）

*例：按鈕*
```css
button {
  background: var(--color-primary);
  cursor: pointer;
  transition: all 0.2s;
}

button:hover {
  background: var(--color-primary-hover);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

button:active {
  transform: translateY(2px);
}

button:disabled {
  background: #ccc;
  cursor: not-allowed;
  opacity: 0.5;
}

button:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}
```

- [ ] **Loading state** — 異步操作時（spinner + disabled）
- [ ] **Empty state** — 沒有資料時（圖示 + 引導文案）
- [ ] **Error state** — 驗證失敗時（紅框 + 錯誤訊息）

### Icon（圖示）

- [ ] **stroke-width: 1.75** — 不用 1.5 或 2，保持統一感
- [ ] **fill: none + stroke: currentColor** — 讓 icon 能跟著文字色彩變
- [ ] **所有 icon 從 ICONS 物件取** — 不自造 SVG path
  ```javascript
  const svg = (iconName) => {
    const paths = {
      'check': '<path d="M20 6L9 17l-5-5"/>',
      'x': '<path d="M18 6L6 18M6 6l12 12"/>'
    };
    return paths[iconName] || '';
  };
  ```
- [ ] **禁止任何外部 CDN**（Font Awesome、Material Icons 等）— 載入速度 + 控制力

### 互動動畫（Animation）

- [ ] **點擊後回饋 < 100ms** — 人腦感知的「即時」閾值
- [ ] **動畫總長 < 300ms** — 再漂亮的動畫超過 0.3 秒就顯得卡頓
- [ ] **使用 `transition` 不要 `animation`** — 更簡潔也夠用

```css
.button {
  transition: all 0.2s ease-out;
}
```

### 點擊目標（Touch Target）

- [ ] **最小 44x44px**（行動裝置無障礙標準）
- [ ] **相鄰點擊目標間距 >= 8px** — 否則誤點率高

---

## 禁止清單

| AI 樣板感 | 正確做法 | 為什麼 |
|----------|--------|-------|
| 全部 border-radius: 16px | 遵照 design system（通常 4/8px） | 大圓角會顯得廉價、不專業 |
| 每個東西都疊 box-shadow | 只在「需要提升」的元件用（按鈕、卡片） | 陰影過多→ 視覺混亂 |
| 漸層當裝飾（background: linear-gradient...） | CTA 按鈕才用漸層，其他扁平色 | 漸層應該強調重點，不是裝飾 |
| 隨便自造色彩 | 只用 design system 色票 | 色彩不協調 → 不專業 |
| 外部 CDN icon | ICONS 物件 + comp_design_system.html | 可控、載入快、換風格容易 |
| 沒有 disabled/focus 狀態 | 每個互動元素 4 個狀態齊全 | 無障礙 + 鍵盤使用者 |

---

## GSD 檢查點

在交接前，確保：

| 檢查項 | 必須完成 | 簽核人 |
|-------|--------|--------|
| 檢查清單全打 ✓ | UX Agent | Review Agent（Gate 1 時驗證） |
| 色彩對比度檢查 | UX Agent | 自動化工具驗證 |
| Prototype 截圖測試 | QA Agent | Playwright (webapp-testing skill) |
| 設計決策文件化 | UX Agent | Frontend Agent 實作時參考 |

---

## 實例

### 不好的例子（AI 樣板感）

```html
<button style="border-radius: 20px; background: linear-gradient(45deg, #667eea, #764ba2);
               box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3); padding: 16px 32px;
               font-size: 18px; color: white; border: none; cursor: pointer;">
  Click Me
</button>
```

問題：
- 圓角 20px（太大，廉價感）
- 不必要的漸層
- 陰影太重
- 沒有 hover/disabled 狀態
- 沒有任何設計理由

### 好的例子

```html
<button class="btn btn-primary">新增訂單</button>

<style>
  /* 使用 design system 變數 */
  .btn {
    padding: 8px 16px;
    border-radius: 4px;  /* 一致的小圓角 */
    border: none;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.2s ease-out;
    font-weight: 500;
  }

  .btn-primary {
    background: var(--color-primary);
    color: white;
  }

  .btn-primary:hover {
    /* 懸停時稍微加深，手指形狀提示「能點」 */
    background: var(--color-primary-hover);
  }

  .btn-primary:disabled {
    /* 禁用時灰化 */
    background: #ccc;
    cursor: not-allowed;
    opacity: 0.6;
  }

  .btn-primary:focus {
    /* 鍵盤聚焦 */
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
</style>
```

設計決策（寫在 Prototype.md 或代碼註解）：
- **圓角 4px**：遵照 design system，保持專業感
- **無漸層**：是 CTA 但不需漸層；首選用色深化表達強調
- **無陰影**：這是行動按鈕，扁平設計；卡片才用陰影提升層級
- **transition: 0.2s**：人感知的即時反應，不會顯得延遲

---

## 快速檢查命令

完成元件後，直接掃檢查清單：

```bash
# 開始新元件
1. cp comp_base_template.html [new-component].html
2. 在 HTML 編寫邏輯
3. 跑這個 Skill 的「檢查清單」
4. 每一項都打 ✓
5. 寫好設計決策說明（3~5 句話）
6. 交給 Frontend Agent 實作或 QA Agent 測試
```

**沒有全打勾？** → 回到第 2 步，改設計，直到清單全綠。

---

## AI Slop Blacklist（AI 生成設計反模式）

> 靈感來源：gstack /plan-design-review — 10 個「一看就知道是 AI 生成的」設計反模式。

以下模式在 AI 生成的 UI 中極為常見，會讓產品看起來「廉價」和「千篇一律」。
**Review 時如果發現以下任何一個，標記 🟡 並要求修正。**

| # | 反模式 | 描述 | 修正方向 |
|---|--------|------|---------|
| 1 | **紫色漸層萬用背景** | 紫→藍漸層作為 hero / header 背景 | 用品牌色或中性色，漸層只用在有明確理由的場合 |
| 2 | **Icon-in-Circle 三欄排版** | 三個圓形 icon + 標題 + 描述並排 | 依內容選擇排版，不要所有 feature section 都三欄 |
| 3 | **彩色圓底 icon** | icon 外包彩色圓形背景 | icon 直接放，用 stroke style，不需要圓底 |
| 4 | **全部置中** | 所有文字和元素都 `text-align: center` | 左對齊是閱讀預設，置中只用在標題或 CTA |
| 5 | **統一超大圓角** | 所有元素都 `border-radius: 16px+` | 按層級用不同圓角：按鈕 4-8px、卡片 8-12px、modal 12px |
| 6 | **裝飾性 blob / 波浪分隔** | 無意義的彩色 blob 或 wave SVG 分隔線 | 用間距和顏色區分段落，不需要裝飾元素 |
| 7 | **Emoji 當設計元素** | 用 🚀🎯💡 當 section icon | 用專業 icon（stroke-width 1.75），emoji 只用在文案 |
| 8 | **彩色左邊框卡片** | 卡片左邊有 4px 粗彩色邊框 | 用 shadow 或 border 全邊框，左邊框只用在狀態指示 |
| 9 | **空洞 Hero 文案** | 「Unlock the power of...」「Revolutionize your...」 | 直接說產品做什麼，用具體數字和動詞 |
| 10 | **千篇一律的段落節奏** | Hero → Feature 三欄 → Testimonial → CTA，每個專案都一樣 | 從使用者 journey 設計佈局，不要套模板 |

### 如何使用

1. **設計產出後**：對照 10 條逐一檢查
2. **Code Review 時**：Frontend Agent 或 Review Agent 掃描
3. **Prototype 驗收時**：UX Agent 確認無 slop
4. **嚴重程度**：單一項 → 🟡 提醒；3+ 項同時出現 → 🔴 重新設計

---

## Design Dials（設計風格旋鈕）

> 靈感來源：MiniMax frontend-dev — 3 軸參數化控制設計產出風格。

設計不是 one-size-fits-all。以下 3 個旋鈕讓設計產出可依專案需求調節：

### 三軸定義

| 旋鈕 | 範圍 | 1（最低） | 5（中間） | 10（最高） |
|-------|------|----------|----------|-----------|
| **DESIGN_VARIANCE** | 1-10 | 保守企業風（直角、標準佈局、中性色） | 現代 SaaS（圓角、卡片、品牌色） | 大膽實驗（不對稱、動態佈局、撞色） |
| **MOTION_INTENSITY** | 1-10 | 無動畫（僅 hover 變色） | 適度過渡（fade、slide、scale） | 全動態（parallax、粒子、3D 轉場） |
| **VISUAL_DENSITY** | 1-10 | 極簡（大留白、少元素） | 平衡（適度資訊密度） | 資訊密集（dashboard、數據面板） |

### 設定方式

在 `memory/product.md` 或設計任務開始前宣告：

```markdown
## Design Dials
DESIGN_VARIANCE: 4    ← 金融產品偏保守
MOTION_INTENSITY: 3   ← 效能優先，動畫克制
VISUAL_DENSITY: 7     ← Dashboard 類產品，資訊密度高
```

### 旋鈕影響規則

| 條件 | 規則 |
|------|------|
| VARIANCE ≤ 3 | 禁止不對稱佈局、禁止撞色、圓角 ≤ 8px |
| VARIANCE ≥ 7 | 允許 Bento grid、不對稱排版、品牌色大面積使用 |
| MOTION ≤ 3 | 只用 CSS transition，禁止 JS 動畫庫 |
| MOTION ≥ 7 | 允許 Framer Motion / GSAP，需標註效能影響 |
| DENSITY ≤ 3 | 每屏最多 3 個資訊區塊 |
| DENSITY ≥ 7 | 允許多面板、折疊區、表格密排 |

---

## 動畫工具選型矩陣

> 靈感來源：MiniMax frontend-dev — 不同動畫需求用不同工具，禁止混用。

### 選型表

| 需求 | 工具 | 適用場景 |
|------|------|---------|
| UI 過渡（mount/unmount、路由切換） | **Framer Motion** | React 元件動畫 |
| 捲動觸發（scroll-based） | **GSAP + ScrollTrigger** | Landing page、視差效果 |
| 迴圈圖示動畫 | **Lottie** | Loading spinner、成功動畫 |
| 3D 視覺化 | **Three.js / R3F** | 產品展示、數據視覺化 |
| Hover 狀態 / 微互動 | **CSS transition** | 按鈕 hover、focus ring |

### 衝突規則（禁止混用）

| ❌ 禁止 | 原因 | ✅ 替代 |
|---------|------|---------|
| Framer Motion + GSAP 同一元件 | 兩套動畫引擎搶 DOM 控制權 | 選一個，用 ref 隔離 |
| CSS animation + Framer Motion 同屬性 | `transform` 衝突導致抖動 | 全部交給 Framer 管理 |
| Lottie 用在大面積背景 | 效能災難（SVG 重繪） | 用 CSS gradient animation 或 video |
| Three.js 不加 `dispose()` | 記憶體洩漏 | cleanup 函式必須呼叫 dispose |

### MOTION_INTENSITY 對照

| 等級 | 允許的工具 |
|------|-----------|
| 1-3 | 僅 CSS transition |
| 4-6 | CSS + Framer Motion |
| 7-8 | CSS + Framer + GSAP |
| 9-10 | 全部（含 Three.js / Lottie）|
