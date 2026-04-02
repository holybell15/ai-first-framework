#!/usr/bin/env python3
"""
Refresh PROJECT_DASHBOARD.data.js from the project's SSOT files.

Reads:
- memory/STATE.md
- TASKS.md
- MASTER_INDEX.md
- memory/hotfix_log.md
- memory/adoption_gap_report.md

Writes:
- PROJECT_DASHBOARD.data.js
"""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path.cwd()
STATE_PATH = ROOT / "memory" / "STATE.md"
TASKS_PATH = ROOT / "TASKS.md"
MASTER_INDEX_PATH = ROOT / "MASTER_INDEX.md"
HOTFIX_PATH = ROOT / "memory" / "hotfix_log.md"
GAP_PATH = ROOT / "memory" / "adoption_gap_report.md"
LAST_TASK_PATH = ROOT / "memory" / "last_task.md"
TEAM_PATH = ROOT / "TEAM.md"
OUTPUT_PATH = ROOT / "PROJECT_DASHBOARD.data.js"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def parse_simple_yaml_section(text: str) -> dict:
    data: dict = {}
    current_section = None
    current_list_key = None
    current_item = None

    in_yaml = False
    for raw in text.splitlines():
        line = raw.rstrip("\n")
        if line.strip() == "---":
            in_yaml = not in_yaml
            continue
        if not in_yaml:
            continue
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        stripped = line.strip()

        if indent == 0 and stripped.endswith(":"):
            current_section = stripped[:-1]
            data[current_section] = {}
            current_list_key = None
            current_item = None
            continue

        if current_section is None:
            continue

        if indent == 2 and stripped.endswith(":"):
            key = stripped[:-1]
            data[current_section][key] = []
            current_list_key = key
            current_item = None
            continue

        if indent == 2 and ":" in stripped:
            key, value = stripped.split(":", 1)
            data[current_section][key.strip()] = clean_value(value)
            current_list_key = None
            current_item = None
            continue

        if indent == 4 and stripped.startswith("- "):
            value = stripped[2:]
            if current_list_key is not None:
                if ": " in value:
                    key, val = value.split(":", 1)
                    current_item = {key.strip(): clean_value(val)}
                    data[current_section][current_list_key].append(current_item)
                else:
                    data[current_section][current_list_key].append(clean_value(value))
                    current_item = None
            continue

        if indent == 6 and current_item is not None and ":" in stripped:
            key, value = stripped.split(":", 1)
            current_item[key.strip()] = clean_value(value)

    return data


def clean_value(value: str):
    v = value.strip()
    if v.startswith('"'):
        m = re.match(r'^"([^"]*)"', v)
        if m:
            return m.group(1)
    if v.startswith("'"):
        m = re.match(r"^'([^']*)'", v)
        if m:
            return m.group(1)
    v = re.split(r"\s+#", v, maxsplit=1)[0].strip()
    if v in {"null", "Null", "NULL"}:
        return None
    if v in {"true", "false"}:
        return v
    if v.startswith("|"):
        return ""
    return v


def parse_resume_command(text: str) -> str:
    m = re.search(r"resume_command:\s*\|\n((?:  .*\n?)*)", text)
    if not m:
        return ""
    lines = [ln[2:] if ln.startswith("  ") else ln for ln in m.group(1).splitlines()]
    return "\n".join(lines).strip()


def split_markdown_sections(text: str):
    current = "ROOT"
    sections = {current: []}
    for line in text.splitlines():
        m = re.match(r"^##+\s+(.*)$", line)
        if m:
            current = m.group(1).strip()
            sections.setdefault(current, [])
        sections[current].append(line)
    return sections


def parse_markdown_table(section_text: str):
    lines = section_text.splitlines()
    tables = []
    i = 0
    while i < len(lines):
        if lines[i].strip().startswith("|") and i + 1 < len(lines) and re.match(r"^\|\s*-", lines[i + 1].strip()):
            header = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            rows = []
            i += 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                cols = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if len(cols) == len(header):
                    rows.append(dict(zip(header, cols)))
                i += 1
            tables.append(rows)
            continue
        i += 1
    return tables


def parse_tasks(text: str):
    sections = split_markdown_sections(text)
    sprint_rows = parse_markdown_table("\n".join(sections.get("目前 Sprint", [])))
    backlog_rows = parse_markdown_table("\n".join(sections.get("Backlog", [])))
    completed_rows = parse_markdown_table("\n".join(sections.get("完成記錄", [])))
    pipeline_rows = parse_markdown_table("\n".join(sections.get("Pipeline 執行記錄", [])))

    def normalize_task(row, backlog=False):
        if row.get("ID", "—") == "—":
            return None
        return {
            "id": row.get("ID", ""),
            "task": row.get("任務") or row.get("功能/任務") or "",
            "agent": row.get("負責 Agent", ""),
            "owner": row.get("@負責人", "").lstrip("@"),
            "priority": row.get("優先級", "P1" if not backlog else row.get("優先級", "P2")),
            "note": row.get("備註/交接") or row.get("備註", ""),
            "status": row.get("狀態", ""),
        }

    in_progress = [x for x in (normalize_task(r) for r in (sprint_rows[0] if sprint_rows else [])) if x]
    backlog = [x for x in (normalize_task(r, backlog=True) for r in (backlog_rows[0] if backlog_rows else [])) if x]

    pipeline_log = []
    for row in (pipeline_rows[0] if pipeline_rows else []):
        if row.get("時間", "—") in {"—", "-", ""}:
            continue
        pipeline_log.append({
            "id": row.get("Pipeline", ""),
            "agent": row.get("Pipeline", ""),
            "owner": "",
            "status": "done" if "完成" in row.get("狀態", "") or row.get("狀態", "") == "✅" else "active",
            "date": row.get("時間", ""),
            "note": row.get("產出", ""),
        })

    recent_outputs = []
    for row in (completed_rows[0] if completed_rows else [])[-5:]:
        if row.get("ID", "-") in {"-", "—", ""}:
            continue
        recent_outputs.append({
            "title": row.get("任務", row.get("ID", "輸出")),
            "detail": row.get("產出", ""),
            "date": row.get("完成日期", ""),
        })

    handoffs = []
    for match in re.finditer(r"##\s+🔁\s+交接摘要\s+—\s+([^\n]+)\n(.*?)(?=\n##\s+🔁\s+交接摘要|\Z)", text, re.S):
        date = match.group(1).strip()
        body = match.group(2)
        table_rows = parse_markdown_table(body)
        if not table_rows:
            continue
        row_map = {r.get("項目", "").replace("**", ""): r.get("內容", "") for r in table_rows[0]}
        handoffs.append({
            "date": date,
            "from": row_map.get("我是", ""),
            "to": row_map.get("交給", ""),
            "done": row_map.get("完成了", ""),
            "need_to_know": row_map.get("你需要知道", ""),
            "blockers": row_map.get("🔴 阻塞項", ""),
        })

    return in_progress, backlog, pipeline_log, recent_outputs, handoffs[:3]


def parse_master_index(text: str):
    sections = split_markdown_sections(text)
    docs = []
    section_to_folder = {
        "📋 需求文件（02_Specifications/）": "02_Specifications/",
        "🏗 系統設計文件（03_System_Design/）": "03_System_Design/",
        "🔒 合規文件（04_Compliance/）": "04_Compliance/",
        "🎨 Prototype（01_Product_Prototype/）": "01_Product_Prototype/",
        "🧪 測試報告（08_Test_Reports/）": "08_Test_Reports/",
        "🚀 上線記錄（09_Release_Records/）": "09_Release_Records/",
    }
    for title, folder in section_to_folder.items():
      for table in parse_markdown_table("\n".join(sections.get(title, []))):
            for row in table:
                if row.get("doc_id", "—") == "—":
                    continue
                maturity = row.get("成熟度", "")
                status = "✅ " + maturity if maturity in {"Approved", "Baselined"} else maturity
                docs.append({
                    "docId": row.get("doc_id", ""),
                    "file": row.get("檔名", ""),
                    "folder": folder,
                    "status": status,
                    "agent": row.get("產出 Agent", ""),
                    "date": row.get("更新日期", ""),
                    "path": folder + row.get("檔名", ""),
                })

    lifecycle_rows = parse_markdown_table("\n".join(sections.get("📊 F-code 分配登記", [])))
    feature_lifecycle = []
    feature_names = {}
    for row in (lifecycle_rows[0] if lifecycle_rows else []):
        if row.get("F-code", "—") in {"—", ""}:
            continue
        fcode = row.get("F-code", "")
        feature_names[fcode] = row.get("中文說明", "") or row.get("功能名稱", "")
        feature_lifecycle.append({
            "fcode": fcode,
            "cnName": row.get("中文說明", "") or row.get("功能名稱", ""),
            "lifecycle": row.get("Lifecycle", ""),
            "featureOwner": row.get("Feature Owner", ""),
            "decisionOwner": row.get("Decision Owner", ""),
            "pipeline": infer_pipeline_from_lifecycle(row.get("Lifecycle", "")),
            "lastGate": infer_gate_from_lifecycle(row.get("Lifecycle", "")),
            "updated": row.get("啟動日期", ""),
        })
    return docs[-12:], feature_lifecycle, feature_names


def parse_team(text: str):
    sections = split_markdown_sections(text)
    tables = parse_markdown_table("\n".join(sections.get("角色認領表", [])))
    rows = []
    agent_key_map = {
        "Task-Master": "task-master",
        "Interviewer": "interviewer",
        "PM": "pm",
        "UX": "ux",
        "Architect": "architect",
        "DBA": "dba",
        "Backend": "backend",
        "Frontend": "frontend",
        "QA": "qa",
        "Security": "security",
        "DevOps": "devops",
        "Review": "review",
    }
    for row in (tables[0] if tables else []):
        agent = row.get("Agent 角色", "")
        if agent in {"", "—"}:
            continue
        rows.append({
            "agent": agent,
            "agent_key": agent_key_map.get(agent, agent.lower()),
            "owner": row.get("負責人", ""),
            "contact": row.get("聯絡方式", ""),
            "pipeline": row.get("主要 Pipeline", ""),
        })
    return rows


def parse_last_task(text: str):
    pending = []
    tables = parse_markdown_table(text)
    if tables:
        for row in tables[0]:
            item = row.get("項目", "").replace("**", "")
            content = row.get("內容", "")
            if item == "下一步" and content not in {"", "—"}:
                pending.append({"title": "上次工作留下的下一步", "detail": content})
    for line in text.splitlines():
        m = re.match(r"^\s*\d+\.\s+(.*)$", line)
        if m:
            pending.append({"title": "待續事項", "detail": m.group(1).strip()})
    return pending[:8]


def infer_pipeline_from_lifecycle(lifecycle: str) -> str:
    mapping = {
        "需求定義中": "P01",
        "需求已收斂": "Gate 1",
        "設計中": "P02/P03",
        "工程就緒": "G4-ENG",
        "開發中": "P04",
        "驗證中": "Gate 3/P05",
        "已發佈": "P06",
    }
    base = lifecycle.split(" (")[0]
    return mapping.get(base, "—")


def infer_gate_from_lifecycle(lifecycle: str) -> str:
    if "需求已收斂" in lifecycle:
        return "Gate 1"
    if "工程就緒" in lifecycle:
        return "G4-ENG"
    if "驗證中" in lifecycle:
        return "Gate 3"
    if "已發佈" in lifecycle:
        return "L2"
    return "—"


def parse_hotfix(text: str):
    entries = []
    for match in re.finditer(r"###\s+(HF-[^\n]+)\n(.*?)(?=\n###\s+HF-|\Z)", text, re.S):
        header = match.group(1).strip()
        body = match.group(2)
        issue = re.search(r"\|\s*issue\s*\|\s*(.*?)\s*\|", body, re.I)
        severity = re.search(r"\|\s*severity\s*\|\s*(.*?)\s*\|", body, re.I)
        resolved = re.search(r"\|\s*resolved\s*\|\s*(.*?)\s*\|", body, re.I)
        if resolved and "✅" in resolved.group(1):
            continue
        entries.append({
            "id": header.split("—")[0].strip(),
            "issue": issue.group(1) if issue else "",
            "severity": severity.group(1) if severity else "",
            "resolved": resolved.group(1) if resolved else "🔄 進行中",
        })
    return entries[:5]


def parse_gap_report(text: str):
    if not text:
        return "", []
    sections = split_markdown_sections(text)
    env_lines = []
    for line in sections.get("Environment Snapshot", []):
        if line.strip().startswith("- "):
            env_lines.append(line.strip()[2:])
    summary = " / ".join(env_lines[:3])

    gaps = []
    for name in ["Now", "Next", "Later"]:
        items = []
        for line in sections.get(name, []):
            if line.strip().startswith("- ["):
                items.append(line.strip())
        if items:
            gaps.append({"section": name, "items": items[:5]})
    return summary, gaps


def build_data():
    state_text = read_text(STATE_PATH)
    state = parse_simple_yaml_section(state_text)
    resume_command = parse_resume_command(state_text)
    in_progress, backlog, pipeline_log, recent_outputs, handoffs = parse_tasks(read_text(TASKS_PATH))
    documents, feature_lifecycle, feature_names = parse_master_index(read_text(MASTER_INDEX_PATH))
    hotfixes = parse_hotfix(read_text(HOTFIX_PATH))
    gap_summary, gap_sections = parse_gap_report(read_text(GAP_PATH))
    team_roles = parse_team(read_text(TEAM_PATH))
    last_task_pending = parse_last_task(read_text(LAST_TASK_PATH))

    session = state.get("session_snapshot", {})
    team = state.get("team", {})
    focus = state.get("current_focus", {})
    gate = state.get("gate_status", {})

    blockers = []
    if focus.get("blocked_by"):
        blockers.append(focus["blocked_by"])
    blockers.extend(gate.get("blockers", []) if isinstance(gate.get("blockers"), list) else [])

    ops_queue = []
    for row in in_progress + backlog[:6]:
        ops_queue.append({
            "id": row["id"],
            "task": row["task"],
            "agent": row["agent"],
            "priority": "P1" if row["status"] == "🔄" and row["priority"] == "" else row["priority"] or "P2",
            "note": row["note"],
        })

    pending_items = list(last_task_pending)
    for row in in_progress:
        if row["owner"] or row["note"]:
            pending_items.append({
                "title": f"{row['id']} · {row['task']}",
                "detail": f"負責：{row['owner'] or row['agent']}\n狀態：{row['status'] or '進行中'}" + (f"\n備註：{row['note']}" if row["note"] else ""),
            })

    data = {
        "overview": {
            "name": session.get("project", ROOT.name),
            "type": "[專案類型]",
            "tech": "[技術棧]",
            "stage": session.get("phase", "未同步"),
            "stageNote": focus.get("doing", "未同步"),
            "updated": session.get("last_updated", "未同步"),
        },
        "inProgress": [
            {
                "id": row["id"],
                "task": row["task"],
                "agent": row["agent"],
                "owner": row["owner"],
                "priority": row["priority"] or "P1",
                "note": row["note"],
                "nextCmd": resume_command or "",
            }
            for row in in_progress if row["status"] == "🔄"
        ],
        "backlog": [
            {
                "id": row["id"],
                "task": row["task"],
                "agent": row["agent"],
                "priority": row["priority"] or "P2",
                "note": row["note"],
            }
            for row in backlog if row["status"] in {"⏳", "🔄", ""}
        ][:8],
        "pipelineLog": pipeline_log,
        "documents": documents,
        "featureLifecycle": feature_lifecycle,
        "featureNames": feature_names,
        "ops": {
            "synced_at": session.get("last_updated", "未同步"),
            "phase": session.get("phase", "未同步"),
            "current_feature": focus.get("module", "未同步"),
            "current_work": focus.get("doing", "未同步"),
            "next_action": focus.get("next_action", "未同步"),
            "current_role": team.get("current_role", "未同步"),
            "active_member": team.get("active_member", "未同步"),
            "handoff_to": team.get("handoff_to", "未同步"),
            "handoff_notified": str(team.get("handoff_notified", "false")),
            "agent_last": session.get("agent_last", "未同步"),
            "resume_command": resume_command or "未同步",
            "blockers": [b for b in blockers if b],
            "open_questions": state.get("open_questions", []),
            "files_in_progress": state.get("files_in_progress", []),
            "work_queue": ops_queue,
            "recent_outputs": recent_outputs or [
                {"title": d["docId"], "detail": d["file"], "date": d["date"]}
                for d in documents[-5:]
            ],
            "hotfixes": hotfixes,
            "team_roles": team_roles,
            "pending_items": pending_items[:8],
            "recent_handoffs": handoffs,
            "adoption_gap_summary": gap_summary,
            "adoption_gaps": gap_sections,
        },
    }
    return data


def main():
    data = build_data()
    payload = "window.PROJECT_DASHBOARD_DATA = " + json.dumps(data, ensure_ascii=False, indent=2) + ";\n"
    OUTPUT_PATH.write_text(payload, encoding="utf-8")
    print(f"Updated {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
