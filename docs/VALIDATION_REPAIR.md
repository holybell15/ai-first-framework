# Validation Repair Guide

> 當 `./scripts/validate-framework.sh` 或 `tools/workflow-test/run_tests.py` 失敗時，先用這份文件快速定位該補什麼。

---

## 1. 缺少核心入口文件

常見症狀：
- 缺少 `docs/LITE_MODE.md`
- 缺少 `docs/START_HERE.md`
- 缺少 `project-template/START_HERE.md`

修復方式：
- 確認這些文件已存在於 repo
- 若是 template 缺漏，補到 `project-template/`
- 若 README 沒引用，補 README 導覽入口

---

## 2. Lite Mode 路由不完整

常見症狀：
- `info-init` 沒提到 Lite Mode
- `info-pipeline` 沒有 Lite 選項
- `info-task-master` 不會優先建議 Lite Mode
- `pipeline-orchestrator` 不認得 `使用 Lite Mode 啟動 F01`

修復方式：
- 檢查 `project-template/.claude/commands/`
- 檢查 `project-template/context-skills/pipeline-orchestrator/SKILL.md`
- 補上 Lite trigger、啟動語句、升級回完整模式條件

---

## 3. 資訊架構邊界檢查失敗

常見症狀：
- `STATE.md` 缺少 `resume_command`
- `TASKS.md` 缺少交接摘要區
- `MASTER_INDEX.md` 缺少 F-code 分配表
- `decisions.md` 看起來像工作日誌而不是 ADR

修復方式：
- 對照 `docs/INFORMATION_ARCHITECTURE.md`
- 補回對應欄位
- 把不屬於該文件的資訊移回正確主檔

---

## 4. 示例專案骨架缺失

常見症狀：
- `examples/lite-task-demo/` 缺少需求文件
- 缺少最小設計文件
- 缺少測試證據

修復方式：
- 補齊最小閉環所需檔案
- 保持這個 demo 是 Lite Mode 的最小示範，而不是完整產品

---

## 5. README 與文件入口不同步

常見症狀：
- README 沒提到 `START_HERE`
- README 沒提到 `validate-framework`
- README 仍只講完整 Pipeline，沒有 Lite Mode 入口

修復方式：
- 補上最常見 5 個入口
- 明確區分第一次使用者與完整模式使用者

---

## 6. 本地驗證怎麼跑

```bash
./scripts/validate-framework.sh
```

若只想看 workflow-test：

```bash
python3 tools/workflow-test/run_tests.py
```

若要看 HTML 報告：

```bash
python3 tools/workflow-test/run_tests.py --open
```

---

## 7. 修完後的確認順序

1. 先跑 `./scripts/validate-framework.sh`
2. 確認缺失數為 0
3. 確認 `workflow-test` 沒有 fail / warn
4. 再檢查 README 與 template 入口是否仍可讀
