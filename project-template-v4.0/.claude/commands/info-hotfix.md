啟動 Hotfix 緊急修復流程。

這個指令現在分成兩種模式：
- `Lite Hotfix`：適合小團隊、沒有 staging、沒有 rollback script 的情況
- `Standard Hotfix`：適合有完整 release / staging / rollback 能力的團隊

**Step 1 — 問題描述**
詢問：「請描述問題：（一句話說明症狀）」

**Step 2 — 嚴重度判定**
根據描述，判定嚴重度並請操作者確認：

```
嚴重度判定：

  🔴 Critical — 服務中斷 / 資料外洩 / P0 合規違規
  🟠 High     — 核心功能完全失效 / 資料錯誤但未外洩
  🟡 Medium   — 功能部分異常，有替代方案 → 正常 Sprint
  🟢 Low      — 體驗問題 / 文字錯誤 → 正常 Sprint

你評估是哪個等級？（輸入 Critical / High / Medium / Low）
```

若回答 Medium 或 Low：停止 Hotfix，說明「請排入正常 Sprint，優先級 P1」。

**Step 3 — 選擇 Hotfix 模式**
詢問：
- 「目前有 staging 或可獨立驗證環境嗎？（有 / 沒有）」
- 「目前有現成 rollback 機制嗎？（git revert / 舊版 artifact / rollback script / 沒有明確機制）」

若沒有 staging，或沒有現成 rollback script，預設走 `Lite Hotfix`。
否則可走 `Standard Hotfix`。

**Step 4 — 建立 HF 條目（Critical / High）**
詢問：
- 「影響哪個功能模組？（F## 名稱）」
- 「受影響的用戶範圍？（全部 / 部分 / 單一租戶）」
- 「實際 production branch 名稱？（預設 main，若不是請填真實分支）」

讀取 `memory/hotfix_log.md`，取得目前最新 HF 編號，新條目編號 = 最新 + 1。
在 `memory/hotfix_log.md` append：

```markdown
## HF-[YYYY]-[NNN] — [日期]
- **問題**：[描述]
- **嚴重度**：[Critical / High]
- **模式**：[Lite / Standard]
- **影響模組**：[F## 名稱]
- **影響範圍**：[受影響用戶]
- **production branch**：[main / release/* / 其他]
- **根因**：待確認
- **修復人**：[操作者名字]
- **狀態**：🔴 調查中
- **補件狀態**：⏳ 待補（最小事故紀錄 / RS 更新 / Gate 文件）
```

**Step 5 — 建立分支指令**
顯示：
```bash
git checkout [production-branch]
git pull
git checkout -b hotfix/HF-[YYYY]-[NNN]
```

**Step 6 — 啟動修復流程**
提示操作者：
```
接下來的步驟：

1. 【根因分析】讀取 context-skills/systematic-debugging/SKILL.md，找出根本原因
   → 禁止猜測，必須有 evidence 才進入修復

2. 【最小化修復】只動必要的 code，不重構，不加功能
   → 修改範圍 ≤ 2 架構層

3. 【確認 Rollback 方案】
   Lite Hotfix：
   → 至少確認 1 種可執行方案：git revert / 舊版 artifact / 手動回復步驟
   Standard Hotfix：
   → rollback script + DB rollback / down-migration（若有 schema 變更）

4. 【快速 Review】新 session → Review Agent 執行 HF-01~06 清單
   🔴 Critical 還需 Security Agent 快速掃描

5. 【部署前驗證】
   Lite Hotfix：
   → 沒有 staging 時，至少完成 production 前 smoke checklist，並留下驗證證據
   Standard Hotfix：
   → Staging 冒煙測試通過後才上 Production

6. 【48hr 補件】
   Lite 最小補件：
   → hotfix_log.md 補齊根因 / 修復摘要 / 驗證結果
   → 建立 1 條 follow-up backlog
   → 若改到需求或行為，補最小 RS 更新
   Standard 完整補件：
   → 更新 RS + Gate 文件 + hotfix_log.md 標記 ✅ 結案
```
