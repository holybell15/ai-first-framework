# Findings

## 2026-03-30 Priority Improvement Summary

- The framework is strong on methodology, but still relies heavily on markdown conventions rather than system-enforced checks.
- Adoption friction is currently the most important product risk, especially for 1-2 person teams.
- The highest-leverage next step is to define a Lite Mode before adding more process complexity.
- The second highest-leverage step is to convert core contract rules into workflow-test automation.
- Core memory and tracking files are valuable, but their boundaries should be documented more explicitly to reduce sync drift.

## 2026-03-30 Lite Mode decisions

- Lite Mode should not become a separate framework; it should be the minimum viable path through the existing framework.
- Lite Mode keeps Task-Master, TASKS, STATE, 10_Standards, and a minimum review checkpoint.
- The first rollout should be documentation-first: define the path, then connect validation and command support in the next step.

## 2026-03-30 Productization follow-ups

- P1 can reuse the existing `tools/workflow-test/run_tests.py`; the highest leverage is to add a local validation entrypoint rather than replace the test stack.
- P2 should be documented as file-boundary rules, because the framework already has the right artifacts but lacks a single explicit boundary guide.
- P3 should start with a documentation-heavy demo skeleton, not a full real app, so teams can understand the minimum viable closed loop faster.
- P4 should expose task-based entry points rather than more conceptual explanation.

## 2026-03-30 Lite Mode routing decisions

- The fastest way to operationalize Lite Mode is to extend existing entry commands instead of creating a separate new command.
- `info-init`, `info-pipeline`, and `info-task-master` are the three highest-leverage entry points for Lite routing.
- `pipeline-orchestrator` should explicitly recognize Lite triggers and upgrade conditions back to the full pipeline.

## 2026-03-30 Validation productization decisions

- Validation becomes more useful when every failure has a nearby repair path.
- `docs/AGENTS.md` and `docs/AGENT_SYNC.md` also need Lite-aware language, otherwise command routing and reference docs drift apart again.

## 2026-03-30 Dashboard decisions

- The dashboard should reflect the new productized onboarding path, not only the original full pipeline.
- Guide Tab is now the highest-leverage place to surface Start Here, Lite Mode, and validation/repair flows.
- `PROJECT_STATUS.routes` should mirror real entry paths, otherwise the dashboard and commands drift apart.

## 2026-03-30 Hotfix / Brownfield findings

- The original Hotfix flow assumed a mature environment: `main`, staging, rollback scripts, DB down-migration, and feature flags. That makes it brittle for small teams and brownfield systems.
- The original Hotfix 48-hour follow-up requirement was too abstract; teams need a clearly defined minimum incident record, not only "補 RS + Gate 文件".
- The original Brownfield onboarding time expectation and stage density were too optimistic for legacy systems.
- `adopt-project.sh` previously skipped whole directories when they already existed, which could leave adopted projects in a half-updated framework state without surfacing gaps.
- A practical Brownfield path needs baseline + gap report first, then selective adoption through real work, instead of pretending full governance can be established in one pass.

## Slice Cycle 設計決策

### G4-ENG 雙層拆法
- G4-ENG-D：設計審查（P03 完成後），審查本 slice 的 Feature Pack + API + DB + Test Design
- G4-ENG-R：實作後審查（P04 Code 完成後），審查 code vs design 一致性 + scope drift + stabilization + hardening 判定

### 回退規則 5 級
1. 範圍漂移/偷補需求 → 回 Review Gate（G4-ENG-R）
2. 設計與實作不一致 → 回 P03（重新設計本 slice）
3. 啟動/安全/主流程問題 → 回 Stabilization
4. 邏輯語意/邊界測試不足 → 回 Hardening
5. 架構邊界錯誤 → 升級回 P02 / Gate 2

### Cross-Slice Integration Check 觸發規則
- 第 3 個骨幹 slice 完成後：第一次整合檢查
- 之後每 2 個 slice 完成後觸發一次
- 或任何 slice 修改了共用模組（auth/state machine/event bus）時強制觸發

## 2026-03-30 Workflow reset feasibility study

- `superpowers` 的核心不是多角色治理，而是少數強制 skill 的串接：`brainstorming -> writing-plans -> subagent-driven-development/executing-plans -> TDD -> review -> finish branch`。
- `superpowers` 最強的地方是把「先設計再實作」和「plan-driven execution」變成硬規則，這正好可以解你現在流程分散、入口太多、大家不知道先做什麼的問題。
- `superpowers` 也有明確弱點：它對長週期專案治理、文件 SSOT、跨 session memory 邊界、正式 pipeline 成熟度管理幾乎沒有你現在這套細。
- `gstack` 的優勢不是 artifact 管理，而是 cognitive mode / gear separation：brainstorm、engineering review、review、qa、ship 是不同腦袋，不混成一團。
- `gstack` 很值得借的觀念有三個：Skill routing 寫進 root instructions、流程階段明確命名、把 review / qa / ship 做成與 build 分離的專用模式。
- 你現在 repo 的痛點不在「沒有流程」，而在「流程物件太多且分散」：Pipeline、Lite Mode、Task-Master、context-seeds、context-skills、STATE/TASKS/MASTER_INDEX、dashboard、slash commands 同時都在承擔路由責任。
- `docs/INFORMATION_ARCHITECTURE.md` 已經把 memory 邊界講得不錯，但實際入口仍然偏向「功能很多」，不像 `superpowers` / `gstack` 那樣能用少數高頻 workflow 覆蓋大部分情境。
- 目前 `project-template/CLAUDE.md` 已經部分吸收 `superpowers` 思路，甚至直接標示「obra/superpowers 系列」，但停留在 skill 列表層，還沒有把它升格成真正的頂層骨架。
- repo 內已出現版本漂移訊號：`VERSION` / `README.md` 仍標示 `2.4.0`，但 `project-template/PROJECT_DASHBOARD.html` 已標示 `v3.3.0`，代表框架現況、入口與對外敘事沒有單一主敘事。
- 因此「基於 superpowers 重整」是可行的，但比較適合採用「骨架遷移、治理保留」策略，而不是全面重做成 superpowers clone。
- 建議重整方向：以 `superpowers` 重新定義 day-to-day workflow 主骨架；以 `gstack` 重新定義 cognitive mode / Agent 定位；保留你自己的 artifact governance、Lite/Standard adoption、Brownfield/Hotfix、dashboard 與 validation。
- 如果直接全面 superpowers 化，最大風險是你會失去目前框架最稀缺的部分：正式交付治理、文件唯一真相來源、接手與審核可追溯性。
