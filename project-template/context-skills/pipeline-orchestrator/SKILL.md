---
name: pipeline-orchestrator
description: >
  **Use this skill whenever you're ready to start a multi-Agent Pipeline or continue a partially-completed one.**

  Triggered by: "我要開始做需求", "來做技術設計", "繼續 P04", "我想執行需求訪談", "開始下一個 pipeline",
  "執行 Pipeline: 技術設計", "Pipeline: 開發準備", or when transitioning between phases (P01 → P02 → P03, etc.).

  This skill orchestrates multi-step Pipelines (Interviewer → PM → UX → Architect → DBA, etc.), manages Agent handoffs,
  tracks state across sessions, and prevents context loss between phases.

source: levnikolaevich/claude-code-skills (adapted for workflow_rules §38-41)
---

# Pipeline Orchestrator Skill

## 啟動前 — CIC Grounding
```markdown
## CIC Grounding Declaration
讀取的上游文件:
- [ ] [文件1] — 摘要: [1句]
- [ ] [文件2] — 摘要: [1句]
繼承決策: [ADR-XXX 摘要]
本 Pipeline 目標: 輸入 → 輸出 → Agent 順序
```

## Agent 交接
每個 Agent 完成後寫入 TASKS.md:
```
| [ID] | [Agent] 完成 | [Agent] | 完成 | 交接: [下一Agent] 需知→ [摘要] |
```

對話中顯示:
```
[Agent] 完成，繼續執行下一步嗎？
交接: 產出[清單] → 下一步[Agent做什麼]
```
等用戶「繼續」或「停」

## 防幻覺
每個 Agent 結束前報告:
```
目前理解確認:
1. [需求是...]
2. [輸出包含...]
3. [下一步是...]
以上正確嗎？
```

## Pipeline 對照表
| Pipeline | Agent 順序 | Gate |
|---------|-----------|------|
| P01 需求訪談 | Interviewer → PM → UX | Gate 1 |
| P02 技術設計 | Architect → DBA → Review | Gate 2 |
| P03 開發準備 | Backend → Frontend → QA | G4-ENG |
| P04 實作開發 | Backend → Frontend → QA | Gate 3 |
| P05 合規審查 | Security → Review | — |
| P06 部署上線 | DevOps → Review | L2 |

## 錯誤處理
| 情境 | 處理 |
|------|------|
| 模糊需求 | 暫停，觸發 brainstorming |
| 產出不合格 | 退回，觸發 verification |
| Gate 不通過 | 退回對應 Pipeline |
| 需要並行 | 觸發 subagent-driven-development |

## Dashboard 自動更新
Agent 完成 → pipelineLog 新增 + inProgress 更新 + documents 新增
Pipeline 完成 → pipelineCompletion = done
Gate 通過 → gateStatus = done

---

## 🔀 工具環境感知

Pipeline 執行時需感知當前所在的工具環境，並在適當時機提示切換：

### 環境判斷
| 環境 | 判斷方式 | 適合的 Pipeline |
|------|---------|---------------|
| **Cowork** | 在 VM 沙盒中，無 Git repo | P01 需求訪談 |
| **Claude Code** | 在用戶機器上，有 Git repo | P02～P06 所有技術階段 |

### 切換規則
| 時機 | 動作 |
|------|------|
| P01 完成 + Gate 1 通過 | 觸發 quality-gates 的切換指引，提示用戶開終端機 |
| P02～P06 在 Cowork 中被觸發 | 輸出警告：「⚠️ 此 Pipeline 建議在 Claude Code 中執行，以便進行技術驗證。請先切換到終端機。」 |
| 用戶堅持在 Cowork 執行 P02+ | 允許，但在交接摘要中標記：`⚠️ 未經開發環境驗證` |
