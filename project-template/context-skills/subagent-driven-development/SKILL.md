---
name: subagent-driven-development
description: >
  多個任務可以同時做。UX 確認功能後，Architect + DBA + Backend 可以並行啟動。
  Backend 完成後，Frontend + QA 也可並行。問「這幾個 Agent 可以並行嗎」或「怎麼加速」時觸發。
  提升一倍效率的關鍵技能。

  觸發詞: "並行", "同時跑", "加速", "多 Agent 一起", "Architect 和 DBA 可以一起做嗎"
source: obra/superpowers (adapted for AI-First workflow)
---

# Subagent-Driven Development Skill

## 為什麼要並行？
- UX 文件確認後，架構設計和資料庫設計**沒有順序依賴**，只需共同輸入（US + Prototype）
- Backend API Spec 和 Frontend 元件規劃**也是獨立**的，只在最後同步欄位命名
- 並行執行能將 P02 從「3 個 Agent 週期」壓到「1.5 週期」

## 並行前置條件：Wave 分析

**執行前必做（GSD §39 Wave-Based 並行）：**

1. **列出待並行的 Agent**
   - 例：Architect、DBA、Backend API Spec
2. **檢查輸入依賴**
   ```
   Architect ← US_F01.md, F01-UX.md ✓
   DBA      ← US_F01.md, F01-UX.md ✓
   Backend  ← US_F01.md, F01-UX.md ✓
   → 無前置 Agent，3 個可並行
   ```
3. **確認同步點**
   - 所有 Agent 都產出完成 → 進行命名一致性檢查（下一個 Wave）
4. **標記 STATE.md**
   ```markdown
   ## Wave-W1: P02 功能 F01 架構設計
   - Agents: Architect, DBA, Backend (API Spec)
   - Inputs ready: ✓ US_F01.md, ✓ F01-UX.md
   - SyncPoint: [日期] 全部完成後比對 SSOT
   ```

## 可並行組合

### P02 技術設計（UX 確認後）
```
Wave-W1:
├── Architect     → F01-SW-ARCH.md  (軟硬體架構)
├── DBA           → F01-DB.md       (Schema)
└── Backend       → F01-API.md      (API Spec)

Wave-W2（W1 完成後）:
├── Frontend      → F01-FE-PLAN.md  (元件規劃)
└── QA            → F01-TC.md       (測試案例)

Wave-W3:
└── Review        → F01-ARCH-RVW.md (驗收)
```

### P04 實作開發（G4-ENG 通過後）
```
Wave-W1:
├── Backend       → src/api/        (API 實作)
└── Frontend      → src/components/ (元件實作)

Wave-W2:
└── QA            → F01-TR.md       (測試執行)
```

## 不可並行（前置依賴）
```
PM 未完成 ──→ 不啟動 UX
UX 未確認 ──→ 不啟動 Architect/DBA/Backend
Architect 未完成 ──→ 不啟動 Frontend 實作
Backend 實作未完成 ──→ 不啟動 QA 測試
G4-ENG 未通過 ──→ 不啟動 P04 實作
```

## 啟動並行 Agent 的檢查清單

- [ ] 前置 Agent 交接摘要已在 TASKS.md
- [ ] 所有並行 Agent 的輸入文件**已確認到位**（不是「預計產出」）
- [ ] Wave 分析已記錄在 STATE.md
- [ ] 各 Agent 的 CIC Grounding 聲明已準備
- [ ] Dashboard 已更新「目前執行中的 Agent」

## 分派格式（複製貼上模板）

```
═══════════════════════════════════════════
Subagent Dispatch: Feature F01
Wave: W1 | SyncPoint: 2026-03-20
═══════════════════════════════════════════

[Subagent 1: Architect]
Role: 軟硬體架構設計
Input:  US_F01.md (User Story)
        F01-UX.md (互動方案)
Output: F01-SW-ARCH.md (→ 03_System_Design/)
Seed:   SEED_Architect.md
Status: 🔄 In Progress

[Subagent 2: DBA]
Role: 資料庫架構設計
Input:  US_F01.md
        F01-UX.md
Output: F01-DB.md (→ 03_System_Design/)
Seed:   SEED_DBA.md
Status: 🔄 In Progress

[Subagent 3: Backend (API Spec)]
Role: API 規格定義
Input:  US_F01.md
        F01-UX.md
Output: F01-API.md (→ 02_Specifications/)
Seed:   SEED_Backend.md (API Spec phase)
Status: 🔄 In Progress

═══════════════════════════════════════════
SyncPoint: 2026-03-20
All agents output → Compare SSOT naming
  - API fields = DB columns = FE model
  - Enum 值一致
  - 型別對齊
→ Update TASKS.md with sync result
═══════════════════════════════════════════
```

## Wave 同步點檢查

**全部完成後執行：**

1. **命名一致性** ✓
   - Architect 說 `user_profile.avatar_url`
   - DBA 說 `tbl_user_profile.avatar_url`
   - API 說 `User.avatarUrl` → **轉換規則清晰**

2. **無衝突決策** ✓
   - 若 Architect 說「用 Redis」但 DBA 說「用 in-memory」→ Architect 優先（記 ADR）
   - 記錄衝突和決議到 memory/decisions.md

3. **更新追蹤** ✓
   ```bash
   # TASKS.md
   | W1-SYNC | 架構+DB+API 規格同步完成 | Architect/DBA/Backend | ✅ 完成 | 交接：Frontend 準備實作，SSOT 已確認 |
   ```

4. **下個 Wave 準備** ✓
   - Frontend Agent 開始前，確認 SSOT 已鎖定
   - QA 開始前，確認 API Spec 最終版

## 衝突解決原則

| 情況 | 決策者 | 紀錄 |
|------|------|------|
| 架構決策（技術棧、分層、集成） | Architect | ADR |
| 資料模型決策（Schema、索引、關連） | DBA | ADR |
| API 契約（端點、欄位、狀態碼） | Backend + Review 共議 | API Spec |
| 多個決策衝突 | Architect → DBA → Review | ADR depends_on |

## 進度追蹤

在 STATE.md 記錄：
```markdown
### Wave-W1 並行進度
- [ ] Architect 開始
- [ ] DBA 開始
- [ ] Backend 開始
- [x] Architect 交接: F01-SW-ARCH.md 完成
- [ ] DBA 交接: F01-DB.md 完成
- [ ] Backend 交接: F01-API.md 完成
- [ ] 同步點：命名一致性驗證通過
```

## 失敗恢復

- 某 Agent 遇到阻礙（設計未決、技術不確定）→ 立即暫停 Wave，改為串行處理
- 中途發現前置依賴不足 → 回 UX Agent 確認，不要猜測
- 多個並行 Agent 產出衝突 → 觸發 Architect 決策會，記 ADR 後繼續
