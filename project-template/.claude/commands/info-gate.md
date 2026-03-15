準備 Gate Review。

**Step 1 — 選擇 Gate**
```
要執行哪個 Gate Review？

  1. Gate 1  — P01 需求訪談完成後
  2. Gate 2  — P02 技術設計完成後
  3. G4-ENG  — P03 開發準備完成後（P04 解鎖條件）
  4. Gate 3  — P04 實作開發完成後

輸入數字：
```

**Step 2 — 確認產出文件是否存在**
根據選擇，確認以下文件存在：

Gate 1：
- `06_Interview_Records/IR-*.md` ✓/✗
- `02_Specifications/US_F##_*.md` ✓/✗
- `01_Product_Prototype/*.html` ✓/✗

Gate 2：
- `03_System_Design/F##-SW-ARCH.md` ✓/✗
- `03_System_Design/F##-DB.md` ✓/✗
- `memory/decisions.md`（有 ADR 內容）✓/✗

G4-ENG：
- `02_Specifications/F##-API.md` ✓/✗
- `03_System_Design/F##-DB.md` ✓/✗

Gate 3：
- `src/` 有程式碼 ✓/✗
- `08_Test_Reports/F##-TR.md` ✓/✗

若有缺漏，列出並詢問是否仍要繼續。

**Step 3 — 輸出 Review Session 開場指令**
顯示以下內容（請操作者複製到新 Claude Code session 或新 Cowork task）：

```
⚠️  請在「新的 Claude Code 視窗」或「新的 Cowork task」中貼上以下指令：
─────────────────────────────────────────────────
你是 Review Agent。請讀取 CLAUDE.md，然後執行 [Gate N / G4-ENG] 驗收。

驗收範圍：
- 讀取 TASKS.md 了解目前進度
- 讀取 context-skills/quality-gates/SKILL.md 取得 checklist
- 逐項檢查對應的產出文件
- 產出 Review 報告到 07_Retrospectives/
─────────────────────────────────────────────────
重要：同一個 session 不做 Review（防止確認偏誤）。
```

**Step 4 — 更新 STATE.md**
將 `gate_status.next_gate` 更新為對應的 Gate 名稱。
