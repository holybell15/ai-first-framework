# Hotfix Log — [專案名稱]

> SSOT：所有緊急修復記錄。由 review-agent 在 Critical/High 問題確認時建立條目。
> 格式規範：見 CLAUDE.md §Hotfix / 緊急修復流程

---

## 使用規則

| 欄位 | 說明 |
|------|------|
| `date` | 發現日期（YYYY-MM-DD） |
| `severity` | 🔴 Critical / 🟠 High / 🟡 Medium |
| `mode` | Lite / Standard |
| `feature` | 受影響 Feature（F-code） |
| `issue` | 問題簡述（一行） |
| `production_branch` | 實際 production branch 名稱 |
| `fix_by` | 修復負責人（Agent 或人員） |
| `patch_status` | Hotfix 補件狀態（最小事故紀錄 / RS更新 / Gate文件） |
| `resolved` | ✅ 已結案 / 🔄 進行中 |

---

## 記錄格式

```markdown
### HF-YYYY-NNN — [問題簡述]

| 欄位 | 值 |
|------|-----|
| date | YYYY-MM-DD |
| severity | 🔴 Critical / 🟠 High |
| mode | Lite / Standard |
| feature | F## |
| issue | [問題描述] |
| production_branch | main / release/* / 其他 |
| fix_by | [backend-agent / devops-agent / 人員名稱] |
| patch_status | ⬜ 事故紀錄補齊 / ⬜ follow-up backlog / ⬜ RS更新（若有） / ⬜ Gate文件補件（Standard） / ⬜ security-agent 快速審查（Critical） |
| resolved | 🔄 進行中 |

**修復摘要：**
[簡述根本原因和修復方式]

**驗證摘要：**
[列出 smoke / unit / 手動驗證結果]

**回滾方案：**
[git revert / 舊版 artifact / rollback script / 手動回復步驟]

**補件截止：** YYYY-MM-DD（發現後 48 小時內）

**補件清單：**
- [ ] 事故紀錄補齊（根因 / 修復摘要 / 驗證結果）
- [ ] 建立 follow-up backlog
- [ ] RS 對應章節更新（若修改需求或行為）
- [ ] Gate Review 補件文件（GRN 記錄，Standard）
- [ ] security-agent 快速審查通過（Critical）
```

---

## 活躍 Hotfix

> （目前無活躍 Hotfix）

---

## 已結案 Hotfix

> （目前無已結案記錄）

<!-- HOTFIX-SIG: 由 review-agent 維護 | 最後更新: 2026-03-15 -->
