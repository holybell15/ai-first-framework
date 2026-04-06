#!/usr/bin/env python3
"""
Tier 2: 工作流模擬測試（透明模式）
每個測試顯示：驗證邏輯 + 實際找到的內容 + 檔案路徑 + 行號

用法:
  python3 workflow-simulation.py                    # 完整報告
  python3 workflow-simulation.py --brief            # 只顯示結果
  python3 workflow-simulation.py --output report.json
"""

import os, re, json, sys, argparse
from datetime import datetime
from pathlib import Path

TEMPLATE_DIR = Path(__file__).parent.parent.parent / "project-template-v4.0"
SPECS_DIR = TEMPLATE_DIR / "02_Specifications"
SKILLS_DIR = TEMPLATE_DIR / "context-skills"
ROLES_DIR = TEMPLATE_DIR / "context-roles"

BRIEF = False
results = {
    "tier": 2, "name": "工作流模擬測試（透明模式）",
    "timestamp": datetime.now().isoformat(),
    "summary": {"pass": 0, "fail": 0, "total_checks": 0, "score": 0},
    "stages": []
}

def find_in_file(filepath, pattern, context_lines=1):
    """在檔案中搜尋 pattern，回傳行號+上下文"""
    if not filepath.exists():
        return None
    lines = filepath.read_text().splitlines()
    for i, line in enumerate(lines):
        if re.search(pattern, line, re.IGNORECASE):
            start = max(0, i - context_lines)
            end = min(len(lines), i + context_lines + 1)
            context = lines[start:end]
            return {
                "file": str(filepath.relative_to(TEMPLATE_DIR)),
                "line": i + 1,
                "match": line.strip(),
                "context": [f"  L{start+j+1}: {l}" for j, l in enumerate(context)]
            }
    return None

def check(stage, name, filepath, pattern, logic_desc, must_find=True):
    """執行一項檢查，輸出透明的驗證過程"""
    results["summary"]["total_checks"] += 1
    found = find_in_file(filepath, pattern)
    passed = (found is not None) == must_find

    if passed:
        results["summary"]["pass"] += 1
    else:
        results["summary"]["fail"] += 1

    status = "✅" if passed else "❌"
    entry = {
        "name": name,
        "status": "pass" if passed else "fail",
        "logic": logic_desc,
        "file": str(filepath.relative_to(TEMPLATE_DIR)) if filepath.exists() else "FILE NOT FOUND",
        "pattern": pattern,
        "found": found,
    }
    stage["tests"].append(entry)

    if not BRIEF:
        print(f"    {status} {name}")
        print(f"       驗證：{logic_desc}")
        print(f"       檔案：{entry['file']}")
        if found:
            print(f"       找到：L{found['line']} → {found['match'][:100]}")
            if len(found['context']) > 1:
                for ctx in found['context']:
                    print(f"       {ctx[:120]}")
        elif must_find:
            print(f"       ❌ 搜尋 '{pattern}' — 未找到")
        print()
    else:
        print(f"    {status} {name}")

    return passed

def check_file_exists(stage, name, filepath, logic_desc):
    """檢查檔案是否存在"""
    results["summary"]["total_checks"] += 1
    exists = filepath.exists()
    if exists:
        results["summary"]["pass"] += 1
        size = filepath.stat().st_size
        lines = len(filepath.read_text().splitlines())
    else:
        results["summary"]["fail"] += 1
        size = 0
        lines = 0

    status = "✅" if exists else "❌"
    entry = {
        "name": name,
        "status": "pass" if exists else "fail",
        "logic": logic_desc,
        "file": str(filepath.relative_to(TEMPLATE_DIR)) if exists else str(filepath),
        "exists": exists,
        "size": size,
        "lines": lines,
    }
    stage["tests"].append(entry)

    if not BRIEF:
        print(f"    {status} {name}")
        print(f"       驗證：{logic_desc}")
        if exists:
            print(f"       結果：存在（{lines} 行, {size} bytes）")
            print(f"       路徑：{entry['file']}")
        else:
            print(f"       ❌ 檔案不存在：{filepath}")
        print()
    else:
        print(f"    {status} {name}")

    return exists

def check_executable(stage, name, filepath, desc):
    """檢查腳本是否存在且可執行"""
    results["summary"]["total_checks"] += 1
    exists = filepath.exists()
    executable = os.access(str(filepath), os.X_OK) if exists else False
    passed = exists and executable

    if passed:
        results["summary"]["pass"] += 1
    else:
        results["summary"]["fail"] += 1

    status = "✅" if passed else "❌"
    entry = {"name": name, "status": "pass" if passed else "fail", "logic": desc}
    stage["tests"].append(entry)

    if not BRIEF:
        print(f"    {status} {name}")
        print(f"       驗證：{desc}")
        print(f"       存在：{'是' if exists else '否'} | 可執行：{'是' if executable else '否'}")
        if exists:
            print(f"       路徑：{filepath.relative_to(TEMPLATE_DIR)}")
        print()
    else:
        print(f"    {status} {name}")

    return passed

# ═══════════════════════════════════════
# Stage 1: P00 需求建立
# ═══════════════════════════════════════
def test_p00():
    stage = {"name": "P00 需求建立", "icon": "💡", "tests": []}
    print(f"\n {'='*55}")
    print(f" 💡 Stage 1: P00 需求建立")
    print(f" {'='*55}\n")

    srs = SPECS_DIR / "TEMPLATE_SRS_Complete.md"
    check_file_exists(stage, "SRS 完整模板", srs, "P00 的核心產出模板必須存在")

    if srs.exists():
        sections = [
            ("封面", "封面", "SRS 必須有封面（產品名/文件編號/版本號/機密等級）"),
            ("版本歷程", "版本歷程", "每次修改都追蹤版本，防止文件混亂"),
            ("系統定位", "系統定位", "包含專案資訊+核心定位+角色定義"),
            ("系統範圍", "系統範圍", "定義系統邊界+外部責任+資料隔離"),
            ("功能規格", "功能規格|功能說明", "逐項功能 7 區塊（說明/角色/流程/情境/欄位/限制/AC）"),
            ("SLA", "非功能.*指標|SLA", "可用性+效能+容量+安全的具體數字"),
            ("MVP 範圍", "MVP.*Phase", "明確切分 MVP 和 Phase 2"),
        ]
        for section_name, pattern, logic in sections:
            check(stage, f"SRS 含 [{section_name}]", srs, pattern, logic)

    func = SPECS_DIR / "TEMPLATE_RS_Function_Spec.md"
    check_file_exists(stage, "功能規格 7 區塊模板", func, "每個功能的標準格式模板")

    if func.exists():
        blocks = [
            ("功能說明", "功能說明", "回答：誰/情境/操作/目的"),
            ("操作角色", "操作角色", "角色×操作矩陣，讓 Frontend 做 RBAC 渲染"),
            ("操作流程", "操作流程", "每步「使用者做 X → 系統做 Y」，讓 Backend 設計 API"),
            ("情境描述", "情境描述", "≥4 種情境（正常/錯誤/邊界/降級），讓 QA 寫 TC"),
            ("欄位規格", "欄位.*參數", "含型別+必填+限制，讓 DBA 設計 Schema"),
            ("條件限制", "條件限制", "技術/安全/合規/效能/多租戶約束"),
            ("驗收條件", "驗收條件", "三段式 AC：前置+操作+預期，QA 唯一依據"),
        ]
        for block_name, pattern, logic in blocks:
            check(stage, f"7 區塊：{block_name}", func, pattern, logic)

    vision = SPECS_DIR / "TEMPLATE_P00_Product_Vision.md"
    check_file_exists(stage, "P00 願景模板", vision, "P00 的替代模板（較輕量）")

    return stage

# ═══════════════════════════════════════
# Stage 2: P01 精煉
# ═══════════════════════════════════════
def test_p01():
    stage = {"name": "Plan 設計+Prototype", "icon": "✨", "tests": []}
    print(f"\n {'='*55}")
    print(f" ✨ Stage 2: Plan 設計+Prototype")
    print(f" {'='*55}\n")

    discovery = ROLES_DIR / "GROUP_Discovery.md"
    check(stage, "Discovery Group 含 PM 職責", discovery, "SRS|需求說明書",
          "PM 負責 SRS 撰寫")
    check(stage, "Discovery Group 含 AC 定義", discovery, "AC|驗收條件",
          "PM 負責 AC 精確定義")
    check(stage, "Discovery Group 含 WBS", discovery, "WBS|工作分解",
          "PM 負責 WBS 拆至 Task 級別")

    check(stage, "UX 含 Design Token", discovery, "Design Token|token",
          "UX 負責 Design Token 定義")
    check(stage, "UX 含 Prototype", discovery, "Prototype",
          "UX 負責 Prototype 產出")

    gates = SKILLS_DIR / "gate-check" / "SKILL.md"
    check(stage, "Gate 1 (Discover) 存在", gates, "Gate 1|Gate.*需求",
          "Gate 驗證需求完整性")

    return stage

# ═══════════════════════════════════════
# Stage 3: P02 Slice Backlog
# ═══════════════════════════════════════
def test_p02():
    stage = {"name": "Plan 技術設計", "icon": "🏛️", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🏛️ Stage 3: Plan 技術設計")
    print(f" {'='*55}\n")

    discovery = ROLES_DIR / "GROUP_Discovery.md"
    check(stage, "Architect 含 ADR", discovery, "ADR|架構決策",
          "Architect 負責 ADR 撰寫")
    check(stage, "Architect 含 SD Checklist", discovery, "SD.*Checklist|Checklist.*7",
          "Architect 完成 SD Checklist 7 項")
    check(stage, "Architect 含 Slice Backlog", discovery, "Slice Backlog|Slice",
          "Architect 建立 Slice Backlog")

    gates = SKILLS_DIR / "gate-check" / "SKILL.md"
    check(stage, "Gate 2 (Plan) 存在", gates, "Gate 2|Gate.*架構",
          "Gate 驗證架構設計完整性")

    config = TEMPLATE_DIR / "project-config.yaml"
    check(stage, "Config 含 Architect skills", config, "Architect",
          "project-config.yaml 定義 Architect 的 skill 配置")

    return stage

# ═══════════════════════════════════════
# Stage 4: Slice Cycle
# ═══════════════════════════════════════
def test_build():
    stage = {"name": "Build 實作開發", "icon": "🔄", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🔄 Stage 4: Build 實作開發")
    print(f" {'='*55}\n")

    build = ROLES_DIR / "GROUP_Build.md"
    check_file_exists(stage, "GROUP_Build.md", build, "Build 群組角色定義")

    if build.exists():
        checks = [
            ("Backend 職責", "Backend|API 端點", "Backend specialist 職責定義"),
            ("Frontend 職責", "Frontend|UI 元件", "Frontend specialist 職責定義"),
            ("DBA 職責", "DBA|schema", "DBA specialist 職責定義"),
            ("TDD 強制", "TDD|RED.*GREEN", "Build group 強制 TDD"),
            ("Worktree 隔離", "worktree|Worktree", "Feature 用 git worktree 隔離"),
            ("Code Review", "Code Review|review", "production code 需 Review"),
        ]
        for name, pattern, logic in checks:
            check(stage, name, build, pattern, logic)

    # v4.1 Build skills
    tdd = SKILLS_DIR / "test-driven-development" / "SKILL.md"
    check_file_exists(stage, "test-driven-development SKILL.md", tdd, "TDD skill 定義")

    sh = SKILLS_DIR / "self-healing-build" / "SKILL.md"
    check_file_exists(stage, "self-healing-build SKILL.md", sh, "v4.1 自動修復 skill")

    pl = SKILLS_DIR / "pattern-library" / "SKILL.md"
    check_file_exists(stage, "pattern-library SKILL.md", pl, "v4.1 模式庫 skill")

    vc = SKILLS_DIR / "validate-contract" / "SKILL.md"
    check_file_exists(stage, "validate-contract SKILL.md", vc, "v4.1 Contract 雙向驗證 skill")

    gates = SKILLS_DIR / "gate-check" / "SKILL.md"
    check(stage, "Gate 3 (Build/Ship) 存在", gates, "Gate 3|G4-ENG",
          "Gate 驗證實作完成度")

    return stage

# ═══════════════════════════════════════
# Stage 5: 自動化
# ═══════════════════════════════════════
def test_automation():
    stage = {"name": "自動化機制", "icon": "⚡", "tests": []}
    print(f"\n {'='*55}")
    print(f" ⚡ Stage 5: 自動化機制")
    print(f" {'='*55}\n")

    scripts = [
        ("destructive-guard-hook.sh", "PreToolUse Hook：攔截危險指令"),
        ("freeze-hook.sh", "PreToolUse Hook：Build 時鎖定 Feature 目錄"),
        ("auto-state-update.sh", "PostToolUse Hook：自動更新 STATE.md"),
        ("validate-skills.sh", "CI 腳本：驗證 SKILL.md 格式+交叉引用"),
        ("skill-eval.sh", "評估腳本：Tier 2 結構+Tier 3 LLM-as-Judge"),
        ("gate-checkpoint.sh", "Gate 驗證 checkpoint 腳本"),
        ("parallel-feature.sh", "v4.1 BE∥FE 並行執行腳本"),
        ("test-on-change.sh", "v4.1 程式碼變更自動測試"),
        ("test-before-continue.sh", "v4.1 繼續前強制測試"),
    ]
    for script, desc in scripts:
        check_executable(stage, script, TEMPLATE_DIR / "scripts" / script, desc)

    claude_md = TEMPLATE_DIR / "CLAUDE.md"
    config = TEMPLATE_DIR / "project-config.yaml"

    check(stage, "CLAUDE.md 含 Pipeline 定義", claude_md, "Discover.*Plan.*Build.*Verify.*Ship",
          "v4.0 五階段 Pipeline 定義")
    check(stage, "CLAUDE.md 含 Skill 觸發索引", claude_md, "Tier 1.*強制",
          "Tier 1 強制載入 Skill 索引")
    check(stage, "CLAUDE.md 含 Quality Gates", claude_md, "Quality Gates|Discover Gate|Plan Gate",
          "Gate 定義完整")
    check(stage, "執行模式定義", config, "autopilot|copilot|manual",
          "三模式切換定義（在 project-config.yaml）")
    check_file_exists(stage, "project-config.yaml", config, "專案級設定 SSOT")
    if config.exists():
        check(stage, "Config 含 self_healing", config, "self_healing",
              "v4.1 Self-Healing Build 設定")
        check(stage, "Config 含 gate_policy", config, "gate_policy",
              "v4.1 Gate 三級分類設定")
        check(stage, "Config 含 concurrency", config, "concurrency",
              "v4.1 並行設定")

    return stage

# ═══════════════════════════════════════
# Stage 6: Group Role 覆蓋
# ═══════════════════════════════════════
def test_cognitive():
    stage = {"name": "Group Role 覆蓋", "icon": "🧠", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🧠 Stage 6: Group Role 覆蓋")
    print(f" {'='*55}\n")

    roles = {
        "GROUP_Discovery.md": [
            ("Interviewer/PM 區段", "Interviewer|PM", "Discovery 含 Interviewer/PM 職責"),
            ("UX 區段", "UX", "Discovery 含 UX 職責"),
            ("Architect 區段", "Architect", "Discovery 含 Architect 職責"),
            ("交接格式", "Handoff|handoff", "Discovery 定義交接格式"),
            ("Scope drift", "drift|DRIFT", "Discovery 定義 scope drift 處理"),
            ("必載 Skill", "brainstorming|planning-with-tasks", "Discovery specialists 有必載 skill"),
            ("禁止事項", "禁止|不做|不寫", "Discovery specialists 有禁止事項"),
            ("完成標準", "完成標準", "Discovery specialists 有完成標準"),
        ],
        "GROUP_Build.md": [
            ("Backend 區段", "Backend", "Build 含 Backend 職責"),
            ("Frontend 區段", "Frontend", "Build 含 Frontend 職責"),
            ("DBA 區段", "DBA", "Build 含 DBA 職責"),
            ("TDD 強制", "TDD|RED.*GREEN", "Build group 強制 TDD"),
            ("Worktree 隔離", "worktree|Worktree", "Build group 用 worktree 隔離"),
            ("Code Review 要求", "Code Review|review", "Build group 要求 Code Review"),
            ("禁止事項", "禁止|不碰|不改", "Build specialists 有禁止事項"),
            ("完成標準", "完成標準|覆蓋率", "Build specialists 有完成標準"),
        ],
        "GROUP_Verify.md": [
            ("QA 區段", "QA", "Verify 含 QA 職責"),
            ("Security 區段", "Security", "Verify 含 Security 職責"),
            ("DevOps 區段", "DevOps", "Verify 含 DevOps 職責"),
            ("Evidence-first", "Evidence|evidence|T1", "Verify group 要求 Evidence"),
            ("唯讀模式", "唯讀|不修改.*source", "Verify group 唯讀不修改 code"),
            ("Rollback", "Rollback|rollback", "DevOps 含 Rollback 驗證"),
            ("Smoke test", "Smoke|smoke", "DevOps 含 Smoke test"),
        ],
        "ROLE_Review.md": [
            ("Review 角色存在", "Review|Gate", "Review 角色文件存在"),
        ],
    }

    for role_file, patterns in roles.items():
        filepath = ROLES_DIR / role_file
        if not filepath.exists():
            check_file_exists(stage, role_file, filepath, f"{role_file} 必須存在")
            continue
        print(f"    ── {role_file} ──")
        for check_name, pattern, logic in patterns:
            check(stage, f"{role_file}: {check_name}", filepath, pattern, logic)

    return stage

# ═══════════════════════════════════════
# Main
# ═══════════════════════════════════════
def main():
    global BRIEF
    parser = argparse.ArgumentParser(description="Tier 2: 工作流模擬測試（透明模式）")
    parser.add_argument("--brief", action="store_true", help="只顯示結果，不顯示驗證過程")
    parser.add_argument("--output", type=str, default=None, help="輸出 JSON")
    args = parser.parse_args()
    BRIEF = args.brief

    print("╔" + "═"*58 + "╗")
    print("║  AI-First Framework v4.1 — Tier 2 工作流模擬測試        ║")
    print("║  透明模式：每項測試顯示驗證邏輯+實際內容+位置           ║")
    print("╚" + "═"*58 + "╝")

    stages = [test_p00(), test_p01(), test_p02(), test_build(), test_automation(), test_cognitive()]
    results["stages"] = stages

    total = results["summary"]["pass"] + results["summary"]["fail"]
    results["summary"]["score"] = round(results["summary"]["pass"] / total * 100, 1) if total > 0 else 0

    print("\n" + "═"*60)
    print(f" 總結")
    print("═"*60)
    for stage in stages:
        passed = sum(1 for t in stage["tests"] if t["status"] == "pass")
        total_s = len(stage["tests"])
        icon = "✅" if passed == total_s else "⚠️"
        print(f"  {stage['icon']} {stage['name']}: {icon} {passed}/{total_s}")

    p = results["summary"]["pass"]
    f = results["summary"]["fail"]
    score = results["summary"]["score"]
    verdict = "🟢 PASS" if score >= 90 else "🟡 WARN" if score >= 70 else "🔴 FAIL"
    print(f"\n  {verdict} — {p} pass / {f} fail — Score: {score}%")
    print("═"*60)

    if args.output:
        with open(args.output, 'w') as fp:
            json.dump(results, fp, ensure_ascii=False, indent=2)
        print(f"\n  JSON：{args.output}")

    return 0 if score >= 70 else 1

if __name__ == "__main__":
    sys.exit(main())
