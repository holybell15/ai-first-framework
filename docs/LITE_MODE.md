# Lite Mode

> Lite Mode 是 AI-First Framework 的最小可用路徑，給 1-2 人團隊、首次導入者、或需要快速起跑的專案使用。
>
> 目標不是跳過品質，而是用更少的必備文件與更少的切換成本，先跑出第一個可交付功能，再逐步升級回完整模式。

---

## 適用情境

符合以下任一條件時，優先使用 Lite Mode：

- 專案剛初始化，團隊還不熟框架
- 只有 1-2 位開發者在推進
- 需要先做出第一個可驗證 feature
- 功能相對單純，沒有複雜外部依賴或高合規要求

不建議使用 Lite Mode 的情境：

- 高風險上線功能
- 大型多人協作專案
- 複雜外部系統整合
- 涉及嚴格法遵、資安、資料治理要求

---

## Lite Mode 核心原則

1. 保留框架最重要的控制點：Task-Master、STATE、TASKS、10_Standards、Gate
2. 精簡早期文書量，只要求最小必要產出
3. 優先做出第一個 feature 的完整閉環
4. 當複雜度升高時，主動升級回完整 Pipeline

---

## Lite Mode 最短路徑

### 新專案

1. 建立專案：`./scripts/new-project.sh [ProjectName]`
2. 讀取 `CLAUDE.md`
3. 填最少初始化資訊：
   - `memory/product.md`
   - `TEAM.md`（若為單人，可先只填自己）
   - `MASTER_INDEX.md` 登記第一個 F-code
4. 說：`使用 Lite Mode 啟動 F01`
5. 走 Lite Pipeline

### 舊專案接入

1. 接入框架：`./scripts/adopt-project.sh [ProjectPath]`
2. 讀取 `CLAUDE.md`
3. 先完成最小 baseline：
   - `memory/product.md`
   - `memory/STATE.md`
   - `TASKS.md`
4. 說：`使用 Lite Mode 接手下一個功能`
5. 走 Lite Pipeline

---

## Lite Pipeline

Lite Mode 不是新的獨立架構，而是對完整 Pipeline 的最小化裁切。

### Step 0 — 對齊現況

- 執行 `/info-task-master`
- 確認目前工作焦點、負責人、下一步
- 若是舊專案，先補最小現況理解

### Step 1 — 最小需求定義

必備產出：
- `MASTER_INDEX.md`：F-code 登記
- `TASKS.md`：建立任務
- `02_Specifications/` 中一份最小需求文件

需求文件允許以下二選一：
- `RFP_Brief_[功能].md`
- `US_F##_[功能名].md`

若需求簡單，可以跳過完整訪談，但仍需寫清楚：
- 誰要用
- 要解決什麼問題
- 成功條件
- 至少 3 條可測試 AC

### Step 2 — 最小設計定義

必備產出：
- 一份最小設計說明，可放在 `03_System_Design/`

內容至少包含：
- 影響模組
- 資料流或 API 變更
- 需要新增或修改的資料表/欄位
- 主要風險

允許不拆完整 SW/HW/DB 多份文件，但不得跳過設計思考。

### Step 3 — 實作與驗證

必備產出：
- 程式碼
- 最小測試
- `TASKS.md` 交接摘要
- `memory/STATE.md` 更新

測試最低要求：
- 至少一條主流程驗證
- 至少一條關鍵錯誤情境驗證
- 若有 UI，至少做一次主流程手動驗證或自動化驗證

### Step 4 — Lite Review

不要求完整 Gate 套件，但必須完成最小放行檢查：

- 範圍是否清楚
- 實作是否符合 AC
- 有沒有明顯破壞 `10_Standards/`
- 測試是否有證據
- `STATE.md` / `TASKS.md` 是否可讓下一個 session 接手

若以上任一項不成立，不能視為完成。

---

## Lite Mode 必備文件

### 一定要有

- `CLAUDE.md`
- `TASKS.md`
- `MASTER_INDEX.md`
- `memory/STATE.md`
- `memory/product.md`
- `10_Standards/`

### 第一個 feature 至少要有

- 一份需求文件
- 一份最小設計文件
- 一份測試證據或測試報告

### 可以延後

- 完整訪談紀錄
- 完整 UX prototype
- 完整合規文件
- 多角色平行分工文件
- 大量 retrospective / archive 類文檔

---

## Lite Mode 角色建議

### 1 人模式

- 同一人操作 Task-Master、PM、Architect、Backend/Frontend、QA、Review
- 每一階段完成後，仍要更新 `TASKS.md` 與 `STATE.md`

### 2 人模式

- 角色 A：PM / Architect / Review
- 角色 B：Backend / Frontend / QA

原則是減少切換，不是追求角色完整模擬。

---

## 何時升級回完整模式

出現以下任一情況時，應升級回完整 Pipeline：

- 第二個以上 feature 開始並行
- 有外部依賴、供應商等待、或高整合風險
- 需要正式 Gate 簽核
- 出現資料模型或架構邊界調整
- 專案開始進入上線、合規、或多人交接階段

---

## Lite Review Checklist

在宣布 Lite feature 完成前，至少確認：

- F-code、任務、目前狀態都已更新
- 需求與 AC 可被他人看懂
- 設計說明足夠讓下個人接手
- 程式碼已有最小驗證證據
- 沒有違反三域標準的明顯問題
- `resume_command` 能讓新 session 直接接續

---

## 推薦啟動話術

### 新專案第一個功能

`讀取 CLAUDE.md，使用 Lite Mode 啟動 F01，幫我用最小可用流程完成需求、設計、實作與驗證。`

### 舊專案接手下一個功能

`讀取 CLAUDE.md 和 memory/STATE.md，使用 Lite Mode 接手目前最優先功能，先補最小需求與設計，再開始實作。`

### 從 Lite 升級回完整模式

`目前功能複雜度已超過 Lite Mode，請改走完整 Pipeline，並告訴我接下來從哪個 Gate 或哪個 Agent 開始。`
