#!/usr/bin/env python3
"""
Tier 3: A/B 品質比對測試
同一個需求「座席管理 CRUD」，用舊流程 vs 新流程各產出一份 RS，
用 LLM-as-Judge 評分比較。

用法:
  python3 workflow-ab-test.py                     # 執行 A/B 測試
  python3 workflow-ab-test.py --skip-generate     # 跳過產出，只評分已有檔案
  python3 workflow-ab-test.py --output report.json

前置條件：需要 claude CLI（npm install -g @anthropic-ai/claude-code）
"""

import os, json, sys, subprocess, argparse, time
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEMPLATE_DIR = SCRIPT_DIR.parent.parent / "project-template"
AB_DIR = SCRIPT_DIR / "ab-test-outputs"

# ═══════════════════════════════════════
# 測試需求（固定，不變）
# ═══════════════════════════════════════
TEST_REQUIREMENT = """
功能名稱：座席管理（Agent Management）
產品：AICC-II（多租戶 SaaS 客服中心平台）
角色：Tenant Admin 可管理座席帳號、Platform Admin 不可存取業務資料
技術棧：Java Spring Boot + MSSQL + Redis

需求描述：
1. 座席帳號的 CRUD（新增、查詢、編輯、刪除）
2. 綁定 SIP 分機
3. 分配技能群組和技能等級
4. 帳號啟用/停用
5. 多租戶隔離（A 租戶看不到 B 租戶的座席）
6. RBAC 權限控制

請產出此功能的需求規格。
"""

# ═══════════════════════════════════════
# Prompt A（舊流程 — 無模板、無 7 區塊、無情境覆蓋要求）
# ═══════════════════════════════════════
PROMPT_A = f"""
你是一個 PM，請根據以下需求撰寫需求規格書。
用 User Story + Acceptance Criteria 格式。

{TEST_REQUIREMENT}

直接產出需求規格，不需要問問題。
"""

# ═══════════════════════════════════════
# Prompt B（新流程 — 7 區塊模板 + 情境 + 回退 + 思維模式）
# ═══════════════════════════════════════
PROMPT_B = f"""
你是 AICC-II 產品團隊的 PM Agent。
你的產出必須嚴格遵循以下 7 區塊格式。

{TEST_REQUIREMENT}

## 強制產出格式（7 區塊，缺一不可）

### 1. 功能說明
[一段話：誰/情境/操作/目的]

### 2. 操作角色
| 操作 | Tenant Admin | 主管 | 座席 | Platform Admin |
用 ✅/❌ 標記。

### 3. 操作流程
每步寫成「使用者做 X → 系統做 Y」。

### 4. 情境描述
至少 6 種：正常 / 錯誤 / 邊界 / 降級 / 權限 / 多租戶。

### 5. 欄位/參數規格
| 欄位名稱 | 顯示名稱 | 型別 | 必填 | 限制 | 預設值 |

### 6. 條件限制
(a) 安全 (b) 合規 (c) 效能 (d) 多租戶

### 7. 驗收條件（AC）
| AC # | 驗證情境（含前置條件與操作步驟） | 預期結果 |
至少 8 條 AC，三段式。

## 額外要求
- 不得使用「適當」「合理」「良好」等模糊用語
- Phase 2 功能標記【Phase 2】
- Open Issue 用 OI-NNN 格式標記

## 重要：直接在此輸出完整文件
⚠️ 不要說「我已完成」或「以下是摘要」— 直接從 `# 座席管理 需求規格` 開始輸出完整 7 區塊文件。
"""

# ═══════════════════════════════════════
# Judge Prompt（LLM-as-Judge）
# ═══════════════════════════════════════
JUDGE_PROMPT_TEMPLATE = """
你是一個嚴格的需求規格評審。以下有兩份需求規格書（A 和 B），是同一個功能「座席管理 CRUD」的兩種寫法。
請從以下 6 個維度各評 1-5 分，並給出具體理由。

## 評分維度

1. **完整度（Completeness）**：功能覆蓋是否完整？有沒有遺漏？
2. **一致性（Consistency）**：角色、欄位、狀態在文件中是否前後一致？
3. **可開發性（Developability）**：後端工程師讀完能直接設計 API 和 Schema 嗎？
4. **可測試性（Testability）**：QA 讀完能直接寫 Test Case 嗎？AC 是否三段式？
5. **Scope 控制（Scope Control）**：MVP 邊界是否清楚？有沒有偷補需求？
6. **邊界覆蓋（Edge Coverage）**：錯誤處理、權限控制、多租戶、空值等邊界案例是否覆蓋？

## 輸出格式（JSON，不要其他文字）

{{
  "a_scores": {{"completeness": N, "consistency": N, "developability": N, "testability": N, "scope_control": N, "edge_coverage": N}},
  "b_scores": {{"completeness": N, "consistency": N, "developability": N, "testability": N, "scope_control": N, "edge_coverage": N}},
  "a_total": N,
  "b_total": N,
  "winner": "A" | "B" | "tie",
  "key_differences": [
    "差異 1: ...",
    "差異 2: ...",
    "差異 3: ..."
  ],
  "verdict": "一句話總結"
}}

## 文件 A（舊流程產出）

{doc_a}

## 文件 B（新流程產出）

{doc_b}
"""

MODEL_ALIASES = {
    "haiku":  "claude-haiku-4-5-20251001",
    "sonnet": "claude-sonnet-4-6",
    "opus":   "claude-opus-4-6",
}

def run_claude(prompt, output_file, model="haiku"):
    """用 claude CLI 產出文件"""
    model_id = MODEL_ALIASES.get(model, model)
    try:
        result = subprocess.run(
            ["claude", "-p", prompt, "--model", model_id],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode != 0 and result.stderr:
            print(f"  ⚠️ stderr: {result.stderr[:200]}")
        output_file.write_text(result.stdout)
        return bool(result.stdout.strip())
    except FileNotFoundError:
        print("❌ claude CLI 未安裝。安裝方式：npm install -g @anthropic-ai/claude-code")
        return False
    except subprocess.TimeoutExpired:
        print("❌ claude CLI 逾時（300 秒）")
        return False

def main():
    parser = argparse.ArgumentParser(description="Tier 3: A/B 品質比對")
    parser.add_argument("--skip-generate", action="store_true", help="跳過產出，只評分")
    parser.add_argument("--output", type=str, default=None, help="輸出 JSON")
    parser.add_argument("--model", type=str, default="haiku", help="LLM 模型（haiku/sonnet/opus）")
    args = parser.parse_args()

    AB_DIR.mkdir(exist_ok=True)
    doc_a_path = AB_DIR / "doc_a_old_workflow.md"
    doc_b_path = AB_DIR / "doc_b_new_workflow.md"
    judge_path = AB_DIR / "judge_result.json"

    print("═" * 60)
    print(" Tier 3: A/B 品質比對測試")
    print(f" 測試功能：座席管理 CRUD")
    print(f" 模型：{args.model}")
    print("═" * 60)

    # Step 1: 產出
    if not args.skip_generate:
        print("\n⏳ 產出文件 A（舊流程）...")
        if not run_claude(PROMPT_A, doc_a_path, args.model):
            return 1
        print(f"  ✅ 文件 A：{doc_a_path}（{doc_a_path.stat().st_size} bytes）")

        print("\n⏳ 產出文件 B（新流程）...")
        if not run_claude(PROMPT_B, doc_b_path, args.model):
            return 1
        print(f"  ✅ 文件 B：{doc_b_path}（{doc_b_path.stat().st_size} bytes）")
    else:
        if not doc_a_path.exists() or not doc_b_path.exists():
            print("❌ --skip-generate 但檔案不存在。先不帶 --skip-generate 跑一次。")
            return 1
        print(f"\n  使用已有檔案：A={doc_a_path.stat().st_size}B, B={doc_b_path.stat().st_size}B")

    # Step 2: 基本統計比較
    doc_a = doc_a_path.read_text()
    doc_b = doc_b_path.read_text()

    print("\n📊 基本統計比較：")
    stats = {
        "行數": (doc_a.count('\n'), doc_b.count('\n')),
        "字數": (len(doc_a), len(doc_b)),
        "AC 數量": (len(re.findall(r'AC-\d+', doc_a)), len(re.findall(r'AC-\d+', doc_b))),
        "情境數": (len(re.findall(r'情境\s*[A-Z]', doc_a)), len(re.findall(r'情境\s*[A-Z]', doc_b))),
        "欄位數": (doc_a.count('|') // 5, doc_b.count('|') // 5),  # 粗估
        "模糊用語": (
            len(re.findall(r'適當|合理|良好|正常', doc_a)),
            len(re.findall(r'適當|合理|良好|正常', doc_b))
        ),
    }

    print(f"  {'指標':<12} {'A（舊流程）':>12} {'B（新流程）':>12} {'差異':>12}")
    print(f"  {'─'*12} {'─'*12} {'─'*12} {'─'*12}")
    for metric, (a_val, b_val) in stats.items():
        diff = b_val - a_val
        indicator = "🟢" if diff > 0 and metric != "模糊用語" else "🔴" if diff < 0 and metric != "模糊用語" else "🟢" if diff < 0 and metric == "模糊用語" else "🔴" if diff > 0 and metric == "模糊用語" else "="
        print(f"  {metric:<12} {a_val:>12} {b_val:>12} {indicator} {diff:>+10}")

    # Step 3: LLM-as-Judge
    print("\n⏳ LLM-as-Judge 評分中...")
    judge_prompt = JUDGE_PROMPT_TEMPLATE.format(
        doc_a=doc_a[:8000],  # 限制長度
        doc_b=doc_b[:8000]
    )

    if run_claude(judge_prompt, judge_path, "sonnet"):
        try:
            # 嘗試從 judge 結果中提取 JSON
            judge_text = judge_path.read_text()
            # 找到 JSON 區塊
            json_match = re.search(r'\{[\s\S]*\}', judge_text)
            if json_match:
                judge_result = json.loads(json_match.group())
                print("\n📊 LLM-as-Judge 評分：")
                print(f"  {'維度':<20} {'A（舊）':>8} {'B（新）':>8}")
                print(f"  {'─'*20} {'─'*8} {'─'*8}")
                for dim in ["completeness", "consistency", "developability", "testability", "scope_control", "edge_coverage"]:
                    dim_zh = {"completeness":"完整度","consistency":"一致性","developability":"可開發性","testability":"可測試性","scope_control":"Scope控制","edge_coverage":"邊界覆蓋"}
                    a_s = judge_result.get("a_scores", {}).get(dim, 0)
                    b_s = judge_result.get("b_scores", {}).get(dim, 0)
                    indicator = "🟢" if b_s > a_s else "🔴" if b_s < a_s else "="
                    print(f"  {dim_zh.get(dim, dim):<20} {a_s:>8} {b_s:>8} {indicator}")

                a_total = judge_result.get("a_total", 0)
                b_total = judge_result.get("b_total", 0)
                winner = judge_result.get("winner", "?")
                verdict = judge_result.get("verdict", "")

                print(f"\n  總分：A={a_total} / B={b_total}")
                print(f"  勝者：{'🏆 B（新流程）' if winner == 'B' else '⚠️ A（舊流程）' if winner == 'A' else '= 平手'}")
                print(f"  評語：{verdict}")

                if "key_differences" in judge_result:
                    print("\n  關鍵差異：")
                    for diff in judge_result["key_differences"]:
                        print(f"    • {diff}")
            else:
                print("  ⚠️ 無法解析 Judge 結果 JSON")
        except (json.JSONDecodeError, KeyError) as e:
            print(f"  ⚠️ Judge 結果解析失敗：{e}")
    else:
        print("  ⚠️ LLM-as-Judge 執行失敗")

    # Step 4: 輸出報告
    report = {
        "tier": 3,
        "name": "A/B 品質比對測試",
        "timestamp": datetime.now().isoformat(),
        "test_feature": "座席管理 CRUD",
        "model": args.model,
        "stats": {k: {"a": v[0], "b": v[1]} for k, v in stats.items()},
        "files": {
            "doc_a": str(doc_a_path),
            "doc_b": str(doc_b_path),
            "judge": str(judge_path),
        }
    }

    if args.output:
        with open(args.output, 'w') as fp:
            json.dump(report, fp, ensure_ascii=False, indent=2)
        print(f"\n  JSON 報告：{args.output}")

    print("\n" + "═" * 60)
    print(" A/B 測試完成。檔案位於：")
    print(f"   A（舊流程）：{doc_a_path}")
    print(f"   B（新流程）：{doc_b_path}")
    print(f"   Judge 結果：{judge_path}")
    print("═" * 60)

    return 0

if __name__ == "__main__":
    import re
    sys.exit(main())
