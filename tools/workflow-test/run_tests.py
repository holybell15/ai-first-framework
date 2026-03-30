#!/usr/bin/env python3
"""
AICC-X Workflow Test Runner
執行所有 agent / skill / pipeline 設定驗證，產出視覺化測試報告。
用法: python3 run_tests.py [--open]
"""

import os, re, json, sys, subprocess
from datetime import datetime
from pathlib import Path

AGENTS_DIR  = Path.home() / ".claude/agents"
SKILLS_DIR  = Path.home() / ".claude/skills"
SCRIPT_DIR  = Path(__file__).parent
HTML_OUTPUT = SCRIPT_DIR / "index.html"

# ── 期望設定 ────────────────────────────────────────────────────────
PIPELINE_CONFIG = {
    "P00 需求建立": {
        "agents": ["aicc-interviewer", "aicc-pm"],
        "skills": ["brainstorming", "forced-thinking", "verification-before-completion"],
        "gate_agent": None,
        "gate_skill": None,
        "confirms": ["C0", "C1", "C2"],
        "templates": ["TEMPLATE_SRS_Complete.md", "TEMPLATE_RS_Function_Spec.md"],
    },
    "P01 精煉+Prototype": {
        "agents": ["aicc-pm", "aicc-ux"],
        "skills": ["frontend-design", "verification-before-completion"],
        "gate_agent": "gate-reviewer",
        "gate_skill": "quality-gates",
    },
    "P02 技術設計": {
        "agents": ["aicc-architect", "aicc-dba", "aicc-review"],
        "skills": ["deep-research", "brainstorming", "forced-thinking", "verification-before-completion"],
        "gate_agent": "gate-reviewer",
        "gate_skill": "quality-gates",
        "extra_outputs": ["SLICE-BACKLOG"],
    },
    "P03+P04 Slice Cycle": {
        "agents": ["aicc-backend", "aicc-frontend", "aicc-qa", "aicc-review"],
        "skills": ["slice-cycle", "test-driven-development", "using-git-worktrees",
                   "finishing-a-development-branch", "systematic-debugging",
                   "destructive-guard", "webapp-testing", "verification-before-completion"],
        "gate_agent": "gate-reviewer",
        "gate_skill": "quality-gates",
        "gates": ["G4-ENG-D", "G4-ENG-R", "Cross-Slice-IC"],
    },
    "P05 合規審查": {
        "agents": ["aicc-security", "aicc-review"],
        "skills": ["deep-research", "quality-gates"],
        "gate_agent": None,
        "gate_skill": None,
    },
    "P06 部署上線": {
        "agents": ["aicc-devops", "aicc-review"],
        "skills": ["deep-research", "verification-before-completion",
                   "info-canary", "info-doc-sync", "quantitative-retro"],
        "gate_agent": "retrospective-facilitator",
        "gate_skill": "retro",
    },
}

AGENT_SKILL_MAP = {
    "aicc-interviewer": ["brainstorming", "forced-thinking", "verification-before-completion"],
    "aicc-pm":          ["brainstorming", "forced-thinking", "verification-before-completion"],
    "aicc-ux":          ["frontend-design", "brainstorming", "verification-before-completion"],
    "aicc-architect":   ["deep-research", "brainstorming", "forced-thinking", "verification-before-completion"],
    "aicc-dba":         ["deep-research", "verification-before-completion"],
    "aicc-backend":     ["test-driven-development", "using-git-worktrees",
                         "finishing-a-development-branch", "systematic-debugging",
                         "destructive-guard", "verification-before-completion"],
    "aicc-frontend":    ["test-driven-development", "using-git-worktrees",
                         "finishing-a-development-branch", "frontend-design",
                         "systematic-debugging", "destructive-guard", "verification-before-completion"],
    "aicc-qa":          ["webapp-testing", "test-driven-development",
                         "systematic-debugging", "verification-before-completion"],
    "aicc-security":    ["deep-research", "verification-before-completion"],
    "aicc-devops":      ["deep-research", "verification-before-completion",
                         "info-canary", "info-doc-sync"],
    "aicc-review":      ["requesting-code-review", "quality-gates", "slice-cycle",
                         "verification-before-completion"],
}

# v2.9 新增：必須存在的 skills（框架級）
FRAMEWORK_SKILLS = [
    "slice-cycle", "info-ship", "info-canary", "info-doc-sync",
    "quantitative-retro", "forced-thinking", "destructive-guard",
    "planning-with-files", "pipeline-orchestrator",
]

# v2.9 新增：必須存在的模板
FRAMEWORK_TEMPLATES = [
    "02_Specifications/TEMPLATE_SRS_Complete.md",
    "02_Specifications/TEMPLATE_RS_Function_Spec.md",
    "02_Specifications/TEMPLATE_P00_Product_Vision.md",
]

FRAMEWORK_DOCS = [
    ("docs/LITE_MODE.md", "Lite Mode guide"),
    ("docs/ROADMAP_PRIORITIES.md", "Priority roadmap"),
    ("docs/INFORMATION_ARCHITECTURE.md", "Information architecture"),
    ("docs/START_HERE.md", "Start here guide"),
    ("docs/VALIDATION_REPAIR.md", "Validation repair guide"),
    ("project-template/START_HERE.md", "Project template start guide"),
]

SUPPORT_AGENTS = [
    "code-grounder", "data-contract-validator", "gate-reviewer",
    "retrospective-facilitator", "ssot-guardian", "doc-generator",
    "task-master",
]

SUPPORT_AGENT_TRIGGERS = {
    "code-grounder":             "ground",
    "data-contract-validator":   "validate-contract",
    "gate-reviewer":             "gate-check",
    "retrospective-facilitator": "retro",
    "ssot-guardian":             "ssot-guardian",
    "doc-generator":             "new-doc",
    "task-master":               None,   # 由 description 觸發，無獨立 skill
}

HOTFIX_PIPELINE_AGENTS  = ["aicc-review", "aicc-backend", "aicc-frontend", "aicc-devops"]
BROWNFIELD_PIPELINE_AGENTS = ["aicc-architect", "aicc-dba", "aicc-pm", "aicc-review", "aicc-devops"]

# Slash commands expected in project-template/.claude/commands/
EXPECTED_PROJECT_COMMANDS = [
    "info-init", "info-health", "info-setup-team", "info-pipeline", "info-gate",
    "info-hotfix", "info-progress", "info-pause", "info-handoff", "info-complete-milestone", "info-quick",
]
EXPECTED_GLOBAL_COMMANDS = ["resume"]

# Framework directory (two levels up from this script)
FRAMEWORK_DIR  = Path(__file__).parent.parent.parent
TEMPLATE_DIR   = FRAMEWORK_DIR / "project-template"
COMMANDS_DIR   = TEMPLATE_DIR / ".claude" / "commands"
GLOBAL_CMDS_DIR = Path.home() / ".claude" / "commands"

PIPELINE_SKILL = "pipeline-orchestrator"

LOCAL_FRAMEWORK_DIR = FRAMEWORK_DIR

# ── 工具函式 ────────────────────────────────────────────────────────
def read_frontmatter(filepath):
    """讀取 markdown frontmatter，回傳 dict"""
    try:
        content = filepath.read_text(encoding="utf-8")
        m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
        if not m:
            return {}
        fm = {}
        for line in m.group(1).splitlines():
            if ':' in line:
                k, _, v = line.partition(':')
                fm[k.strip()] = v.strip()
        return fm
    except Exception as e:
        return {"_error": str(e)}

def agent_exists(name):
    return (AGENTS_DIR / f"{name}.md").exists()

def skill_exists(name):
    return (SKILLS_DIR / name / "SKILL.md").exists()

def agent_description(name):
    p = AGENTS_DIR / f"{name}.md"
    if not p.exists():
        return ""
    fm = read_frontmatter(p)
    return fm.get("description", "")

# ── 測試執行 ────────────────────────────────────────────────────────
results = {
    "timestamp": datetime.now().isoformat(),
    "summary": {"pass": 0, "fail": 0, "warn": 0},
    "categories": []
}

def make_test(name, status, detail="", hint=""):
    """status: pass | fail | warn"""
    results["summary"][status] += 1
    return {"name": name, "status": status, "detail": detail, "hint": hint}

# ── 1. AICC Agent 存在性 ─────────────────────────────────────────────
cat1 = {"name": "AICC Agents 存在性", "icon": "🤖", "tests": []}
for agent in AGENT_SKILL_MAP:
    if agent_exists(agent):
        fm = read_frontmatter(AGENTS_DIR / f"{agent}.md")
        missing = [f for f in ("name","description","tools","color") if f not in fm]
        if missing:
            cat1["tests"].append(make_test(
                agent, "warn",
                f"存在但缺少欄位: {', '.join(missing)}",
                "補充 frontmatter 欄位"))
        else:
            cat1["tests"].append(make_test(agent, "pass", fm.get("color","") + " | " + fm.get("tools","")))
    else:
        cat1["tests"].append(make_test(agent, "fail", "檔案不存在", f"建立 {AGENTS_DIR}/{agent}.md"))
results["categories"].append(cat1)

# ── 2. AICC Agent Description 內容品質 ──────────────────────────────
cat2 = {"name": "Agent Description 品質", "icon": "📝", "tests": []}
next_map = {
    "aicc-interviewer": "aicc-pm",
    "aicc-pm": "aicc-ux",
    "aicc-ux": "gate-reviewer",
    "aicc-architect": "aicc-dba",
    "aicc-dba": "aicc-backend",
    "aicc-backend": "aicc-frontend",
    "aicc-frontend": "aicc-qa",
    "aicc-qa": "gate-reviewer",
    "aicc-security": "aicc-review",
    "aicc-devops": "aicc-review",
}
for agent, expected_skills in AGENT_SKILL_MAP.items():
    if not agent_exists(agent):
        cat2["tests"].append(make_test(f"{agent} description", "fail", "agent 不存在"))
        continue
    desc = agent_description(agent)
    issues = []
    # 檢查 skill 提及
    missing_skills = [s for s in expected_skills if s not in desc]
    if missing_skills:
        issues.append(f"description 未提及 skills: {', '.join(missing_skills)}")
    # 檢查下一個 agent 提及
    if agent in next_map:
        next_a = next_map[agent]
        if next_a not in desc:
            issues.append(f"未提及下一步 agent: {next_a}")
    if issues:
        cat2["tests"].append(make_test(
            f"{agent} description", "warn",
            " | ".join(issues),
            "更新 description 加入 skill 和 next-agent 資訊"))
    else:
        cat2["tests"].append(make_test(f"{agent} description", "pass", "skill 和 next-agent 均有提及"))
results["categories"].append(cat2)

# ── 3. Agent-Skill 連結 ───────────────────────────────────────────────
cat3 = {"name": "Agent ↔ Skill 連結", "icon": "🔗", "tests": []}
for agent, skills in AGENT_SKILL_MAP.items():
    for skill in skills:
        if skill_exists(skill):
            cat3["tests"].append(make_test(f"{agent} → {skill}", "pass"))
        else:
            cat3["tests"].append(make_test(
                f"{agent} → {skill}", "fail",
                f"skill '{skill}' 不存在於 ~/.claude/skills/",
                f"安裝 skill: {skill}"))
results["categories"].append(cat3)

# ── 4. 支援型 Agents ──────────────────────────────────────────────────
cat4 = {"name": "支援型 Agents", "icon": "🛡️", "tests": []}
for agent in SUPPORT_AGENTS:
    if agent_exists(agent):
        trigger_skill = SUPPORT_AGENT_TRIGGERS.get(agent)
        if trigger_skill and not skill_exists(trigger_skill):
            cat4["tests"].append(make_test(
                agent, "warn",
                f"agent 存在，但對應 trigger skill '{trigger_skill}' 缺失",
                f"建立 skill: {trigger_skill}"))
        else:
            detail = f"trigger skill: {trigger_skill}" if trigger_skill else "無對應 skill"
            cat4["tests"].append(make_test(agent, "pass", detail))
    else:
        cat4["tests"].append(make_test(
            agent, "fail",
            "agent 不存在",
            f"建立 {AGENTS_DIR}/{agent}.md"))
results["categories"].append(cat4)

# ── 5. Pipeline 設定完整性 ────────────────────────────────────────────
cat5 = {"name": "Pipeline 完整性", "icon": "🔄", "tests": []}
for pipeline, cfg in PIPELINE_CONFIG.items():
    # agents
    missing_agents = [a for a in cfg["agents"] if not agent_exists(a)]
    if missing_agents:
        cat5["tests"].append(make_test(
            f"{pipeline} agents", "fail",
            f"缺少 agents: {', '.join(missing_agents)}"))
    else:
        cat5["tests"].append(make_test(f"{pipeline} agents", "pass",
            " → ".join(cfg["agents"])))
    # skills
    missing_skills = [s for s in cfg["skills"] if not skill_exists(s)]
    if missing_skills:
        cat5["tests"].append(make_test(
            f"{pipeline} skills", "warn",
            f"缺少 skills: {', '.join(missing_skills)}",
            "安裝缺失的 skills"))
    else:
        cat5["tests"].append(make_test(f"{pipeline} skills", "pass",
            ", ".join(cfg["skills"])))
    # gate
    if cfg["gate_agent"]:
        if agent_exists(cfg["gate_agent"]):
            cat5["tests"].append(make_test(f"{pipeline} gate", "pass",
                f"{cfg['gate_agent']} + {cfg['gate_skill']}"))
        else:
            cat5["tests"].append(make_test(f"{pipeline} gate", "fail",
                f"gate agent '{cfg['gate_agent']}' 缺失"))
results["categories"].append(cat5)

# ── 6. Pipeline Orchestrator Skill ───────────────────────────────────
cat6 = {"name": "Pipeline Orchestrator", "icon": "🎯", "tests": []}
if skill_exists(PIPELINE_SKILL):
    skill_content = (SKILLS_DIR / PIPELINE_SKILL / "SKILL.md").read_text()
    # 檢查是否有 * agent 名稱
    missing_refs = [a for a in AGENT_SKILL_MAP if a not in skill_content]
    if missing_refs:
        cat6["tests"].append(make_test(
            "agent 名稱引用", "warn",
            f"未提及: {', '.join(missing_refs)}",
            "更新 pipeline-orchestrator SKILL.md 加入完整 agent 名稱"))
    else:
        cat6["tests"].append(make_test("agent 名稱引用", "pass", "所有 * agents 均有引用"))
    # 檢查是否有自動觸發規則
    if "自動觸發" in skill_content or "code-grounder" in skill_content:
        cat6["tests"].append(make_test("自動觸發規則", "pass", "含 code-grounder 等自動觸發設定"))
    else:
        cat6["tests"].append(make_test("自動觸發規則", "warn",
            "未找到自動觸發規則",
            "補充 code-grounder, data-contract-validator 的觸發時機"))
else:
    cat6["tests"].append(make_test(PIPELINE_SKILL, "fail", "skill 不存在"))
results["categories"].append(cat6)

# ── 7. 缺失 Skills ────────────────────────────────────────────────────
cat7 = {"name": "已知缺失項目", "icon": "⚠️", "tests": []}
KNOWN_MISSING = {
    "screenshot-to-code": "ux, frontend 有引用此 skill，但尚未安裝",
}
for skill, reason in KNOWN_MISSING.items():
    if skill_exists(skill):
        cat7["tests"].append(make_test(skill, "pass", "已安裝"))
    else:
        cat7["tests"].append(make_test(skill, "warn", reason, f"可執行 /find-skills screenshot-to-code 搜尋"))
results["categories"].append(cat7)

# ── 8. 專家審查補強項 ─────────────────────────────────────────────────
cat8 = {"name": "專家審查補強項", "icon": "🔬", "tests": []}

SKILLS_DIR = Path.home() / ".claude" / "skills"

def check_content(rel_path, keyword, test_name, hint=""):
    if rel_path.startswith("../skills/"):
        path = SKILLS_DIR / rel_path[len("../skills/"):]
    else:
        path = AGENTS_DIR / rel_path
    if path.exists():
        content = path.read_text(encoding="utf-8")
        if keyword in content:
            cat8["tests"].append(make_test(test_name, "pass", "已實作"))
        else:
            cat8["tests"].append(make_test(test_name, "fail", f"未找到關鍵詞: {keyword[:20]}", hint))
    else:
        cat8["tests"].append(make_test(test_name, "fail", f"檔案不存在: {rel_path}", hint))

# FIX-1: Pipeline Wave 並行
check_content("../skills/pipeline-orchestrator/SKILL.md",
    "aicc-architect ∥ aicc-dba",
    "FIX-1: P02 Wave 並行格式",
    "pipeline-orchestrator/SKILL.md 需更新 P02 為 Wave 格式（Wave 1: aicc-architect ∥ aicc-dba）")
check_content("../skills/pipeline-orchestrator/SKILL.md",
    "aicc-backend ∥ aicc-frontend",
    "FIX-1: P03/P04 Wave 並行格式",
    "pipeline-orchestrator/SKILL.md 需更新 P03/P04 為 Wave 格式（Wave 1: aicc-backend ∥ aicc-frontend）")

# FIX-2: Performance Testing
check_content("../skills/quality-gates/SKILL.md",
    "Performance Testing",
    "FIX-2: quality-gates Performance Testing 標準",
    "quality-gates/SKILL.md 需新增 Performance Testing 區塊")
check_content("../skills/quality-gates/SKILL.md",
    "Code Coverage 門檻",
    "FIX-2: quality-gates Code Coverage >= 80%",
    "quality-gates/SKILL.md 需新增 Code Coverage 門檻")

# FIX-3: DevOps 多環境升級路徑
check_content("aicc-devops.md",
    "多環境升級路徑",
    "FIX-3: devops 多環境升級路徑",
    "aicc-devops.md 需新增 §10e 多環境升級路徑")
check_content("aicc-devops.md",
    "Production Runbook",
    "FIX-3: devops Production Runbook",
    "aicc-devops.md 需新增 Production Runbook 格式")

# FIX-4: Security Secrets Management
check_content("aicc-security.md",
    "Secrets Management 審查",
    "FIX-4: security Secrets Management 審查區塊",
    "aicc-security.md 需新增 Secrets Management 審查")
check_content("aicc-security.md",
    "Rotation 策略確認",
    "FIX-4: security Secret Rotation 策略",
    "aicc-security.md 需新增 Rotation 策略表格")

# FIX-5: Frontend Accessibility WCAG 2.1 AA
check_content("aicc-frontend.md",
    "WCAG 2.1 AA",
    "FIX-5: frontend Accessibility WCAG 2.1 AA",
    "aicc-frontend.md 需新增 Accessibility 強制規則")
check_content("aicc-frontend.md",
    "axe-core",
    "FIX-5: frontend axe-core 自動化掃描",
    "aicc-frontend.md 需說明 axe-core CI 整合")

# FIX-6: UX Accessibility
check_content("aicc-ux.md",
    "Accessibility 設計原則",
    "FIX-6: ux Accessibility 設計原則",
    "aicc-ux.md 需新增 Accessibility 設計原則區塊")
check_content("aicc-ux.md",
    "prefers-reduced-motion",
    "FIX-6: ux 動畫可關閉原則",
    "aicc-ux.md 需包含 prefers-reduced-motion 規則")

# FIX-7: Backend Feature Flag
check_content("aicc-backend.md",
    "Feature Flag 設計規則",
    "FIX-7: backend Feature Flag 設計規則",
    "aicc-backend.md 需新增 Feature Flag 設計規則")
check_content("aicc-backend.md",
    "生命週期",
    "FIX-7: backend Feature Flag 生命週期管理",
    "aicc-backend.md 需包含 Flag 生命週期（<= 2 Sprint）規則")

# planning-with-files 整合
skill_name = "planning-with-files"
if skill_exists(skill_name):
    cat8["tests"].append(make_test("planning-with-files skill 已安裝", "pass", "已安裝"))
else:
    cat8["tests"].append(make_test("planning-with-files skill 已安裝", "fail", "skill 不存在", "/find-skills planning-with-files"))

for agent_file, label in [
    ("aicc-pm.md", "pm"),
    ("aicc-architect.md", "architect"),
    ("aicc-qa.md", "qa"),
    ("aicc-devops.md", "devops"),
]:
    check_content(agent_file,
        "planning-with-files",
        f"planning-with-files 整合: {label}",
        f"{agent_file} 需在 description 和 Skill 套件中引用 planning-with-files")

check_content("../skills/pipeline-orchestrator/SKILL.md",
    "planning-with-files",
    "planning-with-files 整合: pipeline-orchestrator 自動觸發",
    "pipeline-orchestrator/SKILL.md 需在自動觸發規則中加入 planning-with-files")

results["categories"].append(cat8)

# ── 9. 10_Standards 結構驗證 ──────────────────────────────────────────
cat9 = {"name": "10_Standards 規範結構", "icon": "📐", "tests": []}
AICC_DIR = Path(os.environ.get("PROJECT_DIR", str(Path.home() / "Projects" / "AICC-X")))
STANDARDS_DIR = AICC_DIR / "10_Standards"

REQUIRED_STANDARDS = [
    ("API/STD_API_Design.md",           "API 設計規範"),
    ("API/Error_Code_Standard_v1.0.md", "API 錯誤碼標準"),
    ("DB/STD_DB_Schema.md",             "DB Schema 規範"),
    ("DB/enum_registry.yaml",           "ENUM Registry（全域 SSOT）"),
    ("DB/field_registry_template.yaml", "Field Registry 模板"),
    ("UI/STD_UI_Design.md",             "UI 設計規範"),
    ("UI/Design_Token_Reference.md",    "Design Token 速查表"),
]

for rel, label in REQUIRED_STANDARDS:
    path = STANDARDS_DIR / rel
    if path.exists():
        size = path.stat().st_size
        cat9["tests"].append(make_test(f"10_Standards/{rel}", "pass", f"存在（{size} bytes）"))
    else:
        cat9["tests"].append(make_test(f"10_Standards/{rel}", "fail", f"檔案不存在", f"需建立 {rel}"))

# 驗證 contracts/README.md 已更新指向 10_Standards/DB/
contracts_readme = AICC_DIR / "contracts" / "README.md"
if contracts_readme.exists():
    content = contracts_readme.read_text(encoding="utf-8")
    if "10_Standards/DB" in content:
        cat9["tests"].append(make_test("contracts/README.md 指向 10_Standards/DB", "pass", "已更新"))
    else:
        cat9["tests"].append(make_test("contracts/README.md 指向 10_Standards/DB", "fail", "未更新", "需更新 contracts/README.md"))
else:
    cat9["tests"].append(make_test("contracts/README.md 存在", "fail", "檔案不存在"))

# 驗證 04_Compliance/ 已移除 Error_Code_Standard（避免 SSOT 重複）
old_path = AICC_DIR / "04_Compliance" / "Error_Code_Standard_v1.0.md"
if old_path.exists():
    cat9["tests"].append(make_test("Error_Code_Standard 已從 04_Compliance 移除", "warn",
        "舊路徑仍存在，建議刪除避免 SSOT 重複", "rm 04_Compliance/Error_Code_Standard_v1.0.md"))
else:
    cat9["tests"].append(make_test("Error_Code_Standard 已從 04_Compliance 移除", "pass", "舊路徑已清除"))

results["categories"].append(cat9)

# ── 10. Slash Commands 完整性 ─────────────────────────────────────────
cat10 = {"name": "Slash Commands 完整性", "icon": "⚡", "tests": []}

for cmd in EXPECTED_PROJECT_COMMANDS:
    path = COMMANDS_DIR / f"{cmd}.md"
    if path.exists():
        size = path.stat().st_size
        cat10["tests"].append(make_test(
            f"/{cmd}", "pass", f"project-template/.claude/commands/{cmd}.md ({size} bytes)"))
    else:
        cat10["tests"].append(make_test(
            f"/{cmd}", "fail",
            f"缺少 project-template/.claude/commands/{cmd}.md",
            f"建立 {COMMANDS_DIR}/{cmd}.md"))

for cmd in EXPECTED_GLOBAL_COMMANDS:
    path = GLOBAL_CMDS_DIR / f"{cmd}.md"
    if path.exists():
        size = path.stat().st_size
        cat10["tests"].append(make_test(
            f"/{cmd} (global)", "pass", f"~/.claude/commands/{cmd}.md ({size} bytes)"))
    else:
        cat10["tests"].append(make_test(
            f"/{cmd} (global)", "fail",
            f"缺少 ~/.claude/commands/{cmd}.md",
            f"建立 {GLOBAL_CMDS_DIR}/{cmd}.md"))

results["categories"].append(cat10)

# ── 11. Pipeline 觸發詞一致性 ─────────────────────────────────────────
cat11 = {"name": "Pipeline 觸發詞一致性", "icon": "🎯", "tests": []}

orchestrator_path = SKILLS_DIR / PIPELINE_SKILL / "SKILL.md"
if orchestrator_path.exists():
    orch_content = orchestrator_path.read_text(encoding="utf-8")
    for pipeline_name in PIPELINE_CONFIG:
        # 只取 P0x 後的中文名稱部分（去掉 "P01 "前綴）
        short_name = pipeline_name.split(" ", 1)[1] if " " in pipeline_name else pipeline_name
        if pipeline_name in orch_content or short_name in orch_content:
            cat11["tests"].append(make_test(
                f"{pipeline_name} 觸發詞", "pass", f"orchestrator 有引用"))
        else:
            cat11["tests"].append(make_test(
                f"{pipeline_name} 觸發詞", "warn",
                f"pipeline-orchestrator/SKILL.md 未提及 '{short_name}'",
                "更新 SKILL.md 加入此 Pipeline 觸發詞"))

    # 檢查 Hotfix 觸發詞
    if "Hotfix" in orch_content or "hotfix" in orch_content:
        cat11["tests"].append(make_test("Hotfix Pipeline 觸發詞", "pass", "orchestrator 有引用"))
    else:
        cat11["tests"].append(make_test("Hotfix Pipeline 觸發詞", "warn",
            "pipeline-orchestrator/SKILL.md 未提及 Hotfix",
            "加入 Hotfix Pipeline 段落"))

    # 檢查 Brownfield 觸發詞
    if "Brownfield" in orch_content or "舊專案" in orch_content:
        cat11["tests"].append(make_test("Brownfield 觸發詞", "pass", "orchestrator 有引用"))
    else:
        cat11["tests"].append(make_test("Brownfield 觸發詞", "warn",
            "pipeline-orchestrator/SKILL.md 未提及 Brownfield / 舊專案",
            "加入 Brownfield 引入段落"))
else:
    cat11["tests"].append(make_test(
        PIPELINE_SKILL, "fail", "skill 不存在，無法驗證觸發詞"))

results["categories"].append(cat11)

# ── 12. Framework Agents 完整性 ──────────────────────────────────────
cat12 = {"name": "Framework Agents 完整性", "icon": "🏗️", "tests": []}

# Hotfix pipeline agents
for agent in HOTFIX_PIPELINE_AGENTS:
    if agent_exists(agent):
        cat12["tests"].append(make_test(f"Hotfix: {agent}", "pass", "agent 存在"))
    else:
        cat12["tests"].append(make_test(f"Hotfix: {agent}", "fail",
            f"Hotfix Pipeline 需要此 agent",
            f"建立 {AGENTS_DIR}/{agent}.md"))

# Brownfield pipeline agents
for agent in BROWNFIELD_PIPELINE_AGENTS:
    if agent_exists(agent):
        cat12["tests"].append(make_test(f"Brownfield: {agent}", "pass", "agent 存在"))
    else:
        cat12["tests"].append(make_test(f"Brownfield: {agent}", "fail",
            f"Brownfield 引入需要此 agent",
            f"建立 {AGENTS_DIR}/{agent}.md"))

# task-master description 品質
tm_desc = agent_description("task-master")
tm_keywords = ["TASKS.md", "STATE.md", "dispatch", "派", "優先", "block"]
missing_kw = [kw for kw in tm_keywords if kw not in tm_desc]
if not agent_exists("task-master"):
    cat12["tests"].append(make_test(
        "task-master 存在", "fail",
        "task-master agent 不存在",
        f"建立 {AGENTS_DIR}/task-master.md"))
elif missing_kw:
    cat12["tests"].append(make_test(
        "task-master description 品質", "warn",
        f"description 缺少關鍵詞: {', '.join(missing_kw)}",
        "更新 description 說明 TASKS.md / STATE.md / 派遣流程"))
else:
    cat12["tests"].append(make_test(
        "task-master description 品質", "pass",
        "包含 TASKS.md / STATE.md / 優先排序 / block 等關鍵觸發詞"))

results["categories"].append(cat12)

# ── 13. Framework Productization Docs ─────────────────────────────────
cat13 = {"name": "Framework Productization Docs", "icon": "🧭", "tests": []}
for rel, label in FRAMEWORK_DOCS:
    path = LOCAL_FRAMEWORK_DIR / rel
    if path.exists():
        cat13["tests"].append(make_test(label, "pass", rel))
    else:
        cat13["tests"].append(make_test(label, "fail", f"缺少 {rel}", f"建立 {rel}"))

readme_path = LOCAL_FRAMEWORK_DIR / "README.md"
if readme_path.exists():
    readme_content = readme_path.read_text(encoding="utf-8")
    for keyword in ("Lite Mode", "validate-framework", "START_HERE"):
        if keyword in readme_content:
            cat13["tests"].append(make_test(f"README 引用 {keyword}", "pass"))
        else:
            cat13["tests"].append(make_test(f"README 引用 {keyword}", "warn", f"README 未提及 {keyword}"))
else:
    cat13["tests"].append(make_test("README.md 存在", "fail", "README.md 不存在"))
results["categories"].append(cat13)

# ── 14. Information Architecture Boundaries ───────────────────────────
cat14 = {"name": "Information Architecture Boundaries", "icon": "🗂️", "tests": []}
boundary_checks = [
    ("project-template/memory/STATE.md", "resume_command", "STATE resume"),
    ("project-template/TASKS.md", "交接摘要", "TASKS handoff"),
    ("project-template/MASTER_INDEX.md", "F-code 分配登記", "MASTER_INDEX f-code"),
    ("project-template/memory/decisions.md", "ADR", "decisions ADR"),
]
for rel, keyword, label in boundary_checks:
    path = LOCAL_FRAMEWORK_DIR / rel
    if not path.exists():
        cat14["tests"].append(make_test(label, "fail", f"缺少 {rel}"))
        continue
    content = path.read_text(encoding="utf-8")
    if keyword in content:
        cat14["tests"].append(make_test(label, "pass", f"找到關鍵詞 '{keyword}'"))
    else:
        cat14["tests"].append(make_test(label, "warn", f"未找到關鍵詞 '{keyword}'", f"檢查 {rel}"))
results["categories"].append(cat14)

# ── 15. Lite Mode Command Routing ────────────────────────────────────
cat15 = {"name": "Lite Mode Command Routing", "icon": "⚡", "tests": []}
lite_command_checks = [
    ("project-template/.claude/commands/info-init.md", "Lite Mode", "info-init Lite"),
    ("project-template/.claude/commands/info-pipeline.md", "Lite Mode", "info-pipeline Lite"),
    ("project-template/.claude/commands/info-task-master.md", "Lite Mode", "info-task-master Lite"),
    ("project-template/context-skills/pipeline-orchestrator/SKILL.md", "使用 Lite Mode 啟動 F01", "orchestrator Lite trigger"),
]
for rel, keyword, label in lite_command_checks:
    path = LOCAL_FRAMEWORK_DIR / rel
    if not path.exists():
        cat15["tests"].append(make_test(label, "fail", f"缺少 {rel}"))
        continue
    content = path.read_text(encoding="utf-8")
    if keyword in content:
        cat15["tests"].append(make_test(label, "pass", f"找到關鍵詞 '{keyword}'"))
    else:
        cat15["tests"].append(make_test(label, "warn", f"未找到關鍵詞 '{keyword}'", f"檢查 {rel}"))
results["categories"].append(cat15)

# ── 統計 ─────────────────────────────────────────────────────────────
total = results["summary"]["pass"] + results["summary"]["fail"] + results["summary"]["warn"]
results["summary"]["total"] = total
results["summary"]["score"] = round(
    (results["summary"]["pass"] / total * 100) if total > 0 else 0, 1)

# ── 寫入 JSON ─────────────────────────────────────────────────────────
json_path = SCRIPT_DIR / "results.json"
json_path.write_text(json.dumps(results, ensure_ascii=False, indent=2))

# ── 產出 HTML ─────────────────────────────────────────────────────────
html_template = '''<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AICC-X Workflow Test Dashboard</title>
<style>
  :root {
    --bg: #0f1117; --surface: #1a1d27; --surface2: #22263a;
    --border: #2e3250; --text: #e2e8f0; --muted: #8892b0;
    --pass: #22c55e; --fail: #ef4444; --warn: #f59e0b;
    --pass-bg: rgba(34,197,94,.1); --fail-bg: rgba(239,68,68,.1); --warn-bg: rgba(245,158,11,.1);
    --accent: #6366f1;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; min-height: 100vh; }

  header { background: var(--surface); border-bottom: 1px solid var(--border); padding: 16px 24px; display: flex; align-items: center; gap: 16px; position: sticky; top: 0; z-index: 10; }
  header h1 { font-size: 18px; font-weight: 700; }
  header .timestamp { font-size: 12px; color: var(--muted); margin-left: auto; }

  .btn { padding: 8px 16px; border-radius: 8px; border: none; cursor: pointer; font-size: 13px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px; }
  .btn-primary { background: var(--accent); color: white; }
  .btn-secondary { background: var(--surface2); color: var(--text); border: 1px solid var(--border); }
  .btn:hover { opacity: .85; }

  .main { max-width: 1100px; margin: 0 auto; padding: 24px; }

  /* Summary */
  .summary { display: grid; grid-template-columns: 1fr auto; gap: 24px; align-items: center; background: var(--surface); border: 1px solid var(--border); border-radius: 16px; padding: 24px; margin-bottom: 24px; }
  .score-ring { position: relative; width: 100px; height: 100px; }
  .score-ring svg { transform: rotate(-90deg); }
  .score-ring .score-text { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; }
  .score-text .num { font-size: 24px; font-weight: 800; }
  .score-text .label { font-size: 10px; color: var(--muted); }
  .stat-grid { display: flex; gap: 20px; }
  .stat { display: flex; flex-direction: column; gap: 4px; }
  .stat .val { font-size: 28px; font-weight: 800; }
  .stat .key { font-size: 12px; color: var(--muted); }
  .pass-val { color: var(--pass); }
  .fail-val { color: var(--fail); }
  .warn-val { color: var(--warn); }

  /* Filter */
  .filter-bar { display: flex; gap: 8px; margin-bottom: 16px; flex-wrap: wrap; }
  .filter-btn { padding: 6px 14px; border-radius: 20px; border: 1px solid var(--border); background: var(--surface); color: var(--muted); font-size: 13px; cursor: pointer; }
  .filter-btn.active { border-color: var(--accent); color: var(--accent); background: rgba(99,102,241,.1); }

  /* Category */
  .category { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 16px; overflow: hidden; }
  .cat-header { padding: 14px 20px; display: flex; align-items: center; gap: 10px; cursor: pointer; user-select: none; border-bottom: 1px solid var(--border); }
  .cat-header:hover { background: var(--surface2); }
  .cat-icon { font-size: 18px; }
  .cat-name { font-weight: 600; font-size: 14px; flex: 1; }
  .cat-badges { display: flex; gap: 6px; }
  .badge { padding: 2px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; }
  .badge-pass { background: var(--pass-bg); color: var(--pass); }
  .badge-fail { background: var(--fail-bg); color: var(--fail); }
  .badge-warn { background: var(--warn-bg); color: var(--warn); }
  .chevron { color: var(--muted); transition: transform .2s; font-size: 14px; }
  .cat-body { display: none; }
  .cat-body.open { display: block; }

  /* Test item */
  .test-item { padding: 10px 20px 10px 20px; display: grid; grid-template-columns: 16px 1fr auto; gap: 10px; align-items: start; border-bottom: 1px solid rgba(46,50,80,.5); }
  .test-item:last-child { border-bottom: none; }
  .test-item:hover { background: var(--surface2); }
  .dot { width: 8px; height: 8px; border-radius: 50%; margin-top: 5px; flex-shrink: 0; }
  .dot-pass { background: var(--pass); }
  .dot-fail { background: var(--fail); }
  .dot-warn { background: var(--warn); }
  .test-name { font-size: 13px; font-weight: 500; }
  .test-detail { font-size: 11px; color: var(--muted); margin-top: 2px; }
  .test-hint { font-size: 11px; color: var(--accent); margin-top: 2px; }
  .status-chip { font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 4px; white-space: nowrap; }
  .chip-pass { background: var(--pass-bg); color: var(--pass); }
  .chip-fail { background: var(--fail-bg); color: var(--fail); }
  .chip-warn { background: var(--warn-bg); color: var(--warn); }

  .empty { padding: 20px; text-align: center; color: var(--muted); font-size: 13px; }
</style>
</head>
<body>
<header>
  <span style="font-size:22px">⚙️</span>
  <h1>AICC-X Workflow Test Dashboard</h1>
  <span class="timestamp" id="ts"></span>
  <button class="btn btn-primary" onclick="rerun()">▶ 重新執行</button>
  <button class="btn btn-secondary" onclick="expandAll()">展開全部</button>
  <button class="btn btn-secondary" onclick="collapseAll()">收合全部</button>
</header>

<div class="main">
  <div class="summary">
    <div>
      <div style="font-size:13px;color:var(--muted);margin-bottom:12px">整體健康分數</div>
      <div class="stat-grid" id="stats"></div>
    </div>
    <div class="score-ring">
      <svg width="100" height="100" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r="40" fill="none" stroke="var(--border)" stroke-width="10"/>
        <circle id="ring" cx="50" cy="50" r="40" fill="none" stroke="var(--pass)" stroke-width="10"
          stroke-dasharray="251" stroke-dashoffset="251" stroke-linecap="round"/>
      </svg>
      <div class="score-text">
        <span class="num" id="score-num">-</span>
        <span class="label">SCORE</span>
      </div>
    </div>
  </div>

  <div class="filter-bar">
    <button class="filter-btn active" onclick="setFilter('all',this)">全部</button>
    <button class="filter-btn" onclick="setFilter('fail',this)">❌ 失敗</button>
    <button class="filter-btn" onclick="setFilter('warn',this)">⚠️ 警告</button>
    <button class="filter-btn" onclick="setFilter('pass',this)">✅ 通過</button>
  </div>

  <div id="categories"></div>
</div>

<script>
const DATA = __DATA__;
let currentFilter = 'all';

function init() {
  document.getElementById('ts').textContent = '最後執行：' + new Date(DATA.timestamp).toLocaleString('zh-TW');

  const s = DATA.summary;
  const scoreColor = s.score >= 90 ? '#22c55e' : s.score >= 70 ? '#f59e0b' : '#ef4444';
  document.getElementById('stats').innerHTML = `
    <div class="stat"><div class="val pass-val">${s.pass}</div><div class="key">通過</div></div>
    <div class="stat"><div class="val fail-val">${s.fail}</div><div class="key">失敗</div></div>
    <div class="stat"><div class="val warn-val">${s.warn}</div><div class="key">警告</div></div>
    <div class="stat"><div class="val" style="color:var(--muted)">${s.total}</div><div class="key">總計</div></div>`;

  const offset = 251 - (251 * s.score / 100);
  const ring = document.getElementById('ring');
  ring.style.strokeDashoffset = offset;
  ring.style.stroke = scoreColor;
  document.getElementById('score-num').textContent = s.score + '%';
  document.getElementById('score-num').style.color = scoreColor;

  renderCategories();
}

function renderCategories() {
  const container = document.getElementById('categories');
  container.innerHTML = '';
  DATA.categories.forEach((cat, ci) => {
    const filtered = currentFilter === 'all' ? cat.tests : cat.tests.filter(t => t.status === currentFilter);
    const counts = {pass:0,fail:0,warn:0};
    cat.tests.forEach(t => counts[t.status]++);

    const div = document.createElement('div');
    div.className = 'category';
    div.innerHTML = `
      <div class="cat-header" onclick="toggle(${ci})">
        <span class="cat-icon">${cat.icon}</span>
        <span class="cat-name">${cat.name}</span>
        <div class="cat-badges">
          ${counts.fail ? `<span class="badge badge-fail">✗ ${counts.fail}</span>` : ''}
          ${counts.warn ? `<span class="badge badge-warn">⚠ ${counts.warn}</span>` : ''}
          ${counts.pass ? `<span class="badge badge-pass">✓ ${counts.pass}</span>` : ''}
        </div>
        <span class="chevron" id="ch${ci}">▶</span>
      </div>
      <div class="cat-body ${counts.fail > 0 || counts.warn > 0 ? 'open' : ''}" id="body${ci}">
        ${filtered.length === 0 ? '<div class="empty">此分類無符合篩選條件的測試</div>' :
          filtered.map(t => `
          <div class="test-item">
            <div class="dot dot-${t.status}"></div>
            <div>
              <div class="test-name">${t.name}</div>
              ${t.detail ? `<div class="test-detail">${t.detail}</div>` : ''}
              ${t.hint ? `<div class="test-hint">💡 ${t.hint}</div>` : ''}
            </div>
            <span class="status-chip chip-${t.status}">${{pass:'PASS',fail:'FAIL',warn:'WARN'}[t.status]}</span>
          </div>`).join('')}
      </div>`;
    container.appendChild(div);
    // update chevron
    const body = document.getElementById(`body${ci}`);
    if (body.classList.contains('open')) document.getElementById(`ch${ci}`).textContent = '▼';
  });
}

function toggle(i) {
  const body = document.getElementById('body'+i);
  const ch = document.getElementById('ch'+i);
  body.classList.toggle('open');
  ch.textContent = body.classList.contains('open') ? '▼' : '▶';
}

function setFilter(f, btn) {
  currentFilter = f;
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  renderCategories();
}

function expandAll() {
  document.querySelectorAll('.cat-body').forEach(b => b.classList.add('open'));
  document.querySelectorAll('.chevron').forEach(c => c.textContent = '▼');
}

function collapseAll() {
  document.querySelectorAll('.cat-body').forEach(b => b.classList.remove('open'));
  document.querySelectorAll('.chevron').forEach(c => c.textContent = '▶');
}

function rerun() {
  const btn = document.querySelector('.btn-primary');
  btn.textContent = '⏳ 執行中...';
  btn.disabled = true;
  // 提示用戶在 terminal 執行
  alert('請在 Terminal 執行:\\n\\npython3 ~/.claude/workflow-test/run_tests.py --open\\n\\n執行完成後此頁面會自動刷新。');
  btn.textContent = '▶ 重新執行';
  btn.disabled = false;
}

init();
</script>
</body>
</html>'''

# Embed JSON into HTML
html_content = html_template.replace(
    "__DATA__",
    json.dumps(results, ensure_ascii=False)
)
HTML_OUTPUT.write_text(html_content, encoding="utf-8")

# ── 輸出摘要 ──────────────────────────────────────────────────────────
s = results["summary"]
print(f"\n{'='*50}")
print(f"AICC-X Workflow Test Results")
print(f"{'='*50}")
print(f"  ✅ PASS : {s['pass']}")
print(f"  ❌ FAIL : {s['fail']}")
print(f"  ⚠️  WARN : {s['warn']}")
print(f"  📊 Score: {s['score']}% ({s['total']} tests)")
print(f"\n  Report : {HTML_OUTPUT}")
print(f"{'='*50}\n")

# 顯示 fail 項目
fails = [(c['name'], t) for c in results['categories'] for t in c['tests'] if t['status']=='fail']
if fails:
    print("❌ Failed Tests:")
    for cat, t in fails:
        print(f"   [{cat}] {t['name']}: {t['detail']}")
        if t['hint']: print(f"           💡 {t['hint']}")
    print()

warns = [(c['name'], t) for c in results['categories'] for t in c['tests'] if t['status']=='warn']
if warns:
    print("⚠️  Warnings:")
    for cat, t in warns:
        print(f"   [{cat}] {t['name']}: {t['detail']}")
    print()

# --open flag
if "--open" in sys.argv or "-o" in sys.argv:
    try:
        subprocess.run(["open", str(HTML_OUTPUT)])
    except:
        print(f"請手動開啟: {HTML_OUTPUT}")
else:
    print(f"提示: 加上 --open 自動在瀏覽器開啟報告")
    print(f"      python3 {__file__} --open\n")
