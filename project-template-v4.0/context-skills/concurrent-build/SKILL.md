---
name: concurrent-build
description: >
  **同一 Feature 內 Backend ∥ Frontend 併發開發 + 跨 Feature 依賴協調。**

  Triggered by: "Backend 和 Frontend 同時做", "並行開發", "split F03", "拆前後端",
  "兩個 Agent 同時跑", "跨 Feature 依賴", "F05 需要 F02 的 API"。

  前提：Tech Spec 已確認（含 Executable Contract），API Contract 是前後端的分界線。

source: AI-First Framework v4.1 — Multi-Agent Concurrency
user-invocable: false
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Concurrent Build: Multi-Agent 併發協調

## 兩層併發模型

```
Layer A — Specialist 並行（同一 Feature 內）
═══════════════════════════════════════════
                    Tech Spec 確認
                         ↓
         ┌───────────────┴───────────────┐
    Backend Agent                  Frontend Agent
    (worktree: f03-be)            (worktree: f03-fe)
    owns: src/backend/            owns: src/frontend/
         ↓                              ↓
    實作 API endpoint ──signal──→ 開始串接 API
         ↓                              ↓
    Backend 完成 ────────→ Merge Point ←──── Frontend 完成
                              ↓
                     整合測試 → Gate

Layer B — Feature 並行（跨 Feature）
═══════════════════════════════════════════
    F02 ████████████████  worktree: f02
    F03 ████████████████  worktree: f03
         ↑
    cross-feature dependency tracking
    shared resource conflict detection
```

---

## Layer A: Specialist 並行

### 啟動條件（全部滿足才能 split）

1. ✅ Tech Spec 已 Baselined（含 §2.3 Executable Contract）
2. ✅ API Contract 明確（每個 endpoint 的 request/response/error 都定義了）
3. ✅ Data Model 已確認（DB Schema 不會在開發中變動）
4. ✅ 共用型別已定義（shared types / DTOs 的結構已 lock）

**不滿足 → 不能 split，繼續串行開發。**

### 啟動指令

```bash
# 將 F03 拆成 backend + frontend 兩個 worktree
bash scripts/parallel-feature.sh split F03

# 產出：
# .worktrees/f03-be/  ← Backend Agent 的工作目錄
# .worktrees/f03-fe/  ← Frontend Agent 的工作目錄
# .coordination/f03/  ← 協調目錄
```

### File Ownership Registry

Split 時自動產生 `.coordination/f03/ownership.yaml`：

```yaml
# .coordination/f03/ownership.yaml
# 定義哪個 Agent 可以寫入哪些目錄/檔案
# 違反 ownership 的寫入會被 hook 攔截

feature: F03
created: 2026-04-05T10:00:00Z

backend:
  worktree: .worktrees/f03-be
  write_allowed:
    - "src/main/java/**"
    - "src/test/java/**"
    - "src/backend/**"
    - "database/**"
  read_only:
    - "src/frontend/**"         # 可讀不可寫
    - "src/shared/**"           # 共用型別只能讀

frontend:
  worktree: .worktrees/f03-fe
  write_allowed:
    - "src/frontend/**"
    - "src/components/**"
    - "src/views/**"
    - "src/composables/**"
    - "src/stores/**"
    - "tests/e2e/**"
  read_only:
    - "src/main/java/**"
    - "src/shared/**"

shared:
  # 共用檔案的修改需要透過 signal 協調
  coordination_required:
    - "src/shared/types/**"
    - "src/api/**"              # API client types
    - "contracts/**"            # API contract files
  modify_protocol: "signal → 對方 ack → 修改 → 通知"
```

### Signal Bus（輕量級訊號機制）

Agent 之間透過 append-only 的 signal 檔案溝通：

```
.coordination/f03/signals.jsonl
```

每行一個 JSON signal：

```jsonl
{"ts":"2026-04-05T10:30:00Z","from":"backend","type":"ENDPOINT_READY","data":{"method":"POST","path":"/api/v1/customers","status":"implemented+tested"}}
{"ts":"2026-04-05T10:45:00Z","from":"frontend","type":"ACK","data":{"ref":"ENDPOINT_READY:POST:/api/v1/customers","action":"will consume"}}
{"ts":"2026-04-05T11:00:00Z","from":"backend","type":"SHARED_TYPE_UPDATED","data":{"file":"src/shared/types/customer.ts","change":"added optional field 'nickname'"}}
{"ts":"2026-04-05T11:05:00Z","from":"frontend","type":"BLOCKED","data":{"need":"GET /api/v1/customers/:id","reason":"detail page needs this endpoint","priority":"high"}}
```

### Signal 類型

| Signal | 方向 | 意義 | 接收方行為 |
|--------|------|------|-----------|
| `ENDPOINT_READY` | BE → FE | API endpoint 已實作 + 通過測試 | FE 可開始串接 |
| `SHARED_TYPE_UPDATED` | 任一 → 另一 | 共用型別有變更 | 對方 pull 最新 + 檢查影響 |
| `BLOCKED` | 任一 → 另一 | 需要對方先完成某事 | 對方優先處理 |
| `CONTRACT_CHANGE` | 任一 → 另一 | API Contract 需要調整 | 雙方停下協商 → CIA |
| `READY_TO_MERGE` | 任一 → Orchestrator | 我這邊完成了 | 等對方也 READY 後 merge |
| `ACK` | 接收方 → 發送方 | 收到，將處理 | 確認對方收到 |

### Sync Points（同步點）

```yaml
# .coordination/f03/sync-points.yaml
# 記錄哪些 endpoint / 元件已經可以串接

endpoints:
  - path: "POST /api/v1/customers"
    backend_status: "implemented+tested"    # ✅
    frontend_status: "consuming"            # 🔄
    integration_tested: false               # ⬜

  - path: "GET /api/v1/customers"
    backend_status: "implemented+tested"    # ✅
    frontend_status: "not_started"          # ⬜
    integration_tested: false               # ⬜

  - path: "GET /api/v1/customers/:id"
    backend_status: "not_started"           # ⬜
    frontend_status: "blocked"              # 🔴
    integration_tested: false               # ⬜

shared_types:
  - file: "src/shared/types/customer.ts"
    version: 2
    last_changed_by: "backend"
    change: "added optional field 'nickname'"
```

### 開發流程

```
Tech Spec 確認 + split
  ↓
┌─── Backend Agent ───────────────────┐  ┌─── Frontend Agent ──────────────────┐
│                                     │  │                                      │
│ 1. 讀 ownership.yaml              │  │ 1. 讀 ownership.yaml                │
│ 2. 讀 Tech Spec §2（API）          │  │ 2. 讀 Tech Spec §4（Frontend）       │
│ 3. 按 endpoint 優先順序開發        │  │ 3. 先做不依賴 API 的 UI             │
│    ↓                                │  │    （靜態佈局、表單驗證、路由）      │
│ 4. endpoint 完成 + 測試通過        │  │    ↓                                 │
│ 5. 發 ENDPOINT_READY signal        │  │ 4. 收到 ENDPOINT_READY              │
│    ↓                                │  │ 5. 開始串接 API                     │
│ 6. 繼續下一個 endpoint             │  │    ↓                                 │
│    ↓                                │  │ 6. 串接測試                          │
│ 7. 全部完成 → READY_TO_MERGE       │  │ 7. 全部完成 → READY_TO_MERGE        │
└─────────────────────────────────────┘  └──────────────────────────────────────┘
                    ↓                                        ↓
              ┌─────────────── Merge Point ───────────────────┐
              │ 1. 兩邊都 READY_TO_MERGE                      │
              │ 2. 先 merge backend → develop                 │
              │ 3. 再 merge frontend → develop（解衝突）      │
              │ 4. 跑整合測試（backend + frontend 一起）      │
              │ 5. 通過 → Gate Review                         │
              └───────────────────────────────────────────────┘
```

### Frontend 不等 Backend 的策略

Frontend 不需要被動等 ENDPOINT_READY。可以用 Mock 先開發：

```
Frontend 開發順序：
  Phase 1 — 靜態 UI（不需要 API）
    - 頁面佈局、路由、表單結構、Prototype 對齊
    - 估計佔 Frontend 工作量 40%

  Phase 2 — Mock API 串接
    - 用 MSW (Mock Service Worker) 或 local mock
    - 從 Tech Spec §2.3 OpenAPI snippet 自動生成 mock
    - 估計佔 30%

  Phase 3 — 真實 API 串接
    - 收到 ENDPOINT_READY 後替換 mock
    - 估計佔 30%（但因為 mock 階段已驗證邏輯，此階段通常很快）
```

**標記規則**：Mock 階段通過的測試標記為 `mock verified`，真實串接後標記為 `real integration verified`。

---

## Layer B: 跨 Feature 依賴協調

### 跨 Feature 依賴追蹤

```yaml
# .coordination/cross-feature/dependency-map.yaml

dependencies:
  - downstream: F05          # 需要等待的 Feature
    upstream: F02             # 被依賴的 Feature
    type: "api"               # api / schema / shared-component / event
    detail: "F05 需要 F02 的 POST /api/v1/cti/calls endpoint"
    status: "waiting"         # waiting / available / integrated
    unblock_signal: "F02 ENDPOINT_READY: POST /api/v1/cti/calls"

  - downstream: F06
    upstream: F03
    type: "shared-component"
    detail: "F06 需要 F03 的 CustomerCard 元件"
    status: "available"
    unblock_signal: "F03 merge 完成"
```

### 共享資源衝突偵測

```yaml
# .coordination/cross-feature/shared-resources.yaml
# 每個 Feature start 時自動更新

resources:
  "src/shared/types/index.ts":
    touched_by: [F02, F03]
    conflict_risk: "high"
    resolution: "F02 先 merge，F03 rebase 後 merge"

  "database/migrations/":
    touched_by: [F02, F03, F05]
    conflict_risk: "medium"
    resolution: "Migration 版本號按 Feature 完成順序分配"

  "src/router/index.ts":
    touched_by: [F03, F05, F06]
    conflict_risk: "low"
    resolution: "各自加 route，merge 時自動合併"
```

### Integration Checkpoint 自動化

```
Feature merge 到 develop 後
  ↓
檢查 dependency-map.yaml：
  有下游 Feature waiting 這個 upstream？
  ├── ✅ 有 → 更新 status: "available" → 通知下游 Feature
  └── ❌ 沒有 → 跳過

每 3 個 Feature merge 後
  ↓
強制 Cross-Feature Integration Test
  → 所有已 merge 的 Feature 一起跑整合測試
  → 失敗 → 找出哪兩個 Feature 衝突 → 修復
```

---

## Merge 策略

### Specialist Merge（同一 Feature 的 BE + FE）

```
順序：永遠 Backend 先 merge
原因：Frontend 依賴 Backend 的 API，反向不成立

步驟：
1. bash scripts/parallel-feature.sh merge-specialist F03 backend
   → merge f03-be → develop
2. bash scripts/parallel-feature.sh merge-specialist F03 frontend
   → merge f03-fe → develop（可能有 shared type 衝突）
3. 跑整合測試
4. 如果衝突 → 在 develop 上解決 → Review Agent 審查衝突解法
```

### Feature Merge（跨 Feature）

```
順序：按完成順序 merge，但有依賴的先 merge upstream

步驟：
1. 確認 upstream Feature 已 merge
2. bash scripts/parallel-feature.sh merge F05
3. 跑 Cross-Feature Integration Test
4. 通過 → 更新 dependency-map.yaml
```

---

## 限制與安全閥

| 規則 | 說明 |
|------|------|
| **最多 2 個 Specialist worktree / Feature** | Backend + Frontend，不再細分 |
| **最多 3 個 Feature 同時 Build** | 超過 3 個併發的認知負擔太高 |
| **CONTRACT_CHANGE 立即停工** | API Contract 有變 → 雙方暫停 → CIA → 重新對齊 |
| **Shared type 修改需要 ACK** | 發 signal → 收到 ACK → 才能修改 |
| **Merge 前必須整合測試** | Specialist merge 和 Feature merge 都需要 |
| **Self-Healing 各自獨立** | 兩個 Agent 的 healing-log.md 各自記錄，不互相干擾 |

---

## Signal Bus 讀取（Agent 啟動時）

每個 Agent 每次開始工作前，先讀取 signal bus 的最新 10 行：

```bash
tail -10 .coordination/f03/signals.jsonl 2>/dev/null || echo "no signals"
```

如果有未處理的 `BLOCKED` signal 指向自己 → 優先處理。

---

## 與其他 Skill 的整合

| Skill | 整合方式 |
|-------|---------|
| `parallel-feature` | `split` 子命令建立 Specialist worktree |
| `self-healing-build` | 各 worktree 獨立執行，healing-log 各自記錄 |
| `gate-check` | Specialist merge 後的整合測試 = 額外 Gate 條件 |
| `pattern-library` | 兩個 Agent 共用同一個 pattern library（read-only） |
| `handoff-protocol` | split 時自動產出 ownership 交接文件 |
| `cia` | CONTRACT_CHANGE signal 觸發 CIA |
