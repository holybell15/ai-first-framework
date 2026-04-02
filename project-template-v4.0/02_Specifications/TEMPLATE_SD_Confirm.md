---
doc_id: SDC.F##.CONFIRM
title: 系統設計確認書 — [功能名稱]
version: v1.0.0
maturity: Draft
owner: Architect + PM
module: F##
feature: [功能名稱]
phase: P02
last_gate: Gate 2
created: YYYY-MM-DD
updated: YYYY-MM-DD
upstream: [SRS, US_F##, SCB_F##]
downstream: [F##-SLICE-BACKLOG, WBS_Confirm, Gate 2]
---

# 系統設計確認書 — [功能名稱]

> **用途**：P02 技術設計完成後，由相關人員確認架構方案、技術選型、風險評估。
> **產出時機**：P02 所有設計文件完成後、Gate 2 審核前。
> **審核者**：系統分析/架構設計 + 專案經理 + 工程師。
> **重要**：此確認書簽核後，技術方案即為 Baseline。後續架構變更需走 CIA + ADR。
> **產出格式**：Markdown（內部用）或 Word（正式簽核用，以 docx skill 生成）。

---

## 1. 設計總覽

| 項目 | 內容 |
|------|------|
| **專案名稱** | [產品名稱] |
| **功能範圍** | [F## 功能名稱，對應的 SRS 章節] |
| **設計文件版本** | SW-ARCH v[N] / HW-ARCH v[N] / DB v[N] |
| **對應 SRS 版本** | SRS v[N]（P00 C2 簽核版） |
| **設計期間** | YYYY-MM-DD ~ YYYY-MM-DD |

---

## 2. 架構方案摘要

> 從 `F##-SW-ARCH.md` 摘要。確認者不需讀完整架構文件，但需理解以下決策。

### 2.1 系統架構概述

```
[一段 3-5 行的架構概述，如：
本系統採用前後端分離架構。後端使用 Spring Boot 提供 REST API，
前端使用 Vue 3 SPA。資料庫使用 PostgreSQL，快取使用 Redis。
部署在 GCP Cloud Run，使用 Cloud SQL 託管資料庫。]
```

### 2.2 技術選型決策

| 領域 | 選擇 | 替代方案 | 選擇理由（摘自 ADR） |
|------|------|---------|-------------------|
| 後端框架 | [Spring Boot] | [Express.js / FastAPI] | [ADR-01: 理由摘要] |
| 前端框架 | [Vue 3] | [React / Svelte] | [ADR-02: 理由摘要] |
| 資料庫 | [PostgreSQL] | [MySQL / MongoDB] | [ADR-03: 理由摘要] |
| 快取 | [Redis] | [Memcached / 無] | [ADR-04: 理由摘要] |
| 部署平台 | [GCP Cloud Run] | [AWS ECS / K8s] | [ADR-05: 理由摘要] |
| [其他] | [...] | [...] | [ADR-##: ...] |

> **完整 ADR 紀錄**：見 `memory/decisions.md`

### 2.3 系統架構圖

> 從 SW-ARCH 複製或引用，確保確認者看到完整的元件 + 資料流。

```
[架構圖 — ASCII 或指向圖片路徑]
```

---

## 3. 資料設計摘要

> 從 `F##-DB.md` 摘要。

### 3.1 核心資料表

| 表名 | 用途 | 欄位數 | 多租戶 | PII |
|------|------|--------|--------|-----|
| [users] | [使用者帳號] | [12] | ✅ tenant_id | ✅ pii_email, pii_name |
| [calls] | [通話記錄] | [18] | ✅ tenant_id | ❌ |
| [...] | [...] | [...] | [...] | [...] |

### 3.2 資料隔離策略

| 機制 | 說明 |
|------|------|
| 多租戶隔離 | [所有業務表強制 `WHERE tenant_id = :tenantId`] |
| PII 保護 | [pii_ 前綴欄位，存取時動態遮罩] |
| 加密存儲 | [enc_ 前綴欄位，AES-256-GCM] |
| 稽核軌跡 | [log_ 前綴表，不可竄改] |

### 3.3 Migration 策略

| 項目 | 說明 |
|------|------|
| Migration 工具 | [Flyway / Liquibase / 手動 SQL] |
| 版本編號 | [V001, V002, ... 順序執行] |
| 可逆性 | [每個 migration 必須有 rollback script] |

---

## 4. API 設計摘要

> 從 `F##-API.md` 摘要。

### 4.1 API 端點總覽

| Method | Path | 用途 | Auth | 對應 AC |
|--------|------|------|------|---------|
| POST | /api/v1/auth/login | 使用者登入 | Public | AC-01 |
| GET | /api/v1/users/me | 取得個人資料 | Bearer | AC-03 |
| [...] | [...] | [...] | [...] | [...] |

### 4.2 API 設計原則

| 原則 | 本專案做法 |
|------|----------|
| 版本策略 | `/api/v1/`，同時最多維護 2 個版本 |
| Response 格式 | `{ success, data, message, errorCode }` |
| 錯誤碼 | `AICC-{LAYER}{CODE}`（見 Error_Code_Standard） |
| 分頁 | `?page=1&size=20`，預設 20 筆 |
| 多租戶 | tenant_id 從 JWT 取得，禁止 Request Body 傳入 |

---

## 5. 非功能設計

| 指標 | 目標 | 設計方案 |
|------|------|---------|
| 效能 | API 回應 < 2s（P95） | [快取 + 索引 + 連線池] |
| 可用性 | 99.5% uptime | [Cloud Run 自動擴展 + 健康檢查] |
| 安全 | OWASP Top 10 | [參數化查詢 + CORS + CSP + Rate Limit] |
| 擴展性 | 支援 10x 使用者成長 | [無狀態 API + 水平擴展 + DB Read Replica] |
| 備份 | RPO < 1hr / RTO < 4hr | [Cloud SQL 自動備份 + Point-in-time Recovery] |

---

## 6. 風險評估

| # | 風險描述 | 影響 | 機率 | Mitigation |
|---|---------|------|------|-----------|
| R1 | [風險 1] | [高/中/低] | [高/中/低] | [緩解措施] |
| R2 | [風險 2] | [高/中/低] | [高/中/低] | [緩解措施] |
| R3 | [風險 3] | [高/中/低] | [高/中/低] | [緩解措施] |

---

## 7. 外部依賴

| # | 依賴項目 | 提供方 | 狀態 | 影響 |
|---|---------|-------|------|------|
| E1 | [外部 API / SDK / 服務] | [廠商名稱] | 🟢 已確認 / 🟡 待確認 | [影響哪些功能] |
| E2 | [...] | [...] | [...] | [...] |

> 🟡 待確認的外部依賴 → 對應 Slice 標記為 🔗 高外部依賴，需準備 Vendor Confirmation。

---

## 8. 設計文件清單

> 確認以下文件已產出且版本正確。

| 文件 | 路徑 | 版本 | 狀態 |
|------|------|------|------|
| 軟體架構 | `03_System_Design/F##-SW-ARCH.md` | v[N] | ✅ 完成 / ❌ 缺失 |
| 硬體/部署架構 | `03_System_Design/F##-HW-ARCH.md` | v[N] | ✅ / ❌ |
| DB Schema | `03_System_Design/F##-DB.md` | v[N] | ✅ / ❌ |
| ADR 決策紀錄 | `memory/decisions.md` | — | ✅ / ❌ |
| 範圍定版 | `02_Specifications/SCB_F##_*.md` | v[N] | ✅ / ❌ |
| Slice Backlog | `03_System_Design/F##-SLICE-BACKLOG.md` | v[N] | ✅ / ❌ |

---

## 9. 確認事項

> 請確認者逐項勾選後簽名。

### 技術確認（系統分析/架構師）

- [ ] 架構方案合理，符合團隊技術能力
- [ ] 技術選型有依據（ADR 完整），替代方案已評估
- [ ] 資料設計合理（正規化、索引、多租戶隔離）
- [ ] API 設計符合規範（版本策略、錯誤碼、分頁）
- [ ] 非功能需求有對應設計方案
- [ ] 風險評估合理，mitigation 可執行
- [ ] 外部依賴已識別且有應對方案

### 管理確認（專案經理）

- [ ] 設計方案符合需求範圍（SRS 對照無遺漏）
- [ ] 風險可接受或已有 mitigation
- [ ] 外部依賴的時程不影響交付計畫
- [ ] 設計文件清單完整

---

## 簽核

| 角色 | 姓名 | 日期 | 狀態 |
|------|------|------|------|
| 系統分析/架構設計 | [姓名] | YYYY-MM-DD | ✅ 確認 / ❌ 待確認 |
| 專案經理 | [姓名] | YYYY-MM-DD | ✅ 確認 / ❌ 待確認 |
| 工程師代表 | [姓名] | YYYY-MM-DD | ✅ 確認 / ❌ 待確認 |

> **簽核後**：此文件成為技術設計 Baseline。後續架構變更需走 `/cia` + 更新 ADR + 升版此文件。
