---
name: slice-cycle
description: >
  垂直切片開發循環 — P03+P04 以 Slice 為單位循環執行。

  遇到「開始 slice」、「執行切片」、「slice cycle」、「垂直切片」、
  「下一個 slice」或 P02 完成後進入 P03 時自動觸發。

  **為什麼？** 一次設計+實作全部功能會失控。
  垂直切片每次只做一條完整的可驗證流程，
  做完、穩定、確認可作為基線後，才開下一個 slice。

  **Pipeline 整合**：Gate 2 通過後，pipeline-orchestrator 自動進入 Slice Cycle。
---

# Slice Cycle：垂直切片開發循環

## 核心原則

```
❌ 先做全部 DB → 全部 Backend → 全部 Frontend（水平切）
✅ 一次做一條完整流程：設計 → 實作 → 穩定 → 下一條（垂直切）
```

**一次只處理一個 slice。禁止同時橫向展開多個模組。**

### 基線紀律（Baseline Discipline）

以下規則不可違反：

1. **不要因為 slice 已可編譯/可啟動，就直接開下一個 slice** — 必須經過完整的 G4-ENG-R → Stabilization → Hardening → 基線判定
2. **只有成為基線的 slice，才可開下一個 slice**
3. **骨幹 slice 應優先做 hardening，不可搶快做下一個業務 slice**
4. **AI 產出的 prototype、placeholder、mock 驗證，一律不得默認為正式定稿**
5. **若有外部依賴未解，但可先做設計，採 Wave 模式（見下方），不可全面停工**
6. **若 Wave 1 已完成且 Wave 2 被外部依賴阻塞，優先產出 Vendor Confirmation，不可繼續內推不確定設計**
7. **複合 slice（涉及 Redis / DB / WS / Scheduler / External Adapter）的 G4-ENG-R 必須附 Source of Truth 與一致性策略**

---

## Slice Backlog 分類標籤

> P02 產出 Slice Backlog 時，每個 slice 必須標示以下分類。

| 標籤 | 說明 | 影響 |
|------|------|------|
| 🦴 **骨幹 slice** | 被 2+ 個 slice 依賴的基礎設施 | 優先開發 + 優先 Hardening |
| 📋 **一般業務 slice** | 獨立業務功能 | 正常順序 |
| 🔗 **高外部依賴 slice** | 依賴外部系統/廠商確認才能完成 | 可能需要 Wave 模式 |
| 🧩 **可 Partial Design** | 部分設計可先做、部分需等外部依賴 | 進入 Wave 設計模式 |
| 📞 **需 Vendor Confirmation** | 有外部未定義事項需廠商回覆 | 必須產出 Vendor Confirmation 文件 |

```markdown
## Slice Backlog 範例

| Slice # | 名稱 | 標籤 | 依賴 | Entry Criteria | Exit Criteria |
|---------|------|------|------|---------------|--------------|
| S01 | Login + Session + RBAC | 🦴 骨幹 | 無 | EC: 無前序依賴 | XC: 登入/登出/權限可驗證 |
| S02 | Agent State Machine | 🦴 骨幹 | S01 | EC: S01 基線通過 | XC: 狀態切換可驗證 |
| S03 | Inbound Screen Pop | 🔗🧩📞 | S01+S02 | EC: S01+S02 基線 + CTI payload 確認 | XC: 來電彈屏完整流程 |
| S04 | Customer 360 Dashboard | 📋 | S01 | EC: S01 基線 | XC: 客戶資訊可查詢 |
```

---

## Slice Cycle 7 步

```
P02 產出的 Slice Backlog
  ↓ 選擇本輪 Slice（依分類標籤 + 依賴順序）
  ↓
┌─────────────────────────────────────────────────────┐
│                                                     │
│  Step 1: Feature Pack（確認範圍）                    │
│  Step 2: Design（設計，⛔ 不寫 code）                │
│    ↳ 若有外部依賴：Wave 1 → [等待] → Wave 2          │
│  Step 3: G4-ENG-D（設計審查）                        │
│  Step 4: Code（只做本 slice，⛔ 不碰其他 slice）     │
│  Step 5: G4-ENG-R（實作後審查 + 12 項正式輸出）      │
│  Step 6: Stabilization（能跑）                       │
│  Step 7: Hardening（可靠 + 基線判定）                │
│    ↓ ✅ 基線通過 → 下一個 slice                     │
│    ↓ ❌ → 依回退規則回到對應步驟                    │
│                                                     │
│  ※ Cross-Slice Integration Check：                  │
│    第 3 個骨幹 slice 後觸發，之後每 2 slice 觸發     │
│                                                     │
└─────────────────────────────────────────────────────┘
  ↓ 所有 slice 完成
Gate 3 → P05 → P06
```

---

## Step 1: Feature Pack（確認範圍）

> ⛔ 不寫 code。只確認「這個 slice 要做什麼」。

每個 Feature Pack 必須包含：

| # | 項目 | 說明 |
|---|------|------|
| 1 | Slice 名稱 | 如「Login + Session + Role Resolve」 |
| 2 | 功能目標 | 一句話：這個 slice 完成後可以驗證什麼 |
| 3 | 範圍內 | 明確列出要做的功能點 |
| 4 | 範圍外 | 明確列出不做的（即使很近的功能） |
| 5 | Entry Criteria | 從 P02 Slice Backlog 讀取（見下方） |
| 6 | Exit Criteria | 從 P02 Slice Backlog 讀取（見下方） |
| 7 | 依賴的前序 Slice | 哪些 slice 必須先完成 |
| 8 | Open Issues | 未定義事項（⛔ 不自行假設） |
| 9 | Blocker 清單 | DES-xx / IMP-xx（見 Blocker 分級制度） |
| 10 | 外部依賴 | 是否需要 Vendor Confirmation / Wave 模式 |

---

## Step 2: Design（設計）

> ⛔ 不寫 code。只產出設計文件。

必須輸出：
1. **Domain Design** — entity / enum / state machine / relation
2. **API Contract** — endpoint / request / response / auth / error code
3. **Sequence Flow** — 正常流程 + 異常流程（文字版即可）
4. **Test Design** — happy path / validation / permission / edge case
5. **Correlation Strategy**（若適用）— 事件關聯設計（見下方）

**複合 Slice 額外必要輸出**（涉及 Redis / DB / WebSocket / Scheduler / External Adapter）：
- **一致性策略** — 各元件間的資料一致性保證方式
- **失敗補償 / Rollback 分析** — 每個外部元件失敗時的處理方式

**輸出類型紀律**：本步驟只產出 Design，不產出 Code / Test Code / Review。

### Correlation Strategy Design（事件關聯策略）

> 適用於事件可能分開到達的 slice（如 INBOUND_RING 與 IVR data 分事件到達）。

至少定義：

| # | 項目 | 說明 |
|---|------|------|
| 1 | Correlation Key | 用什麼欄位關聯分散的事件（如 callId, sessionId） |
| 2 | 等待時間窗 | 等多久才判定為未收到（如 5s, 30s） |
| 3 | 到達順序 | 各事件可能的到達順序組合 |
| 4 | Fallback 觸發條件 | 何時放棄等待、使用 fallback 資料 |
| 5 | UI 策略 | 先顯示 placeholder 還是延後顯示 |
| 6 | 補資料策略 | 遲到事件到達後如何更新已顯示的內容 |

---

## Step 3: G4-ENG-D（設計審查）

> **D = Design**。審查本 slice 的設計品質，未通過不得寫 code。

審查項目：

| # | 檢查項 | 阻塞？ |
|---|--------|--------|
| D-01 | Feature Pack 範圍內/外明確 | 🔴 |
| D-02 | Entry Criteria 全部滿足 | 🔴 |
| D-03 | API Contract 每個 endpoint 有 request/response/error | 🔴 |
| D-04 | Domain Design 有 state machine（如適用） | 🔴 |
| D-05 | Test Design 覆蓋 happy + validation + permission + edge | 🟡 |
| D-06 | 無「自行假設」— Open Issues 都已標記 | 🔴 |
| D-07 | 和前序 Slice 的介面一致（Cross-Slice 相容） | 🔴 |
| D-08 | Complexity Smell：修改檔案預估 ≤ 8 | 🟡 |
| D-09 | Blocker 清單完整（DES-xx / IMP-xx 已分類） | 🔴 |
| D-10 | 複合 Slice 有一致性策略 + 失敗補償分析 | 🔴（若適用）|
| D-11 | Correlation Strategy 已定義（若事件可能分開到達） | 🔴（若適用）|
| D-12 | Fixed vs Placeholder 清單已產出（若 Wave 模式） | 🔴（若適用）|

**PASS → 進入 Step 4 Code。BLOCK → 回 Step 2 修正設計。**

---

## Step 4: Code（實作）

> ⛔ 只做本 slice。不碰其他 slice。不新增未核准功能。

實作前必須先輸出：
1. 本輪預計修改檔案清單
2. 影響範圍
3. 對應的 Feature Pack AC

實作限制：
- 只做本次 slice
- 不可新增未核准功能 / 角色 / 狀態 / 依賴
- 不可跨模組修改
- 所有 code 必須對應 Step 2 設計
- **輸出類型紀律**：本步驟只產出 Code + Unit Test，不混入 Design 修改

---

## Step 5: G4-ENG-R（實作後審查 — 12 項正式輸出）

> **R = Review**。審查本 slice 的實作品質 + 範圍一致性。

### 審查項目

| # | 檢查項 | 阻塞？ |
|---|--------|--------|
| R-01 | 範圍比對：實際修改 vs Feature Pack 範圍一致 | 🔴 |
| R-02 | 超出範圍的實作項目清單（Scope Drift） | 🔴 若有未說明的超出 |
| R-03 | 自行假設的規則清單 | 🔴 若有未標記的假設 |
| R-04 | 設計 vs 實作一致性（API / State / Error Code） | 🔴 |
| R-05 | 測試覆蓋：AC 的 Test Case 全部存在 | 🔴 |
| R-06 | 編譯通過 | 🔴 |
| R-07 | 無 P0 阻塞（啟動失敗 / 安全漏洞 / 主流程壞） | 🔴 |
| R-08 | Open Issues 更新（新增 / 已解決 / 待決） | 🟡 |
| R-09 | 檔案異動清單（新增 / 修改 / 刪除） | 🟡 |
| R-10 | 需要人工決策的 Open Issues | 🟡 |
| R-11 | Mock 驗證標記正確（mock verified vs real integration pending） | 🟡 |
| R-12 | Source of Truth 定義清楚（複合 Slice 必填） | 🔴（若適用）|

### G4-ENG-R 正式輸出物（12 項）

G4-ENG-R 審查完成後，**必須**固定產出以下 12 項內容：

```markdown
## G4-ENG-R Report — Slice [N]: [名稱]

### 1. 本次 Slice 正式範圍定義
[從 Feature Pack 複製，含範圍內 + 範圍外]

### 2. 已完成實作清單
[逐項列出已完成的功能點，每項標注對應的 AC]

### 3. 超出本次範圍的實作項目
[列出超出 Feature Pack 範圍的實作，每項說明原因]
若無：「無超出範圍的實作」

### 4. 自行假設的規則或未定義事項
[列出任何自行假設的決策]
若無：「無自行假設（全部走 Open Issue）」

### 5. 尚未完成的項目
[範圍內但未完成的項目 + 原因 + 預計完成時機]

### 6. 測試覆蓋清單
| AC | Test Case | 狀態 |
|----|-----------|------|
[每條 AC 對應的 Test Case + PASS/FAIL/PENDING]

### 7. 缺少的測試案例
[應有但尚未撰寫的測試]

### 8. 檔案異動清單
| 操作 | 檔案路徑 | 說明 |
|------|---------|------|
| 新增 | ... | ... |
| 修改 | ... | ... |
| 刪除 | ... | ... |

### 9. 外部依賴清單
| 依賴 | 狀態 | 影響 |
|------|------|------|
[外部系統/服務/SDK 依賴 + 目前狀態]

### 10. Source of Truth 定義
[各模組的 SSOT — 資料從哪裡來、以哪裡為準]

### 11. 是否可進下一個 Step / Slice
[PASS / BLOCK + 明確理由]

### 12. 必須先修正的項目
[若 BLOCK：列出修正項目 + 優先順序 + 回退到哪個 Step]
```

**PASS → 進入 Step 6。BLOCK → 依回退規則回到對應步驟。**

---

## Step 6: Stabilization（P0 穩定化）

> 確保本 slice 「能跑」。目標：可編譯、可啟動、主流程可跑。

### 目標

| # | 完成標準 |
|---|---------|
| □ | 專案可編譯，無 error |
| □ | 可啟動（application context 正常載入） |
| □ | 主流程可跑（本 slice 的 happy path 端到端可驗證） |
| □ | Auth / Session / Permission 正常（如涉及） |
| □ | 無 P0 / P1 阻塞 |
| □ | 前端至少可編譯（如涉及） |
| □ | 基本 API endpoint 可呼叫且回應正確 |
| □ | WebSocket 基本穩定性（如涉及） |

### 處理內容範圍

Stabilization **只處理**以下類型的問題：
- 啟動阻塞（缺少必要 bean / config / main class / test profile）
- Security / JWT / Auth 缺失
- Login / Logout 主流程缺陷
- 編譯錯誤
- WebSocket 基本穩定性
- 資料庫連線 / Migration 失敗

**不屬於 Stabilization 的問題**（應交給 Hardening）：
- ❌ 邏輯語意錯誤（如 state machine 行為不對）
- ❌ Edge case 測試不足
- ❌ Adapter 結構最佳化
- ❌ 效能調優

**不通過 → 修復後重新驗證。不允許帶著 P0 進 Hardening。**

---

## Step 7: Hardening（強化 + 基線判定）

> 確保本 slice 「可靠」且「可作為下一個 slice 的依賴」。

### 目標

| # | 完成標準 |
|---|---------|
| □ | 狀態模型正確（state machine 行為和設計一致） |
| □ | 邏輯語意正確（業務規則正確） |
| □ | 關鍵邊界測試補齊 |
| □ | Adapter 結構可延展（real / mock 切換正確） |
| □ | 可作為下一個 slice 的依賴基線 |

### 處理內容範圍

Hardening **只處理**以下類型的問題：
- State machine / 業務邏輯語意修正（如 currentCallId / cancelAcwExpiry）
- Scheduler edge case
- Redis / DB fallback 策略
- 測試補強（test strengthening）
- Adapter mock / real 結構整理
- Placeholder / Pending 行為治理
- Race condition 修復
- 測試 profile / test config 修正

**不屬於 Hardening 的問題**（應回退）：
- ❌ 啟動失敗 → 回 Stabilization
- ❌ 安全漏洞 → 回 Stabilization
- ❌ 設計不一致 → 回 Step 2 Design
- ❌ 範圍漂移 → 回 Step 5 G4-ENG-R

### 基線判定

| 問題 | 必須全部 ✅ |
|------|-----------|
| 本 slice 的 happy path 測試全過？ | □ |
| 本 slice 的 edge case 測試全過？ | □ |
| 本 slice 的 API 介面穩定（下一個 slice 可依賴）？ | □ |
| 無 P0 / P1 阻塞？ | □ |
| Open Issues 已更新且無新增 P0？ | □ |
| Mock 驗證 vs 真實整合已明確標記？ | □ |
| Fixed vs Placeholder 清單已更新（若 Wave 模式）？ | □ |

**全部 ✅ → 本 slice 成為基線 → 可開下一個 slice。**
**任一 ❌ → 依回退規則回到對應步驟。**

---

## 回退規則（5 級分類）

| 問題類型 | 回退到 | 說明 |
|---------|--------|------|
| **範圍漂移 / 偷補需求 / 跨模組擴寫** | → G4-ENG-R（Step 5） | 刪除超出範圍的實作，重新 Review |
| **設計與實作不一致 / 設計未收斂** | → P03 Design（Step 2） | 修正設計或修正 code 使其一致 |
| **啟動失敗 / 安全漏洞 / 主流程不可跑 / 編譯失敗** | → Stabilization（Step 6） | P0 等級問題，先修到能跑 |
| **邏輯語意錯誤 / 邊界測試不足 / 模型不穩** | → Hardening（Step 7） | 補測試、修邏輯，確認可靠 |
| **架構邊界錯誤 / slice 切法錯誤 / Source of Truth 錯誤** | → **P02 / Gate 2**（升級） | slice 切法有誤或模組邊界需重定義 |

---

## Blocker 分級制度

> 設計階段發現的阻塞分為兩類，使用不同前綴避免混淆。

### DES-xx — Design Blocker（設計阻塞）

- 未解除前，**設計文件本身無法正確定稿**
- 範例：
  - DES-01: payload contract 語義未確認（DNIS 到底代表什麼）
  - DES-02: customerId vs 原始身份資料的語義差異
  - DES-03: IVR 轉入時是否帶 context

### IMP-xx — Implementation Blocker（實作阻塞）

- 設計可先完成，但 **P04 正式實作前必須解除**
- 範例：
  - IMP-01: 欄位名稱 callerId 還是 callerNumber
  - IMP-02: 交換機命令 JSON 格式細節
  - IMP-03: timeout event name（TIMEOUT vs CALL_TIMEOUT）
  - IMP-04: sentinel value（null vs empty string vs -1）

### 管理規則

```markdown
## Blocker Log — Slice [N]

| Blocker ID | 類型 | 問題描述 | 影響 Deliverable | 狀態 | 解除條件 |
|-----------|------|---------|-----------------|------|---------|
| DES-01 | Design | DNIS 語義未確認 | D2 Event Contract, D5 UI State Flow | 🔴 | 廠商確認 |
| IMP-01 | Impl | 欄位名 callerId vs callerNumber | API Spec, DB Schema | 🟡 | 廠商確認或內部決策 |
```

⚠️ **命名注意**：Design Blocker 使用 `DES-xx`（不用 `DB-xx`，避免與 Database 混淆）。

---

## Wave 設計模式（Partial Design）

> 適用於有外部依賴但仍有部分設計可先進行的 slice。

### 啟用條件

以下**任一**條件成立即可啟用：
1. Slice 有 📞 Vendor Confirmation 標籤
2. Slice 有 🧩 可 Partial Design 標籤
3. Feature Pack 中有 DES-xx blocker 且部分 deliverable 不受阻塞

### Wave 1（可先做）

與外部依賴無關的 design deliverables：
- Security / PII strategy
- Performance assumption
- Partial UI flow / placeholder prototype
- Minimal schema 草案（僅不受阻塞的欄位）
- 非 blocker 區域的 test thinking
- 內部 API contract（不涉及外部 payload 的部分）

### Wave 2（依賴解除後）

依賴外部資料解除後才能定稿的 deliverables：
- Event contract final
- Lookup rule final
- Reject flow final
- Correlation strategy final
- Full test design
- DB schema final（含外部依賴欄位）

### Wave 設計鐵則

1. **Partial design 不得反向推定外部依賴答案**
   - ❌ 不得因先畫 UI 就擅自決定 DNIS 語義
   - ❌ 不得因先做 schema 就擅自固定 IVR payload
   - ❌ 不得因先做 fallback 就擅自定義 reject command
2. **Wave 1 完成後必須產出 Fixed vs Placeholder 清單**
3. **Wave 2 啟動前必須確認 Vendor Confirmation 已回覆**

### Wave 完成回報

每次 Wave 完成後，固定回報：

```markdown
## Wave [1/2] 完成報告 — Slice [N]

### 1. 本 Wave 產出的設計資產
[列出所有 deliverables]

### 2. 已固定的內容
[列出可視為定稿的設計]

### 3. 仍為 Placeholder 的內容
[列出暫定、等待外部確認的設計]

### 4. 下游可直接重用的 Deliverables
[哪些後續步驟可以開始]

### 5. 仍受外部依賴阻塞的 Deliverables
[哪些要等 Wave 2 才能做]
```

---

## Fixed vs Placeholder 清單

> Wave 模式下的 Slice 必須產出此清單，防止暫定內容被誤認為定稿。

```markdown
## Fixed vs Placeholder — Slice [N]

| # | 設計項目 | 狀態 | 開發指引 |
|---|---------|------|---------|
| 1 | Login API endpoint | ✅ 已固定 | 可開發 |
| 2 | Session timeout 值 | ✅ 已固定 | 可開發 |
| 3 | IVR payload 格式 | 🟡 Placeholder | 可做設計，不可做實作 |
| 4 | DNIS 語義定義 | 🟡 Placeholder | 可做設計，不可做實作 |
| 5 | Reject command JSON | 🔴 Placeholder | 完全禁止依此開發 |
```

### 狀態定義

| 狀態 | 說明 | 開發限制 |
|------|------|---------|
| ✅ 已固定 | 已確認、可視為定稿 | 可開發 |
| 🟡 Placeholder | 暫定值，等外部確認 | 可做設計，不可做實作 |
| 🟠 可開發（含 mock） | 可用 mock 先行實作 | 可開發，但 AC 須拆為 mock verified / real pending |
| 🔴 Placeholder | 高度不確定 | 完全禁止依此開發 |

---

## Vendor Confirmation（外部確認文件）

> 若 Slice 存在外部未定義事項，必須產出 Vendor Confirmation 文件。

### 完整版模板

```markdown
## Vendor Confirmation — Slice [N]: [名稱]

### 確認問題清單

| Q# | 問題描述 | 為什麼需要確認 | 影響的設計文件 | 未確認時的 Mock/Placeholder 策略 | 回覆後影響的階段 | 廠商回覆 |
|----|---------|--------------|--------------|-------------------------------|----------------|---------|
| VC-01 | [問題] | [原因] | D1, D5 | [暫用策略] | Design + P04 | [待回覆] |
| VC-02 | [問題] | [原因] | D2, D9 | [暫用策略] | P04 + UAT | [待回覆] |

### 最低必要確認集（Minimum Required Set）

| Q# | 解除後可啟動/定稿的 Deliverable |
|----|-------------------------------|
| VC-01 | Event Contract + Correlation Strategy |
| VC-02 | DB Schema final + API Spec final |

### 內部預設策略（若會議未取得答案）

| Q# | 暫時採用的預設策略 | 風險等級 |
|----|-------------------|---------|
| VC-01 | 假設 DNIS = 服務類別代碼 | 🟡 中 |
| VC-02 | 使用 mock payload | 🟠 高 |
```

### 會議版精簡確認單

> Vendor Confirmation 完成後，另產一份給廠商的精簡版。

```markdown
## 廠商確認事項 — [專案名稱] / Slice [N]

| # | 確認問題（一句話） | 若未答覆，影響 |
|---|-------------------|--------------|
| 1 | [最容易對外確認的 wording] | [會卡住哪個 deliverable / 哪個階段] |
| 2 | [最容易對外確認的 wording] | [會卡住哪個 deliverable / 哪個階段] |
```

---

## Mock 驗證邊界規則

### Mock 可用於

- 設計驗證
- 測試環境
- 實作過程中的替代路徑
- Partial design / partial implementation 的前進條件

### Mock 不可用於

- ❌ 正式 UAT 完成交付依據
- ❌ Production 完成交付依據
- ❌ 對外宣稱「真實整合已完成」

### AC 拆分規則

若 AC 以 mock 通過，文件中**必須**顯式拆成：

```markdown
| AC | 驗證狀態 |
|----|---------|
| AC-01 來電時彈出客戶資料 | ✅ mock verified |
| AC-01 來電時彈出客戶資料（真實 CTI 整合） | 🟡 real integration pending |
```

---

## Slice Entry / Exit Criteria 範本

> 在 P02 Slice Backlog 中，每個 slice 必須定義 Entry 和 Exit Criteria。

### Entry Criteria（進入條件）

```markdown
## Slice [N]: [名稱] — Entry Criteria

□ EC-01 前序 Slice [列表] 已成為基線（Hardening 通過）
□ EC-02 本 Slice 依賴的 API 介面已穩定且有文件
□ EC-03 本 Slice 依賴的 DB Schema 已 migrate 且可用
□ EC-04 本 Slice 的 Feature Pack 已完成且無 🔴 Open Issue
□ EC-05 本 Slice 的 Design 尚未開始（確認是乾淨起點）
□ EC-06 DES-xx Design Blockers 全部解除（或已確認可進 Wave 模式）
□ EC-07 IMP-xx Implementation Blockers 至少已識別（不需全部解除）
□ EC-08 [專案特定條件，如「交換機 SDK 已提供」]
```

### Exit Criteria（退出條件 = 基線判定）

```markdown
## Slice [N]: [名稱] — Exit Criteria

□ XC-01 Feature Pack 範圍內的所有 AC 實作完成
□ XC-02 G4-ENG-D + G4-ENG-R 雙層審查通過
□ XC-03 Stabilization 通過（能跑）
□ XC-04 Hardening 通過（可靠）
□ XC-05 Happy path + edge case 測試全過
□ XC-06 API 介面穩定（可作為下一個 slice 的依賴）
□ XC-07 無 P0 / P1 阻塞
□ XC-08 Open Issues 更新完成
□ XC-09 Mock 驗證 vs 真實整合已明確標記
□ XC-10 Fixed vs Placeholder 清單已更新（若 Wave 模式）
□ XC-11 [專案特定條件]
```

---

## Cross-Slice Integration Check

> 不等所有 slice 完成才看整合，骨幹 slice 完成後提前檢查。

### 觸發規則

| 觸發條件 | 說明 |
|---------|------|
| **第 3 個骨幹 slice 完成後** | 第一次整合檢查（3 個 slice 已形成基礎骨架） |
| **之後每 2 個 slice 完成後** | 定期整合檢查 |
| **完成一組高依賴 slice 後** | 高依賴 slice 之間的整合確認 |
| **任何 slice 修改共用模組** | Auth / State Machine / Event Bus / 共用 DB Schema 變更時強制觸發 |
| **進入 Gate 3 前至少一次** | 最終整合確認 |

### 檢查項目

```
## Cross-Slice Integration Check — 第 [N] 次

□ IC-01 各 Slice 間 API 介面調用正常（無 contract 不一致）
□ IC-02 共用 State Machine 行為一致（各 slice 看到的狀態轉移相同）
□ IC-03 共用 DB Schema 無衝突（migration 順序正確，無 column 衝突）
□ IC-04 共用 Event/Message 格式一致（publisher 和 consumer 欄位匹配）
□ IC-05 Auth / Permission 跨 slice 一致（同角色在不同 slice 的權限正確）
□ IC-06 多租戶隔離在所有已完成 slice 中正確（tenant_id 過濾無遺漏）
□ IC-07 整合測試可跑（跨 slice 的 happy path 端到端）
□ IC-08 效能無明顯退化（和前次 Integration Check 比較）
□ IC-09 命名一致性（跨 slice 的欄位名、event name、error code 統一）
□ IC-10 Source of Truth 一致（各 slice 對同一資料的 SSOT 指向相同）
□ IC-11 Baseline 之間無互相衝突（後 slice 未破壞前 slice 的 baseline）
□ IC-12 Fixed vs Placeholder 未被誤用（後 slice 未依賴前 slice 的 placeholder）
```

**PASS → 繼續下一個 slice。**
**FAIL → 標記問題 slice + 問題類型 → 依回退規則修正。**

---

## Open Issue Protocol

> 未定義事項不得自行假設。必須結構化記錄。

```markdown
## Open Issues Log

| Issue ID | 模組 | Slice | 問題描述 | 影響範圍 | 建議決策選項 | 狀態 | 決策結果 |
|---------|------|-------|---------|---------|------------|------|---------|
| OI-001 | Auth | S01 | SSO IdP 回傳欄位未定義 | 登入流程 | A: 暫用 mock / B: 等規格 | 🟡 待決 | |
| OI-002 | CTI | S04 | 交換機 event payload 格式 | 來電彈屏 | A: 用文件版 / B: 等實測 | 🟡 待決 | |
```

**規則**：
- 🟡 待決的 Open Issue → 該功能暫不實作，不得自行假設
- 🟢 已決 → 記錄決策結果 + 決策日期
- 🔴 阻塞 → 影響到 Entry Criteria → slice 不得開始

---

## 輸出類型紀律

每輪只允許輸出一種類型，不可混在一起：

| 步驟 | 允許的輸出類型 |
|------|-------------|
| Step 1 Feature Pack | Feature Pack 文件 |
| Step 2 Design | Domain Design + API Contract + Sequence + Test Design + Correlation Strategy |
| Step 3 G4-ENG-D | 設計審查報告 |
| Step 4 Code | 程式碼 + Unit Test |
| Step 5 G4-ENG-R | 實作後審查報告（12 項正式輸出） |
| Step 6 Stabilization | 穩定化修復 + 驗證報告 |
| Step 7 Hardening | 強化修復 + 基線判定報告 |

**每輪完成後固定回答**：
1. 本輪完成了什麼
2. 哪些內容仍未完成
3. 哪些是自行假設（應為 0）
4. 哪些需要人工決策
5. 是否可以進下一步驟
6. 若不可，還缺什麼
