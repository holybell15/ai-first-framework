#!/usr/bin/env python3
"""
Phase 4: 三層測試統一 Master Report
讀取 Tier 1 / Tier 2 / Tier 3 的 JSON 結果，產出單一 HTML dashboard。

用法:
  python3 generate-master-report.py [--open]
"""
import json, sys, os, glob
from pathlib import Path
from datetime import datetime

SCRIPT_DIR  = Path(__file__).parent
RESULTS_DIR = SCRIPT_DIR / "results"

# ── 讀取各層最新結果 ──────────────────────────────────────────────────

def load_tier1():
    p = SCRIPT_DIR / "results.json"
    if not p.exists():
        return None
    return json.loads(p.read_text())

def load_tier2():
    files = sorted(glob.glob(str(RESULTS_DIR / "tier2_*.json")))
    if not files:
        return None
    return json.loads(Path(files[-1]).read_text())

def load_tier3():
    files = sorted(glob.glob(str(RESULTS_DIR / "tier3_*.json")))
    if not files:
        return None
    data = json.loads(Path(files[-1]).read_text())
    # tier3 JSON 有可能沒有 judge 分數，嘗試讀 ab-test-outputs/judge_result.json
    judge_path = SCRIPT_DIR / "ab-test-outputs" / "judge_result.json"
    if judge_path.exists():
        try:
            judge_raw = judge_path.read_text()
            import re
            m = re.search(r'\{[\s\S]*\}', judge_raw)
            if m:
                data["judge"] = json.loads(m.group())
        except Exception:
            pass
    return data

def _esc(s):
    return str(s).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")

# ── Tier 1 HTML 區塊 ──────────────────────────────────────────────────

def render_tier1(d):
    if not d:
        return '<div class="tier-empty">⚠️ Tier 1 結果未找到（先執行 run_tests.py）</div>'
    s = d["summary"]
    total = s.get("total", s["pass"] + s["fail"] + s.get("warn", 0))
    score = s.get("score", round(s["pass"] / total * 100, 1) if total else 0)
    color  = "#10B981" if score >= 90 else "#F59E0B" if score >= 70 else "#EF4444"
    verdict = "PASS" if score >= 90 else "WARN" if score >= 70 else "FAIL"
    ts = d.get("timestamp", "")[:16]

    cats_html = ""
    for cat in d.get("categories", []):
        p = sum(1 for t in cat["tests"] if t["status"] == "pass")
        f = sum(1 for t in cat["tests"] if t["status"] == "fail")
        w = sum(1 for t in cat["tests"] if t["status"] == "warn")
        n = len(cat["tests"])
        pct = round(p / n * 100) if n else 0
        bar_color = "#10B981" if f == 0 else "#EF4444"
        cats_html += f'''
        <div class="cat-row">
          <span class="cat-icon">{cat["icon"]}</span>
          <span class="cat-name">{_esc(cat["name"])}</span>
          <span class="cat-counts">
            <span class="cnt-p">{p}✅</span>
            {'<span class="cnt-f">'+str(f)+'❌</span>' if f else ''}
            {'<span class="cnt-w">'+str(w)+'⚠️</span>' if w else ''}
          </span>
          <div class="mini-bar"><div class="mini-fill" style="width:{pct}%;background:{bar_color}"></div></div>
        </div>'''

    return f'''
    <div class="tier-header">
      <div class="tier-score-ring">
        <svg viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="32" fill="none" stroke="#1E2535" stroke-width="6"/>
          <circle cx="40" cy="40" r="32" fill="none" stroke="{color}" stroke-width="6"
            stroke-dasharray="{score*2.01} 201" stroke-linecap="round" transform="rotate(-90 40 40)"/>
          <text x="40" y="36" text-anchor="middle" class="ring-num" fill="{color}">{score}%</text>
          <text x="40" y="48" text-anchor="middle" class="ring-label">{verdict}</text>
        </svg>
      </div>
      <div class="tier-meta">
        <div class="tier-stats">
          <span class="st pass">{s["pass"]} Pass</span>
          <span class="st fail">{s["fail"]} Fail</span>
          <span class="st warn">{s.get("warn",0)} Warn</span>
          <span class="st total">{total} Total</span>
        </div>
        <div class="tier-ts">{ts}</div>
      </div>
    </div>
    <div class="cat-list">{cats_html}</div>'''

# ── Tier 2 HTML 區塊 ──────────────────────────────────────────────────

def render_tier2(d):
    if not d:
        return '<div class="tier-empty">⚠️ Tier 2 結果未找到（先執行 workflow-simulation.py）</div>'
    s = d["summary"]
    score = s.get("score", 0)
    color  = "#10B981" if score >= 90 else "#F59E0B" if score >= 70 else "#EF4444"
    verdict = "PASS" if score >= 90 else "WARN" if score >= 70 else "FAIL"
    ts = d.get("timestamp", "")[:16]

    stages_html = ""
    for stage in d.get("stages", []):
        p = sum(1 for t in stage["tests"] if t["status"] == "pass")
        n = len(stage["tests"])
        pct = round(p / n * 100) if n else 0
        bar_color = "#10B981" if p == n else "#F59E0B"
        stages_html += f'''
        <div class="cat-row">
          <span class="cat-icon">{stage["icon"]}</span>
          <span class="cat-name">{_esc(stage["name"])}</span>
          <span class="cat-counts"><span class="cnt-p">{p}/{n}</span></span>
          <div class="mini-bar"><div class="mini-fill" style="width:{pct}%;background:{bar_color}"></div></div>
        </div>'''

    return f'''
    <div class="tier-header">
      <div class="tier-score-ring">
        <svg viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="32" fill="none" stroke="#1E2535" stroke-width="6"/>
          <circle cx="40" cy="40" r="32" fill="none" stroke="{color}" stroke-width="6"
            stroke-dasharray="{score*2.01} 201" stroke-linecap="round" transform="rotate(-90 40 40)"/>
          <text x="40" y="36" text-anchor="middle" class="ring-num" fill="{color}">{score}%</text>
          <text x="40" y="48" text-anchor="middle" class="ring-label">{verdict}</text>
        </svg>
      </div>
      <div class="tier-meta">
        <div class="tier-stats">
          <span class="st pass">{s["pass"]} Pass</span>
          <span class="st fail">{s["fail"]} Fail</span>
          <span class="st total">{s["total_checks"]} Total</span>
        </div>
        <div class="tier-ts">{ts}</div>
      </div>
    </div>
    <div class="cat-list">{stages_html}</div>'''

# ── Tier 3 HTML 區塊 ──────────────────────────────────────────────────

def render_tier3(d):
    if not d:
        return '<div class="tier-empty">⚠️ Tier 3 結果未找到（先執行 workflow-ab-test.py）</div>'

    ts = d.get("timestamp", "")[:16]
    judge = d.get("judge", {})
    winner = judge.get("winner", "?")
    a_total = judge.get("a_total", "?")
    b_total = judge.get("b_total", "?")
    verdict_text = judge.get("verdict", "—")
    winner_label = "🏆 B（新流程）" if winner == "B" else "⚠️ A（舊流程）" if winner == "A" else "= 平手"
    winner_color = "#10B981" if winner == "B" else "#EF4444" if winner == "A" else "#F59E0B"

    dims = [
        ("完整度", "completeness"),
        ("一致性", "consistency"),
        ("可開發性", "developability"),
        ("可測試性", "testability"),
        ("Scope控制", "scope_control"),
        ("邊界覆蓋", "edge_coverage"),
    ]
    rows = ""
    a_scores = judge.get("a_scores", {})
    b_scores = judge.get("b_scores", {})
    for zh, key in dims:
        a = a_scores.get(key, "?")
        b = b_scores.get(key, "?")
        try:
            ind = "🟢" if int(b) > int(a) else "🔴" if int(b) < int(a) else "="
        except (ValueError, TypeError):
            ind = "?"
        rows += f'<tr><td>{zh}</td><td class="sc">{a}</td><td class="sc">{b}</td><td>{ind}</td></tr>'

    diffs_html = ""
    for diff in judge.get("key_differences", []):
        diffs_html += f'<li>{_esc(diff)}</li>'

    stats = d.get("stats", {})
    stat_rows = ""
    for metric, vals in stats.items():
        a_v = vals.get("a", "?")
        b_v = vals.get("b", "?")
        stat_rows += f'<tr><td>{_esc(metric)}</td><td class="sc">{a_v}</td><td class="sc">{b_v}</td></tr>'

    return f'''
    <div class="tier-header">
      <div class="tier-score-ring" style="width:auto;padding:8px 16px;text-align:center">
        <div style="font-size:28px;font-weight:800;color:{winner_color}">{winner_label}</div>
        <div style="font-size:13px;color:#8B90A0;margin-top:4px">{a_total} vs {b_total}</div>
      </div>
      <div class="tier-meta">
        <div style="font-size:12px;color:#E4E7EF;line-height:1.6">{_esc(verdict_text)}</div>
        <div class="tier-ts">{ts}</div>
      </div>
    </div>

    <div class="ab-grid">
      <div class="ab-section">
        <h4>評分比對</h4>
        <table class="ab-table">
          <thead><tr><th>維度</th><th>A 舊</th><th>B 新</th><th></th></tr></thead>
          <tbody>{rows}</tbody>
          <tfoot><tr><td><strong>總分</strong></td><td class="sc total-sc">{a_total}</td><td class="sc total-sc">{b_total}</td><td></td></tr></tfoot>
        </table>
      </div>
      <div class="ab-section">
        <h4>基本統計</h4>
        <table class="ab-table">
          <thead><tr><th>指標</th><th>A 舊</th><th>B 新</th></tr></thead>
          <tbody>{stat_rows}</tbody>
        </table>
      </div>
    </div>

    {'<div class="diff-list"><h4>關鍵差異</h4><ul>' + diffs_html + '</ul></div>' if diffs_html else ''}
    '''

# ── 主程式 ────────────────────────────────────────────────────────────

def main():
    t1 = load_tier1()
    t2 = load_tier2()
    t3 = load_tier3()

    t1_score = t1["summary"].get("score", 0) if t1 else 0
    t2_score = t2["summary"].get("score", 0) if t2 else 0
    t3_winner = (t3 or {}).get("judge", {}).get("winner", "?") if t3 else "?"
    overall = round((t1_score + t2_score) / 2, 1)
    overall_color = "#10B981" if overall >= 90 else "#F59E0B" if overall >= 70 else "#EF4444"

    html = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI-First Framework — 工作流品質測試 Master Report</title>
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','Microsoft JhengHei',sans-serif;background:#0B0E14;color:#E4E7EF;min-height:100vh}}
.topbar{{background:#141822;border-bottom:1px solid #1E2535;padding:16px 32px;display:flex;align-items:center;gap:16px}}
.topbar h1{{font-size:16px;font-weight:700;color:#E4E7EF}}
.topbar .ver{{font-size:12px;color:#6C5CE7;background:#6C5CE720;padding:2px 8px;border-radius:4px}}
.topbar .ts{{font-size:11px;color:#8B90A0;margin-left:auto}}
.hero{{text-align:center;padding:32px 24px;border-bottom:1px solid #1E2535}}
.hero .overall-label{{font-size:12px;color:#8B90A0;margin-bottom:8px}}
.hero .overall-score{{font-size:48px;font-weight:900;color:{overall_color}}}
.hero .tier-badges{{display:flex;justify-content:center;gap:24px;margin-top:16px;flex-wrap:wrap}}
.badge{{display:flex;flex-direction:column;align-items:center;background:#141822;border:1px solid #1E2535;border-radius:10px;padding:12px 20px;min-width:120px}}
.badge .b-tier{{font-size:11px;color:#8B90A0;margin-bottom:4px}}
.badge .b-score{{font-size:20px;font-weight:800}}
.badge .b-label{{font-size:11px;color:#8B90A0;margin-top:2px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:24px;padding:24px 32px;max-width:1400px;margin:0 auto}}
.tier-card{{background:#141822;border:1px solid #1E2535;border-radius:12px;overflow:hidden}}
.tier-title{{padding:14px 18px;background:#0D1117;border-bottom:1px solid #1E2535;display:flex;align-items:center;gap:10px}}
.tier-title .num{{font-size:13px;font-weight:700;color:#6C5CE7;background:#6C5CE720;padding:2px 8px;border-radius:4px}}
.tier-title .name{{font-size:14px;font-weight:600}}
.tier-body{{padding:16px 18px}}
.tier-header{{display:flex;gap:16px;align-items:flex-start;margin-bottom:16px}}
.tier-score-ring{{width:80px;flex-shrink:0}}
.tier-meta{{flex:1}}
.tier-stats{{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:6px}}
.st{{font-size:12px;font-weight:600;padding:2px 8px;border-radius:4px}}
.st.pass{{background:#10B98120;color:#10B981}}
.st.fail{{background:#EF444420;color:#EF4444}}
.st.warn{{background:#F59E0B20;color:#F59E0B}}
.st.total{{background:#6C5CE720;color:#6C5CE7}}
.tier-ts{{font-size:11px;color:#8B90A0}}
.ring-num{{font-size:16px;font-weight:800}}
.ring-label{{font-size:9px;fill:#8B90A0}}
.cat-list{{display:flex;flex-direction:column;gap:6px}}
.cat-row{{display:flex;align-items:center;gap:8px;padding:6px 8px;border-radius:6px;background:#0D1117}}
.cat-icon{{font-size:14px;flex-shrink:0}}
.cat-name{{font-size:11px;flex:1;color:#C8CADB}}
.cat-counts{{display:flex;gap:6px;font-size:11px;font-weight:600;flex-shrink:0}}
.cnt-p{{color:#10B981}}.cnt-f{{color:#EF4444}}.cnt-w{{color:#F59E0B}}
.mini-bar{{width:60px;height:4px;background:#1E2535;border-radius:2px;overflow:hidden;flex-shrink:0}}
.mini-fill{{height:100%;border-radius:2px}}
.tier-empty{{color:#8B90A0;font-size:12px;padding:16px;text-align:center}}
.ab-grid{{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px}}
.ab-section h4{{font-size:12px;color:#8B90A0;margin-bottom:8px}}
.ab-table{{width:100%;border-collapse:collapse;font-size:11px}}
.ab-table th{{padding:5px 8px;background:#0D1117;color:#8B90A0;font-weight:600;text-align:left;border-bottom:1px solid #1E2535}}
.ab-table td{{padding:5px 8px;border-bottom:1px solid #1E253550}}
.sc{{text-align:center;font-weight:700}}
.total-sc{{color:#6C5CE7;font-size:13px}}
.diff-list h4{{font-size:12px;color:#8B90A0;margin-bottom:8px}}
.diff-list ul{{padding-left:16px}}
.diff-list li{{font-size:11px;line-height:1.7;color:#C8CADB;margin-bottom:4px}}
.footer{{text-align:center;padding:24px;font-size:11px;color:#8B90A0;border-top:1px solid #1E2535;margin-top:8px}}
@media(max-width:800px){{.grid{{grid-template-columns:1fr}}.ab-grid{{grid-template-columns:1fr}}}}
</style>
</head>
<body>

<div class="topbar">
  <h1>AI-First Framework</h1>
  <span class="ver">v2.9</span>
  <span style="color:#8B90A0;font-size:12px">工作流品質測試 Master Report</span>
  <span class="ts">Generated {datetime.now().strftime("%Y-%m-%d %H:%M")}</span>
</div>

<div class="hero">
  <div class="overall-label">Tier 1 + Tier 2 平均分</div>
  <div class="overall-score">{overall}%</div>
  <div class="tier-badges">
    <div class="badge">
      <span class="b-tier">Tier 1</span>
      <span class="b-score" style="color:{'#10B981' if t1_score>=90 else '#F59E0B' if t1_score>=70 else '#EF4444'}">{t1_score}%</span>
      <span class="b-label">結構驗證</span>
    </div>
    <div class="badge">
      <span class="b-tier">Tier 2</span>
      <span class="b-score" style="color:{'#10B981' if t2_score>=90 else '#F59E0B' if t2_score>=70 else '#EF4444'}">{t2_score}%</span>
      <span class="b-label">流程模擬</span>
    </div>
    <div class="badge">
      <span class="b-tier">Tier 3</span>
      <span class="b-score" style="color:{'#10B981' if t3_winner=='B' else '#EF4444' if t3_winner=='A' else '#F59E0B'}">{'B 勝' if t3_winner=='B' else 'A 勝' if t3_winner=='A' else '未執行'}</span>
      <span class="b-label">A/B 品質比對</span>
    </div>
  </div>
</div>

<div class="grid">
  <div class="tier-card">
    <div class="tier-title">
      <span class="num">Tier 1</span>
      <span class="name">結構驗證 — Agent / Skill / Pipeline 完整性</span>
    </div>
    <div class="tier-body">{render_tier1(t1)}</div>
  </div>

  <div class="tier-card">
    <div class="tier-title">
      <span class="num">Tier 2</span>
      <span class="name">流程模擬 — 模板 / Seed / Skill 內容驗證</span>
    </div>
    <div class="tier-body">{render_tier2(t2)}</div>
  </div>

  <div class="tier-card" style="grid-column:1/-1">
    <div class="tier-title">
      <span class="num">Tier 3</span>
      <span class="name">A/B 品質比對 — LLM-as-Judge 新舊流程評分</span>
    </div>
    <div class="tier-body">{render_tier3(t3)}</div>
  </div>
</div>

<div class="footer">
  AI-First Framework 三層工作流品質測試 — 一鍵執行：<code>bash tools/workflow-test/run-all-tests.sh</code>
</div>

</body>
</html>'''

    out = RESULTS_DIR / "master-report.html"
    out.write_text(html)
    print(f"✅ Master Report：{out}")
    return str(out)

if __name__ == "__main__":
    RESULTS_DIR.mkdir(exist_ok=True)
    path = main()
    if "--open" in sys.argv:
        os.system(f"open '{path}'")
