# Progress

## Session: 2026-03-30 Framework priority adjustment

- [x] Reviewed core framework docs and scripts
- [x] Assessed strengths, weaknesses, and adoption risks
- [x] Converted 5 improvement suggestions into a prioritized roadmap
- [x] Added a README entry point for the roadmap
- [x] Started implementation of the first roadmap item

## Session: 2026-03-30 Lite Mode definition

- [x] Added `docs/LITE_MODE.md`
- [x] Added Lite Mode entry to `README.md`
- [x] Added Lite Mode onboarding guidance to template `CLAUDE.md`
- [x] Added Lite Mode hint to `docs/PIPELINES.md`
- [x] Decided to continue with workflow-test support first

## Session: 2026-03-30 Remaining roadmap execution

- [x] Added `docs/INFORMATION_ARCHITECTURE.md`
- [x] Added `docs/START_HERE.md`
- [x] Added `project-template/START_HERE.md`
- [x] Added `examples/lite-task-demo/` skeleton
- [x] Added `scripts/validate-framework.sh`
- [x] Added `.github/workflows/framework-validation.yml`
- [x] Extended `tools/workflow-test/run_tests.py` with productization checks

## Session: 2026-03-30 Lite Mode routing

- [x] Added Lite Mode guidance to `info-init`
- [x] Added Lite Mode option to `info-pipeline`
- [x] Added Lite Mode prioritization to `info-task-master`
- [x] Added Lite trigger and upgrade rules to `pipeline-orchestrator`
- [x] Added workflow-test checks for Lite command routing

## Session: 2026-03-30 Lite-aware docs and repair guide

- [x] Updated `docs/AGENTS.md` with Lite Mode guidance
- [x] Updated `docs/AGENT_SYNC.md` with Lite Mode sync rules
- [x] Added `docs/VALIDATION_REPAIR.md`
- [x] Updated validation script to print repair-guide path

## Session: 2026-03-30 Dashboard cleanup

- [x] Updated `project-template/PROJECT_DASHBOARD.html` header/version to reflect v3.1
- [x] Added Start Here / Lite Mode guidance to Guide Tab
- [x] Added Validation / Repair section to Guide Tab
- [x] Updated command cheat sheet, folder cheat sheet, FAQ, and route entries
- [x] Verified `<div>` balance remains correct

## Session: 2026-03-30 Hotfix / Brownfield rewrite

- [x] Reframed Brownfield onboarding as Lite / Standard dual-track flow
- [x] Reframed Hotfix as Lite / Standard dual-track flow
- [x] Added minimum follow-up requirements for Lite Hotfix
- [x] Updated `project-template/.claude/commands/info-hotfix.md` to route by environment maturity
- [x] Updated `project-template/memory/hotfix_log.md` to capture mode, production branch, rollback, and verification
- [x] Reworked `scripts/adopt-project.sh` to sync missing files instead of skipping entire directories
- [x] Added `memory/adoption_gap_report.md` bootstrap output for adopted legacy projects
- [x] Verified `scripts/adopt-project.sh` shell syntax and reran framework validation successfully

## Session: 2026-03-30 Dashboard alignment for Hotfix / Brownfield

- [x] Updated `project-template/PROJECT_DASHBOARD.html` to v3.2
- [x] Synced Brownfield pipeline card to Lite / Standard dual-track wording
- [x] Synced Hotfix pipeline card to Lite / Standard dual-track wording
- [x] Updated Guide Tab commands and Brownfield guide steps
- [x] Added direct routes for emergency issues and first-time brownfield adoption
- [x] Updated dashboard release notes and maintenance rules
- [x] Verified `<div>` balance remains correct after edits

## Session: 2026-03-30 Call Center domain skill bootstrap

- [x] Added `project-template/context-skills/call-center-domain/SKILL.md`
- [x] Added `project-template/context-skills/call-center-domain/references/domain-map.md`
- [x] Added `project-template/memory/domain_call_center.md` project-level template
- [x] Updated `docs/AGENTS.md` so PM / Architect / Backend / QA know when to load the new skill
- [x] Reran framework validation successfully after the new skill was added

## Session: 2026-03-30 Call Center domain pack expansion

- [x] Added `state-and-event-model.md` for agent state / interaction state / event-ordering guidance
- [x] Added `test-scenarios.md` for call-center-specific QA and review coverage
- [x] Added `10_Standards/DOMAIN/STD_Call_Center_Engineering.md`
- [x] Updated `call-center-domain` skill to route users to the new references and standard
- [x] Updated `docs/AGENTS.md` to mention the optional Call Center engineering standard
- [x] Reran framework validation successfully after the expansion

## Session: 2026-03-30 Call Center seed integration

- [x] Updated `SEED_PM.md` to load the Call Center skill and output `Call Center Domain Notes`
- [x] Updated `SEED_Architect.md` to require domain pre-checks and call-center-specific architecture notes
- [x] Updated `SEED_QA.md` to require domain pre-checks and `Domain Coverage` in test cases
- [x] Updated `SEED_Review.md` with Call Center-specific Gate 2 / Gate 3 checks
- [x] Added `context-skills/call-center-domain/references/templates.md` for reusable PM / Architect / QA snippets
- [x] Reran framework validation successfully after seed integration

## Session: 2026-03-30 Dashboard ops monitoring upgrade

- [x] Upgraded `project-template/PROJECT_DASHBOARD.html` to v3.3 with a new `Ops` monitoring tab
- [x] Added external `PROJECT_DASHBOARD.data.js` loading so dashboard can reflect synced SSOT data
- [x] Added `scripts/refresh-dashboard-data.py` and copied it into `project-template/scripts/`
- [x] Made `adopt-project.sh` copy dashboard files and project-local scripts for brownfield projects
- [x] Updated Guide Tab and dashboard maintenance docs for the new refresh-based workflow
- [x] Verified refresh script execution, shell syntax, dashboard `<div>` balance, and framework validation

## Session: 2026-03-30 Ops tab completion

- [x] Added agent execution status cards to the Ops tab
- [x] Added team pending / handoff cards to the Ops tab
- [x] Extended refresh script to parse `TEAM.md`, `memory/last_task.md`, and handoff summaries in `TASKS.md`
- [x] Ensured current role in `STATE.md` can mark an agent as active even without a completed pipeline log
- [x] Reran refresh script, HTML structure check, and framework validation successfully

## Session: 2026-03-28 Slice Cycle 重構

- [x] Phase 1: slice-cycle skill — ✅ 建立完成
- [x] Phase 2: quality-gates — ✅ G4-ENG 拆雙層 + Cross-Slice
- [x] Phase 3: pipeline-orchestrator — ✅ Slice Cycle 自動化
- [x] Phase 4: CLAUDE.md — ✅ P02/P03+P04 重寫
- [x] Phase 5: Dashboard — ✅ v2.9.0 + Slice Cycle 卡片
- [ ] Phase 6: 產出 A/B/C/D 報告

## Session: 2026-03-30 Workflow reset feasibility study

- [x] Reviewed current framework routing, agent model, memory boundaries, and Lite/Standard structure
- [x] Compared current design against `obra/superpowers` workflow skeleton
- [x] Compared current design against `gstack` cognitive-mode and skill-routing model
- [x] Captured recommendation: adopt superpowers as workflow skeleton, not as a full replacement
