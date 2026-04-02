---
name: ground
description: >
  AI 修改既有程式碼前的強制接地流程。防止 AI 基於記憶或假設修改程式碼，
  確保每次修改都基於檔案的「當前真實狀態」。
  觸發詞: "ground", "接地", "改既有 code", "修改現有檔案"
---

# Ground Skill — 修改前接地

## 觸發條件

當 specialist 準備**修改既有檔案**時（不是新建檔案），必須先執行 Ground。

## 接地流程

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

## 禁止事項

- ❌ 不從記憶中重建整個檔案（用 Edit 而非 Write）
- ❌ 不修改未讀取過的檔案
- ❌ 不做超出當前 task 範圍的修改
- ❌ 不修改 Baselined 文件而不走 CIA
