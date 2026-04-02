#!/usr/bin/env python3
"""
Execution Audit：比對 Agent 執行 trace vs 預期 checkpoint，產出合規報告。

用法:
  python3 scripts/execution-audit.py                          # 讀取 execution-trace.jsonl
  python3 scripts/execution-audit.py --trace path/to/trace.jsonl
  python3 scripts/execution-audit.py --html                   # 產出 HTML 報告
  python3 scripts/execution-audit.py --json                   # 產出 JSON
"""

import json, sys, argparse, os
from datetime import datetime
from pathlib import Path
from collections import defaultdict

# ═══════════════════════════════════════
# 預期 Checkpoint 定義
# ═══════════════════════════════════════
AGENT_REQUIRED = {
    # 每個 Agent 的基本必要 checkpoint
    "_all": ["seed_read", "ethos_read", "completion_status", "handoff"],

    # 角色特定
    "interviewer": ["precheck", "output"],
    "pm": ["forced_thinking_rt", "precheck", "output", "output_ac", "output_scenarios"],
    "ux": ["precheck", "output"],
    "architect": ["forced_thinking_dt", "precheck", "output"],
    "dba": ["precheck", "output"],
    "backend": ["forced_thinking_pc", "output", "file_modified"],
    "frontend": ["forced_thinking_pc", "output", "file_modified"],
    "qa": ["output"],
    "security": ["precheck", "output"],
    "devops": ["precheck", "output"],
    "review": ["output"],
}

# 每個 Agent 必須讀取的 Skill 清單（從 SEED 的「自動化 Skill 套件」表提取）
AGENT_REQUIRED_SKILLS = {
    "interviewer": ["brainstorming", "verification-before-completion"],
    "pm":          ["forced-thinking", "brainstorming", "verification-before-completion"],
    "ux":          ["frontend-design", "verification-before-completion"],
    "architect":   ["forced-thinking", "deep-research", "brainstorming", "verification-before-completion"],
    "dba":         ["verification-before-completion"],
    "backend":     ["forced-thinking", "test-driven-development", "using-git-worktrees",
                    "destructive-guard", "systematic-debugging", "verification-before-completion"],
    "frontend":    ["frontend-design", "test-driven-development", "using-git-worktrees",
                    "destructive-guard", "verification-before-completion"],
    "qa":          ["webapp-testing", "forced-thinking", "systematic-debugging", "verification-before-completion"],
    "security":    ["deep-research", "verification-before-completion"],
    "devops":      ["verification-before-completion"],
    "review":      ["quality-gates", "requesting-code-review", "verification-before-completion"],
}

# Gate checkpoint
GATE_REQUIRED = {
    "gate_d": ["gate_d_executed", "gate_d_result"],
    "gate_r": ["gate_r_executed", "gate_r_result"],
    "cross_slice": ["cross_slice_ic"],
}

# 異常偵測規則
ANOMALY_RULES = [
    {"name": "跳過 SEED 讀取", "check": lambda traces: not any(t["step"] == "seed_read" for t in traces), "severity": "🔴"},
    {"name": "跳過 ETHOS", "check": lambda traces: not any(t["step"] == "ethos_read" for t in traces), "severity": "🟡"},
    {"name": "無 Completion Status", "check": lambda traces: not any(t["step"] == "completion_status" for t in traces), "severity": "🔴"},
    {"name": "Code 在 G4-ENG-D 前", "check": lambda traces: _code_before_gate(traces), "severity": "🔴"},
]

def _code_before_gate(traces):
    code_time = next((t["ts"] for t in traces if t["step"] == "file_modified"), None)
    gate_time = next((t["ts"] for t in traces if t["step"] == "gate_d_result"), None)
    if code_time and gate_time:
        return code_time < gate_time
    return False

def load_trace(path):
    """載入 execution-trace.jsonl"""
    traces = []
    if not Path(path).exists():
        return traces
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            traces.append(json.loads(line))
        except json.JSONDecodeError:
            # 嘗試解析 [TRACE] 格式
            if line.startswith("[TRACE]"):
                parts = {}
                for pair in line.replace("[TRACE] ", "").split(" "):
                    if "=" in pair:
                        k, v = pair.split("=", 1)
                        parts[k] = v.strip('"')
                if parts:
                    parts["ts"] = datetime.now().isoformat()
                    parts.setdefault("status", "done")
                    traces.append(parts)
    return traces

def audit_agent(agent_name, agent_traces):
    """稽核單一 Agent 的 trace"""
    required = list(AGENT_REQUIRED.get("_all", []))
    required.extend(AGENT_REQUIRED.get(agent_name, []))

    results = []

    # 1. 檢查基本 checkpoint
    for step in required:
        found = [t for t in agent_traces if t["step"] == step]
        if found:
            t = found[0]
            results.append({
                "step": step,
                "status": "pass",
                "detail": t.get("detail", ""),
                "time": t.get("ts", ""),
            })
        else:
            results.append({
                "step": step,
                "status": "fail",
                "detail": "未找到此 checkpoint",
                "time": "",
            })

    # 2. 逐一檢查必須讀取的 Skill
    required_skills = AGENT_REQUIRED_SKILLS.get(agent_name, [])
    if required_skills:
        # 收集所有 skill_read 的 detail
        skill_reads = []
        for t in agent_traces:
            if t["step"] == "skill_read":
                skill_reads.append(t.get("detail", "").lower())
        all_skill_text = " ".join(skill_reads)

        for skill in required_skills:
            # 檢查 skill 名稱是否出現在任何 skill_read 的 detail 中
            skill_lower = skill.lower()
            found_skill = any(skill_lower in sr for sr in skill_reads)
            if found_skill:
                results.append({
                    "step": f"skill:{skill}",
                    "status": "pass",
                    "detail": f"已讀取 {skill}",
                    "time": "",
                })
            else:
                results.append({
                    "step": f"skill:{skill}",
                    "status": "fail",
                    "detail": f"❌ 未讀取 {skill}（SEED 要求必讀）",
                    "time": "",
                })

    # 3. 異常偵測
    anomalies = []
    for rule in ANOMALY_RULES:
        if rule["check"](agent_traces):
            anomalies.append({"name": rule["name"], "severity": rule["severity"]})

        # 額外異常：必讀 skill 未讀
    missing_skills = [r for r in results if r["step"].startswith("skill:") and r["status"] == "fail"]
    if missing_skills:
        anomalies.append({
            "name": f"跳過必讀 Skill（{len(missing_skills)} 個）：{', '.join(r['step'].replace('skill:','') for r in missing_skills)}",
            "severity": "🔴"
        })

    # 4. Skill Impact 驗證（讀了之後有沒有產生可觀測效果）
    skill_impact_results = check_skill_impact(agent_name, agent_traces, results)

    results.extend(skill_impact_results)

    passed = sum(1 for r in results if r["status"] == "pass")
    total = len(results)

    return {
        "agent": agent_name,
        "checkpoints": results,
        "anomalies": anomalies,
        "passed": passed,
        "total": total,
        "compliance": round(passed / total * 100, 1) if total > 0 else 0,
    }


# ═══════════════════════════════════════
# Skill Impact Matrix — 讀了之後有沒有產生可觀測效果
# ═══════════════════════════════════════

SKILL_IMPACT_RULES = {
    "forced-thinking": {
        "observable": "產出含強制思考紀錄（RT-/DT-/PC-/DL-）",
        "check_steps": ["forced_thinking_rt", "forced_thinking_dt", "forced_thinking_pc", "forced_thinking_dl"],
        "applies_to": ["pm", "architect", "backend", "frontend", "qa"],
    },
    "brainstorming": {
        "observable": "需求/設計有多方案比較",
        "check_steps": [],  # 檢查 output detail 中是否有 alternatives/方案 相關字眼
        "check_output_keywords": ["方案", "alternative", "比較", "選項", "Implementation Alternatives"],
        "applies_to": ["interviewer", "pm", "architect"],
    },
    "verification-before-completion": {
        "observable": "交接有 Completion Status + handoff",
        "check_steps": ["completion_status", "handoff"],
        "applies_to": ["_all"],
    },
    "frontend-design": {
        "observable": "Prototype 有 6 Interaction States 覆蓋",
        "check_steps": [],
        "check_output_keywords": ["Interaction State", "6 State", "Empty", "Loading", "Error"],
        "applies_to": ["ux", "frontend"],
    },
    "destructive-guard": {
        "observable": "有攔截記錄 或 確認無危險操作（安全通過）",
        "check_steps": [],  # 這個 skill 的效果是「沒壞事發生」— 難以正面驗證
        "passive": True,  # 標記為被動 skill
        "applies_to": ["backend", "frontend"],
    },
    "webapp-testing": {
        "observable": "QA 報告含 Health Score + 截圖報告",
        "check_steps": [],
        "check_output_keywords": ["Health Score", "QA-Report", "TC", "截圖"],
        "applies_to": ["qa"],
    },
    "quality-gates": {
        "observable": "Gate 報告有 checklist 逐項結果（PASS/BLOCK）",
        "check_steps": ["gate_d_executed", "gate_d_result", "gate_r_executed", "gate_r_result"],
        "check_output_keywords": ["PASS", "BLOCK", "Gate", "RVW"],
        "applies_to": ["review"],
    },
    "slice-cycle": {
        "observable": "有 Feature Pack + Entry/Exit Criteria + G4-ENG-D/R",
        "check_steps": ["gate_d_executed", "gate_d_result", "gate_r_executed", "gate_r_result"],
        "check_output_keywords": ["Feature Pack", "FP.md", "Entry", "S01"],
        "applies_to": ["backend", "frontend", "review"],
    },
    "deep-research": {
        "observable": "技術選型有 ADR 或替代方案比較",
        "check_steps": [],
        "check_output_keywords": ["ADR", "ARCH", "方案", "比較", "research"],
        "applies_to": ["architect", "security"],
    },
    "systematic-debugging": {
        "observable": "Bug 修復有 root cause 記錄",
        "check_steps": [],
        "check_output_keywords": ["root cause", "Root Cause", "根因", "regression"],
        "passive": True,  # 沒遇到 bug 就不會觸發
        "applies_to": ["backend", "frontend", "qa"],
    },
    "test-driven-development": {
        "observable": "有測試產出（TC/Test/spec）",
        "check_steps": [],
        "check_output_keywords": ["TC", "test", "spec", "Test", "TDD"],
        "applies_to": ["backend", "frontend"],
    },
    "using-git-worktrees": {
        "observable": "在獨立 worktree 中開發",
        "check_steps": [],
        "passive": True,  # 效果在 git 層面，trace 不一定看得到
        "applies_to": ["backend", "frontend"],
    },
    "requesting-code-review": {
        "observable": "Gate Review 有結構化審查報告",
        "check_steps": [],
        "check_output_keywords": ["RVW", "Review", "PASS", "BLOCK"],
        "applies_to": ["review"],
    },
}

def check_skill_impact(agent_name, agent_traces, existing_results):
    """檢查每個已讀 skill 是否產生可觀測效果"""
    impact_results = []

    # 收集所有 output 的 detail 文字
    all_output_text = " ".join(
        t.get("detail", "") for t in agent_traces
        if t["step"] in ("output", "output_ac", "output_scenarios", "file_modified",
                         "gate_d_result", "gate_r_result", "completion_status", "concerns")
    )

    # 收集已有的 step 名稱
    actual_steps = {t["step"] for t in agent_traces}

    # 找出此 Agent 已讀的 skill
    read_skills = set()
    for r in existing_results:
        if r["step"].startswith("skill:") and r["status"] == "pass":
            read_skills.add(r["step"].replace("skill:", ""))

    for skill_name, rule in SKILL_IMPACT_RULES.items():
        # 跳過不適用此 Agent 的 skill
        applies = rule.get("applies_to", [])
        if "_all" not in applies and agent_name not in applies:
            continue

        # 跳過 Agent 沒讀的 skill（impact 只測已讀的）
        if skill_name not in read_skills:
            continue

        is_passive = rule.get("passive", False)
        has_impact = False
        evidence = ""

        # 方法 1：檢查是否有對應的 trace step
        check_steps = rule.get("check_steps", [])
        if check_steps:
            found_steps = [s for s in check_steps if s in actual_steps]
            if found_steps:
                has_impact = True
                evidence = f"觸發了 {', '.join(found_steps)}"

        # 方法 2：檢查 output 中是否有關鍵字
        keywords = rule.get("check_output_keywords", [])
        if keywords and not has_impact:
            found_kw = [kw for kw in keywords if kw.lower() in all_output_text.lower()]
            if found_kw:
                has_impact = True
                evidence = f"產出含 '{', '.join(found_kw[:3])}'"

        # 被動 skill 特殊處理（沒觸發 = 正常，不算 fail）
        if is_passive and not has_impact:
            impact_results.append({
                "step": f"impact:{skill_name}",
                "status": "pass",
                "detail": f"🔹 被動 Skill（{rule['observable']}）— 未觸發屬正常",
                "time": "",
            })
            continue

        if has_impact:
            impact_results.append({
                "step": f"impact:{skill_name}",
                "status": "pass",
                "detail": f"🟢 有效 — {evidence}（{rule['observable']}）",
                "time": "",
            })
        else:
            impact_results.append({
                "step": f"impact:{skill_name}",
                "status": "fail",
                "detail": f"🔴 讀了但無效果 — 產出中找不到：{rule['observable']}",
                "time": "",
            })

    return impact_results

def run_audit(trace_path):
    """執行完整稽核"""
    traces = load_trace(trace_path)

    if not traces:
        return {
            "timestamp": datetime.now().isoformat(),
            "trace_file": str(trace_path),
            "status": "no_data",
            "message": "execution-trace.jsonl 為空或不存在。Agent 尚未執行或未產生 trace。",
            "agents": [],
            "overall_compliance": 0,
        }

    # 按 agent 分組
    by_agent = defaultdict(list)
    for t in traces:
        by_agent[t.get("agent", "unknown")].append(t)

    agent_results = []
    for agent_name, agent_traces in by_agent.items():
        agent_results.append(audit_agent(agent_name, agent_traces))

    total_passed = sum(a["passed"] for a in agent_results)
    total_checks = sum(a["total"] for a in agent_results)
    overall = round(total_passed / total_checks * 100, 1) if total_checks > 0 else 0

    return {
        "timestamp": datetime.now().isoformat(),
        "trace_file": str(trace_path),
        "trace_count": len(traces),
        "agents": agent_results,
        "overall_compliance": overall,
        "total_passed": total_passed,
        "total_checks": total_checks,
    }

def print_report(report):
    """輸出文字報告"""
    print("╔" + "═"*50 + "╗")
    print("║  Execution Audit Report" + " "*26 + "║")
    print("║  " + report["timestamp"][:19] + " "*29 + "║")
    print("╠" + "═"*50 + "╣")

    if report.get("status") == "no_data":
        print(f"║  ⚠️  {report['message']}")
        print("║")
        print("║  要產生 trace，Agent 執行時需輸出 [TRACE] 行，")
        print("║  或由 pipeline-orchestrator 自動記錄。")
        print("╚" + "═"*50 + "╝")
        return

    print(f"║  Trace 記錄數：{report['trace_count']}")
    print(f"║  Agent 數量：{len(report['agents'])}")
    print("╚" + "═"*50 + "╝")
    print()

    for agent in report["agents"]:
        pct = agent["compliance"]
        icon = "✅" if pct == 100 else "⚠️" if pct >= 70 else "❌"
        print(f"Agent: {agent['agent']}  — {icon} {agent['passed']}/{agent['total']} ({pct}%)")
        print("─" * 50)

        for cp in agent["checkpoints"]:
            status = "✅" if cp["status"] == "pass" else "❌"
            time_str = cp["time"][:19] if cp["time"] else ""
            print(f"  {status} {cp['step']:<25} {cp['detail'][:40]:<40} {time_str}")

        if agent["anomalies"]:
            print()
            print("  🔍 Anomalies:")
            for a in agent["anomalies"]:
                print(f"    {a['severity']} {a['name']}")

        print()

    overall = report["overall_compliance"]
    verdict = "🟢 COMPLIANT" if overall >= 90 else "🟡 PARTIAL" if overall >= 70 else "🔴 NON-COMPLIANT"
    print("═" * 50)
    print(f"Overall: {report['total_passed']}/{report['total_checks']} — {overall}% {verdict}")
    print("═" * 50)

def generate_html(report, output_path):
    """產生 HTML 報告"""
    overall = report.get("overall_compliance", 0)
    v_color = "#10B981" if overall >= 90 else "#D97706" if overall >= 70 else "#EF4444"
    v_text = "COMPLIANT" if overall >= 90 else "PARTIAL" if overall >= 70 else "NON-COMPLIANT"

    agents_html = ""
    for agent in report.get("agents", []):
        pct = agent["compliance"]
        a_color = "#10B981" if pct == 100 else "#D97706" if pct >= 70 else "#EF4444"

        rows = ""
        for cp in agent["checkpoints"]:
            s = "✅" if cp["status"] == "pass" else "❌"
            bg = "#0F291D" if cp["status"] == "pass" else "#2D1215"
            rows += f'<tr style="background:{bg}"><td>{s}</td><td><code>{cp["step"]}</code></td><td>{cp["detail"][:60]}</td><td style="color:#8B90A0">{cp["time"][:19] if cp["time"] else ""}</td></tr>'

        anomaly_html = ""
        if agent["anomalies"]:
            anomaly_html = '<div style="margin-top:8px;padding:8px;background:#2D1215;border-radius:6px;font-size:11px">'
            for a in agent["anomalies"]:
                anomaly_html += f'{a["severity"]} {a["name"]}<br>'
            anomaly_html += '</div>'

        agents_html += f'''
        <div style="margin-bottom:16px;border:1px solid #1E2535;border-radius:10px;overflow:hidden">
          <div style="padding:12px 18px;background:#141822;display:flex;align-items:center;gap:12px">
            <span style="font-size:14px;font-weight:700">{agent["agent"]}</span>
            <span style="margin-left:auto;font-weight:700;color:{a_color}">{agent["passed"]}/{agent["total"]} ({pct}%)</span>
          </div>
          <table style="width:100%;font-size:12px;border-collapse:collapse">
            <thead><tr style="background:#1A1F2E"><th style="padding:6px 12px;text-align:left;width:30px"></th><th style="padding:6px;text-align:left">Checkpoint</th><th style="padding:6px;text-align:left">Detail</th><th style="padding:6px;text-align:left;width:140px">Time</th></tr></thead>
            <tbody>{rows}</tbody>
          </table>
          {anomaly_html}
        </div>'''

    no_data_msg = ""
    if report.get("status") == "no_data":
        no_data_msg = f'<div style="text-align:center;padding:40px;color:#8B90A0;font-size:14px">⚠️ {report["message"]}<br><br>Agent 執行時需輸出 [TRACE] 行，或由 pipeline-orchestrator 自動記錄。</div>'

    html = f'''<!DOCTYPE html>
<html lang="zh-TW"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Execution Audit Report</title>
<style>*{{box-sizing:border-box;margin:0;padding:0}}body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','Microsoft JhengHei',sans-serif;background:#0B0E14;color:#E4E7EF;padding:24px}}
.hdr{{text-align:center;padding:24px 0;border-bottom:1px solid #1E2535}}.hdr h1{{font-size:18px;color:#6C5CE7}}.hdr .sub{{font-size:12px;color:#8B90A0}}
table th{{color:#8B90A0;font-weight:600;font-size:11px}}table td{{padding:6px 12px;border-top:1px solid #1E2535}}code{{background:#1E2535;padding:1px 6px;border-radius:4px;font-size:11px}}
.ring{{width:100px;height:100px;margin:20px auto}}
</style></head><body>
<div class="hdr"><h1>Execution Audit Report</h1><div class="sub">{report.get("timestamp","")[:19]}</div></div>
<div class="ring"><svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="none" stroke="#1E2535" stroke-width="6"/><circle cx="50" cy="50" r="42" fill="none" stroke="{v_color}" stroke-width="6" stroke-dasharray="{overall*2.64} 264" stroke-linecap="round" transform="rotate(-90 50 50)"/><text x="50" y="48" text-anchor="middle" fill="{v_color}" font-size="20" font-weight="800">{overall}%</text><text x="50" y="62" text-anchor="middle" fill="#8B90A0" font-size="8">{v_text}</text></svg></div>
<div style="display:flex;justify-content:center;gap:24px;margin:12px 0 24px;font-size:12px"><span>Trace: {report.get("trace_count",0)} 筆</span><span>|</span><span style="color:#10B981">Pass: {report.get("total_passed",0)}</span><span>|</span><span style="color:#EF4444">Fail: {report.get("total_checks",0)-report.get("total_passed",0)}</span></div>
{no_data_msg}{agents_html}
<div style="text-align:center;padding:16px;font-size:11px;color:#8B90A0;border-top:1px solid #1E2535;margin-top:24px">Execution Audit — AI-First Framework v2.9</div>
</body></html>'''

    Path(output_path).write_text(html)
    return str(output_path)

def main():
    parser = argparse.ArgumentParser(description="Execution Audit")
    parser.add_argument("--trace", default="execution-trace.jsonl", help="Trace 檔案路徑")
    parser.add_argument("--html", action="store_true", help="產出 HTML 報告")
    parser.add_argument("--json", action="store_true", help="產出 JSON")
    parser.add_argument("--open", action="store_true", help="自動開啟 HTML")
    args = parser.parse_args()

    report = run_audit(args.trace)
    print_report(report)

    if args.json:
        out = Path(args.trace).with_suffix('.audit.json')
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2))
        print(f"\nJSON: {out}")

    if args.html:
        out = Path(args.trace).with_suffix('.audit.html')
        generate_html(report, out)
        print(f"\nHTML: {out}")
        if args.open:
            os.system(f"open {out}")

if __name__ == "__main__":
    main()
