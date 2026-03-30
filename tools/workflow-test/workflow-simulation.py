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

TEMPLATE_DIR = Path(__file__).parent.parent.parent / "project-template"
SPECS_DIR = TEMPLATE_DIR / "02_Specifications"
SKILLS_DIR = TEMPLATE_DIR / "context-skills"
SEEDS_DIR = TEMPLATE_DIR / "context-seeds"

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
    stage = {"name": "P01 精煉+Prototype", "icon": "✨", "tests": []}
    print(f"\n {'='*55}")
    print(f" ✨ Stage 2: P01 精煉+Prototype")
    print(f" {'='*55}\n")

    pm = SEEDS_DIR / "SEED_PM.md"
    check(stage, "PM 含 7 區塊格式", pm, "7 區塊|TEMPLATE_RS_Function_Spec",
          "PM 撰寫 RS 時必須遵循 7 區塊模板")
    check(stage, "PM 含 4 Scope Modes", pm, "Scope Mode|4 Scope|Expansion",
          "收到需求後先選 Scope Mode（Expansion/Selective/Hold/Reduction）")
    check(stage, "PM 含 Kill Criteria", pm, "Kill Criteria",
          "每功能定義「什麼情況下放棄」— Review Agent 檢查是否觸發")
    check(stage, "PM 含 Type 1/2 Door", pm, "Type 1|Type 2|Bezos",
          "可逆決策快速做、不可逆決策慎重做（Bezos 模型）")

    ux = SEEDS_DIR / "SEED_UX.md"
    check(stage, "UX 含 6 Interaction States", ux, "Interaction State|Empty.*Loading.*Error",
          "每畫面必須定義 6 態（Empty/Loading/Error/Overflow/First-time/Permission）")

    gates = SKILLS_DIR / "quality-gates" / "SKILL.md"
    check(stage, "Gate 1 含 RS 品質檢查", gates, "RS 功能規格品質",
          "Gate 1 審查 PM 產出的 RS 是否符合 7 區塊標準")
    check(stage, "Gate 1 含模糊用語偵測", gates, "模糊用語|適當.*合理",
          "搜尋「適當」「合理」「良好」— 全部退回改為具體描述")

    return stage

# ═══════════════════════════════════════
# Stage 3: P02 Slice Backlog
# ═══════════════════════════════════════
def test_p02():
    stage = {"name": "P02 技術設計 + Slice", "icon": "🏛️", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🏛️ Stage 3: P02 技術設計 + Slice Backlog")
    print(f" {'='*55}\n")

    arch = SEEDS_DIR / "SEED_Architect.md"
    check(stage, "Architect 含 Complexity Smell", arch, "Complexity Smell",
          "修改 >8 檔案 = 🔴 必須拆分（防過度設計）")
    check(stage, "Architect 含 Existing Code Leverage", arch, "Existing Code",
          "設計前搜尋 context-skills/10_Standards/npm 有無可重用方案")
    check(stage, "Architect 含 Failure Scenario", arch, "Failure Scenario|失敗場景|生產環境失敗",
          "每個新 API/模組附一個生產環境失敗場景")

    gates = SKILLS_DIR / "quality-gates" / "SKILL.md"
    check(stage, "Gate 2 含 Slice Backlog 審查", gates, "Slice Backlog",
          "Gate 2 驗證 Slice Backlog 存在 + Entry/Exit Criteria + 依賴無循環")

    orch = SKILLS_DIR / "pipeline-orchestrator" / "SKILL.md"
    check(stage, "Orchestrator 含 Slice Cycle", orch, "Slice Cycle",
          "Gate 2 通過後自動進入 Slice Cycle 模式")
    check(stage, "Orchestrator 含 Entry/Exit", orch, "Entry.*Criteria|Entry",
          "每個 slice 有進入和退出條件")

    return stage

# ═══════════════════════════════════════
# Stage 4: Slice Cycle
# ═══════════════════════════════════════
def test_slice_cycle():
    stage = {"name": "P03+P04 Slice Cycle", "icon": "🔄", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🔄 Stage 4: P03+P04 Slice Cycle")
    print(f" {'='*55}\n")

    sc = SKILLS_DIR / "slice-cycle" / "SKILL.md"
    check_file_exists(stage, "slice-cycle SKILL.md", sc, "垂直切片循環的完整定義")

    if sc.exists():
        steps = [
            ("Feature Pack", "Feature Pack", "Step 1：確認本 slice 範圍（做什麼/不做什麼）"),
            ("Design", "Step 2.*Design|Design.*不寫 code", "Step 2：設計 API+DB+Sequence，⛔不寫 code"),
            ("G4-ENG-D", "G4-ENG-D", "Step 3：設計審查 Gate，未通過不得寫 code"),
            ("Code", "Step 4.*Code|Code.*只做本", "Step 4：只實作本 slice，⛔不碰其他 slice"),
            ("G4-ENG-R", "G4-ENG-R", "Step 5：實作後審查 Gate，範圍比對+假設清單"),
            ("Stabilization", "Stabilization|P0 穩定", "Step 6：確保能跑（編譯通過+主流程可驗證）"),
            ("Hardening", "Hardening|基線判定", "Step 7：確保可靠+可作為下一個 slice 的依賴"),
        ]
        for step_name, pattern, logic in steps:
            check(stage, f"Slice 7 步：{step_name}", sc, pattern, logic)

        print(f"    {'─'*50}")
        print(f"    回退規則驗證：")
        print()
        rollbacks = [
            ("範圍漂移", "範圍漂移", "偷補需求 → 回 G4-ENG-R 刪除超出範圍實作"),
            ("設計不一致", "設計與實作不一致", "code 和 design 對不上 → 回 Design 修正"),
            ("啟動/安全", "啟動.*安全|安全.*主流程", "P0 問題 → 回 Stabilization 先修到能跑"),
            ("邏輯/測試", "邏輯語意|邊界測試", "邊界沒覆蓋 → 回 Hardening 補測試"),
            ("架構錯誤", "架構邊界", "slice 切法有誤 → 升級回 P02 重新設計"),
        ]
        for rb_name, pattern, logic in rollbacks:
            check(stage, f"回退：{rb_name}", sc, pattern, logic)

        print(f"    {'─'*50}")
        print(f"    跨切片+協議驗證：")
        print()
        check(stage, "Cross-Slice Integration Check", sc, "Cross-Slice",
              "第 3 骨幹 slice 後+每 2 slice+修改共用模組 → 強制整合檢查")
        check(stage, "Open Issue Protocol", sc, "Open Issue|OI-",
              "未定義事項不假設，結構化記錄 OI-NNN")
        check(stage, "Entry Criteria 範本", sc, "Entry Criteria",
              "每 slice 進入前必須滿足的條件（前序基線、API 穩定、Schema 可用）")
        check(stage, "Exit Criteria 範本", sc, "Exit Criteria",
              "每 slice 退出=基線判定（AC 完成、測試全過、API 穩定、無 P0）")

    gates = SKILLS_DIR / "quality-gates" / "SKILL.md"
    check(stage, "G4-ENG-D checklist", gates, "G4-ENG-D",
          "設計審查 8 項 checklist（D-01~D-08）")
    check(stage, "G4-ENG-R checklist", gates, "G4-ENG-R",
          "實作後審查 10 項 checklist（R-01~R-10）")
    check(stage, "Cross-Slice IC checklist", gates, "IC-01|Cross-Slice Integration",
          "整合檢查 8 項 checklist（IC-01~IC-08）")

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
        ("destructive-guard-hook.sh", "PreToolUse Hook：攔截 rm -rf/DROP/force-push 等危險指令"),
        ("freeze-hook.sh", "PreToolUse Hook：P04 時鎖定只能改 Feature 對應目錄"),
        ("auto-state-update.sh", "PostToolUse Hook：偵測 Pipeline 產出物自動更新 STATE.md"),
        ("validate-skills.sh", "CI 腳本：驗證 SKILL.md 格式+SEED 完整+交叉引用"),
        ("skill-eval.sh", "評估腳本：Tier 2 結構+Tier 3 LLM-as-Judge"),
        ("worktree-setup.sh", "Worktree 建立後自動安裝依賴+複製 .env+基準測試"),
        ("worktree-archive.sh", "Worktree 完成後自動歸檔+清理+記錄日誌"),
    ]
    for script, desc in scripts:
        check_executable(stage, script, TEMPLATE_DIR / "scripts" / script, desc)

    claude_md = TEMPLATE_DIR / "CLAUDE.md"
    check(stage, "Hook 配置：UserPromptSubmit", claude_md, "UserPromptSubmit",
          "/clear 後每次送訊息自動提醒讀取 planning files")
    check(stage, "Hook 配置：PreToolUse", claude_md, "PreToolUse",
          "Bash 指令前自動攔截危險操作 + Edit/Write 前檢查 scope")
    check(stage, "Autopilot 模式定義", claude_md, "Autopilot.*Copilot.*Manual|三種執行模式",
          "三模式切換：Autopilot（自動）/Copilot（確認）/Manual（手動）")

    check_file_exists(stage, "ETHOS.md", TEMPLATE_DIR / "ETHOS.md",
          "4 原則：Boil the Lake/Search Before Building/Fix-First/Evidence")
    check_file_exists(stage, "conductor.json", TEMPLATE_DIR / "conductor.json",
          "並行工作區配置（Worktree lifecycle hooks）")

    return stage

# ═══════════════════════════════════════
# Stage 6: Agent 思維模式
# ═══════════════════════════════════════
def test_cognitive():
    stage = {"name": "Agent 思維模式覆蓋", "icon": "🧠", "tests": []}
    print(f"\n {'='*55}")
    print(f" 🧠 Stage 6: Agent 思維模式覆蓋")
    print(f" {'='*55}\n")

    agents = {
        "SEED_Interviewer": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Push-Until-Specific", "Push-Until-Specific", "每個問題有「推到什麼程度才算回答」的標準"),
            ("Escape Hatch", "Escape Hatch", "用戶不耐煩時自動減少問題，不問第三次"),
            ("Anti-Sycophancy", "Anti-Sycophancy", "禁止說「很有趣」— 訪談師不評價只追問"),
            ("Struggle Moments", "Struggle Moments", "從「掙扎時刻」定義需求而非功能列表"),
        ],
        "SEED_PM": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("4 Scope Modes", "Scope Mode|Expansion", "需求建立前先選模式"),
            ("Implementation Alternatives", "Implementation Alternatives", "每功能至少 2 條路徑比較"),
            ("Type 1/2 Door", "Type 1|Type 2", "可逆決策快速做、不可逆慎重做"),
            ("Kill Criteria", "Kill Criteria", "開始前定義放棄條件"),
            ("Appetite", "Appetite", "「願意花多少時間」取代「估計多少時間」"),
        ],
        "SEED_UX": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("12 Cognitive Patterns", "Cognitive Pattern|看系統不看畫面", "12 個設計師內化直覺"),
            ("6 Interaction States", "Interaction State|Empty", "每畫面 6 態強制覆蓋"),
        ],
        "SEED_Architect": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("15 Engineering Patterns", "Engineering.*Pattern|Boring by Default", "15 個工程師思維直覺"),
            ("Complexity Smell", "Complexity Smell", ">8 檔案 = 🔴 必須拆分"),
            ("Context Engineering", "Context Engineering", "AI 功能品質=context 設計品質"),
        ],
        "SEED_DBA": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Shadow Path Tracing", "Shadow Path", "每資料流追蹤 4 路徑（happy/null/empty/error）"),
            ("Temporal Depth", "Temporal Depth", "Schema 能承受 5x 資料量？"),
        ],
        "SEED_Backend": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("三層 Never Rules", "Never Rules|三層", "Controller/Service/Repository 各層禁止行為"),
            ("18 Anti-Patterns", "Anti-Pattern", "Don't/Do 對照表"),
            ("Test Coverage Diagram", "Test Coverage Diagram", "每 API 附 ASCII 覆蓋圖"),
        ],
        "SEED_Frontend": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Per-Page QA", "Per-Page QA", "前端自己先跑 7 步 QA"),
            ("Design Review Lite", "Design Review Lite", "改 UI 就自動對照 checklist"),
        ],
        "SEED_QA": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Diff-Aware Testing", "Diff-Aware", "只測改動的（不是全跑）"),
            ("Regression Mode", "Regression Mode", "和上次比較，追蹤品質趨勢"),
            ("Evals as PRD", "Evals as PRD", "AI 功能用 binary eval+統計 pass rate"),
        ],
        "SEED_Security": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Attack Surface Census", "Attack Surface", "量化攻擊面：N 個公開 endpoint/認證/上傳/整合"),
            ("False Positive Rules", "False Positive", "每個檢查類別有誤報排除規則"),
            ("14 Phase Audit", "14.*階段|Phase.*0", "14 階段安全審計架構"),
        ],
        "SEED_DevOps": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Land-and-Deploy", "Land-and-Deploy", "verify→merge→deploy→canary→confirm 一條龍"),
            ("Rollback-First", "Rollback-First|Rollback.*原則", "部署前必須確認 rollback 方案"),
        ],
        "SEED_Review": [
            ("ETHOS 引用", "ETHOS.md", "Agent 知道框架的 4 原則"),
            ("Scope Drift Detection", "Scope Drift", "比對 plan vs diff：做的是不是當初說的"),
            ("Two-Pass Review", "Two-Pass", "Pass 1 Critical（阻塞）→ Pass 2 Informational（不阻塞）"),
            ("Fix-First", "Fix-First", "格式/lint/console.log 自動修，業務邏輯才問人"),
            ("Kill Criteria Check", "Kill Criteria", "檢查 RS 的放棄條件是否已觸發"),
        ],
    }

    for seed_name, patterns in agents.items():
        seed_file = SEEDS_DIR / f"{seed_name}.md"
        if not seed_file.exists():
            check_file_exists(stage, f"{seed_name}", seed_file, f"{seed_name} 必須存在")
            continue
        print(f"    ── {seed_name} ──")
        for check_name, pattern, logic in patterns:
            check(stage, f"{seed_name}: {check_name}", seed_file, pattern, logic)

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
    print("║  AI-First Framework v2.9 — Tier 2 工作流模擬測試        ║")
    print("║  透明模式：每項測試顯示驗證邏輯+實際內容+位置           ║")
    print("╚" + "═"*58 + "╝")

    stages = [test_p00(), test_p01(), test_p02(), test_slice_cycle(), test_automation(), test_cognitive()]
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
