讀取 `memory/STATE.md` + `TASKS.md`，輸出 Task-Master 派遣報告。

**Step 1 — 讀取現況**
依序讀取：
1. `memory/STATE.md` — 目前階段、正在做什麼、上次停在哪
2. `TASKS.md` — 所有 Feature 的狀態（Backlog / 進行中 / Done / Blocked）

若 `TEAM.md` 存在，也讀取（確認各角色負責人）。

**Step 2 — 分析優先順序**

| 優先級 | 條件 |
|--------|------|
| 🔴 P0 | Hotfix 未解決 / Gate 被 FAIL 需退回修正 |
| 🟠 P1 | 目前進行中且無阻塞的任務（繼續推進） |
| 🟡 P2 | 依賴已解除的 Backlog 任務（可以啟動） |
| 🟢 P3 | 無依賴的新 Backlog 任務（按 F-code 順序） |
| ⬜ P4 | 阻塞中的任務（等待外部，先放） |

**Step 3 — 輸出派遣報告**

```
📋 Task-Master 派遣報告
━━━━━━━━━━━━━━━━━━━━━━━
📍 目前狀態
  階段：[Pipeline 名稱]
  進行中：[F-code] [Feature名稱]（[Agent/成員]負責）

🎯 現在最優先
  任務：[具體任務描述]
  派給：[Agent 名稱] / @[成員名字]
  啟動方式：[具體指令或說明]

⏭️ 接下來（依序）
  1. [任務] → [Agent/成員]
  2. [任務] → [Agent/成員]

⚠️ 阻塞中（需關注）
  [F-code]：[阻塞原因] — 等待：[解除條件]

💡 建議行動
  [一句話說明為什麼這樣排]
━━━━━━━━━━━━━━━━━━━━━━━
```

**Step 4 — 若有新功能請求**
若使用者在呼叫時描述了新功能（例：`/task-master 我要加用戶登入功能`）：
1. 讀取 `TASKS.md` 找目前最大的 F-code 編號
2. 分配下一個 F-code
3. 判斷從哪個 Pipeline 開始（需求模糊 → 需求訪談；有規格 → 技術設計）
4. 在 `TASKS.md` 新增條目
5. 更新 `memory/STATE.md` 的 `current_focus`
6. 在派遣報告中標示此新 Feature 為 P3

**注意事項**
- 必須先讀取文件，不憑記憶判斷
- 不直接執行任務，只做派遣決策
- 若 TASKS.md 不存在或為空，提示：「TASKS.md 尚未初始化，請先執行 /init」
