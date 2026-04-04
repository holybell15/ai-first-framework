---
name: requesting-code-review
description: >
  Use this skill when preparing for a Gate review, submitting a PR for Review Agent, or asking
  "is this ready for review?". Trigger on: "我要提 Gate", "幫我看看這個 PR", "Gate 2/3 驗收",
  "準備提 Gate", "Review Agent 要看什麼", "code review 模板", "G4-ENG 驗收清單".
  Also trigger proactively when finishing a development branch that requires formal review —
  don't just merge; structure the review request so the reviewer has everything they need upfront.
source: obra/superpowers (adapted for AI-First workflow)
---

# Requesting Code Review Skill

## 為什麼要結構化 Review Request？

Review Agent（或任何 reviewer）在沒有上下文的情況下看 code 很低效。
結構化的 request 讓 reviewer 在 5 分鐘內了解：「這在做什麼、改了什麼、期望確認什麼」。
這也是 §31.7 「獨立 session Review」有效的前提。

---

## Review Request 標準模板

```markdown
## Review Request: [F碼] [功能名稱]

**Branch**: track-a/f[##]
**Author**: [Agent 名稱]
**Gate**: [Gate 2 / G4-ENG / Gate 3]（若適用）

### 變更摘要
- [2~4 行說明做了什麼，為什麼這樣做]

### 測試結果
- 後端: X passed / Y total
- 前端: X passed / Y total
- E2E:  X passed / Y total

### 自我 Review 清單
- [ ] 符合 US AC（AC-F##-01 ~ 0X 全覆蓋）
- [ ] TDD cycle 完整（DSV 聲明已填）
- [ ] tenant_id 隔離正確（若有業務資料）
- [ ] API response 與 F##-API.md 一致
- [ ] DB 操作與 F##-DB.md Schema 一致
- [ ] 無 hardcoded 密碼/key
- [ ] 錯誤碼完整定義
- [ ] STATE.md 已更新（§38）

### 特別請 Reviewer 注意
- [有疑慮的地方、不確定的決策、需要確認的邊界條件]
```

---

## Review 嚴重度

| 級別 | 類型 | 處理方式 |
|------|------|---------|
| **Block** | 安全漏洞、資料外洩、核心邏輯錯誤 | 必修，退回重審 |
| **Major** | 效能問題、edge case 未處理、AC 未滿足 | 強烈建議修 |
| **Minor** | 命名不一致、冗餘代碼 | 建議改善 |
| **Nit** | 風格偏好、個人習慣 | 可忽略 |

Block 或 Major → 退回 finishing-a-development-branch → 修正後重新 request。

---

## Gate 專用擴充清單

### Gate 2（技術設計驗收）
- [ ] SW-ARCH.md 架構完整，ADR 已記錄
- [ ] DB Schema 所有表有 tenant_id + 必要 index
- [ ] API 介面與前端需求對齊
- [ ] 無未解 Block（來自 Architect/DBA 自我 review）

### G4-ENG（工程設計驗收 — P04 的解鎖條件）
- [ ] GA 密度 ≥ 5 標記/千字（API Spec + DB Schema）
- [ ] DDG 依賴圖完整（depends_on / depended_by 已填）
- [ ] 跨層一致性：API ↔ DB ↔ FE 欄位名稱/型別對齊
- [ ] PTC-04 抽查 3~5 個 UI 元件（Prototype 追溯）
- [ ] SignoffLog: Architect + DBA + Review 三方簽核

### Gate 3（交付前審查）
- [ ] P0 測試全過，覆蓋率 ≥ 80%
- [ ] E2E 關鍵流程通過
- [ ] DSV 稽核日誌完整
- [ ] Security Review 通過（OWASP Top 10）
- [ ] Gate 1/2 遺留項已確認處理（L1 回顧）

---

## 啟動獨立 Review Session（§31.7）

Gate Review **必須在獨立 session** 中執行（不能自己審自己）：

**Cowork**:
```
開一個新的 Cowork task → 選同一個專案資料夾
說：「你是 Review Agent。讀取 CLAUDE.md，執行 [Gate X] 驗收。」
```

**Claude Code**:
```bash
# 開新終端機視窗
cd [專案路徑] && claude
# 說：你是 Review Agent。讀取 CLAUDE.md，執行 Gate X 驗收。
```
