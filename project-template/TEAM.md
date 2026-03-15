# TEAM.md — [專案名稱] 團隊協作設定

> 多人協作必讀。每位成員首次加入專案時，完成「角色認領表」的自己那行。

---

## 角色認領表

| Agent 角色 | 負責人 | 聯絡方式 | 主要 Pipeline |
|-----------|--------|---------|-------------|
| Interviewer | [名字] | [@handle] | P01 |
| PM | [名字] | [@handle] | P01 |
| UX | [名字] | [@handle] | P01 |
| Architect | [名字] | [@handle] | P02 |
| DBA | [名字] | [@handle] | P02 |
| Backend | [名字] | [@handle] | P03 / P04 |
| Frontend | [名字] | [@handle] | P03 / P04 |
| QA | [名字] | [@handle] | P03 / P04 |
| Security | [名字] | [@handle] | P05 |
| DevOps | [名字] | [@handle] | P06 |
| Review | [名字] | [@handle] | Gate 1/2/G4/3 |

> 一個人可擔任多個角色。
> **Gate Review 必須由未參與該 Pipeline 的人執行**（e.g. PM 不能做 Gate 1 的 Review）。

---

## Session 開場流程（每次工作前必做）

```bash
# Step 1 — 取得最新狀態
git pull

# Step 2 — 確認目前進度（必讀）
# 讀 memory/STATE.md → 確認 phase / next_action / 是否有 blockers
# 讀 TASKS.md → 找你的 @[名字] 任務

# Step 3 — 啟動你的 Agent（見下方各角色指令）
```

### 各角色啟動指令

將對應提示詞貼到新的 Claude 對話開頭：

**Interviewer：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_Interviewer.md，你現在是 Interviewer Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**PM：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_PM.md，你現在是 PM Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**UX：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_UX.md，你現在是 UX Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**Architect：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_Architect.md，你現在是 Architect Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**DBA：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_DBA.md，你現在是 DBA Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**Backend：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_Backend.md，你現在是 Backend Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**Frontend：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_Frontend.md，你現在是 Frontend Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**QA：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_QA.md，你現在是 QA Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**Security：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_Security.md，你現在是 Security Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**DevOps：**
```
讀取 CLAUDE.md 和 memory/STATE.md。
接著讀取 context-seeds/SEED_DevOps.md，你現在是 DevOps Agent。
目前任務：[填入 TASKS.md 中你的待辦項目]
```

**Review（Gate）：**
```
讀取 CLAUDE.md。你是 Review Agent。
執行 Gate [N] 驗收。
讀取 TASKS.md 了解進度，讀取 context-skills/quality-gates/SKILL.md 取得 checklist。
```
> ⚠️ Gate Review 必須開新 Claude session，不可在做 Pipeline 的同一個 session 中執行。

---

## 人對人交接協議（Person-to-Person Handoff）

AI Agent 完成工作並輸出交接摘要後，由負責人執行以下步驟：

### Step 1 — 確認並 Commit

```bash
# 確認 AI 輸出的交接摘要內容正確後：
git add TASKS.md memory/STATE.md [產出文件路徑]
git commit -m "handoff([你的角色]→[下一角色]): [F## 功能] [一句話說明]"

# 範例：
# git commit -m "handoff(PM→UX): F01 Login US 完成，12 條 AC，NYQ hints 已填"
```

### Step 2 — 通知下一位

在團隊頻道發送交接通知（格式）：

```
[交接通知] @{下一位成員}

Pipeline：P## [名稱]
階段：[你的角色] → [下一個角色]
完成：[1-2 句，做了什麼]
你需要知道：[關鍵決策或注意事項]
產出文件：[檔案路徑]
詳見 TASKS.md → T-###
```

### Step 3 — 下一位確認接手

收到通知後：
1. `git pull`
2. 確認 TASKS.md 中的交接摘要
3. 回覆 ✅ 確認接手
4. 照「Session 開場流程」啟動自己的 Agent

---

## Git 分支規範（多人並行）

| 情境 | 分支格式 | 範例 |
|------|---------|------|
| Pipeline 規格文件產出 | `docs/P##-[agent]-F##` | `docs/P01-pm-f01` |
| 實作程式碼（worktree） | `feature/F##-[功能]-[縮寫]` | `feature/F01-login-bob` |
| Gate Review 報告 | `review/Gate[N]-[縮寫]` | `review/Gate1-alice` |

**Wave 並行（P02）規則：**
- Architect 開 `docs/P02-arch-F##` 分支
- DBA 開 `docs/P02-dba-F##` 分支
- 兩人完成後各自 PR，Review 後 merge 到 `main`，再由 Backend/Frontend 繼續

---

## 共用檔案衝突處理規則

| 檔案 | 寫入規則 |
|------|---------|
| `TASKS.md` | 只 append（在表格末端加新行），不修改他人已寫的行；merge conflict 以時間較晚者為準 |
| `memory/STATE.md` | 當前工作者（`active_member`）才有寫入權；其他人唯讀 |
| `memory/decisions.md` | 透過 PR 修改，不直接 push to main |
| 規格文件（US / API Spec / DB Schema 等）| 由負責該 Agent 角色的人 owns；他人需開 PR 提出修改意見 |
| `01_Product_Prototype/` | UX 負責人 owns；Frontend 修改需 PR |

---

## 新成員加入清單

新成員加入時，依序完成：

- [ ] Clone repo：`git clone [repo-url]`
- [ ] 讀 `README.md`（了解框架概念）
- [ ] 讀 `CLAUDE.md`（了解專案結構和 Pipeline）
- [ ] 讀 `TEAM.md`（本文件）→ 在角色認領表填上自己的名字
- [ ] 讀 `memory/STATE.md`（了解目前進度）
- [ ] 讀 `TASKS.md`（確認待辦任務）
- [ ] 與 PM / 團隊負責人確認你第一個任務
- [ ] 用對應的「啟動指令」開始第一個 Agent session
