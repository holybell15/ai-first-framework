# TASKS.md — [專案名稱] 任務清單

> 由 PM Agent 維護，所有 Agent 完成任務後在此更新狀態。

---

## 任務狀態說明

| 符號 | 意思 |
|------|------|
| ⏳ | 待開始 |
| 🔄 | 進行中 |
| ✅ | 完成 |
| ❌ | 取消/擱置 |

## 優先級說明

| 級別 | 說明 |
|------|------|
| P0 | MVP 核心，沒有就不能上線 |
| P1 | 重要但可後續迭代 |
| P2 | Nice to have |

---

## 目前 Sprint

**Sprint [編號]**：[開始日期] ～ [結束日期]

| ID | 任務 | 負責 Agent | 狀態 | 備註/交接 |
|----|------|-----------|------|---------|
| T001 | [任務描述] | [Agent] | ⏳ | |

---

## Backlog

| ID | 功能/任務 | 優先級 | 負責 Agent | 狀態 | 備註 |
|----|----------|--------|-----------|------|------|
| B001 | [任務描述] | P0 | [Agent] | ⏳ | |

---

## 完成記錄

| ID | 任務 | 完成日期 | 產出 |
|----|------|---------|------|
| - | - | - | - |

---

## Pipeline 執行記錄

| 時間 | Pipeline | 狀態 | 產出 |
|------|---------|------|------|
| - | - | - | - |

---

## 📌 Pipeline 快速參考

| 指令 | 主要 Agent | 主要輸出 | Gate |
|------|-----------|---------|------|
| `執行 Pipeline: 需求訪談` | Interviewer → PM → UX | IR-[日期].md + F##-US.md + F##-UX.md | Gate 1 |
| `執行 Pipeline: 技術設計` | Architect → DBA → Review | F##-SW-ARCH.md + F##-HW-ARCH.md + F##-DB.md + F##-ARCH-RVW.md | Gate 2 |
| `執行 Pipeline: 開發準備` | Backend → Frontend → QA | F##-API.md + F##-FE-PLAN.md + F##-TC.md | — |
| `執行 Pipeline: 實作開發` | Backend → Frontend → QA | src/ + F##-TR.md（→ 08_Test_Reports/） | Gate 3 |
| `執行 Pipeline: 合規審查` | Security → Review | F##-SEC.md + F##-COMPLY-RVW.md（→ 04_Compliance/） | — |
| `執行 Pipeline: 部署上線` | DevOps → Review | F##-DEPLOY.md + F##-DEPLOY-RVW.md（→ 09_Release_Records/） | L2 回顧 |

---

## 🗂️ MASTER_INDEX — 文件總覽

> 每次 Agent 產出新文件，在此更新一行。doc_id 格式：`F##-[類型]-v[版本]`

| doc_id | 檔名 | 狀態 | 產出 Agent | 最後更新 |
|--------|------|------|-----------|---------|
| — | — | — | — | — |

> 新文件加入時，格式範例：
> `| F03-US-v0.1 | F03_US_[功能名稱]_v0.1.md | 草稿 | PM | YYYY-MM-DD |`
