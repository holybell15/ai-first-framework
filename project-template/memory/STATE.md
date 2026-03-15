# memory/STATE.md — 跨 Session 狀態快照
<!-- 自動維護（workflow_rules.md §38）| 請勿手動大幅修改 -->
<!-- 更新時機：Pipeline Agent 交接後 / 用戶說「暫停」/ Context > 60% -->

---
session_snapshot:
  last_updated: "YYYY-MM-DDTHH:MM:SS+08:00"
  project: "[專案名稱]"
  phase: "[Px 階段名稱]"           # 例：P02 技術設計
  agent_last: "[最後執行的 Agent]"  # 例：Architect Agent

team:
  active_member: "[名字]"          # 目前持有工作權的人
  current_role: "[Agent 角色]"     # 例：Backend Agent
  handoff_to: "[下一位名字]"       # 完成後交給誰（null = 尚未決定）
  handoff_notified: false          # 是否已通知下一位（true/false）

current_focus:
  module: "[F## 功能名稱]"          # 例：F01 用戶登入
  doing: "[進行中的工作描述]"        # 例：撰寫 F01-SW-ARCH.md
  blocked_by: null                  # null 或 "[阻塞原因]"
  next_action: "[下一步應做什麼]"    # 例：繼續 DBA Agent 設計 Schema

decisions_locked:
  - id: "ADR-XXX"
    summary: "[一句話決策摘要]"
  # 只記錄最近 3-5 個關鍵決策，舊的移到 memory/decisions.md

open_questions:
  - "🔴 [阻塞性未決問題]"
  - "🟡 [非緊急待確認問題]"
  # 🔴 = 阻塞進行  🟡 = 非緊急但需確認  空列表 = []

files_in_progress:
  - path: "[檔案路徑]"
    status: "進行中"                # 進行中 / 待開始 / 待 Review
    completion: "0%"

gate_status:
  last_passed: "無"                 # 無 / Gate 1 / Gate 2 / G4-ENG / Gate 3
  next_gate: "Gate 1"
  blockers: []

model_profile: "balanced"           # quality | balanced | budget（§40）

resume_command: |
  讀取 memory/STATE.md 和 CLAUDE.md，
  接續 [Pipeline名稱] 的 [Agent名稱] 工作。
  目前焦點：[F## 功能名稱]，[進行中的工作]。

---

## 使用說明

### 新 Session 恢復流程
1. 讀取此檔案
2. 輸出「STATE 讀取確認」（§38.3 格式）
3. 根據 `resume_command` 自動繼續

### 自動更新時機（§38 ST-01~ST-03）
- Pipeline Agent 交接完成後
- 用戶說「暫停」/「先停這裡」/「明天繼續」
- Context 消耗超過 60%（觸發 Context 隔離提示時）
