# ETHOS.md — AI-First Framework 工程哲學

> 此文件定義框架的核心工程哲學。每個 Agent 在執行任務時應內化這些原則。
> 靈感來源：gstack ETHOS.md（Boil the Lake / Search Before Building）

---

## 原則一：Boil the Lake（做完整，不留尾巴）

> AI 讓「做完整」的邊際成本趨近零。所以永遠選擇完整方案。

### 核心邏輯

傳統開發中，「做完整」等於「花更多時間」。但 AI Agent 改變了這個等式：
- 寫 100% 測試覆蓋 vs 60%，時間差異從「3 天 vs 1 天」變成「5 分鐘 vs 3 分鐘」
- 處理所有 edge case vs 只做 happy path，成本差異趨近零
- 完整 error handling vs 「之後再補」，AI 一次到位

**結論：既然成本相同，永遠選擇完整。**

### Lake vs Ocean — 判斷標準

| 類型 | 定義 | 例子 | 處理方式 |
|------|------|------|---------|
| **Lake（湖）** | 範圍有限、可窮盡 | 一個 API 的所有 error code、一個表單的所有驗證規則、一個功能的所有 edge case | **Boil it** — 做完、測完、不留 TODO |
| **Ocean（海）** | 無限擴展、不可窮盡 | 「所有可能的使用者行為」、「所有瀏覽器版本」、「所有可能的資料組合」 | **Don't boil** — 定義邊界、設定 scope、記錄排除理由 |

### 實踐規則

1. **測試覆蓋**：新功能的 happy path + 所有已知 edge case 必須有測試。不留 `// TODO: add tests later`
2. **錯誤處理**：每個 API 的 error response 必須有對應的前端處理邏輯。不留 `catch(e) { console.log(e) }`
3. **文件同步**：改了 code 就改 doc。不留「程式碼已更新，文件待補」
4. **型別完整**：TS/Java 的型別定義必須完整。不留 `any` 或 `Object`
5. **AC 覆蓋**：每條 AC 必須有對應的 TC。不留「待 QA 細化」超過 1 個 Sprint

### 什麼時候不 Boil

- 效能優化：先 measure 再 optimize，不 premature optimize 所有東西
- 未來需求：不為假設的未來需求預先設計
- 跨系統整合：第三方 API 的 edge case 超出控制範圍時，記錄已知限制即可

---

## 原則二：Search Before Building（先查再建）

> 不要從零開始。先看現有方案，再決定自己寫。

### 三層知識金字塔

| 層級 | 來源 | 信任度 | 使用方式 |
|------|------|--------|---------|
| **Layer 1：已驗證方案** | 框架內既有 Skill / SEED / 標準 | 高 | 直接使用或擴展 |
| **Layer 2：社群實踐** | npm 熱門套件、GitHub 高星專案、官方文件 | 中 | 評估後採用，記錄 ADR |
| **Layer 3：原創設計** | 自行設計的方案 | 需驗證 | 只有 Layer 1 + 2 都不適用時才走這條路 |

### 實踐規則

1. **新功能前**：先搜尋 `context-skills/` 是否有可用 Skill
2. **技術選型前**：先用 `deep-research` skill 調查已有方案
3. **寫 util 前**：先確認框架或語言標準庫是否已有等效功能
4. **設計 API 前**：先看 `10_Standards/API/` 是否已有類似模式

---

## 原則三：Fix-First, Not Read-Only（能修就修，不只報告）

> 發現問題時，能直接修的就修。不要只產出報告讓人去修。

### 適用範圍

| 情境 | Fix-First 行為 | 例外（需人工判斷） |
|------|---------------|-----------------|
| Code Review 發現格式問題 | 直接修正 | — |
| Code Review 發現邏輯問題 | 提出修正建議 + 說明原因 | 商業邏輯變更需 PM 確認 |
| QA 發現 UI bug | 修復 + 回歸測試 | 設計方向問題需 UX 確認 |
| 文件不一致 | 直接同步 | 需求變更需走 CIA |

### 界線

Fix-First 不等於自作主張。以下情況必須停下來問：
- 修改會影響其他模組的介面
- 修改涉及商業邏輯或合規要求
- 修改範圍超過 2 個架構層（SC-01）
- 不確定「正確行為」是什麼

---

## 原則四：Evidence Over Assertion（證據優先）

> 每個判斷都要有依據。不接受「我認為」「應該」「通常」。

### 實踐規則

1. **Review 報告**：每個 🔴/🟡 判定必須引用具體行號或文件段落
2. **技術選型**：ADR 必須有 benchmark 數據或社群使用統計
3. **Bug Report**：必須有重現步驟，不接受「有時候會壞」
4. **效能評估**：必須有測量數據，不接受「感覺很慢」

---

## 與框架機制的對應

| 哲學原則 | 對應框架機制 |
|---------|------------|
| Boil the Lake | 強制思考模板（RT/DT/PC/DL）、Nyquist AC 密度、test-driven-development |
| Search Before Building | deep-research skill、context-skills 路由表、10_Standards/ |
| Fix-First | AFL 自動修復迴圈、webapp-testing 30-fix 額度、Review Agent fix-first 模式 |
| Evidence Over Assertion | 信心度標記（🟢/🟡/🔴）、GA-SIG 簽核、CHC Context Health Check |
