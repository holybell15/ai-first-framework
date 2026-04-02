# KB-AH — AI 幻覺已知模式庫
<!-- KB 分類: KB-AH（AI Hallucination） | 版本: v2.0 | 日期: YYYY-MM-DD -->
<!-- 來源: A_Law v3.0 Rebuild Template v1.1 + Continuous_Improvement v1.4 §8.1a -->

> 本庫記錄本專案已觀察到的 AI 幻覺模式，供所有 Agent 進場前閱讀。
> **更新時機**：每次 CR 若 `hallucination_root_cause: true`，必須產出或更新對應條目（KB-AH-01）。

---

## KB-AH 管理規則（KB-AH-01~04）

| 規則 | 說明 |
|------|------|
| **KB-AH-01** | 每次 CR 若 `hallucination_root_cause: true`，必須在本庫產出或更新對應的 KB-AH 條目（當天完成） |
| **KB-AH-02** | KB-AH 條目的 `prevention_prompt` 段落，須於下次同類型互審時注入 Reviewer Agent 的 System Prompt（防止同類幻覺重複逃逸） |
| **KB-AH-03** | 每季由架構師 Review KB-AH 條目，驗證 `prevention_prompt` 是否有效降低該 H 類型的 HT-01 指標；無效者更新條目 |
| **KB-AH-04** | KB-AH 條目達 `verified: true` 且連續 2 季無同類型幻覺，可轉為 KB-BP（最佳實踐）歸檔，原條目標記 `status: archived` |

---

## H1~H8 高風險場景速查表

| 幻覺代碼 | 名稱 | 高風險文件/階段 | 偵測關鍵字 | 預防措施 |
|---------|------|--------------|-----------|---------|
| **H1** | NFR 值捏造 | SRS §8（NFR章節）、SA 效能章節 | `< Nms`、`≥ N%`、`TPS > N`、`並發 N 人` | 效能數字必標 🟡 + 附訪談記錄依據（若無，標 🔴） |
| **H2** | 業務規則腦補 | SRS §3（業務邏輯）、GWT 驗收條件 | 「如果...則...」、「超過N元」、「主管覆核」 | AC 必須可追溯至訪談記錄；無記錄者標 🟡 等確認 |
| **H3** | 架構假設 | SA 技術選型、SD 系統設計 | 「使用 Redis」、「採用 Kafka」、「透過 MQ」 | 每個技術選型必須有 ADR 記錄（memory/decisions.md） |
| **H4** | 邊界行為假設 | SRS §9（邊界NFR）、API 錯誤碼定義 | 「自動重試」、「N秒後逾時」、「斷線重連」 | NFR 邊界必有訪談依據，否則 🔴 阻塞 |
| **H5** | 合規要求推論 | SRS §7（合規章節）、SEC 審查報告 | 「法規要求」、「金管會規定」、「個資法第N條」 | 必附法條出處；無出處者一律 🔴 並提交 Security 確認 |
| **H6** | API 欄位擴充 | API Spec、DB Schema、Field Registry | 欄位名不在 Field Registry、`// 額外欄位` | VO 欄位數 ≤ API Spec 定義數（DC-05）；Review Agent 核查 [GA-XMOD-002] |
| **H7** | 錯誤處理腦補 | API 錯誤碼表、Backend Service 實作 | `catch`、`retry`、`fallback`、`exponential backoff` | 錯誤處理策略必有 NFR 依據；無依據者標 🟡 等確認 |
| **H8** | UI 流程假設 | Proto 原型、UISpec 元件規格 | 「確認彈窗」、「自動導轉」、「Toast 通知」 | UI 流程必有 UX Seed（View Matrix）或 UX Brief 依據 |

---

## KB-AH 條目 YAML 模板

> 每次新增幻覺案例時，複製此模板填寫，存為 `KB-AH-{H類型}-{YYYY}-{NNN}.yaml`。

```yaml
# 路徑：memory/knowledge_base/KB-AH-{H類型}-{YYYY}-{NNN}.yaml
id: KB-AH-H?-YYYY-001
title: "[幻覺模式簡述，例：H1-CTI 回應時間無 NFR 依據]"
hallucination_type: H1  # H1 | H2 | H3 | H4 | H5 | H6 | H7 | H8
status: active          # active | under_review | deprecated | archived

trigger_pattern: |
  [觸發此幻覺的典型 Prompt / Context 模式]
  例：AI 從 SRS §8 衍生 NFR 數字，但訪談記錄無對應需求

example_hallucination: |
  [實際發生的幻覺內容]
  例：「CTI API 回應時間需 < 200ms」（出現在 SA 文件，但訪談未提及）

ground_truth: |
  [正確答案或應有的做法]
  例：NFR 數字必須來自 Seed §S4 明確記錄，或標記 🟡 等凱子確認

prevention_prompt: |
  [建議加入 Reviewer Agent System Prompt 的防範指令]
  例：「當文件出現效能數字（ms / TPS / 並發量）時，
       必須確認 Seed §S4 或訪談記錄中有對應依據，
       否則標記 🟡 並要求補充來源」

affected_modules:
  - F##

affected_phases:
  - P4   # 幻覺最常在哪個 Phase 產生

review_tier_impact: Tier-1  # Tier-1（高風險）| Tier-2 | Tier-3

source_cr: CR-YYYY-NNN  # 追溯至觸發此條目的 CR（Gate Review Note）
hallucination_origin_phase: P?
hallucination_discovery_phase: P?

verified: false
verified_by: null
verified_date: null

roi_tracking:
  citation_count: 0
  time_saved_hours: 0
  prevented_issues: 0
  last_cited: null
  effectiveness_score: null  # 1~5 分

created: YYYY-MM-DD
updated: YYYY-MM-DD
```

---

## 已記錄的幻覺條目

> 每次 CR 後（若 `hallucination_root_cause: true`），在此追加一條。
> 完整 YAML 條目存為獨立檔案（`KB-AH-H?-YYYY-NNN.yaml`），此表為索引。

| 條目 ID | 幻覺類型 | 標題摘要 | 影響模組 | verified | 最後更新 |
|--------|---------|---------|---------|---------|---------|
| （首次 CR 後填入）| H? | [描述] | F## | false | YYYY-MM-DD |

---

## 幻覺統計（每模組 L2 回顧後更新）

| 幻覺類型 | 累計次數 | 佔比 | 趨勢 | prevention_prompt 注入狀態 |
|---------|---------|------|------|--------------------------|
| H1 NFR 值捏造 | 0 | — | — | 未注入 |
| H2 業務規則腦補 | 0 | — | — | 未注入 |
| H3 架構假設 | 0 | — | — | 未注入 |
| H4 邊界行為假設 | 0 | — | — | 未注入 |
| H5 合規要求推論 | 0 | — | — | 未注入 |
| H6 API 欄位擴充 | 0 | — | — | 未注入 |
| H7 錯誤處理腦補 | 0 | — | — | 未注入 |
| H8 UI 流程假設 | 0 | — | — | 未注入 |
| **合計** | **0** | — | — | — |

> **HT-02 監控**：若任一類型佔比 > 30%，觸發 PIP 並針對性補充該類型的 `prevention_prompt` + Reviewer Few-shot。
> **HT-01 目標**：幻覺逃逸率 < 5%（連續 2 個月超標 → 觸發 PIP）。

---

## 相關文件引用

- 幻覺類型完整定義 → `memory/workflow_rules.md Section 十二`
- HT 追蹤指標（HT-01~06）→ `memory/workflow_rules.md Section 十 追蹤指標`
- Gate Review Note HT YAML 欄位 → `memory/workflow_rules.md Section 十 L1 Gate Review Note`
- L2 回顧 Seed 觀察 → `workflow_rules.md Section 十 MR-08`
