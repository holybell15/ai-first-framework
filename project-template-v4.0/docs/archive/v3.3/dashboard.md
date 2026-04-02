# PROJECT_DASHBOARD.html — 技術文件

> ⛔ **修改前必讀**。此檔案記錄 Dashboard 的完整結構與設計決策，避免重複理解或錯誤覆寫。

---

## 基本資訊

| 項目 | 內容 |
|------|------|
| **檔案路徑** | `PROJECT_DASHBOARD.html`（根目錄） |
| **目前大小** | ~109KB（_PROJECT_TEMPLATE 版）|
| **`<div>` 平衡** | 修改後請重新驗證（每次修改後須驗證） |
| **外部依賴** | 無（不使用任何 CDN） |
| **設計系統** | ICONS 物件 + `svg()` 函式，stroke-width: 1.75 |

---

## Tab 結構總覽

| Tab ID | 名稱 | 色點 | 主要功能 |
|--------|------|------|---------|
| `pipeline` | Pipeline 視角 | 紫 `#7C3AED` | 6 個 Pipeline 卡片 + 執行狀態徽章 + 可展開階段作業卡 |
| `agent` | Agent 視角 | 藍 `#1B5FD6` | 11 個 Agent 卡片 + 執行狀態摘要列 |
| `gate` | Gate 視角 | 青 `#0891B2` | 3 個 Gate 檢核清單 + 通過狀態 |
| `retro` | 回顧視角 | 綠 `#059669` | 里程碑回顧、PIP、持續改善 |
| `status` | 專案狀態 | 紫 `#7C3AED` | 進行中任務、待辦、文件清單、Agent 路由 |
| `ops` | Ops 監看 | 紅 `#DC2626` | Current Focus、Agent / Handoff、Blockers、Recovery、Live Queue、Hotfix / Gap Watch |
| `health` | 健康儀表板 | 綠 `#059669` | 健康分數環、文件覆蓋矩陣、Gantt、Prototype 預覽 |
| `lifecycle` | 功能狀態 | 橘 `#EA580C` | Feature Lifecycle 總覽、Owner 責任人、Gate SLA 參考 |
| `slice` | Slice 治理 | 藍綠 `#0D9488` | Slice Backlog 表格 + Blocker 追蹤 + Vendor Confirmation + Cross-Slice Check |
| `guide` | 使用指南 | 琥珀 `#D97706` | Start Here、Lite Mode、Validation / Repair、Command / 資料夾 / 常見問題 |
| `changelog` | 更新日誌 | 紫 `#7C3AED` | Dashboard 版本歷史與框架更新摘要 |

---

## 唯一資料源：`PROJECT_STATUS` 物件 + 外部 `PROJECT_DASHBOARD.data.js`

> 位於 JS 區塊尾段（搜尋 `var PROJECT_STATUS`）。Dashboard 會先載入 `PROJECT_STATUS` 預設值，再用 `PROJECT_DASHBOARD.data.js` 覆蓋。  
> **專案日常使用時，優先更新 SSOT 並執行 `scripts/refresh-dashboard-data.py`，不要手工改一堆 JS。**

```javascript
var PROJECT_STATUS = {
  overview: {
    name: '...',        // 專案名稱
    type: '...',        // 產品類型
    tech: '...',        // 技術棧
    stage: '...',       // 階段（概念期/規格期/開發期/上線期）
    stageNote: '...',   // 目前里程碑描述
    updated: 'YYYY-MM-DD'
  },

  pipelineLog: [        // Pipeline 執行紀錄（已完成的 Agent 任務）
    { id:'P001', agent:'Interviewer Agent', owner:'王小明', status:'done', date:'YYYY-MM-DD', note:'...' }
  ],

  inProgress: [         // 目前進行中的任務
    { id:'T003', task:'...', agent:'Architect', owner:'李小華', priority:'P0', note:'...', nextCmd:'執行 Pipeline: 技術設計' }
  ],

  backlog: [            // 待規劃任務
    { id:'T016', task:'...', agent:'PM Agent', priority:'中', note:'...' }
  ],

  todos: [              // 對照 memory/last_task.md 的待辦事項
    { priority:'P0', item:'...', seed:'context-seeds/SEED_Architect.md' }
  ],

  documents: [          // 已產出文件清單
    { docId:'RS-001', file:'...', folder:'02_Specifications/', status:'✅ v0.2', agent:'PM/Review', date:'YYYY-MM-DD', path:'02_Specifications/...' }
  ],

  ops: {                // Ops 監看資料（建議由 refresh script 產生）
    synced_at: '...',
    current_feature: '...',
    current_work: '...',
    blockers: [],
    work_queue: [],
    recent_outputs: []
  },

  routes: [ ... ],      // Agent 路由表（固定，通常不需改）

  pipelineCompletion: { // Pipeline 完成狀態
    'P01':'pending',    // 改為 'done' | 'active' | 'pending'
    'P02':'pending',
    'P03':'pending', 'P04':'pending', 'P05':'pending', 'P06':'pending'
  },

  gateStatus: {         // Gate 通過狀態
    gate1:'pending',    // 改為 'done' | 'active' | 'pending'
    gate2:'pending', gate3:'pending'
  },

  protoFiles: [         // Prototype 預覽清單（Tab 6 健康儀表板）
    { name:'...', file:'...', note:'...' }
  ]
};
```

### HOW TO UPDATE（每次 Agent 完成任務後）

1. 更新 `memory/STATE.md`
2. 更新 `TASKS.md`
3. 有正式文件產出時更新 `MASTER_INDEX.md`
4. 執行 `python3 scripts/refresh-dashboard-data.py`
5. 重新整理 Dashboard，確認 Ops Tab 與專案狀態一致
6. 只有在 framework 開發 / 結構調整時，才手工改 `PROJECT_STATUS` 預設資料

---

## 主要 JS 函式

| 函式 | 用途 | 觸發時機 |
|------|------|---------|
| `initDashboard()` | 頁面初始化，呼叫所有 render | DOMContentLoaded |
| `switchTab(id, btn)` | 切換 Tab 顯示 | 點擊 Tab 按鈕 |
| `renderPipelineStatus()` | 讀 `pipelineCompletion`，在 Pipeline 卡片加狀態徽章 | initDashboard |
| `deriveAgentStatus()` | 從 `pipelineLog`/`inProgress` 自動推算 11 個 Agent 狀態 | renderAgents 內呼叫 |
| `renderAgents()` | 渲染 Agent 卡片 + 摘要列（已執行/進行中/待執行計數） | initDashboard |
| `renderGateChecklists()` | 渲染 Gate 檢核清單 | initDashboard |
| `renderStatus()` | 渲染 Tab 5 所有區塊（任務、待辦、文件、路由） | initDashboard |
| `renderOps()` | 渲染 Ops 監看 Tab | initDashboard |
| `renderHealth()` | 呼叫 Tab 6 所有子函式 | initDashboard |
| `renderHealthScore()` | 計算健康分數（Pipeline 35% + Gate 25% + 文件 25% + Todo 15%）並繪製 SVG 環 | renderHealth |
| `renderDocCoverage()` | 渲染 11×5 文件覆蓋矩陣 | renderHealth |
| `renderGantt()` | 渲染 6 個 Pipeline 的 Gantt 進度條 | renderHealth |
| `renderProtoList()` | 渲染 Prototype 快速預覽連結 | renderHealth |
| `renderSliceGovernance()` | 渲染 Slice 治理 Tab（Backlog 表格 + Blocker + Vendor + Cross-Slice） | load |
| `exportReport()` | 匯出純文字專案報告 | 點擊 Export 按鈕 |
| `copyCmd(cmd)` | 複製指令到剪貼簿 | 點擊 nextCmd chip |

---

## 關鍵 CSS Class

| Class | 用途 |
|-------|------|
| `.pipe-status-badge.done/active/pending` | Pipeline 卡片狀態徽章 |
| `.ac-status-badge.done/active/pending` | Agent 卡片狀態徽章 |
| `.agent-summary-bar` | Agent Tab 頂部統計列容器 |
| `.asb-chip.done/active/pending` | 統計列內的計數 chip |
| `.asb-total` | 統計列右側「共 N 個 Agent」 |
| `.gate-chip.done/active/pending` | Gate 通過狀態 chip |
| `.next-cmd-chip` | Tab 5 進行中任務的「下一步指令」chip |
| `.doc-link` | Tab 5 文件清單的可點擊連結 |
| `@keyframes pulse-badge` | active 狀態的呼吸動畫（2s infinite） |

---

## Agent ID 對照表（`deriveAgentStatus` 用）

`deriveAgentStatus()` 以 **模糊比對** 從 `pipelineLog[].agent` 和 `inProgress[].agent` 欄位推算狀態，對應規則如下：

| Agent ID | 比對關鍵字 |
|----------|-----------|
| `interviewer` | `interviewer` |
| `pm` | `pm agent`、`pm `、`(pm)` |
| `ux` | `ux agent`、`ux `、`(ux)` |
| `architect` | `architect` |
| `frontend` | `frontend` |
| `backend` | `backend` |
| `dba` | `dba` |
| `devops` | `devops` |
| `qa` | `qa agent`、`qa `、`(qa)` |
| `security` | `security` |
| `review` | `review agent`、`review ` |

**推算邏輯**：`pipelineLog` 有紀錄 → `done`；`inProgress` 有紀錄且非 done → `active`；其餘 → `pending`

---

## 修改守則

1. **⛔ 禁止另開新檔**：只能在現有檔案上 Edit，不得另存新版或重寫
2. **每次修改後驗證** `<div>` 平衡：`python3 -c "import re; c=open('PROJECT_DASHBOARD.html').read(); print(len(re.findall(r'<div[\s>]',c)), len(re.findall(r'</div>',c)))"`
3. **專案日常同步優先跑 refresh script**：不要把 dashboard 當成另一份手工狀態表
4. **Guide Tab 需反映實際入口**：若 README / START_HERE / Lite Mode / validation repair / Hotfix / Brownfield 路由有變更，Guide Tab 要一起更新
5. **特殊流程要雙向同步**：Hotfix 與 Brownfield 若改成 Lite / Standard 雙軌，需同步更新 Pipeline 卡、Guide Tab、`PROJECT_STATUS.routes`、Release Notes
6. **Ops Tab 是監看頁，不是介紹頁**：優先顯示「現在在做什麼 / 卡在哪 / 下一句輸入什麼」
