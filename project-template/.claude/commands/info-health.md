檢查專案結構完整性，輸出健康報告。

**Step 0 — 框架健康檢查（若 tools/workflow-test/ 存在）**
找到 `tools/workflow-test/run_tests.py`（從框架根目錄往上搜尋，或使用 `$FRAMEWORK_ROOT`）。
若找到，執行：
```bash
python3 [framework-root]/tools/workflow-test/run_tests.py
```
擷取結果摘要（Pass / Fail / Warning 數量）並顯示在報告頂部：
```
🔬 框架測試：[N] pass / [N] fail / [N] warn
   若有 fail → 提示：詳細結果見 tools/workflow-test/index.html（執行時加 --open 自動開啟）
```
若找不到 run_tests.py，跳過此步並顯示 `⚠️ 框架測試工具未找到（可選）`。

**Step 1 — 檢查必要資料夾**
確認以下目錄存在（✅ / ❌）：
- `01_Product_Prototype/`
- `02_Specifications/`
- `03_System_Design/`
- `04_Compliance/`
- `05_Archive/`
- `06_Interview_Records/`
- `07_Retrospectives/`
- `08_Test_Reports/`
- `09_Release_Records/`
- `10_Standards/`
- `context-seeds/`
- `context-skills/`
- `memory/`
- `contracts/`

**Step 2 — 檢查必要檔案**
確認以下檔案存在且非空（✅ / ❌ / ⚠️ 存在但空白）：
- `CLAUDE.md`
- `TASKS.md`
- `TEAM.md`
- `memory/STATE.md`
- `memory/workflow_rules.md`
- `memory/decisions.md`
- `memory/product.md`
- `memory/last_task.md`

**Step 3 — 檢查 SEED 檔案**
確認 `context-seeds/` 有 11 個 SEED 檔（Interviewer / PM / UX / Architect / DBA / Backend / Frontend / QA / Security / DevOps / Review）。

**Step 4 — 檢查 TEAM.md 填寫狀態**
掃描 `TEAM.md`，計算仍有 `[名字]` 或 `[@handle]` 未填的角色數量。

**Step 5 — 輸出報告**
```
🏥 專案健康報告
─────────────────
🔬 框架測試：[N] pass / [N] fail / [N] warn
✅ 通過  [N] 項
❌ 缺失  [N] 項：[列出缺失項目]
⚠️ 空白  [N] 項：[列出空白項目]
👤 TEAM.md 未填角色：[N] 個

整體狀態：[🟢 健康 / 🟡 需補齊 / 🔴 結構不完整]
```

若有 `--repair` 參數（使用者輸入 `/health --repair`）：
- 建立所有缺失的資料夾（加 `.gitkeep`）
- 提示哪些檔案需要手動建立
- 提示 `/setup-team` 可補齊 TEAM.md
