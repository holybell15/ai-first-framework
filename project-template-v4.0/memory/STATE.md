# STATE.md — 即時狀態（≤400 tokens）
<!-- Task-Master 必讀 | 每次 handoff / 暫停 / context>60% 時更新 -->

```yaml
stage: "Discover"                   # Discover | Plan | Build | Verify | Ship
mode: "standard"                    # standard | lite
task_current: ""                    # 當前任務 ID (e.g. F01-API-users)
task_status: "pending"              # pending | in_progress | blocked | in_review | done
blocked_by: null                    # null 或 "[原因]"

dispatcher:
  active_specialist: ""             # 當前 specialist 角色
  active_group: ""                  # Discovery | Build | Verify
  skills_loaded: []                 # 當前已載入的 skill

next_action: "初始化專案"
resume_command: "讀取 STATE.md，啟動 Task-Master 分派第一個任務"
last_updated: ""
```
