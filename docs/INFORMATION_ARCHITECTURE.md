# Information Architecture

> 本文件定義 AI-First Framework 核心文件的責任邊界，避免同一資訊重複維護、交接時找不到唯一真相來源、或長期使用後文件彼此漂移。

---

## 設計原則

1. 一份資訊只應有一個主要落點
2. 其他文件可以引用或摘要，但不應重新成為主檔
3. Agent 更新責任要清楚，不依賴個人默契
4. 先解決接手成本，再擴充文件密度

---

## 核心文件責任矩陣

| 文件 | 主要用途 | 允許記錄的資訊 | 不應記錄的資訊 | 主要更新者 |
|------|---------|---------------|---------------|-----------|
| `memory/STATE.md` | 當前工作態與恢復點 | 現在做到哪、誰在做、下一步、阻塞、resume command | 完整決策歷史、正式規格、完整任務列表 | 當前 Agent / Task-Master |
| `TASKS.md` | 任務追蹤與交接 | 任務狀態、優先級、交接摘要、執行記錄 | 詳細架構決策、正式文件成熟度、長期知識庫 | PM / Task-Master / 各 Agent 交接時 |
| `MASTER_INDEX.md` | 正式產出文件登記 | 文件名稱、版本、成熟度、最後 Gate、F-code 分配 | 交接摘要、當前阻塞、實作細節 | PM / Architect / Review |
| `memory/decisions.md` | 關鍵決策歷史 | ADR、架構取捨、重大流程決策、依賴關係 | 每日工作進度、短期暫存資訊 | Architect / Review |
| `memory/product.md` | 產品與技術基線 | 產品定位、技術棧、核心背景 | 單一 feature 的實作狀態、短期任務 | PM / Architect |
| `memory/TECH_DEBT.md` | 技術債登記 | 已知缺口、風險、延期項、改善建議 | 當前 sprint 任務分派 | Architect / Backend / Frontend |

---

## 寫入位置判斷

### 問題 1：這是「現在」還是「正式」

- 若是「現在做到哪」→ `memory/STATE.md`
- 若是「正式產出文件是否存在」→ `MASTER_INDEX.md`

### 問題 2：這是「任務」還是「決策」

- 若是「誰做什麼」→ `TASKS.md`
- 若是「為什麼這樣做」→ `memory/decisions.md`

### 問題 3：這是「產品背景」還是「功能進度」

- 若是產品層設定 → `memory/product.md`
- 若是單一功能現況 → `TASKS.md` 或 `memory/STATE.md`

---

## 常見資訊應寫在哪裡

| 資訊類型 | 正確位置 | 原因 |
|---------|---------|------|
| 下一個 session 要接什麼 | `memory/STATE.md` | 這是恢復點資訊 |
| 本週任務由誰負責 | `TASKS.md` | 這是任務與責任分派 |
| F-code 與文件版本 | `MASTER_INDEX.md` | 這是正式登記索引 |
| 為什麼選這個 DB 設計 | `memory/decisions.md` | 這是決策，不是進度 |
| 技術債與延後處理項 | `memory/TECH_DEBT.md` | 需要長期追蹤，不是短期狀態 |
| 前後端技術棧 | `memory/product.md` | 這是專案基線資訊 |

---

## 允許重複的唯一例外

以下情況允許摘要式重複，但主檔仍只有一個：

1. `TASKS.md` 交接摘要可提到正式文件路徑，但不重寫完整內容
2. `memory/STATE.md` 可寫最近 3-5 個鎖定決策摘要，但完整版本仍在 `memory/decisions.md`
3. `CLAUDE.md` 可做導覽，但不能取代正式規範文件

---

## Agent 更新責任

| Agent | 最低更新責任 |
|------|-------------|
| Task-Master | `TASKS.md` 優先順序、`memory/STATE.md` 恢復點 |
| PM | `TASKS.md`、`MASTER_INDEX.md`、需求文件 |
| Architect | `memory/decisions.md`、`MASTER_INDEX.md`、設計文件 |
| Backend / Frontend | 實作文件、必要時補 `TASKS.md` 交接摘要 |
| QA | 測試報告、`TASKS.md` 驗證結果 |
| Review | Gate 結果、`MASTER_INDEX.md` 成熟度、必要時更新 `memory/STATE.md` |

---

## 更新規則

### `memory/STATE.md`

- 每次 session 結束前更新
- Agent handoff 前更新
- 使用者說「暫停」時更新

### `TASKS.md`

- 任務狀態改變時更新
- 每次 Agent 完成後貼交接摘要
- Pipeline 切換時追加執行記錄

### `MASTER_INDEX.md`

- 新增正式文件時更新
- Gate 通過時更新成熟度
- F-code 登記時更新分配表

### `memory/decisions.md`

- 有架構、資料模型、流程規則決策時更新
- 不要拿來記錄日常工作碎片

---

## Anti-Patterns

- 在 `STATE.md` 記一長串歷史決策
- 在 `TASKS.md` 重新寫一份架構規格
- 在 `MASTER_INDEX.md` 當任務清單使用
- 在 `CLAUDE.md` 塞進大量會持續變動的操作狀態
- 同一個阻塞原因同時維護在 3 個以上檔案

---

## 建議驗證規則

未來 workflow checks 應優先驗證：

- `STATE.md` 是否包含 `current_focus` 與 `resume_command`
- `TASKS.md` 是否包含目前 sprint / backlog / 交接摘要區
- `MASTER_INDEX.md` 是否包含 F-code 分配表
- `memory/decisions.md` 是否仍維持 ADR 性質，而不是任務日誌
