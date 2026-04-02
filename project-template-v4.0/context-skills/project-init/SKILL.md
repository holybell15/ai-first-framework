---
name: project-init
description: >
  從 template 一鍵初始化新專案，全部檔案自動生成和配置。

  遇到「開新專案」、「建立新專案」、「new project」、「初始化」、「clone 這個專案結構」
  或任何「我想要個新的完整專案」的要求，就用這個。

  **為什麼？** 手工複製檔案容易遺漏、佔位符忘記改、資料夾亂七八糟。
  這個 skill 自動做完，凱子只回答 4 個問題，省時 30 分鐘，錯誤率 0。
---

# Project Init Skill

## 工作流程

```
凱子說「開新專案」
    ↓
我提問 4 個問題（一次全問）
    ↓
凱子回答 4 題
    ↓
自動找 _PROJECT_TEMPLATE
    ↓
跑 init_project.py 複製+配置
    ↓
驗證所有檔案正確生成
    ↓
完成！還需 2 件手工事
    ↓
凱子說「執行 Pipeline: 需求訪談」開始
```

**投資報酬**：5 分鐘提問 + 10 秒自動化 = 省去 30 分鐘手工操作 + 100% 避免人工錯誤。

---

## Step 1 — 一次提問 4 個關鍵問題

**一定要同時問，不要分次問。** 用這個格式：

### Q1：專案名稱
**問**：「新專案的英文/縮寫名稱是什麼？會套用到所有文件、CLAUDE.md 和 Dashboard 標題」

**選項舉例**：
- `FinCore-X`（金融核心系統）
- `InsureAI-Pro`（保險 AI 平台）
- `RetailSaaS`（零售 SaaS）
- `其他：[輸入自訂名稱]`

*為什麼問這個？* 專案名稱會出現在 20+ 個檔案裡，手工改容易漏掉。

### Q2：產品類型（一句話）
**問**：「產品本質是什麼？會顯示在 Dashboard 概覽卡片」

**選項**：
- `SaaS B2B — 多租戶企業管理平台`
- `SaaS B2C — 消費者服務應用`
- `內部系統 — 企業內部管理工具`
- `API 平台 — 微服務 / 第三方整合`
- `其他：[自訂敘述]`

*為什麼問這個？* 決定技術棧傾向（B2B 通常多租戶設計、B2C 重效能）。

### Q3：技術棧
**問**：「主要技術棧是什麼？」

**選項**：
- `Vue 3 / Spring Boot / MySQL + MSSQL / GCP`
- `React / Node.js / PostgreSQL / AWS`
- `Next.js / FastAPI / MongoDB / Azure`
- `Angular / .NET / SQL Server / Azure`
- `其他：[自訂組合]`

*為什麼問這個？* SEED 檔案和 memory/product.md 要填技術棧。

### Q4：存放位置
**問**：「新專案資料夾要建立在哪個目錄？輸入父目錄的完整路徑（會自動建立新資料夾）」

**選項舉例**：
- `[父目錄路徑]/`（最常用）
- `[下載資料夾路徑]/`
- `其他完整路徑`

*為什麼問這個？* 決定最後專案位置。凱子可能有不同的工作目錄。

---

## Step 2 — 自動找 Template

優先順序：

1. **同級目錄**（最常見）
   - 假設專案在 `[專案路徑]/`
   - 檢查 `[父目錄路徑]/_PROJECT_TEMPLATE`

2. **mnt 根目錄**
   - 檢查 `/sessions/dreamy-jolly-goldberg/mnt/_PROJECT_TEMPLATE`

3. **仍未找到** → 問凱子：「找不到 _PROJECT_TEMPLATE，請告訴我它的完整路徑」

**驗證**：
```bash
ls -la /path/to/_PROJECT_TEMPLATE/

# 應該看到：
# CLAUDE.md
# TASKS.md
# memory/
# context-seeds/
# 01_Product_Prototype/
# ... 等所有資料夾
```

---

## Step 3 — 執行初始化腳本

用 `init_project.py` 完成所有複製和替換：

```bash
python3 /sessions/dreamy-jolly-goldberg/mnt/.skills/skills/project-init/scripts/init_project.py \
  --project-name "FinCore-X" \
  --product-type "SaaS B2B — 多租戶企業管理平台" \
  --tech-stack "Vue 3 / Spring Boot / MySQL + MSSQL / GCP" \
  --target "[父目錄路徑]/FinCore-X" \
  --template "/sessions/dreamy-jolly-goldberg/mnt/_PROJECT_TEMPLATE"
```

**腳本做什麼**：
1. 複製整個 `_PROJECT_TEMPLATE/` 到 `--target` 路徑
2. 在所有檔案裡把 `[專案名稱]` 替換成凱子提供的名稱
3. 在所有 markdown 裡把 `[產品類型]` 替換成產品敘述
4. 更新 CLAUDE.md、memory/product.md、SEED 檔案裡的技術棧
5. 初始化 TASKS.md 的時間戳
6. 建立空的 Dashboard 初始狀態

---

## Step 4 — 驗證和呈現

執行完成後，驗證新專案結構：

### 快速檢查（確保沒遺漏檔案）

```bash
ls -la [父目錄路徑]/FinCore-X/

# 應該有：
# CLAUDE.md ✓
# TASKS.md ✓
# PROJECT_DASHBOARD.html ✓
# SETUP.md ✓
# memory/ ✓
# context-seeds/ ✓
# 01_Product_Prototype/ ✓
# 02_Specifications/ ✓
# ... 所有 09 個資料夾 ✓

# 驗證沒有 [佔位符]
grep -r "\[專案名稱\]" [父目錄路徑]/FinCore-X/
# 應該無結果（全部替換完了）
```

### 驗證關鍵檔案的替換

```bash
# 確認專案名稱已替換
grep "FinCore-X" [父目錄路徑]/FinCore-X/CLAUDE.md

# 確認技術棧已寫入
grep "Vue 3" [父目錄路徑]/FinCore-X/memory/product.md

# 確認 TASKS.md 有初始化
head -5 [父目錄路徑]/FinCore-X/TASKS.md
```

### 用 present_files 呈現 Dashboard

用工具呈現新生成的 Dashboard，讓凱子看得見：

```
📁 新專案已建立！
  Project Dashboard: [父目錄路徑]/FinCore-X/PROJECT_DASHBOARD.html
```

---

## Step 5 — 報告和後續步驟

```
✅ FinCore-X 專案初始化完成！

📁 位置：[父目錄路徑]/FinCore-X/
📝 自動更新了 50+ 個檔案

⏳ 還需要手動完成 2 件事（只要 5 分鐘）：

1️⃣ 填寫 memory/product.md
   - 補充產品詳細資料（目標客群、核心功能清單 5~7 項）
   - 填寫時間表（預計上線日期）
   - 寫競品分析（3~5 個競品對標）

   為什麼要填？Interviewer Agent 需要這些背景做訪談、PM Agent 會用這個寫 User Story

2️⃣ 上傳 memory/*.md 至 Claude Project 知識庫（可選，但強烈建議）
   - 前往 https://claude.ai → Projects
   - 建立新 Project：「FinCore-X」
   - 上傳這 4 個檔案：
     * memory/product.md
     * memory/workflow_rules.md
     * memory/decisions.md
     * memory/glossary.md

   為什麼？Claude 每個 session 都能讀到專案背景，上下文更清楚

之後就可以說「執行 Pipeline: 需求訪談」開始第一個 Pipeline 了！
```

---

## 錯誤處理

### 目標資料夾已存在

```
⚠️ [父目錄路徑]/FinCore-X/ 已存在

選項：
1. 改專案名稱（例如改成 FinCore-X-v2）
2. 刪除舊資料夾（如果確認沒有重要檔案）
3. 選擇不同的存放位置

要重新開始嗎？請提供新的專案名稱或路徑
```

### Template 找不到

```
⚠️ 找不到 _PROJECT_TEMPLATE

我已檢查過：
- [父目錄路徑]/_PROJECT_TEMPLATE ✗
- /sessions/dreamy-jolly-goldberg/mnt/_PROJECT_TEMPLATE ✗

請告訴我 _PROJECT_TEMPLATE 的完整路徑（例如：/path/to/template/）
```

### 部分檔案處理失敗

```
⚠️ 初始化遇到問題

成功複製：48 個檔案
失敗：2 個檔案
  - memory/failing-file.md（原因：檔案被鎖定）
  - some/path/file.txt（原因：編碼錯誤）

✅ 專案結構已建立，但請手工檢查上述 2 個檔案

操作：
1. cd [父目錄路徑]/FinCore-X/
2. 手動修復或從 _PROJECT_TEMPLATE 重新複製這些檔案
```

---

## GSD 鉤點

| 階段 | 動作 | 負責人 |
|------|------|--------|
| 初始化 | 執行 project-init | 凱子（或我自動觸發） |
| P01 開始 | 執行「Pipeline: 需求訪談」 | Interviewer Agent |
| STATE.md 讀入 | 新 session 自動讀初始專案狀態 | 系統 |
| Dashboard 監控 | 全 Pipeline 追蹤進度 | update-dashboard skill |

---

## Step 5（新增）— Token Budget 驗證（RR-3）

初始化完成後，**強制執行** token budget 驗證。確保所有關鍵檔案未超過預算上限。

### Token Budget 上限表

| 檔案 | 上限 | 說明 |
|------|------|------|
| `CLAUDE.md` | 5,000 tokens | 全域指令，每次 session 必讀 |
| `context-skills/task-master/SKILL.md` | 2,000 tokens | Dispatcher，輕量為原則 |
| `context-seeds/GROUP_Discovery.md` | 2,000 tokens | Discovery 角色群組 |
| `context-seeds/GROUP_Build.md` | 2,000 tokens | Build 角色群組 |
| `context-seeds/GROUP_Verify.md` | 2,000 tokens | Verify 角色群組 |
| `context-seeds/ROLE_Review.md` | 1,000 tokens | 跨階段 Review 角色 |
| `memory/STATE.md` | 400 tokens | 即時狀態，必須精簡 |

### 驗證腳本

```bash
#!/bin/bash
# Token Budget Validator
# 1 token ≈ 4 characters（保守估算）

PROJECT_DIR="[目標專案路徑]"

check_budget() {
  local file="$1"
  local limit_tokens="$2"
  local label="$3"
  local limit_chars=$((limit_tokens * 4))

  if [ ! -f "$PROJECT_DIR/$file" ]; then
    echo "⏭️  SKIP   $label ($file 不存在)"
    return
  fi

  local char_count=$(wc -c < "$PROJECT_DIR/$file")
  local est_tokens=$((char_count / 4))

  if [ "$char_count" -le "$limit_chars" ]; then
    echo "✅ PASS   $label — ~${est_tokens} tokens (limit: ${limit_tokens})"
  else
    local overage=$((est_tokens - limit_tokens))
    echo "❌ FAIL   $label — ~${est_tokens} tokens (limit: ${limit_tokens}, 超出 ~${overage} tokens)"
    echo "          路徑: $PROJECT_DIR/$file"
  fi
}

echo "======================================"
echo "  Token Budget Validation"
echo "  Project: $PROJECT_DIR"
echo "======================================"

check_budget "CLAUDE.md"                                    5000  "CLAUDE.md"
check_budget "context-skills/task-master/SKILL.md"          2000  "task-master SKILL"
check_budget "context-seeds/GROUP_Discovery.md"             2000  "GROUP_Discovery"
check_budget "context-seeds/GROUP_Build.md"                 2000  "GROUP_Build"
check_budget "context-seeds/GROUP_Verify.md"                2000  "GROUP_Verify"
check_budget "context-seeds/ROLE_Review.md"                 1000  "ROLE_Review"
check_budget "memory/STATE.md"                              400   "STATE.md"

echo "======================================"
echo "  驗證完成"
echo "  ❌ FAIL 項目必須精簡後才能繼續"
echo "======================================"
```

### 執行方式

```bash
# 直接執行（替換路徑後）
bash context-skills/project-init/scripts/validate-token-budget.sh \
  --project "[新專案的完整路徑]"
```

### 如果有 FAIL

| 情況 | 處置 |
|------|------|
| CLAUDE.md 超出 5K | 把 Domain 知識移至 `memory/` 或 `context-skills/`；CLAUDE.md 只留框架指令 |
| GROUP 檔案超出 2K | 把範例/參考資料移至獨立的 reference 目錄；GROUP 只留角色定義 |
| task-master 超出 2K | 移除詳細範例；只保留觸發規則和路由邏輯 |
| ROLE_Review 超出 1K | 精簡成核心 checklist；詳細說明移至 SKILL.md |
| STATE.md 超出 400 | 移除過時狀態；只保留當前 Phase 和最近 2 個 Task |

> **原則**：Token budget 不是建議，是強制上限。超出 = 框架退化回 v3.3 的 token bloat 問題。

---

## 檢查清單

完成後確認：

- [ ] 新專案資料夾建立成功
- [ ] CLAUDE.md、TASKS.md、PROJECT_DASHBOARD.html 都存在
- [ ] 沒有 `[佔位符]` 留在檔案裡
- [ ] memory/product.md 的技術棧已填寫
- [ ] **Token Budget 驗證全部 PASS（無 ❌ FAIL）**
- [ ] 呈現了 Dashboard 給凱子看
- [ ] 凱子知道還有 2 件手工事要做

**沒打滿勾？** → 重新檢查或重新執行初始化。Token Budget FAIL 必須處理，不能跳過。

---

## 常見問題

**Q：能同時開 2 個新專案嗎？**
A：可以。每個新專案完全獨立，沒有衝突。

**Q：初始化後能改專案名稱嗎？**
A：不建議。改名需要改 50+ 檔案，容易出錯。建議重新初始化。

**Q：能修改 _PROJECT_TEMPLATE 嗎？**
A：可以。修改後的內容會套用到下一個新專案。但最好先備份原始版本。

**Q：初始化需要多久？**
A：< 1 秒（Python 複製 + 替換）。最長的是凱子回答 4 個問題。
