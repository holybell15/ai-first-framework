---
name: info-doc-sync
description: >
  程式碼 ship 後自動同步文件，確保文件不落後於實作。

  遇到「同步文件」、「文件更新」、「info-doc-sync」、「CHANGELOG 更新」、
  「P06 完成後」或任何「文件和程式碼不同步」的情況時觸發。

  **為什麼？** 程式碼改了但文件沒跟上是最常見的技術債。
  這個 skill 在 deploy 後自動掃描所有 .md 文件，修正事實性錯誤，只有敘事性變更才問人。

  靈感來源：gstack /document-release — factual auto-update + narrative ask-user

  **Pipeline 整合**：P06 完成後由 pipeline-orchestrator 自動觸發。
---

# info-doc-sync Skill：Ship 後文件自動同步

## 核心原則：事實自動改，敘事問人

| 類型 | 定義 | 處理方式 |
|------|------|---------|
| **事實性** | 路徑、數量、表格、API 欄位名、版本號 | 自動修正 |
| **敘事性** | 功能描述、架構說明、設計理由 | 問人確認 |

---

## 執行流程

### Step 1 — 收集變更範圍

```bash
# 取得自上次 release 以來的所有變更
git diff --name-only $(git describe --tags --abbrev=0)...HEAD

# 分類檔案
#   CODE: src/ 下的程式碼變更
#   DOCS: *.md, 02_Specifications/, 03_System_Design/ 等
#   SPEC: contracts/, 10_Standards/
```

### Step 2 — 掃描文件過時項

針對每個 .md 文件，檢查：

| 檢查項 | 方法 | 類型 |
|--------|------|------|
| 檔案路徑引用 | 確認引用的檔案還存在 | 事實 → 自動修 |
| API 端點引用 | 對照最新 API Spec | 事實 → 自動修 |
| 表格中的欄位列表 | 對照最新 Schema | 事實 → 自動修 |
| 版本號引用 | 對照最新 VERSION | 事實 → 自動修 |
| 數量統計 | 重新計算（「共 N 個 API」） | 事實 → 自動修 |
| 功能描述 | 對照實際行為 | 敘事 → 問人 |
| 架構說明 | 對照最新 ADR | 敘事 → 問人 |

### Step 3 — 自動修正事實性錯誤

```
📝 info-doc-sync 自動修正報告

事實性修正（已自動套用）：
  1. 02_Specifications/F02-API.md — 更新端點數量 5→6
  2. 03_System_Design/F02-DB.md — 新增 `contact_source` 欄位
  3. MASTER_INDEX.md — 新增 F02-QA-Report.html 條目
  4. README.md — 更新技術棧版本 Node 18→20

敘事性變更（需確認）：
  1. 02_Specifications/US_F02.md — AC-3 描述與實作行為不一致
     現在：「顯示最近 5 筆通話記錄」
     實際：程式碼顯示最近 10 筆
     → 更新文件？還是修改程式碼？
```

### Step 4 — CHANGELOG 精修

檢查 CHANGELOG 品質：
- 用使用者能理解的語言（不是 commit message）
- 不覆蓋已有條目（只新增）
- Breaking change 有遷移指引

### Step 5 — 跨文件一致性

| 文件 A | 文件 B | 檢查項 |
|--------|--------|--------|
| README.md | CLAUDE.md | 技術棧描述一致 |
| API Spec | DB Schema | 欄位名稱和型別一致 |
| US (AC) | Test Cases | AC-TC 覆蓋完整 |
| RS | Prototype | UI 行為一致（P84 規則） |
| MASTER_INDEX | 實際檔案 | 所有登記的檔案都存在 |

### Step 6 — TODOS.md 清理

```
TODOS.md 清理建議：
  ✅ 標記完成：T-003（F02 API 實作）
  ✅ 標記完成：T-005（F02 前端元件）
  🔄 保留：T-008（F03 需求訪談 — 尚未開始）
  📦 歸檔建議：已完成項目 > 50 行，建議移至 05_Archive/
```

---

## 輸出

```
08_Test_Reports/doc-sync-report-YYYY-MM-DD.md
```

報告包含：
- 自動修正清單（已套用）
- 敘事性變更待決清單
- 跨文件一致性結果
- TODOS 清理建議

---

## Pipeline 整合

| 時機 | 行為 |
|------|------|
| P06 部署完成後 | pipeline-orchestrator 自動觸發 info-doc-sync |
| Gate 3 前 | 可手動觸發做預檢（確保文件已同步） |
| Hotfix 補件（48hr 內）| hotfix pipeline Step 4 自動觸發 |
| 手動 | 任何時候說「info-doc-sync」或「同步文件」|

---

## 與 CIA skill 的關係

| 機制 | 觸發時機 | 方向 |
|------|---------|------|
| `cia` | RS/SSD/API 變更**前** | 評估影響範圍 → 決定要不要改 |
| `info-doc-sync` | 程式碼 ship **後** | 掃描已過時的文件 → 自動/半自動修正 |

兩者互補：CIA 是「向前看」（變更會影響什麼），doc-sync 是「向後看」（什麼已經過時了）。
