首次專案初始化流程。新 repo 套用框架後執行一次，設定好一切再開始工作。

**Step 0 — 框架完整性驗證**
找到 `tools/workflow-test/run_tests.py`（從框架根目錄往上搜尋，或使用 `$FRAMEWORK_ROOT`）。
若找到，執行：
```bash
python3 [framework-root]/tools/workflow-test/run_tests.py
```
顯示結果：
- ✅ 全部通過 → 繼續 Step 1
- 🔴 有失敗項 → 列出失敗項，提示：「框架安裝可能不完整，建議先排除後再繼續。繼續嗎？（是 / 否）」

**Step 1 — 確認專案基本資訊**
詢問（一次問完）：
1. 「專案名稱？（英文，用於資料夾和 git）」
2. 「產品中文名稱？（用於文件標題）」
3. 「技術棧？（例：Vue 3 / Laravel 11 / PostgreSQL / GCP）」
4. 「目標用戶類型？（B2B / B2C / 內部工具）」
5. 「第一個 Feature 主題是什麼？（例：用戶身份驗證）」

**Step 2 — 替換佔位符**
將以下檔案中的 `[專案名稱]`、`[產品名稱]`、`[技術棧]` 等佔位符替換為實際值：
- `CLAUDE.md`
- `memory/product.md`
- `memory/STATE.md`（若存在佔位符）
- `10_Standards/API/Error_Code_Standard_v1.0.md`（替換錯誤碼前綴）

**Step 3 — 設定團隊成員**
提示：「接下來設定團隊成員。」
執行 `/info-setup-team` 流程，填入各 Agent 角色的負責人姓名和 @handle。

**Step 4 — 建立第一個 Feature 條目**
在 `TASKS.md` 新增第一個 Feature 的 Backlog 條目：
```
| F01 | [Feature主題] | — | 📋 Backlog | — |
```
在 `MASTER_INDEX.md`（若存在）登記 F01。

**Step 5 — Git 初始化提交**
顯示建議的初始化 commit 指令：
```bash
git add .
git commit -m "feat: init project with AI-First Framework

專案：[專案名稱]
框架版本：見 ai-first-framework/VERSION"
```

**Step 6 — 完成確認**
```
🚀 專案初始化完成

[產品名稱] 已就緒
─────────────────
✅ 框架驗證：[N] pass
✅ 佔位符替換完成
✅ 團隊成員設定完成
✅ 第一個 Feature (F01) 已建立

下一步：
  若你是第一次使用框架或目前只有 1-2 人：
    讀取 CLAUDE.md，使用 Lite Mode 啟動 F01

  若你已準備好走完整流程：
    執行 /pipeline 選擇「Pipeline: 需求訪談」
    建議第一句話：「執行 Pipeline: 需求訪談，針對 [Feature主題]」
```

> 若 Step 0 框架測試有 fail，建議先至 `tools/workflow-test/index.html` 查看詳細報告。
