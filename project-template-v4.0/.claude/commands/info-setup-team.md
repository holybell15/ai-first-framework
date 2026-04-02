執行以下團隊設定流程：

**Step 1 — 讀取現況**
讀取 `TEAM.md`，找出角色認領表中所有仍是 `[名字]` 或 `[@handle]` 的未填欄位。
讀取 `memory/STATE.md`，確認 `team.active_member` 是否已填。

**Step 2 — 逐一詢問**
針對每個未填的角色，依序問操作者：

```
「[角色名稱] 由誰負責？
  請輸入：名字（空白）@聯絡方式
  例：Alex @alex_slack
  （直接按 Enter = 暫時跳過）」
```

收集完所有角色後，額外問：
```
「目前是誰在工作？（會填入 STATE.md 的 active_member）
  輸入名字，或按 Enter 跳過」
```

**Step 3 — 寫入**
將收集到的資料寫入 `TEAM.md` 的角色認領表，替換對應的 `[名字]` 和 `[@handle]`。
若有填入 active_member，同步更新 `memory/STATE.md` 的 `team.active_member` 和 `team.current_role`。

**Step 4 — 確認**
顯示已填入的對照表，請操作者確認：
```
已設定：
  PM：[名字] [@handle]
  Backend：[名字] [@handle]
  ...
  目前工作者：[名字]

正確嗎？（是 / 否）
```
若回答「否」，重新詢問哪個角色要修改並更新。

**Step 5 — 完成提示**
顯示：
```
✅ 團隊設定完成。
下一步：請每位成員執行 git pull，然後按照 TEAM.md 的「Session 開場流程」啟動工作。
```
