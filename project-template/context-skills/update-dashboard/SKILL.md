---
name: update-dashboard
description: >
  即時更新 PROJECT_DASHBOARD.html 的進度狀態。確保 Dashboard 與現實同步。

  遇到「任務完成了」、「Pipeline XX 結束」、「Agent 做完」、「Gate 通過」、「更新進度」
  或任何任務狀態變更，就該觸發這個。

  **為什麼主動觸發？** 不等凱子說「更新」，任何 Agent 任務完成後自動跑一次。
  這樣 Dashboard 永遠是最新狀態，新成員開著 Dashboard 能看到「現在卡在哪」。

  **GSD 好處**：STATE.md 從 Dashboard 讀狀態；CODE REVIEW 也參考 Dashboard 看進度。
---

# Update Dashboard Skill

## 為什麼重要

- **進度能見度** — 凱子打開 Dashboard，一眼看本週做了什麼、下週要幹什麼
- **新成員快速上手** — 讀 Dashboard，不用問「現在到哪了」
- **多 session 協調** — 不同 session 的工程師都看同一份 Dashboard，杜絕訊息不對稱
- **GSD 依賴** — STATE.md 重建、CODE REVIEW 決策都參考 Dashboard

## 動作前必讀

```
讀取：memory/dashboard.md
```

此檔案紀錄了：
- Dashboard 資料結構（PROJECT_STATUS 物件裡有哪些欄位）
- 所有 render 函式的用途
- CSS class 對照
- Agent 比對邏輯
- 修改時該注意什麼

**為什麼先讀？** 直接改會破壞結構。例如 `pipelineLog` 只能新增不能刪除，修改錯誤會導致 Dashboard 無法正常解析。

---

## 資料結構快速查表

| 欄位 | 用途 | 修改規則 |
|------|------|---------|
| `overview.updated` | 最後更新日期 | 改成今天日期（ISO 格式：YYYY-MM-DD） |
| `pipelineLog` | Pipeline 執行歷史 | **只新增，不刪除** — 是審計日誌 |
| `inProgress` | 現在進行中的任務 | 完成的刪除；新的加入；最多 1~2 個 |
| `backlog` | 待辦清單 | 新增或移除（FIFO） |
| `todos` | 下一步建議 | 更新 1~3 條優先任務 |
| `documents` | 文件清單 | **只新增，不刪除** — 記錄成果物 |
| `pipelineCompletion` | P01~P06 進度 | 完成 → `'done'`；進行 → `'active'`；待開 → `'pending'` |
| `gateStatus` | Gate 審查狀態 | 通過 → `'done'`；進行 → `'active'`；待審 → `'pending'` |

---

## 修改流程（5 步）

### Step 1 — 確認資訊

**通常不需多問，直接推理：**

從對話裡推斷：
- **哪個專案**？（AICC-X / TimeX / 其他）
- **完成了什麼**？（哪個 Agent / Pipeline / Gate）
- **輸出了什麼檔案**？（檔名 + 資料夾）
- **下一步是誰**？（下個 Agent 或 Gate Review）

### Step 2 — 讀取 Dashboard 檔

根據專案路徑找到 Dashboard：

```
AICC-X         → /sessions/dreamy-jolly-goldberg/mnt/AICC-X/PROJECT_DASHBOARD.html
Softphone_Demo → /sessions/dreamy-jolly-goldberg/mnt/Softphone_Demo/PROJECT_DASHBOARD.html
TimeX          → /sessions/dreamy-jolly-goldberg/mnt/TimeProject/TimeX/PROJECT_DASHBOARD.html
[其他]         → /sessions/dreamy-jolly-goldberg/mnt/[ProjectName]/PROJECT_DASHBOARD.html
```

### Step 3 — 修改 JavaScript 物件

用字串替換直接改 `PROJECT_STATUS = { ... }` 物件，**不用解析 JavaScript**。

**原因**：JavaScript 物件語法複雜（有逗號、空格、巢狀），parse 容易失敗；用正則替換更穩定。

#### 範例：更新日期

```python
import re
from datetime import date

with open(dashboard_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 改 overview.updated 日期
old_date = "updated: '2026-03-10'"
new_date = f"updated: '{date.today().isoformat()}'"
content = content.replace(old_date, new_date)

with open(dashboard_path, 'w', encoding='utf-8') as f:
    f.write(content)
```

#### 範例：新增 pipelineLog 記錄

完成一個 Agent 後，新增記錄：

```python
# 找到 pipelineLog 的最後一筆，插入新記錄

new_entry = """{
    id: 'P042',
    agent: 'Backend Agent',
    owner: 'Claude',
    status: 'done',
    date: '2026-03-15',
    note: '完成 Order API 設計，產出 F07-API.md'
}"""

# 在 pipelineLog 的結尾（]）前插入
content = re.sub(
    r'(pipelineLog: \[.*?)(  \],)',
    rf'\1,\n  {new_entry}\n\2',
    content,
    flags=re.DOTALL
)
```

#### 範例：更新 P01 狀態為 done

```python
content = content.replace(
    "'P01': 'active'",
    "'P01': 'done'"
)
```

### Step 4 — 驗證修改

寫入檔案後，檢查關鍵字確實存在：

```python
with open(dashboard_path, 'r', encoding='utf-8') as f:
    verify = f.read()

# 確認新增的內容在檔裡
assert "F07-API.md" in verify, "新增的文件名稱沒找到"
assert "'P01': 'done'" in verify, "P01 狀態沒改成 done"
assert date.today().isoformat() in verify, "日期沒更新"

print("✅ Dashboard 驗證通過")
```

如果有斷言失敗 → 回到 Step 3 檢查正則替換邏輯。

### Step 5 — 回報結果

在對話裡用簡潔格式說明已改什麼：

```
✅ AICC-X Dashboard 已更新：
  • pipelineLog  → 新增 Backend Agent（P042）
  • documents    → 新增 F07-API.md
  • P02 狀態     → done ✅
  • updated 日期 → 2026-03-15

下一步：開新 session 做 Gate 2 審查
```

**不產出任何新檔案**，結果直接在對話裡報告。

---

## 常見情境速查表

### 場景 1：Agent 任務完成

凱子說「Backend Agent 完成了，產出 F07-API.md」

**要改的欄位**：
- `pipelineLog` → 新增 Backend Agent 記錄
- `documents` → 新增 F07-API.md
- `inProgress` → 移除 Backend Agent，換成下個任務（若有）
- `updated` → 改今天日期

### 場景 2：Pipeline 整個完成

凱子說「P02 技術設計全部完成」

**要改的欄位**：
- `pipelineCompletion['P02']` → 改成 `'done'`
- `pipelineLog` → 新增 P02 summary 記錄
- `inProgress` → 換成「P03 開發準備」任務（若有）
- `todos` → 更新成「開新 session 做 Gate 2」

### 場景 3：Gate 通過

凱子說「Gate 1 審查通過」

**要改的欄位**：
- `gateStatus['gate1']` → 改成 `'done'`
- `pipelineLog` → 新增 Gate 1 Review 記錄
- `updated` → 改今天日期

### 場景 4：發現 Bug，回到某步驟

凱子說「Gate 2 發現問題，Architect 要重做」

**要改的欄位**：
- `gateStatus['gate2']` → 改成 `'pending'`（重新評估）
- `inProgress` → 換成「Architect 重做」
- `pipelineCompletion['P02']` → 改成 `'active'`（回到進行中）
- 新增 pipelineLog 記錄說「Gate 2 發現 XXX，Architect 重做」

---

## GSD 鉤點

| 完成時刻 | 自動觸發 | 更新內容 |
|---------|---------|--------|
| Agent 任務完 | 是 | pipelineLog + documents + inProgress |
| Pipeline 完 | 是 | pipelineCompletion + pipelineLog |
| Gate 審查完 | 是 | gateStatus + pipelineLog |
| 新 session 開始 | 讀取 Dashboard | STATE.md 重建 |
| CODE REVIEW 審查 | 讀取 Dashboard | 看現在進度判斷審查 scope |

---

## 常見修改失敗排查

| 現象 | 原因 | 修復 |
|------|------|------|
| `pipelineLog` 格式錯誤 | 忘記加逗號或引號 | 用 `print(content)` 看實際內容，對照 memory/dashboard.md |
| Dashboard 無法讀取 | JavaScript 物件語法破壞 | 用 Firefox DevTools 開 Dashboard，檢查 console 錯誤 |
| 日期格式錯誤 | 沒用 ISO 格式（應 YYYY-MM-DD） | `date.today().isoformat()` 確保格式 |
| 找不到要替換的字串 | 正則模式寫錯 | 先 `grep` 確認該字串存在 |

---

## 檢查清單

完成修改後：

- [ ] 開了 Dashboard 檔並讀取內容
- [ ] 讀了 memory/dashboard.md 確認欄位含義
- [ ] 用字串替換（不是 eval）修改 PROJECT_STATUS
- [ ] 驗證了新增的內容存在於檔案裡
- [ ] 寫回原檔（沒另存新檔）
- [ ] 在對話裡清楚報告改了什麼
- [ ] 沒產出任何額外檔案

**沒打滿勾？** → 檢查遺漏的步驟。
