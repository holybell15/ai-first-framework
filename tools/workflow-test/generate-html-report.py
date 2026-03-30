#!/usr/bin/env python3
"""
從 Tier 2 JSON 結果產生互動式 HTML 報告。
用法: python3 generate-html-report.py [json_path] [--open]
"""
import json, sys, os
from pathlib import Path
from datetime import datetime

def generate(json_path, output_path=None):
    data = json.loads(Path(json_path).read_text())
    if not output_path:
        output_path = Path(json_path).with_suffix('.html')

    s = data["summary"]
    score = s["score"]
    verdict_color = "#10B981" if score >= 90 else "#D97706" if score >= 70 else "#EF4444"
    verdict_text = "PASS" if score >= 90 else "WARN" if score >= 70 else "FAIL"

    stages_html = ""
    for stage in data["stages"]:
        passed = sum(1 for t in stage["tests"] if t["status"] == "pass")
        total = len(stage["tests"])
        pct = round(passed/total*100) if total else 0
        stage_color = "#10B981" if passed == total else "#D97706"

        tests_html = ""
        for t in stage["tests"]:
            is_pass = t["status"] == "pass"
            icon = "✅" if is_pass else "❌"
            bg = "#0F291D" if is_pass else "#2D1215"
            border = "#10B98133" if is_pass else "#EF444433"

            detail_lines = []
            detail_lines.append(f'<div class="t-logic">驗證：{t.get("logic","")}</div>')
            detail_lines.append(f'<div class="t-file">檔案：<code>{t.get("file","")}</code></div>')

            found = t.get("found")
            if found and isinstance(found, dict):
                detail_lines.append(f'<div class="t-match">找到：<strong>L{found["line"]}</strong> → <code>{_esc(found["match"][:120])}</code></div>')
                if found.get("context"):
                    ctx = "\n".join(found["context"][:3])
                    detail_lines.append(f'<pre class="t-ctx">{_esc(ctx)}</pre>')
            elif t.get("exists") is not None:
                if t["exists"]:
                    detail_lines.append(f'<div class="t-match">結果：存在（{t.get("lines",0)} 行, {t.get("size",0)} bytes）</div>')
                else:
                    detail_lines.append(f'<div class="t-match" style="color:#EF4444">❌ 檔案不存在</div>')

            details = "\n".join(detail_lines)
            tests_html += f'''
            <div class="test-item" style="background:{bg};border:1px solid {border}" onclick="this.querySelector('.t-detail').classList.toggle('open')">
              <div class="t-header">
                <span class="t-icon">{icon}</span>
                <span class="t-name">{_esc(t["name"])}</span>
                <span class="t-arrow">▸</span>
              </div>
              <div class="t-detail">{details}</div>
            </div>'''

        stages_html += f'''
        <div class="stage">
          <div class="stage-header">
            <span class="stage-icon">{stage["icon"]}</span>
            <span class="stage-name">{_esc(stage["name"])}</span>
            <span class="stage-score" style="color:{stage_color}">{passed}/{total}</span>
            <div class="stage-bar"><div class="stage-fill" style="width:{pct}%;background:{stage_color}"></div></div>
          </div>
          <div class="stage-tests">{tests_html}</div>
        </div>'''

    html = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI-First Framework — Tier 2 工作流測試報告</title>
<style>
*{{box-sizing:border-box;margin:0;padding:0}}
body{{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','Microsoft JhengHei',sans-serif;background:#0B0E14;color:#E4E7EF;min-height:100vh;padding:24px}}
.header{{text-align:center;padding:32px 0;border-bottom:1px solid #1E2535}}
.header h1{{font-size:20px;color:#6C5CE7;margin-bottom:4px}}
.header .sub{{font-size:13px;color:#8B90A0}}
.score-ring{{width:120px;height:120px;margin:24px auto}}
.score-ring svg{{width:100%;height:100%}}
.score-ring .score-text{{font-size:28px;font-weight:800}}
.score-ring .score-label{{font-size:11px;fill:#8B90A0}}
.summary{{display:flex;justify-content:center;gap:32px;margin:16px 0 32px}}
.summary .s-item{{text-align:center}}
.summary .s-num{{font-size:24px;font-weight:700}}
.summary .s-label{{font-size:11px;color:#8B90A0}}
.stage{{margin-bottom:16px;border:1px solid #1E2535;border-radius:10px;overflow:hidden}}
.stage-header{{display:flex;align-items:center;gap:10px;padding:14px 18px;background:#141822;cursor:pointer}}
.stage-header:hover{{background:#1A1F2E}}
.stage-icon{{font-size:18px}}
.stage-name{{font-size:14px;font-weight:600;flex:1}}
.stage-score{{font-size:13px;font-weight:700;min-width:50px;text-align:right}}
.stage-bar{{width:80px;height:6px;background:#1E2535;border-radius:3px;overflow:hidden}}
.stage-fill{{height:100%;border-radius:3px;transition:.3s}}
.stage-tests{{padding:0 12px 12px}}
.test-item{{margin-top:8px;border-radius:8px;padding:10px 14px;cursor:pointer;transition:.15s}}
.test-item:hover{{filter:brightness(1.1)}}
.t-header{{display:flex;align-items:center;gap:8px}}
.t-icon{{font-size:14px;flex-shrink:0}}
.t-name{{font-size:12px;font-weight:600;flex:1}}
.t-arrow{{font-size:10px;color:#8B90A0;transition:.2s}}
.t-detail{{display:none;margin-top:8px;padding-top:8px;border-top:1px solid #ffffff10;font-size:11px;line-height:1.8}}
.t-detail.open{{display:block}}
.t-detail .open+.t-arrow{{transform:rotate(90deg)}}
.t-logic{{color:#8B90A0}}
.t-file{{color:#6C5CE7}}
.t-file code{{background:#1E2535;padding:1px 6px;border-radius:4px;font-size:11px}}
.t-match{{color:#10B981;margin-top:2px}}
.t-match code{{background:#10B98115;padding:1px 6px;border-radius:4px;color:#6EE7B7;font-size:11px}}
.t-ctx{{background:#0D1117;border:1px solid #1E2535;border-radius:6px;padding:8px 12px;font-size:11px;color:#8B90A0;margin-top:6px;overflow-x:auto;white-space:pre;font-family:'SF Mono','Fira Code',monospace}}
.footer{{text-align:center;padding:24px;font-size:11px;color:#8B90A0;border-top:1px solid #1E2535;margin-top:32px}}
</style>
</head>
<body>
<div class="header">
  <h1>AI-First Framework v2.9</h1>
  <div class="sub">Tier 2 工作流模擬測試 — 透明模式報告</div>
  <div class="sub">{data["timestamp"]}</div>
</div>

<div class="score-ring">
  <svg viewBox="0 0 120 120">
    <circle cx="60" cy="60" r="50" fill="none" stroke="#1E2535" stroke-width="8"/>
    <circle cx="60" cy="60" r="50" fill="none" stroke="{verdict_color}" stroke-width="8"
      stroke-dasharray="{score*3.14} 314" stroke-dashoffset="0" stroke-linecap="round"
      transform="rotate(-90 60 60)"/>
    <text x="60" y="56" text-anchor="middle" class="score-text" fill="{verdict_color}">{score}%</text>
    <text x="60" y="72" text-anchor="middle" class="score-label">{verdict_text}</text>
  </svg>
</div>

<div class="summary">
  <div class="s-item"><div class="s-num" style="color:#10B981">{s["pass"]}</div><div class="s-label">Pass</div></div>
  <div class="s-item"><div class="s-num" style="color:#EF4444">{s["fail"]}</div><div class="s-label">Fail</div></div>
  <div class="s-item"><div class="s-num" style="color:#6C5CE7">{s["total_checks"]}</div><div class="s-label">Total</div></div>
</div>

{stages_html}

<div class="footer">
  AI-First Framework Tier 2 Test Report — Generated {datetime.now().strftime("%Y-%m-%d %H:%M")}
  <br>點擊任一測試項目展開查看驗證邏輯、檔案位置和匹配內容
</div>

<script>
document.querySelectorAll('.stage-header').forEach(h=>{{
  h.addEventListener('click',()=>{{
    const tests=h.nextElementSibling;
    tests.style.display=tests.style.display==='none'?'block':'none';
  }});
}});
</script>
</body>
</html>'''

    Path(output_path).write_text(html)
    return str(output_path)

def _esc(s):
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace('"',"&quot;")

if __name__ == "__main__":
    json_path = sys.argv[1] if len(sys.argv) > 1 else "tools/workflow-test/results/tier2_latest.json"
    out = generate(json_path, "tools/workflow-test/results/tier2-report.html")
    print(f"✅ HTML 報告：{out}")
    if "--open" in sys.argv:
        os.system(f"open {out}")
