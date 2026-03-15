讀取 `memory/STATE.md` 和 `TASKS.md`，輸出一份快速狀態摘要：

```
📍 現在在哪
  專案：[project]
  階段：[phase]
  目前工作者：[team.active_member]（角色：[team.current_role]）
  正在做：[current_focus.doing]

⏭️ 下一步
  [current_focus.next_action]
  交給：[team.handoff_to]（若有）

🚦 Gate 狀態
  上次通過：[gate_status.last_passed]
  下一個：[gate_status.next_gate]
  阻塞項：[gate_status.blockers，若無顯示「無」]

⚠️ 未解問題
  [open_questions，若無顯示「無」]

📋 進行中任務（TASKS.md）
  列出狀態為 🔄 的任務，最多 5 條
```

不詢問任何問題，直接輸出後停止。
