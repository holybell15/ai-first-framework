---
name: brownfield-onboard
description: >
  接手既有程式碼時的 4 步上車流程：Snapshot → Baseline → Gap → Safe Change。
  觸發詞: "接手舊專案", "brownfield", "舊程式碼", "接手", "onboard existing"
user-invocable: true
allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
---

# Brownfield Onboarding Protocol

> 接手任何既有程式碼時，先跑完這 4 步再開始改東西。

---

## Step 1: Codebase Snapshot（自動化，~5 min）

掃描既有程式碼，產出地圖。

```bash
# 語言/框架偵測
find . -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.vue" | head -50

# 依賴分析
cat package.json 2>/dev/null || cat requirements.txt 2>/dev/null || cat pom.xml 2>/dev/null

# 目錄結構（前 3 層）
find . -maxdepth 3 -type d | grep -v node_modules | grep -v .git | sort
```

**產出**: `docs/brownfield/CODEBASE_MAP.md`

```markdown
# Codebase Map — [專案名稱]

**掃描日期**: [YYYY-MM-DD]
**語言**: [TypeScript / Python / Java / ...]
**框架**: [Vue 3 / React / Spring Boot / ...]
**套件管理**: [npm / pnpm / pip / maven]

## 目錄結構
[tree output]

## 主要依賴
[dependency list with versions]

## 進入點
[main entry files]
```

---

## Step 2: Baseline 建立（半自動，~10 min）

量化現狀，建立可比較的基準線。

| 檢查項 | 指令 | 記錄 |
|--------|------|------|
| 既有測試 | `npm test` / `pytest` | pass/fail 數量 |
| 靜態分析 | `npx eslint .` / `flake8` | error/warning 數量 |
| Type 覆蓋 | `npx tsc --noEmit` | error 數量 |
| DB Schema | `pg_dump --schema-only` | table 清單 |
| CI 狀態 | 檢查 `.github/workflows/` | 有/無，最近是否 green |

**產出**: `docs/brownfield/BASELINE_SNAPSHOT.md`

```markdown
# Baseline Snapshot

**日期**: [YYYY-MM-DD]

| Metric | Value | Notes |
|--------|-------|-------|
| Tests (pass/fail) | 42/3 | 3 個 flaky test |
| Lint errors | 128 | 主要是 no-any |
| Type errors | 23 | 缺少 type 定義 |
| DB tables | 15 | 無 migration 工具 |
| CI status | Yellow | 最近 3 次有 1 次失敗 |
```

---

## Step 3: Gap Report（分析，~10 min）

比對 Baseline 和我們框架的標準，找出缺口。

| 面向 | 框架標準 | 現況 | Gap |
|------|---------|------|-----|
| 測試覆蓋 | L1 ≥ 80% | [?%] | [差距] |
| CI/CD | 有且 green | [有/無] | [缺什麼] |
| 文件 | SRS + API Spec | [有/無] | [缺什麼] |
| Type Safety | strict mode | [有/無] | [缺什麼] |
| DB Migration | 可回滾 | [有/無] | [缺什麼] |
| Code Style | eslint/prettier | [有/無] | [缺什麼] |

**產出**: `docs/brownfield/GAP_REPORT.md`

含優先順序：
1. **Must Fix**（不修就不能安全改 code）
2. **Should Fix**（在第一個 Feature 前處理）
3. **Nice to Have**（逐步改善）

---

## Step 4: First Safe Change（建立信心，~15 min）

選一個**最小的改動**，驗證改動流程可行。

**好的第一個改動**：
- 加一個 missing test
- 修一個 lint warning
- 加一個 README section
- 設定 CI（如果沒有）

**壞的第一個改動**：
- 重構核心模組
- 升級主要依賴
- 改 DB schema

**流程**：
```
選最小改動
    ↓
建 feature branch
    ↓
改動 + 跑既有 test（確認沒壞）
    ↓
commit + PR
    ↓
確認 CI green（如果有）
    ↓
Merge → 信心建立 → 併入主流程 Build 階段
```

---

## 完成後

1. 3 份文件歸檔到 `docs/brownfield/`
2. Gap Report 的 Must Fix 項轉為 TASKS.md 中的 Task
3. 在 ARTIFACTS.md 登記 CODEBASE_MAP + BASELINE_SNAPSHOT + GAP_REPORT
4. 開始正常的 Build 階段

---

## Anti-Patterns

| 不要 | 改這樣 |
|------|--------|
| 直接開始改 code | 先跑 4 步 |
| 重構再了解 | 先 Snapshot 再決定 |
| 忽略既有 test | 先跑 Baseline 知道現狀 |
| 一次修所有 Gap | 按優先級逐步修 |
