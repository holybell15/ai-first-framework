執行里程碑完成流程（Gate 通過後使用）。

**Step 1 — 確認 Gate 通過**
詢問：「哪個 Gate 剛通過？（Gate 1 / Gate 2 / G4-ENG / Gate 3）」
詢問：「Review 報告存在 `07_Retrospectives/` 嗎？（是 / 否）」

若報告不存在，停止並提示：「請先完成 Gate Review，報告存入 07_Retrospectives/ 後再執行此指令。」

**Step 2 — 歸檔 TASKS.md 已完成任務**
讀取 `TASKS.md`，找出所有狀態為 ✅ 的任務。

若超過 15 筆：
- 將這些 ✅ 任務移至 `05_Archive/TASKS_archive_[YYYY-MM].md`
- 在 TASKS.md 保留一行提示：`<!-- [N] 筆已完成任務已歸檔至 05_Archive/TASKS_archive_[YYYY-MM].md -->`

**Step 3 — 更新 STATE.md**
- `gate_status.last_passed` = 剛通過的 Gate
- `gate_status.next_gate` = 對應的下一個 Gate 或 Pipeline
- `gate_status.blockers` = []
- `current_focus.next_action` = 下一個 Pipeline 名稱

Gate → 下一步對照：
- Gate 1 通過 → 下一步：Pipeline: 技術設計（P02）
- Gate 2 通過 → 下一步：Pipeline: 開發準備（P03）
- G4-ENG 通過 → 下一步：Pipeline: 實作開發（P04）
- Gate 3 通過 → 下一步：Pipeline: 合規審查（P05）

**Step 4 — 觸發 Retro（Gate 3 專用）**
若通過的是 Gate 3：
提示「請執行 `/retro` 進行 L1 Gate 回顧。」

**Step 5 — Git Tag（可選）**
詢問：「要打 Git Tag 嗎？（是 / 否）」
若是，顯示：
```bash
git tag -a [Gate-名稱]-[YYYY-MM-DD] -m "[Gate 名稱] 通過"
git push origin --tags
```

**Step 6 — 完成提示**
```
✅ 里程碑完成

[Gate 名稱] 通過 ✓
TASKS.md 已歸檔 ✓
STATE.md 已更新 ✓

下一步：執行 /pipeline 選擇 [下一個 Pipeline]
```
