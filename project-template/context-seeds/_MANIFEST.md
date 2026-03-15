# 📦 SEED 檔案清單 & 版本記錄

## 清單概覽

- **版本**：1.0
- **建立日期**：2026-03-08
- **總檔案數**：13 個（11 個 SEED + 2 個說明文件）
- **總大小**：68 KB
- **適用範圍**：PROJECT_TEMPLATE 通用版

---

## 核心 SEED 檔案（11 個）

| 編號 | 檔案名稱 | 角色 | 行數 | 說明 |
|------|---------|------|------|------|
| 1 | SEED_Interviewer.md | 需求訪談師 | 50 | 新功能需求訪談與摘要 |
| 2 | SEED_PM.md | 產品經理 | 54 | 需求轉為 RS 與 User Story |
| 3 | SEED_UX.md | UX 設計師 | 75 | 用戶旅程、流程、Wireframe |
| 4 | SEED_Architect.md | 系統架構師 | 59 | 架構設計與技術決策(ADR) |
| 5 | SEED_Frontend.md | 前端工程師 | 52 | UI 元件與頁面實作 |
| 6 | SEED_Backend.md | 後端工程師 | 59 | API 設計與商業邏輯 |
| 7 | SEED_DBA.md | 資料庫管理師 | 53 | 資料模型設計與 Schema |
| 8 | SEED_DevOps.md | 部署工程師 | 62 | 環境建置與 CI/CD |
| 9 | SEED_QA.md | QA 工程師 | 59 | 測試計劃與測試案例 |
| 10 | SEED_Security.md | 資安專家 | 58 | 資安審查與合規確認 |
| 11 | SEED_Review.md | 總審查官 | 59 | Code Review 與文件審查 |

**小計**：11 個核心 SEED 檔案，共 640 行

---

## 輔助文件（2 個）

| 檔案名稱 | 用途 | 內容 |
|---------|------|------|
| README.md | 完整使用說明 | 詳細介紹每個 SEED 的使用方式、佔位符速查表、常見問題 |
| QUICK_START.txt | 快速參考卡 | 30 秒上手指南、工作流程、佔位符對照表 |

---

## 檔案結構驗證

```
context-seeds/
├── _MANIFEST.md              ← 你在這裡
├── QUICK_START.txt           ← 快速開始指南
├── README.md                 ← 完整文件
├── SEED_Interviewer.md       ← Agent 1
├── SEED_PM.md                ← Agent 2
├── SEED_UX.md                ← Agent 3
├── SEED_Architect.md         ← Agent 4
├── SEED_Frontend.md          ← Agent 5
├── SEED_Backend.md           ← Agent 6
├── SEED_DBA.md               ← Agent 7
├── SEED_DevOps.md            ← Agent 8
├── SEED_QA.md                ← Agent 9
├── SEED_Security.md          ← Agent 10
└── SEED_Review.md            ← Agent 11
```

---

## 佔位符統一標準

所有 SEED 檔案均使用以下佔位符規範：

### 產品信息類
```
[產品名稱]
[SaaS / App / 內部工具 / ...]
[負責人背景]
```

### 技術棧類
```
[前端]                    → 需替換為前端框架（Vue 3 / React 等）
[後端]                    → 需替換為後端框架（Spring Boot / Express 等）
[資料庫]                  → 需替換為資料庫類型（MySQL / PostgreSQL 等）
[雲端]                    → 需替換為雲端平台（GCP / AWS / Azure 等）
[前端框架]                → 明確指定前端框架
[後端框架與語言]          → 明確指定後端框架與語言
[主資料庫]                → 明確指定主資料庫
[整合資料庫]              → 明確指定整合資料庫（若有）
[雲端平台]                → 明確指定雲端平台
[AI 整合]                 → 明確指定 AI 方案
```

### 其他類
```
[適用法規]
[環境]
[元件名稱]
[功能名稱]
[決策主題]
[日期]
```

---

## 質量檢查清單

### 格式驗證
- [x] 所有 Markdown 代碼區塊配對正確（```）
- [x] 所有檔案編碼為 UTF-8
- [x] 所有檔案結尾無多餘空行

### 內容驗證
- [x] 11 個核心 SEED 檔案完整
- [x] 所有佔位符格式統一（使用 [xxx]）
- [x] 每個 SEED 都含有「種子提示詞」區塊
- [x] 每個 SEED 都含有「適用場景」說明
- [x] 每個 SEED 都含有「輸出位置」說明

### 可用性驗證
- [x] README.md 提供完整使用指南
- [x] QUICK_START.txt 提供快速參考
- [x] 佔位符對照表清晰完整
- [x] Agent 角色與工作流程說明清楚

---

## 版本歷史

### v1.0 (2026-03-08) — 初始版本
- 建立 11 個通用版 SEED 檔案
- 移除所有產品特定細節，替換為 [佔位符]
- 保留所有結構、規則、輸出格式
- 新增 README.md 與 QUICK_START.txt 說明檔

---

## 使用建議

### 適用場景
- 新增任何新專案時，複製本 context-seeds 目錄
- 替換 [佔位符] 為實際產品資訊
- 即可開始使用各角色 Agent

### 推薦工作流程

#### 新功能從 0 到 1
```
Interviewer Agent → PM Agent → UX Agent → Architect Agent 
→ Frontend/Backend Agent → QA Agent → Security Agent → Review Agent
```

#### 快速原型開發
```
UX Agent → Frontend Agent → Review Agent
```

#### 後端開發
```
Architect Agent → Backend Agent → DBA Agent → DevOps Agent
```

#### 上線前準備
```
Security Agent → DevOps Agent → QA Agent → Review Agent
```

---

## 常見問題解答

**Q: 這些檔案可以直接用在我的專案嗎？**
A: 可以，但需要先替換所有 [佔位符]。

**Q: 可以修改 SEED 的內容嗎？**
A: 完全可以。根據專案需求自由調整。

**Q: 如何確保多個 Agent 的協作順暢？**
A: 在 TASKS.md 中記錄每個 Agent 的交接信息。

**Q: SEED 包含 AI 功能相關內容嗎？**
A: 是的，多個 SEED 都有涉及 AI 相關考量。

**Q: 這套 SEED 應該如何版本控制？**
A: 建議：
- 核心 SEED 檔案保持不變
- 專案特定修改放在專案層級的 CLAUDE.md
- 在 memory/decisions.md 記錄重要調整

---

## 後續改進方向

- [ ] 增加 SEED 的多語言版本（中文已完成）
- [ ] 針對特定技術棧（如 Next.js + Go）的專門版本
- [ ] 互動式 CLI 工具自動替換佔位符
- [ ] 每季度檢視實際專案使用經驗，更新最佳實踐

---

## 相關文件

- **完整使用指南**：見 README.md
- **快速開始卡**：見 QUICK_START.txt
- **專案主導航**：見上層 CLAUDE.md
- **決策記錄**：見 memory/decisions.md

---

**最後更新**：2026-03-08
**維護者**：PROJECT_TEMPLATE Owner
**狀態**：Active
