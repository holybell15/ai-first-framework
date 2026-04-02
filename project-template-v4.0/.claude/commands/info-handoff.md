執行 Agent 交接流程：

**Step 1 — 收集資訊**
依序詢問操作者：
1. 「你是哪個 Agent？（PM / UX / Architect / DBA / Backend / Frontend / QA / Security / DevOps / Review）」
2. 「你完成了什麼？（一句話）」
3. 「交給下一個誰？」
4. 「有哪些關鍵決策要告訴下一個人？（可多條，輸入完按 Enter 兩次）」
5. 「下一個人需要特別知道什麼？」
6. 「有未解問題或阻塞項嗎？（沒有就說無）」
7. 「產出了哪些文件？（路徑，可多條）」

**Step 2 — 產出交接摘要**
格式化輸出以下內容（確認後才寫入）：
```markdown
## 🔁 交接摘要 — [今天日期]

| 項目 | 內容 |
|------|------|
| **我是** | [Agent 名稱] |
| **交給** | [下一個 Agent] |
| **完成了** | [完成內容] |
| **關鍵決策** | [決策列點] |
| **產出文件** | [路徑列點] |
| **你需要知道** | [重點列點] |
| **🔴 阻塞項** | [阻塞項或「無」] |
```

顯示後問：「這樣正確嗎？（是 / 修改）」

**Step 3 — 寫入**
確認後：
1. 將交接摘要 append 到 `TASKS.md` 的交接摘要區塊
2. 更新 `memory/STATE.md`：
   - `team.handoff_to` = 下一個人的名字
   - `team.handoff_notified` = false
   - `current_focus.next_action` = 下一步描述
   - `session_snapshot.agent_last` = 目前 agent

**Step 4 — 提醒**
顯示：
```
✅ 交接完成。
請執行：git commit -m "handoff([你的角色]→[下一角色]): [完成內容一句話]"
然後通知 @[下一位] 可以開始工作。
```
