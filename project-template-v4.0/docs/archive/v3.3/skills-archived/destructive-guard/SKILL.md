---
name: destructive-guard
description: >
  破壞性指令安全護欄。在執行可能造成不可逆損害的操作前自動攔截並警告。

  遇到「rm -rf」、「DROP TABLE」、「force-push」、「git reset --hard」、「刪除分支」、
  「覆蓋檔案」、「清空資料」或任何可能造成資料遺失的指令時自動觸發。

  **為什麼？** 一次誤操作可能毀掉數小時的工作成果。AI Agent 執行速度快，
  沒有護欄時破壞也快。這個 skill 是最後一道防線。

  靈感來源：gstack /careful + /freeze 安全護欄機制
---

# Destructive Guard Skill：破壞性指令安全護欄

## 為什麼需要這個？

- **速度是雙面刃**：AI Agent 可以秒級執行指令，但破壞也是秒級
- **不可逆操作無法 undo**：`rm -rf`、`DROP TABLE`、`git push --force` 執行後無法輕易復原
- **防止連鎖反應**：一個錯誤的 `git reset --hard` 可能丟失整個 Feature 的未 commit 工作
- **合規要求**：金融系統更不能容忍誤刪資料的風險

---

## 攔截規則（Guardrail Rules）

### 🔴 Level 1 — 強制攔截（必須用戶確認才能執行）

| 指令模式 | 風險說明 | 安全替代方案 |
|---------|---------|------------|
| `rm -rf /` 或 `rm -rf *` | 刪除根目錄或當前目錄所有內容 | 指定具體路徑，使用 `trash` 指令 |
| `rm -rf` 任何非暫存目錄 | 永久刪除目錄 | 先 `ls` 確認內容，改用 `mv` 到暫存區 |
| `DROP TABLE` / `DROP DATABASE` | 永久刪除資料表/資料庫 | 先備份，使用 `RENAME` 替代 |
| `TRUNCATE TABLE` | 清空資料表所有資料 | 確認有備份，加 `WHERE` 條件限縮 |
| `DELETE FROM` 無 `WHERE` | 刪除表中所有資料 | 加 `WHERE` 條件，先 `SELECT COUNT` 確認 |
| `git push --force` / `git push -f` | 覆蓋遠端歷史 | 使用 `--force-with-lease` 替代 |
| `git reset --hard` | 丟棄所有未 commit 的變更 | 先 `git stash`，再 reset |
| `git branch -D` (大寫 D) | 強制刪除未合併分支 | 使用 `-d`（小寫），會檢查是否已合併 |
| `git clean -fd` | 刪除所有未追蹤檔案 | 先 `git clean -n` 預覽，再決定 |
| `chmod -R 777` | 開放所有權限 | 使用最小權限原則（如 755/644） |
| `kill -9` 系統程序 | 強制終止系統關鍵程序 | 先用 `kill`（SIGTERM），給程序優雅退出的機會 |

### 🟡 Level 2 — 警告提示（顯示風險，建議確認）

| 指令模式 | 風險說明 |
|---------|---------|
| `git rebase` 已推送的 commit | 可能導致其他人的分支衝突 |
| `git checkout -- .` | 丟棄所有未暫存的變更 |
| `npm uninstall` / `pip uninstall` 核心依賴 | 可能破壞專案執行環境 |
| `ALTER TABLE` 生產環境 | Schema 變更可能影響正在運行的服務 |
| 覆寫已存在的重要檔案（RS、SSD、API Spec 等規格文件） | 可能丟失已審查通過的內容 |
| `docker system prune -a` | 刪除所有未使用的映像/容器/網路 |

### 🟢 Level 3 — 安全放行（不攔截）

以下目錄/操作視為安全，不觸發攔截：

- `node_modules/`、`dist/`、`build/`、`.cache/`、`__pycache__/` 的刪除
- `*.log`、`*.tmp`、`*.bak` 暫存檔案的刪除
- `git branch -d`（小寫 d，已合併才允許刪除）
- 測試資料庫的 `DROP` / `TRUNCATE`（名稱含 `test`、`dev`、`staging`）
- `05_Archive/` 目錄內的檔案操作

---

## 攔截時的處理流程

### Step 1 — 偵測

Agent 在執行任何 Bash 指令前，先比對上方攔截規則表。

### Step 2 — 分級回應

**🔴 Level 1 攔截格式：**

```
⛔ 破壞性指令攔截

指令：[即將執行的指令]
風險等級：🔴 強制攔截
風險說明：[為什麼這個指令危險]
影響範圍：[會影響哪些檔案/資料/服務]

🛡️ 安全替代方案：[建議的替代指令]

請確認：
  (1) 確定執行原始指令
  (2) 改用安全替代方案
  (3) 取消操作
```

**🟡 Level 2 警告格式：**

```
⚠️ 風險提示

指令：[即將執行的指令]
風險等級：🟡 警告
風險說明：[潛在風險]

建議：[降低風險的做法]

繼續執行？(Y/N)
```

### Step 3 — 記錄

所有 🔴 攔截事件記錄到交接摘要中，格式：

```
🛡️ Guard Log：
- [時間] 攔截 `rm -rf src/` → 用戶選擇改用 `mv src/ /tmp/src_backup`
- [時間] 攔截 `git push --force` → 用戶確認改用 `--force-with-lease`
```

---

## 目錄鎖定模式（Freeze Mode）

> 類似 gstack `/freeze`，限制 Agent 只能修改指定目錄。

### 啟用方式

用戶說：「鎖定目錄：`src/modules/auth/`」

### 鎖定後行為

- ✅ 允許：讀取任何檔案
- ✅ 允許：在鎖定目錄內建立/修改/刪除檔案
- ⛔ 攔截：在鎖定目錄外建立/修改/刪除檔案
- ⛔ 攔截格式：

```
🔒 目錄鎖定攔截

嘗試修改：[檔案路徑]
鎖定範圍：[鎖定目錄]
原因：此檔案不在鎖定範圍內

選項：
  (1) 暫時解鎖此檔案（本次操作）
  (2) 擴大鎖定範圍到 [建議目錄]
  (3) 取消操作
  (4) 完全解除目錄鎖定
```

### 解除方式

用戶說：「解除目錄鎖定」

---

## 與現有 Skill 的整合

| Skill | 整合方式 |
|-------|---------|
| `ground` | Grounding 完成後，自動啟用 Freeze Mode 鎖定修改範圍 |
| `systematic-debugging` | Debug 過程中的修復操作受 Guard 保護 |
| `finishing-a-development-branch` | Merge/PR 操作中的 force-push 受 Level 1 攔截 |
| `pipeline-orchestrator` | Pipeline 執行期間自動啟用 Guard |

---

## Agent 使用指引

1. **所有 Agent 預設啟用** Level 1 攔截 — 不可關閉
2. **Level 2 警告**可由用戶在 session 開始時選擇關閉（「關閉 Guard 警告」）
3. **Freeze Mode** 由用戶或 `ground` skill 主動啟用
4. **Hotfix Pipeline** 自動啟用 Freeze Mode（鎖定在 hotfix 修復範圍內）

---

## PreToolUse Hook 配置（settings.json）

> 靈感來源：gstack /careful — 用 PreToolUse hook 在指令執行前自動攔截。
> 以下配置可寫入 `.claude/settings.json`，實現真正的自動攔截（不依賴 Agent 自律）。

### 配置方式

在 `.claude/settings.json` 或 `.claude/settings.local.json` 中加入：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash project-template/scripts/destructive-guard-hook.sh \"$TOOL_INPUT\""
          }
        ]
      }
    ]
  }
}
```

### Hook 腳本邏輯（scripts/destructive-guard-hook.sh）

Hook 腳本接收工具輸入，檢查是否包含危險指令：

```bash
#!/usr/bin/env bash
# destructive-guard-hook.sh — PreToolUse 安全攔截
# 傳回非零 exit code = 攔截指令

INPUT="$1"

# ─── Level 1：強制攔截 ───
LEVEL1_PATTERNS=(
  "rm -rf /"
  "rm -rf \*"
  "rm -rf ."
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "DELETE FROM.*WHERE.*1=1"
  "git push --force"
  "git push -f "
  "git reset --hard"
  "git branch -D "
  "git clean -fd"
  "chmod -R 777"
)

for pattern in "${LEVEL1_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    echo "⛔ BLOCKED: 偵測到 Level 1 破壞性指令"
    echo "   匹配：$pattern"
    echo "   建議：使用安全替代方案（見 destructive-guard SKILL.md）"
    exit 2  # 非零 = 攔截
  fi
done

# ─── Level 1 擴充：額外危險模式 ───
EXTENDED_PATTERNS=(
  "DROP INDEX"
  "DROP VIEW"
  "DROP SCHEMA"
  "ALTER TABLE.*DROP COLUMN"
  "git stash drop"
  "git stash clear"
  "docker system prune -a"
  "docker volume prune"
  "kubectl delete namespace"
  "terraform destroy"
  "> /dev/sda"
  "mkfs\\."
  "dd if=.*/dev/"
  ":(){ :|:& };:"
)

for pattern in "${EXTENDED_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    echo "⛔ BLOCKED: 偵測到擴充危險指令"
    echo "   匹配：$pattern"
    exit 2
  fi
done

# ─── Level 3：安全放行 ───
SAFE_PATTERNS=(
  "rm -rf.*node_modules"
  "rm -rf.*dist/"
  "rm -rf.*build/"
  "rm -rf.*\\.cache"
  "rm -rf.*__pycache__"
  "rm -rf.*\\.tmp"
  "rm -rf.*05_Archive"
  "DROP.*test"
  "DROP.*dev"
  "DROP.*staging"
)

for pattern in "${SAFE_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    exit 0  # 安全放行
  fi
done

# ─── 通用 rm -rf 檢查（不在安全清單中的 rm -rf）───
if echo "$INPUT" | grep -qE "rm\s+-r?f?\s+-?r?f?\s+"; then
  echo "⚠️ WARNING: 偵測到 rm 刪除指令，請確認目標路徑"
  # Level 2: 警告但不攔截
  exit 0
fi

exit 0  # 預設放行
```

### 安全例外清單（不觸發攔截）

以下路徑/操作視為安全，Hook 直接放行：

| 類別 | 路徑 / 模式 | 原因 |
|------|------------|------|
| 建置產物 | `node_modules/`、`dist/`、`build/`、`.cache/` | 可隨時重建 |
| 暫存檔 | `*.log`、`*.tmp`、`*.bak`、`__pycache__/` | 不含重要資料 |
| 歸檔目錄 | `05_Archive/` | 已是舊版備份 |
| 測試資料庫 | 名稱含 `test`、`dev`、`staging` | 非生產資料 |
| Git 已合併分支 | `git branch -d`（小寫 d） | Git 會檢查是否已合併 |

### 部署步驟

1. 將 `destructive-guard-hook.sh` 放在專案 `scripts/` 目錄
2. `chmod +x scripts/destructive-guard-hook.sh`
3. 在 `.claude/settings.json` 加入 hook 配置
4. 測試：嘗試執行 `rm -rf /tmp/test`，確認攔截生效

### Freeze Mode Hook 實作（Directory Scope Lock）

> 靈感來源：gstack /freeze — PreToolUse hook 攔截 Edit/Write 超出 scope 的操作。

**原理**：在 `.claude-freeze-scope` 寫入允許的目錄路徑，Hook 檢查每個 Edit/Write 操作。

#### settings.json 配置

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "bash scripts/freeze-hook.sh \"$TOOL_INPUT\"" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "bash scripts/freeze-hook.sh \"$TOOL_INPUT\"" }]
      }
    ]
  }
}
```

#### freeze-hook.sh 邏輯

```bash
#!/usr/bin/env bash
# freeze-hook.sh — Freeze Mode 目錄鎖定 Hook
SCOPE_FILE=".claude-freeze-scope"

# 如果沒有 scope file，放行
[ ! -f "$SCOPE_FILE" ] && exit 0

INPUT="$1"
ALLOWED_DIR=$(cat "$SCOPE_FILE" | head -1)

# 提取檔案路徑（從 Edit/Write 工具輸入中）
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
[ -z "$FILE_PATH" ] && exit 0

# 檢查是否在允許範圍內
case "$FILE_PATH" in
  ${ALLOWED_DIR}*) exit 0 ;;  # 在 scope 內，放行
  */memory/*) exit 0 ;;       # memory/ 永遠允許（STATE.md 等）
  */TASKS.md) exit 0 ;;       # TASKS.md 永遠允許
  *)
    echo "🔒 FREEZE: 嘗試修改 scope 外的檔案"
    echo "   檔案：$FILE_PATH"
    echo "   允許範圍：$ALLOWED_DIR"
    echo "   解除：刪除 .claude-freeze-scope 或說「解除目錄鎖定」"
    exit 2  # 攔截
    ;;
esac
```

#### 啟用/解除指令

```bash
# 啟用 Freeze（鎖定到 src/modules/auth/）
echo "src/modules/auth/" > .claude-freeze-scope
echo "✅ Freeze Mode 啟用，僅允許修改 src/modules/auth/"

# 解除 Freeze
rm -f .claude-freeze-scope
echo "🔓 Freeze Mode 解除"
```

#### 自動啟用時機

| 時機 | Scope | 啟用方式 |
|------|-------|---------|
| `ground` skill 完成後 | grounding 識別的修改範圍 | ground skill 自動寫入 |
| P04 Feature 開始 | `src/` + Feature 對應目錄 | worktree-setup.sh 自動寫入 |
| Hotfix Pipeline | hotfix 修改範圍 | orchestrator 自動寫入 |
| 3-Strike BLOCKED | 當前 debug 目錄 | systematic-debugging 自動寫入 |
| 手動 | 用戶指定 | 用戶說「鎖定目錄：[path]」|

#### 與 destructive-guard-hook.sh 的整合

`destructive-guard-hook.sh`（Bash 指令攔截）+ `freeze-hook.sh`（Edit/Write 攔截）共同構成完整的安全護欄：

```
Bash 指令 → destructive-guard-hook.sh → 攔截 rm/DROP/force-push
Edit 操作 → freeze-hook.sh → 攔截 scope 外修改
Write 操作 → freeze-hook.sh → 攔截 scope 外修改
Read 操作 → 不攔截（永遠允許讀取）
```
