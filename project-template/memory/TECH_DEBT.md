# TECH_DEBT.md — 技術債登錄簿
<!-- 版本: v1.0 | 日期: YYYY-MM-DD | 來源: A_Law v3.0 Rebuild Template v1.1 -->

> **自動觸發條件**（Agent 必須主動登記，不需等人指示）：
> - QA Agent：Bug 嚴重度 ≥ Medium（High / Critical）
> - QA Agent：測試覆蓋缺口（業務關鍵路徑缺乏測試）
> - DevOps Agent：部署發現架構或基礎設施缺陷
> - DevOps Agent：CI/CD Pipeline 測試覆蓋率下降
> - 任何 Agent：暫時繞過問題（workaround）而非正式修復

---

## CVSS-based SLA

| 嚴重度 | 定義 | SLA（必須解決期限） |
|--------|------|-------------------|
| **Critical** | 影響多租戶隔離、資料外洩風險、服務中斷 | 7 個工作天 |
| **High** | 核心功能異常、效能嚴重降級、安全漏洞 | 30 個工作天 |
| **Medium** | 非核心功能異常、代碼品質問題、測試覆蓋缺口 | 90 個工作天 |
| **Low** | 小問題、最佳化建議、文件補強 | 下版排期 |

---

## 技術債清單

| TD-ID | 發現日期 | 發現階段 | 描述 | 嚴重度 | SLA 截止 | 負責 Agent | 狀態 |
|-------|---------|---------|------|--------|---------|-----------|------|
| TD-001 | YYYY-MM-DD | [QA/DevOps/Gate#] | [問題描述] | Critical/High/Medium/Low | YYYY-MM-DD | [角色] | Open |

---

## 登錄說明

**TD-ID 格式**：`TD-[NNN]`（三位數遞增，例：TD-001、TD-002）

**發現階段範例**：
- `QA-G3`（Gate 3 測試期間）
- `DevOps-Staging`（Staging 部署時）
- `Review-G2`（Gate 2 審查時）
- `Prod-Hotfix`（上線後緊急修復）

**狀態流轉**：
```
Open → InProgress → Resolved → Verified（QA 確認修復有效）
                              → Deferred（延至下版，需填理由）
```

**登錄後必做**：
1. 在 `TASKS.md` 新增對應 TD 追蹤項目
2. Critical/High 的 TD 必須在下一個 Gate Review 時向 Review Agent 報告
3. Resolved 後由 QA Agent 執行回歸測試並更新狀態為 Verified

---

## 已解決清單

| TD-ID | 解決日期 | 解決方式 | 驗證人 |
|-------|---------|---------|--------|
| — | — | — | — |
