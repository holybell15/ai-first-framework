顯示 Agent 選單，載入對應 SEED 檔並啟動該 Agent 角色。

**Step 1 — 顯示選單**
```
請選擇要啟動的 Agent：

  1.  Interviewer  → 需求訪談、釐清模糊需求
  2.  PM           → User Story、AC 撰寫、需求規格整理
  3.  UX           → 用戶流程設計、Prototype 製作
  4.  Architect    → 系統架構設計、ADR 決策記錄
  5.  DBA          → DB Schema 設計、Migration 計畫
  6.  Backend      → API Spec、後端實作、Exception 處理
  7.  Frontend     → UI 元件實作、Design Token、前端整合
  8.  QA           → 測試案例設計、E2E 執行、NYQ 驗證
  9.  Security     → 資安審查、合規確認、多租戶安全
  10. DevOps       → CI/CD、部署計畫、Rollback、雲端設定
  11. Review       → Gate 驗收、Code Review、文件審查（⚠️ 新 session）

輸入數字：
```

**Step 2 — 載入 SEED 並啟動**

根據選擇，讀取對應檔案：

| 選擇 | 讀取的 SEED 檔 |
|------|--------------|
| 1 Interviewer | `context-seeds/SEED_Interviewer.md` |
| 2 PM | `context-seeds/SEED_PM.md` |
| 3 UX | `context-seeds/SEED_UX.md` |
| 4 Architect | `context-seeds/SEED_Architect.md` |
| 5 DBA | `context-seeds/SEED_DBA.md` |
| 6 Backend | `context-seeds/SEED_Backend.md` |
| 7 Frontend | `context-seeds/SEED_Frontend.md` |
| 8 QA | `context-seeds/SEED_QA.md` |
| 9 Security | `context-seeds/SEED_Security.md` |
| 10 DevOps | `context-seeds/SEED_DevOps.md` |
| 11 Review | `context-seeds/SEED_Review.md` |

讀取 SEED 檔後，宣告角色並詢問：
```
✅ [Agent名稱] 已啟動。
請描述你需要我做什麼？
（或直接告訴我 F-code，我會先讀取相關文件再開始）
```

**Step 3 — 上下文接地（Grounding）**

啟動後，若使用者提供了 F-code，先讀取：
- `TASKS.md` → 確認該 Feature 目前狀態
- `memory/STATE.md` → 確認目前 Pipeline 階段
- 對應的上游文件（例：PM 啟動時讀 IR-*.md；Backend 啟動時讀 F##-API.md）

**注意事項**
- 選 11（Review）時，額外提示：「⚠️ Gate Review 應在新 session 執行，避免審查偏差。請開新終端機視窗或新 Cowork task，再說 /agent 選 11。」
- 若直接帶參數（例：`/agent pm`），跳過選單，直接載入對應 SEED
- 若帶 F-code（例：`/agent backend F03`），載入 SEED 後自動讀取 F03 相關文件
