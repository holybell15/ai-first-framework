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

| ID | 任務 | 負責 Agent | @負責人 | 狀態 | 備註/交接 |
|----|------|-----------|--------|------|---------|
| T001 | [任務描述] | [Agent] | @[名字] | ⏳ | |

---

## Backlog

| ID | 功能/任務 | 優先級 | 負責 Agent | @負責人 | 狀態 | 備註 |
|----|----------|--------|-----------|--------|------|------|
| B001 | [任務描述] | P0 | [Agent] | @[名字] | ⏳ | |

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

## 📋 Agent 交接摘要格式（每個 Agent 完成後貼入下方）

> **格式規範**：`workflow_rules.md §2`。每次 Agent 完成任務，把交接摘要貼在這裡，
> 讓下一個 Agent 或 Review Agent 不需要重讀整個 session 就能接手。

```
<!-- 範例交接摘要（複製並填入實際內容）

## 🔁 交接摘要 — YYYY-MM-DD

| 項目 | 內容 |
|------|------|
| **我是** | [Agent 名稱，e.g. PM Agent] |
| **交給** | [下一個 Agent，e.g. Architect Agent] |
| **完成了** | [一句話說完成了什麼，e.g. 完成 F02 來電彈屏 User Story，共 6 條 AC] |
| **關鍵決策** | [本階段做的技術/業務決策，e.g. 決定彈屏觸發時機為振鈴事件而非接聽] |
| **產出文件** | [`路徑/檔名_v版本.md`（可多行）] |
| **你需要知道** | [對下一個 Agent 重要的背景，e.g. CRM 為舊系統需 API 串接] |
| **信心度分布** | 🟢 N 項清晰 / 🟡 N 項模糊 / 🔴 N 項阻塞 |
| **🟡 待釐清** | [可繼續但需後續確認的項目，或「無」] |
| **🔴 阻塞項** | [必須先解決才能推進的項目，或「無」] |

-->
```

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
| `執行 Hotfix: [問題描述]` | Review → Backend/Frontend → DevOps → Review | hotfix_log.md（HF-YYYY-NNN）+ hotfix branch | HF 快速審查 |

---

## 🗂️ MASTER_INDEX — 文件總覽

> 每次 Agent 產出新文件，在此更新一行。doc_id 格式：`F##-[類型]-v[版本]`

| doc_id | 檔名 | 狀態 | 產出 Agent | 最後更新 |
|--------|------|------|-----------|---------|
| — | — | — | — | — |

> 新文件加入時，格式範例：
> `| F03-US-v0.1 | F03_US_[功能名稱]_v0.1.md | 草稿 | PM | YYYY-MM-DD |`
