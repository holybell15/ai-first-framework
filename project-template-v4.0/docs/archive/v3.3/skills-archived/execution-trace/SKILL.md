---
name: execution-trace
description: >
  Agent 執行過程追蹤與合規稽核。記錄每個 Agent 的每一步操作，事後可稽核。

  **所有 Agent 預設啟用**。每做一個關鍵步驟就寫一行到 execution-trace.jsonl。
  Pipeline 結束後跑 audit 腳本，比對「應該做的 vs 實際做的」，產出合規報告。

  **為什麼？** Agent 說它讀了 SEED 不代表它真的讀了。
  Trace 記錄是客觀證據，audit 是自動化稽核。
---

# Execution Trace：Agent 執行追蹤

## 核心原則

```
Agent 說「我做了」 ≠ Agent 真的做了
Trace 記錄 + Audit 比對 = 客觀證據
```

---

## Trace 記錄格式

每個關鍵動作寫一行到 `execution-trace.jsonl`：

```jsonl
{"ts":"2026-03-29T10:00:00Z","agent":"interviewer","step":"seed_read","detail":"SEED_Interviewer.md","status":"done"}
{"ts":"2026-03-29T10:00:05Z","agent":"interviewer","step":"ethos_read","detail":"ETHOS.md","status":"done"}
{"ts":"2026-03-29T10:00:10Z","agent":"interviewer","step":"skill_read","detail":"brainstorming/SKILL.md","status":"done"}
{"ts":"2026-03-29T10:01:00Z","agent":"interviewer","step":"forced_thinking","detail":"RT-01~07","status":"skipped","reason":"not PM agent"}
{"ts":"2026-03-29T10:05:00Z","agent":"interviewer","step":"output","detail":"RFP_Brief_F02.md","status":"done"}
{"ts":"2026-03-29T10:05:30Z","agent":"interviewer","step":"completion_status","detail":"DONE","status":"done"}
{"ts":"2026-03-29T10:05:31Z","agent":"interviewer","step":"handoff","detail":"→ PM","status":"done"}
```

## 必須記錄的 Checkpoint（24 個）

每個 Agent 在執行過程中，遇到以下 checkpoint 必須寫 trace：

### 進場 Checkpoint（每個 Agent 都要）

| # | Checkpoint | step 值 | 說明 |
|---|-----------|---------|------|
| 1 | 讀取 SEED | `seed_read` | 讀了哪個 SEED 檔案 |
| 2 | 讀取 ETHOS | `ethos_read` | 確認讀了 ETHOS.md |
| 3 | 讀取 Skill | `skill_read` | 讀了哪些 SKILL.md（可多行） |
| 4 | CIC Grounding | `cic_grounding` | 輸出了 CIC 聲明（讀了哪些上游文件） |
| 5 | Pre-check | `precheck` | Pre-check 項目全部通過 / 哪些未通過 |

### 思考 Checkpoint（依角色觸發）

| # | Checkpoint | step 值 | 觸發條件 |
|---|-----------|---------|---------|
| 6 | 需求思考 7 問 | `forced_thinking_rt` | PM 寫 US 前 |
| 7 | Plan Challenge 5 問 | `forced_thinking_pcs` | P01→P02 銜接 |
| 8 | 設計思考 8 問 | `forced_thinking_dt` | Architect 設計前 |
| 9 | 提交前檢查 6 問 | `forced_thinking_pc` | P04 每次 commit 前 |
| 10 | 缺陷學習 4 問 | `forced_thinking_dl` | QA 發現缺陷時 |

### 產出 Checkpoint

| # | Checkpoint | step 值 | 說明 |
|---|-----------|---------|------|
| 11 | 產出文件 | `output` | 產出了什麼文件（路徑） |
| 12 | 產出 AC | `output_ac` | AC 數量 |
| 13 | 產出情境 | `output_scenarios` | 情境數量（A/B/C/D/E/F） |
| 14 | 修改檔案 | `file_modified` | 修改了哪些既有檔案 |

### Gate Checkpoint

| # | Checkpoint | step 值 | 說明 |
|---|-----------|---------|------|
| 15 | G4-ENG-D 執行 | `gate_d_executed` | 設計審查有沒有跑 |
| 16 | G4-ENG-D 結果 | `gate_d_result` | PASS / BLOCK + 原因 |
| 17 | G4-ENG-R 執行 | `gate_r_executed` | 實作後審查有沒有跑 |
| 18 | G4-ENG-R 結果 | `gate_r_result` | PASS / BLOCK + 原因 |
| 19 | Cross-Slice IC | `cross_slice_ic` | 整合檢查有沒有跑 |

### 收尾 Checkpoint（每個 Agent 都要）

| # | Checkpoint | step 值 | 說明 |
|---|-----------|---------|------|
| 20 | Completion Status | `completion_status` | DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT |
| 21 | Concerns 清單 | `concerns` | DONE_WITH_CONCERNS 時列出 |
| 22 | Open Issues | `open_issues` | 新增/更新的 OI-NNN |
| 23 | 交接摘要 | `handoff` | 交給誰 + 需知道什麼 |
| 24 | Friction Log | `friction` | 有沒有記錄摩擦點 |

---

## Agent 怎麼寫 Trace

在 Agent 執行過程中，遇到 checkpoint 時追加一行到 `execution-trace.jsonl`：

```bash
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","agent":"[agent]","step":"[step]","detail":"[detail]","status":"done"}' >> execution-trace.jsonl
```

**或在對話中輸出格式**（orchestrator 自動收集）：

```
[TRACE] agent=pm step=forced_thinking_rt detail="RT-01~07 完成" status=done
[TRACE] agent=pm step=output detail="02_Specifications/US_F02_v1.0.md" status=done
[TRACE] agent=pm step=completion_status detail="DONE" status=done
```

Pipeline-orchestrator 看到 `[TRACE]` 行時自動追加到 `execution-trace.jsonl`。

---

## Audit 腳本：比對「應該做的 vs 實際做的」

### 每個 Pipeline 階段的必要 Checkpoint

```python
EXPECTED_CHECKPOINTS = {
    "P00": {
        "interviewer": ["seed_read", "ethos_read", "precheck", "output", "completion_status", "handoff"],
        "pm": ["seed_read", "ethos_read", "skill_read", "forced_thinking_rt", "precheck",
               "output", "output_ac", "output_scenarios", "completion_status", "handoff"],
    },
    "P01": {
        "pm": ["seed_read", "ethos_read", "output", "completion_status", "handoff"],
        "ux": ["seed_read", "ethos_read", "skill_read", "precheck", "output", "completion_status", "handoff"],
    },
    "P02": {
        "architect": ["seed_read", "ethos_read", "forced_thinking_dt", "precheck",
                      "output", "completion_status", "handoff"],
        "dba": ["seed_read", "ethos_read", "precheck", "output", "completion_status", "handoff"],
    },
    "slice_cycle": {
        "design": ["seed_read", "skill_read", "output", "gate_d_executed", "gate_d_result"],
        "code": ["seed_read", "forced_thinking_pc", "output", "file_modified",
                 "gate_r_executed", "gate_r_result", "completion_status"],
        "stabilization": ["completion_status"],
        "hardening": ["completion_status"],
    },
}
```

### Audit 輸出格式

```
╔══════════════════════════════════════════════════╗
║  Execution Audit Report                         ║
║  Pipeline: P00 需求建立 — Slice S01             ║
╠══════════════════════════════════════════════════╣

Agent: interviewer
  ✅ seed_read         — SEED_Interviewer.md (10:00:00)
  ✅ ethos_read        — ETHOS.md (10:00:05)
  ✅ precheck          — 5/5 通過 (10:00:10)
  ✅ output            — RFP_Brief_F02.md (10:05:00)
  ✅ completion_status — DONE (10:05:30)
  ✅ handoff           — → PM (10:05:31)
  合規率：6/6 (100%) ✅

Agent: pm
  ✅ seed_read         — SEED_PM.md (10:06:00)
  ✅ ethos_read        — ETHOS.md (10:06:02)
  ✅ skill_read        — forced-thinking/SKILL.md (10:06:05)
  ✅ forced_thinking_rt — RT-01~07 完成 (10:10:00)
  ✅ precheck          — 4/4 通過 (10:06:10)
  ✅ output            — SRS_AICC-II_v1.0.md (10:30:00)
  ✅ output_ac         — 42 條 AC (10:30:01)
  ✅ output_scenarios  — 28 個情境 (10:30:02)
  ✅ completion_status — DONE (10:30:30)
  ✅ handoff           — → UX (10:30:31)
  合規率：10/10 (100%) ✅

  ⚠️ Missing Checkpoints:
  （無）

  🔍 Anomalies:
  （無）

Overall: 16/16 checkpoints — 100% 合規
╚══════════════════════════════════════════════════╝
```

---

## Anomaly Detection（異常偵測）

Audit 腳本自動偵測以下異常：

| 異常 | 偵測方式 | 嚴重度 |
|------|---------|--------|
| **跳過 SEED 讀取** | 無 `seed_read` checkpoint | 🔴 |
| **跳過 ETHOS** | 無 `ethos_read` | 🟡 |
| **跳過 forced-thinking** | PM 無 `forced_thinking_rt` / Architect 無 `forced_thinking_dt` | 🔴 |
| **跳過 Gate** | slice 有 `code` 但無 `gate_d_executed` | 🔴 |
| **無 Completion Status** | Agent 結束但無 `completion_status` | 🔴 |
| **Scope Drift** | `file_modified` 中有 Feature Pack 範圍外的檔案 | 🔴 |
| **自行假設** | `open_issues` 為空但 design 有「假設」字眼 | 🟡 |
| **時間異常** | 某步驟耗時 > 30 分鐘 | 🟡 |
| **順序異常** | `code` 出現在 `gate_d_result=PASS` 之前 | 🔴 |

---

## 與 Pipeline 整合

| 時機 | 行為 |
|------|------|
| 每個 Agent 啟動時 | 自動寫 `seed_read` + `ethos_read` |
| 每個 Agent 完成時 | 自動寫 `completion_status` + `handoff` |
| Pipeline 結束時 | 自動跑 audit 腳本 |
| Gate 通過/失敗時 | 自動寫 `gate_*_result` |
| 使用者說「稽核執行過程」 | 手動跑 audit 腳本 |
