# Call Center Engineering Standard — [專案名稱]

> **版本**：v1.0 | **SSOT**：本文件 + `memory/domain_call_center.md`
> **適用對象**：pm-agent、architect-agent、backend-agent、dba-agent、qa-agent、review-agent

---

## 1. 適用範圍

本標準適用於以下功能：

- inbound / outbound / blended contact center
- CTI / IVR / routing / queue
- agent desktop / supervisor console / QA scorecard
- recording / transcript / disposition / callback

若功能只是一個與聯絡中心完全無關的後台管理頁，可不套用本標準。

---

## 2. 狀態模型規則

以下狀態概念預設必須分離：

- `agent_state`
- `interaction_state`
- `outcome_state`

禁止將上述概念全部塞進單一 `status` 欄位，除非設計文件明確證明不會造成 routing、報表、audit 錯誤。

---

## 3. 事件與來源規則

- 每個關鍵狀態變更必須定義 source-of-truth
- 需標明事件來源：PBX / CTI / internal routing / CRM / UI
- 若存在重送或重複事件風險，需定義 idempotency / dedupe 規則
- 若存在狀態漂移風險，需定義 reconciliation 機制

---

## 4. 資料建模最低要求

涉及 Call Center 業務資料時，設計文件至少要說明：

- queue / campaign / channel / agent 的邊界
- vendor call id 與 internal interaction id 的對應
- transfer leg 是否拆成獨立 interaction record
- disposition、wrap-up、recording metadata 的存放位置
- KPI-sensitive timestamps 的來源與定義

---

## 5. 稽核與合規最低要求

若功能影響通話生命週期、錄音、客戶識別、或 agent 行為，至少要能追蹤：

- queue entered
- answered / connected
- hold / resume
- transfer target
- ended
- wrap-up completed
- disposition selected
- recording id 或 recording failure

若專案有遮罩、保留期限、同意錄音等要求，必須補充到 `memory/domain_call_center.md`。

---

## 6. 規格文件最低要求

PM / Architect / Backend / QA 文件中，至少其中一份必須明確寫出：

- 主要角色
- 主要流程
- 影響到的狀態轉換
- 影響到的外部整合
- 影響到的 KPI 或合規要求

高風險功能建議直接加入 `Call Center Domain Notes` 章節。

---

## 7. 測試最低要求

每個高風險功能至少覆蓋：

- 1 條主流程
- 1 條關鍵失敗流程
- 1 條狀態 / audit / recording 驗證

若功能涉及 routing、transfer、callback、recording、screen pop，測試設計需明確列出對應場景。

---

## 8. Review 擋板

以下情況預設不可直接過 Review：

- agent state 與 interaction state 混成單一欄位且未解釋
- routing 規則隱含在 UI 或程式碼中，未文件化
- 沒有 audit / recording linkage 設計
- 只測 happy path，未覆蓋轉接 / 中斷 / 事件亂序
- KPI 相關時間欄位未定義來源

---

## 9. 專案化要求

採用本標準時，專案應補齊：

- `memory/domain_call_center.md`

若有既有術語、報表定義、PBX / CTI 特例，皆以該檔案作為專案層 SSOT。

<!-- STD-SIG: Call Center Engineering Standard v1.0 | 2026-03-30 -->
