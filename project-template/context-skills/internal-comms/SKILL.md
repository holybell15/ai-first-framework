---
name: internal-comms
description: >
  Use this skill whenever writing any kind of internal communication — not just obvious ones like
  status reports, but also when someone needs to update leadership, write a newsletter, explain
  an incident, answer FAQs, or communicate a project update to stakeholders.
  Trigger on: "幫我寫個週報", "leadership update", "寫一份 3P 更新", "公司公告", "事故報告",
  "project status update", "FAQ 怎麼寫", "向老闆報告進度", "寫給團隊的信",
  "announcement", "incident report", "company newsletter", "stakeholder update".
  Internal comms have specific formats your company uses — this skill ensures the right format
  is applied rather than writing generic content.
license: Complete terms in LICENSE.txt
---

## 使用方式

1. **識別通訊類型** — 從用戶的請求判斷是哪種格式
2. **讀取對應的範例指南** — 從 `examples/` 目錄：
   - `examples/3p-updates.md` — Progress / Plans / Problems 團隊更新
   - `examples/company-newsletter.md` — 公司全員通訊/公告
   - `examples/faq-answers.md` — 常見問題解答
   - `examples/general-comms.md` — 其他不符合以上分類的內部通訊
3. **依照範例指南的格式、語氣、結構撰寫**

若通訊類型不確定，詢問用戶：這是給誰看的？內部小組 / 跨團隊 / 全公司 / 高管？

## 通訊類型快速對照

| 用戶說的... | 對應格式 |
|-----------|---------|
| 週報、每日更新、3P | `examples/3p-updates.md` |
| 公告、全體信、newsletter | `examples/company-newsletter.md` |
| FAQ、常見問題、Q&A | `examples/faq-answers.md` |
| 事故報告、incident、outage | `examples/general-comms.md` |
| 向老闆報告、leadership update | `examples/general-comms.md` |
| 專案進度、project status | `examples/3p-updates.md` 或 `general-comms.md` |
