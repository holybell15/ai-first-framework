# 技術決策記錄（ADR）

> 每次重大技術決策都要在此記錄，格式由 Architect Agent 維護。

---

## 使用方式

每個 ADR 由 Architect Agent 產出後，貼入此檔案。
決策一旦記錄，不可在未新增反向 ADR 的情況下直接修改。

---

## ADR 格式

```yaml
adr_id: "ADR-{NNN}"
title: "[決策主題]"
status: "accepted | superseded | deprecated"
date: "YYYY-MM-DD"
owner: "Architect"
background: "為何需要這個決策"
decision: "最終選擇"
rationale: "選擇理由"
alternatives: "考慮過的其他選項"
consequences: "這個決策的影響"
depends_on:
  - id: "ADR-{NNN}"
    relationship: "[依賴關係說明，例如：本 ADR 的實作前提是 ADR-001 的快取策略]"
depended_by:
  - id: "ADR-{NNN}"
    relationship: "[被依賴關係說明，例如：ADR-010 的 API 設計依賴本決策的認證機制]"
```

> **DDG 規則（DDG-01~05）**：每條 ADR 必須填寫 `depends_on` 與 `depended_by`；若確認無依賴，填寫 `[]` 並在 `rationale` 中說明。空值（未填）視為違規（DDG-04 告警）。

---

<!-- 從這裡開始貼入 ADR -->
