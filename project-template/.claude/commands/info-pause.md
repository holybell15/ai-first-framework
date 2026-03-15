暫停目前工作，將狀態寫入 STATE.md 供下次同一人恢復。

**Step 1 — 確認暫停原因**
詢問：「暫停原因？（例：今天先到這、等待某人確認、切換去做其他事）」

**Step 2 — 確認當前狀態**
詢問：
1. 「目前做到哪裡？（一句話）」
2. 「下次恢復要從哪裡繼續？」
3. 「有沒有未解問題需要記下來？（沒有就說無）」

**Step 3 — 更新 STATE.md**
將以下欄位寫入 `memory/STATE.md`：
- `session_snapshot.last_updated` = 現在時間
- `current_focus.doing` = 做到哪裡
- `current_focus.next_action` = 下次恢復從哪繼續
- `current_focus.blocked_by` = 未解問題（若無則 null）
- `resume_command` = 適合下次恢復的開場指令

`resume_command` 格式：
```
讀取 memory/STATE.md 和 CLAUDE.md。
接續 [Pipeline 名稱] 的 [Agent 名稱] 工作。
目前焦點：[模組/功能名稱]，[做到哪裡]。
```

**Step 4 — 輸出確認**
```
⏸️ 工作已暫停

狀態已儲存到 memory/STATE.md
下次恢復：輸入 /resume 即可接續

記得執行：
  git add memory/STATE.md
  git commit -m "pause: [做到哪裡一句話]"
```
