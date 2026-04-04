---
name: ground
description: >
  AI 修改或新建程式碼前的強制接地流程。分兩種模式：
  (A) Build Grounding：新 Feature 進入 Build 前，讀 RS + Prototype + Tech Spec → Build Checklist → 確認
  (B) Code Grounding：修改既有檔案前，讀取當前內容確認實際狀態
  觸發詞: "ground", "接地", "改既有 code", "修改現有檔案", "開始 Build", "開始實作"
---

# Ground Skill — 接地流程

## 兩種模式

| 模式 | 時機 | 目的 |
|------|------|------|
| **Build Grounding** | Feature 進入 Build 階段、開始寫新 code | 確保理解 spec 和 UI，不靠記憶 |
| **Code Grounding** | 修改既有檔案 | 確保基於檔案現狀，不靠記憶 |

---

## Mode A: Build Grounding（新 Feature 開始 Build 前）

### 觸發條件

Feature 從 Plan 進入 Build 階段，準備開始寫 production code。

### 流程

#### Step 1: 讀取 Source of Truth（必做，禁止跳過）

依序**實際讀取**以下檔案（用 Read 工具，不是靠記憶）：

```
1. RS 文件：02_Specifications/RS_F[XX]_*.md
   → 提取所有 AC（Acceptance Criteria）
   → 標記哪些 AC 涉及 UI、哪些是純後端

2. Prototype HTML：01_Product_Prototype/[對應畫面].html
   → 用 Read 工具讀取 HTML 原始碼
   → 描述看到的 UI 佈局：哪些區塊、哪些元件、位置關係
   → 記錄 Design Token 使用（CSS 變數、class 名稱）
   → ⚠️ 禁止靠記憶描述 UI，必須讀檔案後描述

3. Tech Spec：02_Specifications/TS_F[XX]_*.md
   → 提取 API endpoint 清單
   → 提取 Data Model / Schema
   → 提取前端元件清單和依賴關係
   → 標記與其他 Feature 的共用元件
```

#### Step 2: 產出 Build Checklist（必做）

將讀到的內容整理成可執行的 checklist：

```markdown
# Build Checklist — F[XX] [Feature 名稱]

## Source of Truth 已讀取
- [x] RS: [檔名] — [AC 數量] 條 AC
- [x] Prototype: [檔名] — [描述看到的主要區塊]
- [x] Tech Spec: [檔名] — [API 數量] / [元件數量]

## AC → 實作對照表
| AC ID | AC 描述 | 後端實作 | 前端實作 | UI 參考 |
|-------|---------|---------|---------|---------|
| AC-1  | ...     | API endpoint | Vue 元件 | Prototype 區塊 X |
| AC-2  | ...     | Service 邏輯 | Store 更新 | 無 UI |

## UI 元件清單（從 Prototype 提取）
| 元件 | Prototype 中的位置 | 對應 AC | 互動行為 |
|------|-------------------|---------|---------|
| ...  | ...               | AC-1    | 點擊 → ... |

## API 清單（從 Tech Spec 提取）
| Endpoint | Method | 對應 AC | 請求/回應摘要 |
|----------|--------|---------|-------------|
| ...      | ...    | AC-1    | ...         |

## 風險/待確認
- [ ] [任何 spec 不明確或 Prototype 與 RS 有差異的地方]
```

#### Step 3: 用戶確認

提交 Build Checklist 給用戶。用戶確認後建立 checkpoint：

```bash
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F[XX]/build-grounded.confirmed
```

**用戶沒確認 → checkpoint 不存在 → gate-checkpoint.sh 阻擋寫入 production code。**

### 完成標準

- ✅ RS、Prototype、Tech Spec 三份文件都**實際讀取**過（不是靠記憶）
- ✅ Build Checklist 已產出，每條 AC 都有對應實作項目
- ✅ UI 元件清單基於 Prototype 實際內容（不是想像的）
- ✅ 用戶已確認 Checklist
- ✅ `.gates/F[XX]/build-grounded.confirmed` 已建立

#### Step 4: Pattern Library 查詢（v4.1 — 強制）

Build Grounding 確認後，**寫 code 之前**必須查 Pattern Library：

1. 讀取 `verified-patterns/README.md`
2. 對照 Build Checklist 每個實作項目，標記：

```markdown
## Pattern Check Log — F[XX]

| # | 實作項目 | 有 Pattern？ | Pattern 名稱 | 備註 |
|---|---------|-------------|-------------|------|
| 1 | 客戶 CRUD API | ✅ 有 | crud-standard | 直接複用 |
| 2 | 搜尋分頁 | ✅ 有 | search-with-pagination | 需調整欄位 |
| 3 | CTI 事件處理 | ❌ 無 | — | 從零實作 |
```

3. 建立 checkpoint：

```bash
echo "confirmed $(date -u +%Y-%m-%dT%H:%M:%SZ)" > .gates/F[XX]/pattern-checked.confirmed
```

**gate-checkpoint.sh 會攔截：沒有 pattern-checked.confirmed → 不能寫 production code。**

> 查完就好，不強制使用 pattern。但先查再寫，避免重複造輪子。

### 禁止事項

- ❌ 不靠記憶描述 UI — 必須讀 Prototype HTML
- ❌ 不跳過 Checklist 直接寫 code
- ❌ 不省略 AC — 每條 AC 都要有對應實作
- ❌ 不在 Checklist 中加入 RS 未定義的功能
- ❌ 不跳過 Pattern Check — gate-checkpoint.sh 會攔截

---

## Mode B: Code Grounding（修改既有檔案前）

### 觸發條件

準備**修改既有檔案**時（不是新建檔案），必須先執行。

### Step 1: Read Before Write（必做）

修改任何檔案前，先完整讀取該檔案的當前內容：

```
1. Read 目標檔案 → 確認當前內容
2. 比對你的預期 vs 實際內容
3. 如果有差異 → 基於實際內容規劃修改
4. 不基於記憶或假設修改
```

### Step 2: Context Check（必做）

確認修改不會違反已鎖定的基線：

```
1. 查 ARTIFACTS.md → 該檔案是否 Baselined?
2. 如果 Baselined → 必須先走 CIA 流程
3. 查 DESIGN.md → 修改是否涉及 Design Token?
4. 如果涉及 → 確認修改等級（Free/Review/CIA/禁止）
```

### Step 3: Scope Validation（必做）

確認修改範圍在授權範圍內：

```
1. 只修改 task 指定的範圍
2. 不做 "順手修" — 發現其他問題記入 findings.md
3. 不改 import/export 結構（除非 task 明確要求）
4. 不改 API 介面簽名（除非 task 明確要求）
```

### Step 4: Execute & Verify

```
1. 執行修改
2. 修改後重新讀取檔案 → 確認修改正確
3. 跑相關 test → 確認不破壞既有功能
4. 記錄修改摘要到 progress.md
```

### 禁止事項

- ❌ 不從記憶中重建整個檔案（用 Edit 而非 Write）
- ❌ 不修改未讀取過的檔案
- ❌ 不做超出當前 task 範圍的修改
- ❌ 不修改 Baselined 文件而不走 CIA
