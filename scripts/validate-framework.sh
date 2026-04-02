#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python || true)}"

if [ -z "$PYTHON_BIN" ]; then
  echo "❌ python3 或 python 不存在，無法執行 workflow-test"
  exit 1
fi

echo "╔══════════════════════════════════════════════════╗"
echo "║      AI-First Framework — Validation            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

required_files=(
  "README.md"
  "docs/LITE_MODE.md"
  "docs/ROADMAP_PRIORITIES.md"
  "docs/INFORMATION_ARCHITECTURE.md"
  "docs/START_HERE.md"
  "docs/VALIDATION_REPAIR.md"
  "project-template/CLAUDE.md"
  "project-template/START_HERE.md"
  "project-template/TASKS.md"
  "project-template/MASTER_INDEX.md"
  "project-template/memory/STATE.md"
)

failures=0

echo "[1/3] Checking required framework files..."
for rel in "${required_files[@]}"; do
  if [ -f "$ROOT_DIR/$rel" ]; then
    echo "  ✅ $rel"
  else
    echo "  ❌ $rel"
    failures=$((failures + 1))
  fi
done

echo ""
echo "[2/3] Checking example project skeleton..."
example_files=(
  "examples/lite-task-demo/README.md"
  "examples/lite-task-demo/MASTER_INDEX.md"
  "examples/lite-task-demo/TASKS.md"
  "examples/lite-task-demo/memory/STATE.md"
  "examples/lite-task-demo/02_Specifications/US_F01_CreateTask.md"
  "examples/lite-task-demo/03_System_Design/F01-MINI-DESIGN.md"
  "examples/lite-task-demo/08_Test_Reports/F01-LITE-TR.md"
)
for rel in "${example_files[@]}"; do
  if [ -f "$ROOT_DIR/$rel" ]; then
    echo "  ✅ $rel"
  else
    echo "  ❌ $rel"
    failures=$((failures + 1))
  fi
done

echo ""
echo "[3/3] Running workflow-test..."
PROJECT_DIR="$ROOT_DIR/project-template" "$PYTHON_BIN" "$ROOT_DIR/tools/workflow-test/run_tests.py"

echo ""
if [ "$failures" -gt 0 ]; then
  echo "❌ Validation finished with $failures missing file issue(s)."
  echo "💡 Repair guide: $ROOT_DIR/docs/VALIDATION_REPAIR.md"
  exit 1
fi

echo "✅ Validation finished."
echo "💡 Repair guide: $ROOT_DIR/docs/VALIDATION_REPAIR.md"
