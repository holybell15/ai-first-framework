# 三層工作流測試體系

## Goal
建立可重複執行的工作流品質測試，讓每次流程修改後能快速驗證「有沒有變好」。

## Phases

### Phase 1: Tier 1 — 更新結構驗證（run_tests.py）
**Status:** pending
- 更新 PIPELINE_CONFIG 對應 v2.9（P00+P01 精煉+Slice Cycle）
- 新增 G4-ENG-D / G4-ENG-R 雙層 Gate 驗證
- 新增 slice-cycle skill 存在性驗證
- 新增 TEMPLATE_SRS_Complete / TEMPLATE_RS_Function_Spec 存在性
- 新增 Cross-Slice Integration Check 觸發規則驗證

### Phase 2: Tier 2 — 流程模擬（workflow-simulation.py）
**Status:** pending
- 用假功能「用戶登入」模擬 P00→P01→P02→Slice S01
- 每步檢查產出物是否符合模板結構
- 不呼叫 LLM（純結構驗證）+ 可選 LLM 評分

### Phase 3: Tier 3 — A/B 品質比對（workflow-ab-test.py）
**Status:** pending
- 同一個需求「座席管理 CRUD」用舊流程 vs 新流程各產出一次
- LLM-as-Judge 評分：完整度/一致性/可開發性/可測試性/scope 控制
- 產出比較報告

### Phase 4: 整合 + HTML 報告
**Status:** pending
- 三層測試統一 HTML 報告
- 一鍵執行指令

## Decisions
- Tier 1 直接修改現有 run_tests.py
- Tier 2 新建 workflow-simulation.py
- Tier 3 新建 workflow-ab-test.py
- 三層共用 HTML 報告框架

---

## 2026-03-30 Priority Adjustment

### Goal
把框架的下一階段工作收斂成 5 個高優先補強方向，優先解決 adoption friction、規則不可驗證、文件同步成本高等問題。

### Phases

#### Phase A: Roadmap 定義
**Status:** completed
- 盤點目前框架的優勢、限制與主要風險
- 收斂出 5 個優先補強主題
- 建立 `docs/ROADMAP_PRIORITIES.md`

#### Phase B: 入口文件掛接
**Status:** completed
- 在 `README.md` 新增 roadmap 入口
- 讓後續執行不依賴對話背景

#### Phase C: 第一個補強項目落地
**Status:** in_progress
- 建立 `docs/LITE_MODE.md`
- 更新 `README.md` 與 template `CLAUDE.md` 的 Lite 入口
- 後續再補 Lite Mode 對應的 command / health check

#### Phase D: 後續優先項目落地
**Status:** in_progress
- 建立 framework validation 入口與 CI workflow
- 建立資訊架構責任邊界文件
- 建立 Lite Mode demo project
- 建立 Start Here 導覽入口

#### Phase E: Lite Mode routing
**Status:** in_progress
- 將 Lite Mode 接入 `info-init`
- 將 Lite Mode 接入 `info-pipeline`
- 將 Lite Mode 接入 `info-task-master`
- 將 orchestrator 補上 Lite 路由規則

#### Phase F: Lite-aware docs and repair guide
**Status:** in_progress
- 更新 `docs/AGENTS.md`
- 更新 `docs/AGENT_SYNC.md`
- 建立 `docs/VALIDATION_REPAIR.md`
- 讓 validation script 提示修復入口

#### Phase G: Dashboard alignment
**Status:** in_progress
- 更新 `PROJECT_DASHBOARD.html` 的 Guide Tab
- 將 Start Here / Lite Mode / Validation Repair 反映到 dashboard
- 同步 `memory/dashboard.md` 的維護說明

### Decisions
- 優先順序定為：Lite Mode → 規則腳本化 → 文件邊界 → 示範專案 → 採用體驗
- 先把調整路線圖寫進 repo，再開始逐項實作

---

## 2026-03-30 Hotfix / Brownfield rewrite

### Goal
保留完整理想流程，但把 Hotfix 與舊專案接入重寫成小團隊也能直接採用的雙軌版本。

### Phases

#### Phase H: Process review
**Status:** completed
- 重新審視 README、PIPELINES、`info-hotfix`、`adopt-project.sh`
- 找出與小團隊現況不相容的理想化前提

#### Phase I: Hotfix dual-track rewrite
**Status:** completed
- 將 Hotfix 改成 Lite / Standard 雙軌
- 定義 Lite 模式的最小 rollback、驗證、補件要求

#### Phase J: Brownfield dual-track rewrite
**Status:** completed
- 將舊專案接入改成 Lite / Standard 雙軌
- 明確定義接入後修改舊功能的四步法最低要求

#### Phase K: Script alignment
**Status:** completed
- 改造 `adopt-project.sh` 的逐檔補齊邏輯
- 新增 `memory/adoption_gap_report.md` 初始模板
- 更新接入摘要與下一步指引

### Decisions
- 熱修與 Brownfield 都保留完整理想流程，但預設入口改為先判斷 Lite 是否更適合
- Brownfield 真正需要的是 baseline + gap report，而不是一開始就假設能在 1~2 天補完整個 legacy 治理層
