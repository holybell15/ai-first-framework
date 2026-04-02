顯示 Pipeline 選單並啟動：

**Step 1 — 顯示選單**
```
請選擇要執行的 Pipeline：

  L. Lite Mode       → 最小可用流程（第一次使用 / 1-2 人 / 第一個 feature）
  1. P01 需求訪談     → Interviewer → PM → UX → Gate 1
  2. P02 技術設計     → Architect → DBA → Review → Gate 2
  3. P03 開發準備     → Backend → Frontend → QA → G4-ENG
  4. P04 實作開發     → Backend → Frontend → QA → Gate 3
  5. P05 合規審查     → Security → Review
  6. P06 部署上線     → DevOps → Review → L2 Retro
  7. 舊專案接入       → 4 Agent 並行掃描 → Baseline → 技術債登記

  H. Hotfix          → 緊急修復通道（Critical/High 專用）
  T. Task-Master     → 查看目前優先任務派遣報告

輸入數字、L、H 或 T：
```

**Step 2 — 前置確認**
根據選擇，確認前置條件：
- Lite Mode：確認這是第一個 feature、或目前僅 1-2 人、或功能複雜度不高
- P02：確認 Gate 1 已通過（`07_Retrospectives/` 有 Gate 1 報告）
- P03：確認 Gate 2 已通過
- P04：確認 G4-ENG 已通過（`F##-ENG-RVW.md` 存在且無 Block）
- P05/P06：確認 Gate 3 已通過
- 舊專案接入：確認 `scripts/adopt-project.sh` 已執行，且 `/info-setup-team` 已完成

若前置條件不滿足，告知缺少什麼並停止。

若選擇 T（Task-Master）→ 執行 `/info-task-master` 流程後結束。
若選擇 H（Hotfix）→ 執行 `/info-hotfix` 流程後結束。
若選擇 L（Lite Mode）→ 讀取 `docs/LITE_MODE.md`，並輸出以下啟動建議後結束：

```
⚡ 建議使用 Lite Mode 啟動：

讀取 CLAUDE.md，使用 Lite Mode 啟動 F01

最低要求：
- 登記 F-code
- 補一份最小需求文件
- 補一份最小設計文件
- 完成最小測試與 Lite Review
```

**Step 3 — Discuss Phase（P02 / P04 適用）**
P01→P02 銜接時問：
- 「前後端框架確認了嗎？有無更改？」
- 「雲端平台偏好？」

P03→P04 銜接時問：
- 「TDD 強制執行嗎？」
- 「Backend / Frontend 並行還是順序？」

**Step 4 — Quick Mode 判斷**
詢問：「這個 Pipeline 是否適用 Quick Mode？（修改 ≤ 3 檔案、無新功能、5 分鐘可驗證）」
- 是 → 跳過 Pipeline，直接執行變更
- 否 → 繼續正常 Pipeline

**Step 5 — 啟動**
讀取 `context-skills/pipeline-orchestrator/SKILL.md`，啟動對應 Pipeline。
更新 `memory/STATE.md` 的 `phase` 欄位。
