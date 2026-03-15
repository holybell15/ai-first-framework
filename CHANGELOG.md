# Changelog

All notable changes to AI-First Framework are documented here.
Format: [Semantic Versioning](https://semver.org/)

---

## [2.4.0] — 2026-03-15

### Added — 多人協作 + 任務分派 + 框架維護機制

- **`task-master` agent** — 框架層任務指揮官。讀取 TASKS.md + STATE.md 後自動判斷優先任務、派遣 Agent、處理 block 重路由、分配 F-code
- **`/init` command** — 新專案首次初始化：框架完整性驗證 → 填寫資訊 → 替換佔位符 → setup-team → 建立 F01
- **`/quick` command** — Quick Mode（GSD §37）：≤3 檔案小修正，含 DSV 聲明與驗證
- **`/progress` command** — 快速狀態快照，從 STATE.md + TASKS.md 直接輸出
- **`/health` command** — 專案結構完整性檢查，Step 0 整合 `tools/workflow-test/run_tests.py`
- **`/pause` command** — 暫停工作，寫入 STATE.md resume_command
- **`/complete-milestone` command** — Gate 通過後歸檔 + 更新狀態 + 可選 git tag
- **`/setup-team` command** — 互動式填寫 TEAM.md（11 角色）
- **`/handoff` command** — Agent 完成交接，更新 TASKS.md + STATE.md
- **`TEAM.md`** — 多人協作成員配置表，含交接協議與 Git 分支規範
- **`tools/workflow-test/`** — 框架健康測試工具（`PROJECT_DIR` 環境變數可覆寫專案路徑）
- **PROJECT_DASHBOARD 更新日誌 Tab** — Tab 8，`RELEASE_NOTES` 資料物件結構化版本歷史
- **Agent Teams 支援** — `settings.json` 啟用實驗性多 AI 並行，`task-master` 作為 team lead
- STATE.md `team` 區塊：active_member / current_role / handoff_to / handoff_notified

### Changed

- `/health` command 新增 Step 0（框架測試）
- `scripts/new-project.sh` 新增 Step 7（填寫 TEAM.md）
- TASKS.md 新增 `@負責人` 欄位
- PROJECT_DASHBOARD 使用指南新增 5 個區塊：Slash Command 速查、新專案流程、舊專案流程、setup-team 說明、Agent Teams 說明

---

## [2.3.0] — 2026-03-15

### Added — GSD Phase 2 (§38–§41)

- **§38 STATE.md Cross-Session Memory** — Agents write a YAML state snapshot before ending any session. New sessions auto-read it to resume without re-explaining context.
- **§39 Wave-Based Parallel Execution** — Dependency analysis before launching parallel agents. W1/W2/W3 wave groups with Mermaid dependency diagrams.
- **§40 Model Profiles** — Three-tier model switching: `quality` (Opus), `balanced` (Sonnet, default), `budget` (Haiku). Configurable per-project in `memory/product.md`.
- **§41 map-codebase** — 4-agent parallel entry scan for existing codebases. Produces `memory/codebase_snapshot.md` with tech stack, architecture, conventions, and risk analysis.

### Added — Pipeline Cards GSD Chips
- Visual GSD mechanism chips on each Pipeline card in PROJECT_DASHBOARD.html
- P01–P04 each show which §-mechanisms apply with clickable references

### Added — 27 Upgraded Skills
- All 27 skills rewrote with "pushy" descriptions, GSD hook references, richer content
- `verification-before-completion`: expanded from 22 to 232 lines with LPC and Reality-Check Ritual
- `quality-gates`: added G4-ENG HARD BLOCK procedure and §31.7 Independent Session Protocol
- `systematic-debugging`: AFL §36 integration, environment-specific debugging patterns

### Updated
- `workflow_rules.md` bumped to v2.3 (+4 new sections §38–§41)
- `pipeline-orchestrator` SKILL.md: STATE.md auto-update + Wave analysis sections
- `CLAUDE.md`: GSD reference table extended to §41, memory index updated

---

## [2.2.0] — 2026-03-13

### Added — GSD Phase 1 (§32–§37)

- **§32 Context Health Check (CHC)** — Auto-runs before every agent handoff
- **§33 Discuss Phase** — Preference confirmation at P01→P02 and P03→P04 transitions
- **§34 Lightweight Plan Check (LPC)** — 5-dimension self-review, max 3 rounds
- **§35 Nyquist Validation Layer** — Every AC includes a testability hint (NYQ)
- **§36 Auto-Fix Loop (AFL)** — Failed verify → debug → fix → re-verify, max 3 rounds
- **§37 Quick Mode** — Bypass pipeline for ≤3 file, no-new-feature changes

---

## [2.1.0] — 2026-02-01

### Added
- G4-ENG (Engineering Design Gate) as mandatory P04 unlock condition
- SignoffLog three-party sign-off (Architect / DBA / Review)
- GA density rules (≥5 GA markers per 1000 words in API Spec + DB Schema)
- DDG dependency graph completeness checks

---

## [2.0.0] — 2026-01-01

### Initial Release
- 6 Pipeline system (P01–P06)
- 11 Agent roles with SEED files
- 4 Quality Gates (Gate 1 / Gate 2 / G4-ENG / Gate 3)
- PROJECT_DASHBOARD.html visual progress tracker
- TASKS.md handoff format
- `memory/workflow_rules.md` v2.0
