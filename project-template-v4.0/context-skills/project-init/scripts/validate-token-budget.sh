#!/bin/bash
# ============================================================
# Token Budget Validator — V4 AI-First Framework
# RR-3 Fix: Validates key files stay within token budget limits
#
# Usage:
#   bash validate-token-budget.sh --project /path/to/project
#   bash validate-token-budget.sh  (uses current directory)
#
# Token estimation: 1 token ≈ 4 characters (conservative)
# ============================================================

# Parse arguments
PROJECT_DIR="${PWD}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--project /path/to/project]"
      exit 1
      ;;
  esac
done

# ---- Configuration: file → token limit ----
declare -A FILES
FILES["CLAUDE.md"]=5000
FILES["context-skills/task-master/SKILL.md"]=2000
FILES["context-seeds/GROUP_Discovery.md"]=2000
FILES["context-seeds/GROUP_Build.md"]=2000
FILES["context-seeds/GROUP_Verify.md"]=2000
FILES["context-seeds/ROLE_Review.md"]=1000
FILES["memory/STATE.md"]=400

declare -A LABELS
LABELS["CLAUDE.md"]="CLAUDE.md (global instructions)"
LABELS["context-skills/task-master/SKILL.md"]="task-master SKILL (dispatcher)"
LABELS["context-seeds/GROUP_Discovery.md"]="GROUP_Discovery (role group)"
LABELS["context-seeds/GROUP_Build.md"]="GROUP_Build (role group)"
LABELS["context-seeds/GROUP_Verify.md"]="GROUP_Verify (role group)"
LABELS["context-seeds/ROLE_Review.md"]="ROLE_Review (cross-stage role)"
LABELS["memory/STATE.md"]="STATE.md (live status)"

# ---- Check function ----
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

check_budget() {
  local file="$1"
  local limit_tokens="$2"
  local label="$3"
  local full_path="$PROJECT_DIR/$file"
  local limit_chars=$((limit_tokens * 4))

  if [ ! -f "$full_path" ]; then
    echo "  ⏭️  SKIP   $label"
    echo "             (file not found: $file)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    return
  fi

  local char_count
  char_count=$(wc -c < "$full_path")
  local est_tokens=$((char_count / 4))

  if [ "$char_count" -le "$limit_chars" ]; then
    local pct=$((est_tokens * 100 / limit_tokens))
    echo "  ✅ PASS   $label"
    echo "             ~${est_tokens} / ${limit_tokens} tokens  (${pct}% of budget)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    local overage=$((est_tokens - limit_tokens))
    local pct=$((est_tokens * 100 / limit_tokens))
    echo "  ❌ FAIL   $label"
    echo "             ~${est_tokens} / ${limit_tokens} tokens  (${pct}% — 超出 ~${overage} tokens)"
    echo "             路徑: $full_path"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# ---- Main ----
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           Token Budget Validation — V4 Framework          ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Project: $PROJECT_DIR"
echo "║  Note: 1 token ≈ 4 chars (conservative estimate)"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Run checks in priority order
check_budget "CLAUDE.md"                               5000  "${LABELS["CLAUDE.md"]}"
check_budget "context-skills/task-master/SKILL.md"    2000  "${LABELS["context-skills/task-master/SKILL.md"]}"
check_budget "context-seeds/GROUP_Discovery.md"       2000  "${LABELS["context-seeds/GROUP_Discovery.md"]}"
check_budget "context-seeds/GROUP_Build.md"           2000  "${LABELS["context-seeds/GROUP_Build.md"]}"
check_budget "context-seeds/GROUP_Verify.md"          2000  "${LABELS["context-seeds/GROUP_Verify.md"]}"
check_budget "context-seeds/ROLE_Review.md"           1000  "${LABELS["context-seeds/ROLE_Review.md"]}"
check_budget "memory/STATE.md"                        400   "${LABELS["memory/STATE.md"]}"

# ---- Summary ----
echo ""
echo "──────────────────────────────────────────────────────────"
echo "  Summary: ✅ ${PASS_COUNT} PASS  |  ❌ ${FAIL_COUNT} FAIL  |  ⏭️  ${SKIP_COUNT} SKIP"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "  🚫 Token budget validation FAILED."
  echo ""
  echo "  Action required — for each ❌ FAIL:"
  echo "    CLAUDE.md         → Move domain knowledge to memory/ or context-skills/"
  echo "    GROUP files       → Move examples to a reference/ subfolder"
  echo "    task-master SKILL → Remove verbose examples, keep routing logic only"
  echo "    ROLE_Review       → Condense to core checklist items"
  echo "    STATE.md          → Remove stale entries, keep current phase only"
  echo ""
  echo "  ⚠️  Do NOT proceed with project init until all FAILs are resolved."
  echo "──────────────────────────────────────────────────────────"
  echo ""
  exit 1
else
  echo "  🎉 All token budgets within limits. Project init can proceed."
  echo "──────────────────────────────────────────────────────────"
  echo ""
  exit 0
fi
