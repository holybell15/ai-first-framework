# Agent Sync 策略 — AI-First Framework

> **最後更新**：2026-03-15 | **版本**：v1.0

---

## 問題背景

AI-First Framework 存在兩套平行的 Agent 系統：

| 系統 | 位置 | 使用方式 | 適用工具 |
|------|------|---------|---------|
| **Global Agents** | `~/.claude/agents/*.md` | 自動觸發（`@agent-name`）| Claude Code（CLI）|
| **SEED 檔案** | `project-template/context-seeds/SEED_*.md` | 手動貼上對話開頭 | Cowork / 任何 Claude session |

若不明確管理，兩套系統會隨著時間漂移，產生一致性問題。

---

## 設計決策：各有職責，SEED 為 Canonical Source

```
SEED_*.md（project-template/context-seeds/）
    ↓  是 Canonical Source（正本）
    ↓  包含完整提示詞 + 工作流規則
    ↓
Global Agents（~/.claude/agents/）
    → 從 SEED 精煉而來
    → 只保留 frontmatter + description + 核心行為摘要
    → 不複製完整提示詞內容（節省 context）
```

**原則**：
- SEED 檔案是 Agent 行為的**唯一真理來源**，包含完整的提示詞、工作流規則、輸出格式
- Global Agent 檔案是**精煉版**，只需 description 足夠精確讓 Claude 自動選擇正確 Agent
- 若兩者有衝突，**以 SEED 為準**

---

## 同步規則

### 何時需要同步

| 情境 | 需要更新 |
|------|---------|
| SEED 提示詞更新（新增工作流、修改輸出格式）| Global Agent description 可能需要更新 |
| Global Agent 加新 skill | SEED 的「自動化 Skill 套件」表格同步更新 |
| 工作流規則（workflow_rules.md）更新 | 所有相關 SEED 的 Pre-check 清單審查 |
| 新增 Agent 角色 | 同時建立 SEED + Global Agent |

### 同步 Checklist（修改 Agent 後執行）

```
[ ] 確認 SEED 的工作流規則是否還有效
[ ] Global Agent 的 description 是否仍準確反映 SEED 的行為
[ ] SEED 的 Skill 套件表格是否和 Global Agent frontmatter 的 skills 一致
[ ] 修改了多個 Agent 時，確認交接摘要格式仍相容
```

---

## 各 Agent 對應關係

| 職責 | SEED 檔案 | Global Agent | 備註 |
|------|---------|-------------|------|
| 需求訪談 | `SEED_Interviewer.md` | `aicc-interviewer.md`（或自定名稱）| 雙軌訪談（Functional + UX Track）|
| 需求規格 | `SEED_PM.md` | `aicc-pm.md` | US + AC + NYQ 驗證提示 |
| UX 設計 | `SEED_UX.md` | `aicc-ux.md` | Prototype + IA |
| 技術架構 | `SEED_Architect.md` | `aicc-architect.md` | ADR + Wave 並行 |
| 資料庫 | `SEED_DBA.md` | `aicc-dba.md` | Schema + ENUM + Field Registry |
| 後端開發 | `SEED_Backend.md` | `aicc-backend.md` | API Spec + TDD |
| 前端開發 | `SEED_Frontend.md` | `aicc-frontend.md` | 元件 + Design Token |
| QA 測試 | `SEED_QA.md` | `aicc-qa.md` | TC + TR + E2E |
| 資安合規 | `SEED_Security.md` | `aicc-security.md` | OWASP + FSC |
| 部署維運 | `SEED_DevOps.md` | `aicc-devops.md` | CI/CD + Rollback |
| 審查關卡 | `SEED_Review.md` | `aicc-review.md` | Gate 1/2/3 + Hotfix |

---

## 新專案的 Agent 命名策略

新專案使用 AI-First Framework 時，有兩種策略：

### 策略 A：沿用框架 Global Agents（推薦快速啟動）
- 直接使用 `~/.claude/agents/aicc-*.md` 的全域 Agent
- 優點：零配置，立即可用
- 限制：所有專案共用同一套 Agent 配置，無法專案客製

### 策略 B：為新專案建立專屬 Global Agents
```bash
# 複製框架 SEED 建立專案專屬 Agent
cp project-template/context-seeds/SEED_Review.md ~/.claude/agents/[project]-review.md
# 修改 frontmatter name/description 為專案前綴
```
- 優點：可針對專案客製 Agent 行為
- 限制：需維護多套 Global Agents

### 決策建議
- **單一產品** → 策略 A，SEED 當備份文件即可
- **多產品並行 / 不同技術棧** → 策略 B，各自維護

---

## Global Agent Frontmatter 標準格式

```markdown
---
name: [project-prefix]-[role]
description: [一句話描述，要能讓 Claude 在對話中自動選擇此 Agent]
  包含：職責範圍 / 使用時機 / 自動觸發的 skills
tools: Read, Write, Bash, Glob, Grep
color: [blue|green|purple|orange|red|gray|yellow]
---
```

**description 撰寫原則**：必須明確到 Claude 可以靠 description 決定要不要自動啟用此 Agent，避免過於模糊（「負責後端」→ 不夠；「執行 P03/P04 後端 API Spec 設計與實作，TDD 驅動，多租戶 tenant_id 強制隔離」→ 足夠）。

---

*此文件由框架維護者維護。新增 Agent 角色時同步更新。*
