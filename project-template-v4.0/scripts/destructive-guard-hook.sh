#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# destructive-guard-hook.sh — PreToolUse 安全攔截
# 用途：在 Claude Code 執行 Bash 指令前自動檢查危險操作
# 配置：寫入 .claude/settings.json 的 hooks.PreToolUse
# 傳回非零 exit code = 攔截指令
# ─────────────────────────────────────────────────────────────
set -uo pipefail

INPUT="$1"

# ─── Level 3：安全放行（優先檢查）───
SAFE_PATTERNS=(
  "rm -rf.*node_modules"
  "rm -rf.*dist/"
  "rm -rf.*build/"
  "rm -rf.*\.cache"
  "rm -rf.*__pycache__"
  "rm -rf.*\.tmp"
  "rm -rf.*05_Archive"
  "rm -rf.*test-results"
  "rm -rf.*\.playwright"
  "DROP.*(test|dev|staging|mock)"
  "TRUNCATE.*(test|dev|staging|mock)"
)

for pattern in "${SAFE_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    exit 0
  fi
done

# ─── Level 1：強制攔截 ───
LEVEL1_PATTERNS=(
  "rm -rf /$"
  "rm -rf /[^t]"
  "rm -rf \*"
  "rm -rf \."
  "DROP TABLE"
  "DROP DATABASE"
  "DROP SCHEMA"
  "TRUNCATE TABLE"
  "DELETE FROM[^W]*$"
  "git push --force[^-]"
  "git push -f "
  "git reset --hard"
  "git branch -D "
  "git clean -fd"
  "git stash clear"
  "chmod -R 777"
  "kill -9 1$"
  "terraform destroy"
  "kubectl delete namespace"
  "docker system prune -a"
)

for pattern in "${LEVEL1_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    cat <<EOF
⛔ BLOCKED by destructive-guard

偵測到 Level 1 破壞性指令
匹配模式：$pattern
原始指令：$INPUT

建議：
- rm -rf → 改用 mv 到暫存區，或指定具體路徑
- DROP/TRUNCATE → 先備份，確認非生產環境
- git push --force → 改用 --force-with-lease
- git reset --hard → 先 git stash 保存變更
- git branch -D → 改用 -d（會檢查是否已合併）

詳見：context-skills/destructive-guard/SKILL.md
EOF
    exit 2
  fi
done

# ─── Level 2：警告（不攔截，僅提示）───
LEVEL2_PATTERNS=(
  "git rebase"
  "git checkout -- \."
  "npm uninstall"
  "pip uninstall"
  "ALTER TABLE.*prod"
  "docker volume prune"
  "DROP INDEX"
  "DROP VIEW"
  "ALTER TABLE.*DROP COLUMN"
)

for pattern in "${LEVEL2_PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qiE "$pattern"; then
    echo "⚠️ destructive-guard WARNING: 偵測到 Level 2 風險指令 ($pattern)"
    echo "   建議在執行前確認影響範圍"
    exit 0  # 警告但不攔截
  fi
done

exit 0
