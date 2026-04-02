#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# AI-First Framework — handoff.sh
# 一個指令完成：git add → commit → push → 自動通知下一位
#
# Usage:
#   ./scripts/handoff.sh <from> <to> <feature> "<message>"
#
# Examples:
#   ./scripts/handoff.sh PM UX F01 "Login US 完成，12 條 AC"
#   ./scripts/handoff.sh Backend Frontend F01 "API Spec 8 個 endpoint"
#   ./scripts/handoff.sh QA Review F01 "所有測試通過" --gate 3
#
# Notification channels (configure in .env):
#   HANDOFF_TEAMS_WEBHOOK=https://xxx.webhook.office.com/...  (recommended)
#   HANDOFF_SLACK_WEBHOOK=https://hooks.slack.com/services/...
#   HANDOFF_DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
#   HANDOFF_LINE_TOKEN=<LINE Notify token>
#   HANDOFF_GITHUB_ISSUE=true   (creates GitHub issue comment)
#
# Required: git, curl
# Optional: gh (for GitHub issue notifications)
# ──────────────────────────────────────────────────────────────

set -euo pipefail

# ── Color output ─────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# ── Detect project root ─────────────────────────────────────
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
TASKS_FILE="$PROJECT_ROOT/TASKS.md"
STATE_FILE="$PROJECT_ROOT/memory/STATE.md"

# ── Load .env if exists ─────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# ── Parse arguments ──────────────────────────────────────────
FROM_ROLE=""
TO_ROLE=""
FEATURE=""
MESSAGE=""
GATE_NUM=""
FILES_TO_ADD=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gate)
      GATE_NUM="$2"
      shift 2
      ;;
    --add)
      FILES_TO_ADD+=("$2")
      shift 2
      ;;
    --help|-h)
      echo "Usage: handoff.sh <from> <to> <feature> \"<message>\" [--gate N] [--add file]"
      echo ""
      echo "Roles: Interviewer, PM, UX, Architect, DBA, Backend, Frontend, QA, Security, DevOps, Review"
      echo ""
      echo "Examples:"
      echo "  handoff.sh PM UX F01 \"Login US done\""
      echo "  handoff.sh QA Review F01 \"Tests pass\" --gate 3"
      echo "  handoff.sh Backend Frontend F01 \"API Spec\" --add 02_Specifications/F01-API.md"
      exit 0
      ;;
    *)
      if [ -z "$FROM_ROLE" ]; then
        FROM_ROLE="$1"
      elif [ -z "$TO_ROLE" ]; then
        TO_ROLE="$1"
      elif [ -z "$FEATURE" ]; then
        FEATURE="$1"
      elif [ -z "$MESSAGE" ]; then
        MESSAGE="$1"
      fi
      shift
      ;;
  esac
done

# ── Validate ─────────────────────────────────────────────────
if [ -z "$FROM_ROLE" ] || [ -z "$TO_ROLE" ] || [ -z "$FEATURE" ] || [ -z "$MESSAGE" ]; then
  echo -e "${RED}Error: Missing required arguments${NC}"
  echo "Usage: handoff.sh <from> <to> <feature> \"<message>\""
  echo "Run with --help for details."
  exit 1
fi

# ── Role → Person mapping (read from TEAM.md) ───────────────
TEAM_FILE="$PROJECT_ROOT/TEAM.md"

get_person_for_role() {
  local role="$1"
  if [ -f "$TEAM_FILE" ]; then
    # Parse TEAM.md table: | Role | Person | Contact | Pipeline |
    local person
    person=$(grep -i "| *${role}" "$TEAM_FILE" 2>/dev/null | head -1 | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
    if [ -n "$person" ] && [ "$person" != "[名字]" ]; then
      echo "$person"
      return
    fi
  fi
  echo "$role"
}

FROM_PERSON=$(get_person_for_role "$FROM_ROLE")
TO_PERSON=$(get_person_for_role "$TO_ROLE")

# ── Determine pipeline from roles ────────────────────────────
get_pipeline() {
  local from="$1" to="$2"
  case "$from→$to" in
    *Interviewer*→*PM*) echo "P01 需求訪談" ;;
    *PM*→*UX*)          echo "P01 需求訪談" ;;
    *UX*→*Review*)      echo "P01 → Gate 1" ;;
    *Architect*→*DBA*)  echo "P02 技術設計" ;;
    *DBA*→*Review*)     echo "P02 → Gate 2" ;;
    *Backend*→*Frontend*) echo "P03/P04" ;;
    *Frontend*→*QA*)    echo "P03/P04" ;;
    *QA*→*Review*)      echo "P04 → Gate 3" ;;
    *Security*→*DevOps*) echo "P05 → P06" ;;
    *Review*→*)         echo "Gate → 下一階段" ;;
    *)                  echo "Pipeline" ;;
  esac
}

PIPELINE=$(get_pipeline "$FROM_ROLE" "$TO_ROLE")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
COMMIT_MSG="handoff(${FROM_ROLE}→${TO_ROLE}): ${FEATURE} ${MESSAGE}"

# ── Detect changed files ─────────────────────────────────────
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || true)

# ── Display handoff summary ──────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║              HANDOFF — 交接通知                  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${CYAN}Feature：${NC}${FEATURE}"
echo -e "  ${CYAN}Pipeline：${NC}${PIPELINE}"
echo -e "  ${CYAN}從：${NC}${FROM_PERSON} (${FROM_ROLE})"
echo -e "  ${CYAN}到：${NC}${TO_PERSON} (${TO_ROLE})"
echo -e "  ${CYAN}摘要：${NC}${MESSAGE}"
if [ -n "$GATE_NUM" ]; then
  echo -e "  ${YELLOW}Gate：${NC}Gate ${GATE_NUM} Review"
fi
echo ""

# Show files to be committed
if [ -n "$CHANGED_FILES" ] || [ -n "$STAGED_FILES" ] || [ -n "$UNTRACKED" ]; then
  echo -e "  ${DIM}Changed files:${NC}"
  { echo "$CHANGED_FILES"; echo "$STAGED_FILES"; echo "$UNTRACKED"; } | sort -u | grep -v '^$' | while read -r f; do
    echo -e "    ${DIM}${f}${NC}"
  done
  echo ""
fi

# ── Confirm ──────────────────────────────────────────────────
echo -e -n "  ${YELLOW}確認交接？${NC} [Y/n] "
read -r confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
  echo -e "  ${RED}已取消${NC}"
  exit 0
fi

echo ""

# ── Step 1: Git add + commit + push ─────────────────────────
echo -e "  ${BLUE}[1/3]${NC} Git commit + push..."

# Always include TASKS.md and STATE.md if they exist and changed
git add TASKS.md 2>/dev/null || true
git add memory/STATE.md 2>/dev/null || true

# Add explicitly specified files
for f in "${FILES_TO_ADD[@]}"; do
  git add "$f" 2>/dev/null || true
done

# Add any remaining staged changes
if [ -z "$(git diff --cached --name-only)" ]; then
  # Nothing staged yet, add all tracked changes
  git add -u 2>/dev/null || true
fi

# Check if there's anything to commit
if [ -z "$(git diff --cached --name-only)" ]; then
  echo -e "  ${YELLOW}Warning: No changes to commit. Proceeding with notification only.${NC}"
else
  git commit -m "$COMMIT_MSG"
  echo -e "  ${GREEN}✓${NC} Committed: ${DIM}${COMMIT_MSG}${NC}"

  # Push
  CURRENT_BRANCH=$(git branch --show-current)
  if git push origin "$CURRENT_BRANCH" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Pushed to ${CURRENT_BRANCH}"
  else
    echo -e "  ${YELLOW}⚠${NC} Push failed (offline or no remote). Changes committed locally."
  fi
fi

# ── Step 2: Build notification payload ───────────────────────
echo -e "  ${BLUE}[2/3]${NC} Building notification..."

# Gate badge
GATE_BADGE=""
if [ -n "$GATE_NUM" ]; then
  GATE_BADGE=" | Gate ${GATE_NUM} Review"
fi

# Plain text (for LINE / terminal)
NOTIFY_TEXT="[交接通知] @${TO_PERSON}
Pipeline：${PIPELINE}${GATE_BADGE}
${FROM_PERSON}(${FROM_ROLE}) → ${TO_PERSON}(${TO_ROLE})
Feature：${FEATURE}
完成：${MESSAGE}
時間：${TIMESTAMP}
下一步：git pull → 確認 TASKS.md → 啟動 ${TO_ROLE} Agent"

# Slack payload (Block Kit)
SLACK_PAYLOAD=$(cat <<EOFSLACK
{
  "blocks": [
    {
      "type": "header",
      "text": {"type": "plain_text", "text": "🔀 交接通知", "emoji": true}
    },
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*Feature：*\n${FEATURE}"},
        {"type": "mrkdwn", "text": "*Pipeline：*\n${PIPELINE}${GATE_BADGE}"}
      ]
    },
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*從：*\n${FROM_PERSON} (${FROM_ROLE})"},
        {"type": "mrkdwn", "text": "*到：*\n@${TO_PERSON} (${TO_ROLE})"}
      ]
    },
    {
      "type": "section",
      "text": {"type": "mrkdwn", "text": "*完成：*\n${MESSAGE}"}
    },
    {
      "type": "context",
      "elements": [
        {"type": "mrkdwn", "text": "📋 下一步：\`git pull\` → 確認 TASKS.md → 啟動 ${TO_ROLE} Agent"}
      ]
    },
    {
      "type": "divider"
    }
  ]
}
EOFSLACK
)

# Discord payload (Embed)
DISCORD_PAYLOAD=$(cat <<EOFDISCORD
{
  "embeds": [{
    "title": "🔀 交接通知",
    "color": 4886754,
    "fields": [
      {"name": "Feature", "value": "${FEATURE}", "inline": true},
      {"name": "Pipeline", "value": "${PIPELINE}${GATE_BADGE}", "inline": true},
      {"name": "交接", "value": "${FROM_PERSON}(${FROM_ROLE}) → **@${TO_PERSON}**(${TO_ROLE})", "inline": false},
      {"name": "完成", "value": "${MESSAGE}", "inline": false},
      {"name": "下一步", "value": "\`git pull\` → 確認 TASKS.md → 啟動 ${TO_ROLE} Agent", "inline": false}
    ],
    "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  }]
}
EOFDISCORD
)

# Teams payload (Adaptive Card)
TEAMS_PAYLOAD=$(cat <<EOFTEAMS
{
  "type": "message",
  "attachments": [{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
      "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
      "type": "AdaptiveCard",
      "version": "1.4",
      "body": [
        {
          "type": "ColumnSet",
          "columns": [
            {
              "type": "Column",
              "width": "auto",
              "items": [{
                "type": "TextBlock",
                "text": "🔀",
                "size": "Large"
              }]
            },
            {
              "type": "Column",
              "width": "stretch",
              "items": [
                {
                  "type": "TextBlock",
                  "text": "交接通知",
                  "weight": "Bolder",
                  "size": "Large"
                },
                {
                  "type": "TextBlock",
                  "text": "${FROM_PERSON}(${FROM_ROLE}) → ${TO_PERSON}(${TO_ROLE})",
                  "spacing": "None",
                  "isSubtle": true
                }
              ]
            }
          ]
        },
        {
          "type": "FactSet",
          "facts": [
            { "title": "Feature", "value": "${FEATURE}" },
            { "title": "Pipeline", "value": "${PIPELINE}${GATE_BADGE}" },
            { "title": "完成", "value": "${MESSAGE}" },
            { "title": "時間", "value": "${TIMESTAMP}" }
          ]
        },
        {
          "type": "TextBlock",
          "text": "📋 **下一步：** \`git pull\` → 確認 TASKS.md → 啟動 ${TO_ROLE} Agent",
          "wrap": true,
          "spacing": "Medium",
          "separator": true
        }
      ],
      "msteams": {
        "width": "Full"
      }
    }
  }]
}
EOFTEAMS
)

# ── Step 3: Send notifications ───────────────────────────────
echo -e "  ${BLUE}[3/3]${NC} Sending notifications..."

NOTIFY_COUNT=0

# Microsoft Teams (primary)
if [ -n "${HANDOFF_TEAMS_WEBHOOK:-}" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H 'Content-Type: application/json' \
    -d "$TEAMS_PAYLOAD" \
    "$HANDOFF_TEAMS_WEBHOOK")
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "  ${GREEN}✓${NC} Teams notification sent"
    NOTIFY_COUNT=$((NOTIFY_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} Teams notification failed (HTTP ${HTTP_CODE})"
  fi
fi

# Slack
if [ -n "${HANDOFF_SLACK_WEBHOOK:-}" ]; then
  if curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H 'Content-Type: application/json' \
    -d "$SLACK_PAYLOAD" \
    "$HANDOFF_SLACK_WEBHOOK" | grep -q "200"; then
    echo -e "  ${GREEN}✓${NC} Slack notification sent"
    NOTIFY_COUNT=$((NOTIFY_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} Slack notification failed"
  fi
fi

# Discord
if [ -n "${HANDOFF_DISCORD_WEBHOOK:-}" ]; then
  if curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H 'Content-Type: application/json' \
    -d "$DISCORD_PAYLOAD" \
    "$HANDOFF_DISCORD_WEBHOOK" | grep -q "204"; then
    echo -e "  ${GREEN}✓${NC} Discord notification sent"
    NOTIFY_COUNT=$((NOTIFY_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} Discord notification failed"
  fi
fi

# LINE Notify
if [ -n "${HANDOFF_LINE_TOKEN:-}" ]; then
  if curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${HANDOFF_LINE_TOKEN}" \
    -d "message=${NOTIFY_TEXT}" \
    "https://notify-api.line.me/api/notify" | grep -q "200"; then
    echo -e "  ${GREEN}✓${NC} LINE Notify sent"
    NOTIFY_COUNT=$((NOTIFY_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} LINE Notify failed"
  fi
fi

# GitHub Issue (using gh CLI)
if [ "${HANDOFF_GITHUB_ISSUE:-}" = "true" ] && command -v gh &>/dev/null; then
  ISSUE_TITLE="[Handoff] ${FROM_ROLE}→${TO_ROLE}: ${FEATURE}"
  ISSUE_BODY="## 交接通知

| 欄位 | 內容 |
|------|------|
| **Feature** | ${FEATURE} |
| **Pipeline** | ${PIPELINE}${GATE_BADGE} |
| **從** | ${FROM_PERSON} (${FROM_ROLE}) |
| **到** | @${TO_PERSON} (${TO_ROLE}) |
| **摘要** | ${MESSAGE} |
| **時間** | ${TIMESTAMP} |

### 下一步
1. \`git pull\`
2. 確認 TASKS.md 中的交接摘要
3. 回覆 ✅ 確認接手
4. 啟動 ${TO_ROLE} Agent"

  if gh issue create --title "$ISSUE_TITLE" --body "$ISSUE_BODY" --label "handoff" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} GitHub Issue created"
    NOTIFY_COUNT=$((NOTIFY_COUNT + 1))
  else
    echo -e "  ${RED}✗${NC} GitHub Issue creation failed"
  fi
fi

# Fallback: terminal only
if [ "$NOTIFY_COUNT" -eq 0 ]; then
  echo -e "  ${YELLOW}⚠${NC} No notification channel configured."
  echo -e "  ${DIM}Configure in .env: HANDOFF_TEAMS_WEBHOOK / HANDOFF_SLACK_WEBHOOK / HANDOFF_LINE_TOKEN${NC}"
  echo ""
  echo -e "  ${DIM}── Notification content (copy to your team channel) ──${NC}"
  echo ""
  echo "$NOTIFY_TEXT"
  echo ""
  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"

  # Copy to clipboard if possible
  if command -v pbcopy &>/dev/null; then
    echo "$NOTIFY_TEXT" | pbcopy
    echo -e "  ${GREEN}✓${NC} Copied to clipboard (Cmd+V to paste)"
  elif command -v xclip &>/dev/null; then
    echo "$NOTIFY_TEXT" | xclip -selection clipboard
    echo -e "  ${GREEN}✓${NC} Copied to clipboard"
  fi
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}✅ 交接完成${NC}"
echo -e "${DIM}${TO_PERSON} 收到通知後：git pull → TASKS.md → 啟動 ${TO_ROLE} Agent${NC}"
echo ""
