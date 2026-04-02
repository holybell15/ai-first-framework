# [專案名稱] Token 預算追蹤

> 目的：控制 AI 成本，避免 context window 爆炸

## Context Budget 規則

| 情境 | 建議載入檔案 | 預估 Token |
|------|-------------|------------|
| 一般對話 | CLAUDE.md + last_task.md | ~2K |
| 需求訪談 | + product.md | ~4K |
| 寫 RS | + 對應 RS 檔案 + glossary.md | ~8K |
| 架構設計 | + decisions.md + company.md | ~6K |
| Code Review | + 對應程式碼 | ~10K |

## 大型檔案警示

> 載入超過 20K token 的檔案前，先確認是否真的需要

| 檔案類型 | 預估大小 | 建議 |
|----------|----------|------|
| 完整 RS 文件 | 5~15K | 只讀相關章節 |
| Prototype HTML | 3~8K | 只在 Frontend/UX Agent 使用 |
| 完整 Schema | 3~10K | 只在 DBA Agent 使用 |

## 專案實際檔案大小

> 使用前替換為實際測量值

| 檔案 | Token 數 | 備註 |
|------|----------|------|
| CLAUDE.md | <!-- TODO: 測量後填入 --> | 每次必讀 |
| memory/workflow_rules.md | <!-- TODO --> | 每次必讀 |
| memory/decisions.md | <!-- TODO --> | 按需讀取 |
| 各 RS 文件 | <!-- TODO --> | 按需讀取 |

## 每月 AI 成本追蹤

| 月份 | 預估用量 | 實際用量 | 備註 |
|------|----------|----------|------|
| <!-- TODO --> | - | - | 專案啟動月 |

---

<!-- TODO: 每個 AI 功能上線後，記錄實際 token 用量 -->
