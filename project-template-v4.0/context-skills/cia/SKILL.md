---
name: cia
description: >
  Change Impact Assessment — 對 Approved 或 Baselined 文件進行變更前的強制評估。
  自動觸發：當任何 Baselined 文件被修改時。
  手動觸發：使用者輸入 "/cia"，或說「做變更影響評估」、「CIA 分析」、「評估這個變更的影響範圍」。
user-invocable: true
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            # 檢查即將修改的檔案是否為 Baselined artifact
            # 如果是，提醒需要執行 CIA
            FILE="$CLAUDE_TOOL_INPUT_file_path"
            if grep -q "maturity.*Baselined\|status.*Baselined" "$FILE" 2>/dev/null; then
              echo "[CIA-GUARD] ⚠️  此檔案為 Baselined artifact！修改前必須完成 CIA (Change Impact Assessment)。請先執行 /cia 指令。"
            fi
---

# Change Impact Assessment (CIA)

> **強制規則**：任何 Approved 或 Baselined 文件的修改，必須先完成 CIA。
> 未完成 CIA 直接修改 = Gate 不通過。

---

## 自動觸發條件

以下情況自動需要 CIA：

| 觸發條件 | 說明 |
|---|---|
| 修改 Baselined 文件 | ARTIFACTS.md 中標記為 `Baselined` 的任何文件 |
| 修改 Approved 文件 | ARTIFACTS.md 中標記為 `Approved` 的任何文件 |
| 跨 Gate 回溯修改 | 前一個 Gate 已通過後，修改前一個 Gate 的產出物 |
| 架構決策修改 | 修改 DECISIONS.md 中任何已定案的決策 |

---

## CIA 流程

```
偵測需要修改 Baselined/Approved 文件
    ↓
Step 1: 填寫 CIA Checklist（本 skill）
    ↓
Step 2: 評估影響範圍
    ↓
Step 3: 決定是否需要重跑 Gate
    ↓
Step 4: 在 ARTIFACTS.md 建立 CIA 記錄
    ↓
Step 5: 執行變更（獲得授權後）
    ↓
Step 6: 更新 ARTIFACTS.md artifact 狀態
```

---

## CIA Checklist Template

執行 CIA 時，使用以下格式填寫（存為 `memory/cia-[YYYYMMDD]-[簡短描述].md`）：

```markdown
# CIA — Change Impact Assessment

**CIA-ID**: CIA-[YYYYMMDD]-[序號]
**日期**: [YYYY-MM-DD]
**執行者**: [角色名稱]
**狀態**: Draft | Under Review | Approved | Rejected

---

## 1. 變更描述

| 項目 | 內容 |
|------|------|
| **變更項目** | [被修改的文件/功能/設計] |
| **變更原因** | [為什麼需要這個變更] |
| **變更類型** | Bug Fix / Enhancement / Scope Change / Design Correction |
| **緊急程度** | Low / Medium / High / Critical |

---

## 2. 受影響文件（Affected Doc IDs）

> 從 ARTIFACTS.md 查詢所有可能受影響的 artifact。

| Doc ID | 文件名稱 | 當前成熟度 | 影響程度 | 說明 |
|--------|----------|-----------|---------|------|
| [ID]   | [名稱]   | Baselined | High    | [為什麼受影響] |
| [ID]   | [名稱]   | Approved  | Medium  | [為什麼受影響] |

**影響程度**：High（需要修改）| Medium（需要驗證）| Low（僅參考）

---

## 3. 影響範圍評估

### 功能影響
- [ ] 核心業務流程受影響？描述：___
- [ ] API 介面變更？描述：___
- [ ] 資料庫 Schema 變更？描述：___
- [ ] UI/UX 流程變更？描述：___

### 測試影響
- [ ] 需要重新跑 Unit Test？
- [ ] 需要重新跑 Integration Test？
- [ ] 需要重新跑 E2E Test？
- [ ] 需要更新 Test Case 文件？

### 文件影響
- [ ] SRS 需要更新？
- [ ] API Spec 需要更新？
- [ ] 系統設計文件需要更新？
- [ ] DECISIONS.md 需要更新？

---

## 4. 需要重跑的 Gates

| Gate | 原因 | 必須 / 建議 |
|------|------|------------|
| [Gate name] | [為什麼需要重跑] | 必須 / 建議 |

> 如果影響 Baselined 文件，至少對應的 Gate 必須重跑。

---

## 5. 風險評估

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|--------|------|---------|
|      | Low/Med/High | Low/Med/High | |

---

## 6. 決策

- [ ] **批准**：變更可以進行，受影響文件降級為 Draft，完成後重新走 Gate
- [ ] **有條件批准**：[條件列表]
- [ ] **拒絕**：[拒絕原因]

**決策者**: [Task-Master / 凱子]
**決策日期**: [YYYY-MM-DD]

---

## 7. 執行計畫

| 步驟 | 動作 | 負責角色 | 預計完成 |
|------|------|---------|---------|
| 1    | [動作] | [角色] | [日期] |

---

## 8. 完成確認

- [ ] 所有 High 影響文件已更新
- [ ] 受影響的 Gate 已重新執行
- [ ] ARTIFACTS.md 已更新所有文件的成熟度
- [ ] CIA 記錄已移至 Approved 狀態
```

---

## ARTIFACTS.md CIA 記錄格式

每次 CIA 完成後，在 ARTIFACTS.md 新增一條記錄：

```yaml
# ARTIFACTS.md 中的 CIA 記錄區塊

## CIA Records

- id: CIA-20250115-001
  date: "2025-01-15"
  change_item: "用戶登入流程重新設計"
  affected_docs:
    - id: SRS-F-001
      maturity_before: Baselined
      maturity_after: Draft
      notes: "需重新通過 Plan Gate"
    - id: API-SPEC-AUTH
      maturity_before: Approved
      maturity_after: Draft
      notes: "新增 OAuth2.0 端點"
  gates_to_rerun:
    - gate: "Plan Gate"
      mandatory: true
    - gate: "Build Gate"
      mandatory: false
      reason: "建議驗證但不強制"
  status: Approved
  decision_by: "Task-Master"
```

---

## 文件成熟度降級規則

| 原成熟度 | 受影響後降為 | 說明 |
|---------|-----------|------|
| Baselined | Draft | 必須重走完整 Gate 流程 |
| Approved | Draft | 需要重新 Review |
| In Review | Draft | 重新起草 |
| Draft | Draft | 無需降級，繼續修改 |

---

## 快速判斷：這個變更需要 CIA 嗎？

```
Q1: 這個文件在 ARTIFACTS.md 中嗎？
    → 不在 → 不需要 CIA，直接修改
    → 在 ↓

Q2: 成熟度是 Approved 或 Baselined？
    → 否（Draft / In Review）→ 不需要 CIA，直接修改
    → 是 ↓

Q3: 必須執行 CIA ✅
```

---

## Auto-Trigger 行為

當 CIA-GUARD hook 偵測到你要修改 Baselined 文件時：

```
[CIA-GUARD] ⚠️ 此檔案為 Baselined artifact！
修改前必須完成 CIA (Change Impact Assessment)。

請先執行：
1. 填寫 CIA Checklist → 存為 memory/cia-[date]-[desc].md
2. 更新 ARTIFACTS.md 新增 CIA record
3. 獲得 Task-Master / 凱子批准
4. 將受影響文件降為 Draft
5. 才能開始修改

如果這是緊急 Hotfix，說「這是緊急 Hotfix」並說明原因。
```

---

## 緊急 Hotfix 例外

緊急 Hotfix 可跳過完整 CIA 流程，但必須：

1. 明確說明「這是緊急 Hotfix」+ 原因
2. 事後 24 小時內補完整 CIA 記錄
3. 在 ARTIFACTS.md 標記 `hotfix: true`
4. 下一個 Gate Review 時強制審查此 CIA

---

## Anti-Patterns

| ❌ 不要這樣 | ✅ 改這樣做 |
|---|---|
| 直接修改 Baselined 文件 | 先做 CIA，獲得批准再修改 |
| CIA 只填一半就開始修改 | 填完整並獲得決策者批准 |
| 忘記更新 ARTIFACTS.md | CIA 完成後立即更新成熟度 |
| 忽略 CIA-GUARD 警告繼續修改 | 停下來，先完成 CIA |
| 沒有列出所有受影響文件 | 從 ARTIFACTS.md 全面搜尋依賴關係 |
