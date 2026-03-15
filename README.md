# AI-First Framework

> **A production-grade, multi-agent development system for Claude Code and Cowork.**
> Turn any product idea into shipping code using structured Pipelines, 11 specialized AI Agents, and built-in quality gates.

---

## What is this?

AI-First Framework is a context engineering and spec-driven development system that makes AI-assisted development **reliable, traceable, and repeatable**. Instead of ad-hoc prompting, it gives you:

- **6 Pipelines** — structured workflows from idea → deployed product
- **11 Agent Roles** — each with a clear scope (PM, Architect, DBA, Backend, Frontend, UX, QA, Security, DevOps, Review, Interviewer)
- **4 Quality Gates** — mandatory checkpoints that prevent moving forward with broken foundations
- **29 Skills** — reusable capability modules that agents invoke automatically
- **8 Slash Commands** — one-liner shortcuts for common framework operations
- **3-Domain Standards** — canonical API / DB / UI rules enforced across all agents (SSOT)
- **GSD Mechanics** — 10 reliability mechanisms built into every pipeline (§32–§41)

---

## Quick Start (5 minutes)

### Step 1 — Clone the framework

```bash
git clone https://github.com/your-org/ai-first-framework.git
cd ai-first-framework
```

### Step 2 — Create your project

```bash
./scripts/new-project.sh MyProductName
# → Creates /path/to/MyProductName/ with everything configured
```

Or adopt an existing project:

```bash
./scripts/adopt-project.sh /path/to/existing-project
```

### Step 3 — Open with Cowork or Claude Code

**Cowork**: Open a new task, select the `MyProductName/` folder.

**Claude Code**:
```bash
cd ../MyProductName
claude
```

### Step 4 — Start your first Pipeline

```
讀取 CLAUDE.md，然後執行 Pipeline: 需求訪談
```

That's it. Claude reads the navigation file, activates the Interviewer Agent, and begins structured requirements gathering.

---

## Framework Architecture

```
ai-first-framework/
├── README.md                    ← You are here
├── CHANGELOG.md                 ← Version history
├── VERSION                      ← Current version (2.4.0)
├── scripts/
│   ├── new-project.sh           ← One-command project setup
│   └── adopt-project.sh         ← Onboard an existing codebase
├── docs/
│   ├── PIPELINES.md             ← All 6 pipelines explained
│   ├── AGENTS.md                ← 11 agent roles reference
│   └── AGENT_SYNC.md            ← Multi-agent coordination guide
├── tools/
│   └── workflow-test/           ← Framework health test suite
└── project-template/            ← Copy this for each new project
    ├── CLAUDE.md                ← Navigation & routing (SSOT)
    ├── TASKS.md                 ← Task tracking (F-code + @owner)
    ├── TEAM.md                  ← Multi-member config & handoff protocol
    ├── MASTER_INDEX.md          ← Document registry
    ├── PROJECT_DASHBOARD.html   ← Visual progress dashboard
    ├── .claude/
    │   └── commands/            ← 8 slash commands (/init /health /quick …)
    ├── 10_Standards/            ← 3-domain technical standards (SSOT)
    │   ├── API/                 ← API design + error code standards
    │   ├── DB/                  ← Schema rules + enum/field registry
    │   └── UI/                  ← Design tokens + component guidelines
    ├── context-seeds/           ← 11 Agent activation prompts
    ├── context-skills/          ← 29 capability skill modules
    ├── contracts/               ← Data contracts & field registry
    ├── memory/                  ← Cross-session state & rules
    │   ├── workflow_rules.md    ← GSD §32–§41 complete rulebook
    │   ├── STATE.md             ← Session state snapshot (§38)
    │   ├── decisions.md         ← Architecture decisions (ADR)
    │   ├── gate_baseline.yaml   ← Gate exit criteria baselines
    │   ├── token_budget.md      ← Context budget tracking
    │   └── smoke_tests.md       ← Deployment smoke test checklist
    └── 01–09 folders/           ← Structured output directories
```

---

## The 6 Pipelines

| # | Pipeline | What it produces | Gate |
|---|---------|-----------------|------|
| P01 | 需求訪談 | Interview records, User Stories, Prototype | Gate 1 |
| P02 | 技術設計 | Architecture, DB Schema, ADR | Gate 2 |
| P03 | 開發準備 | API Spec, Component plan, Test cases | G4-ENG |
| P04 | 實作開發 | Working code + passing tests | Gate 3 |
| P05 | 合規審查 | Security & compliance docs | — |
| P06 | 部署上線 | CI/CD config, deployment, release | — |

Each Pipeline is executed by typing: `執行 Pipeline: [名稱]`

---

## The 11 Agent Roles

| Agent | Scope | Seed file |
|-------|-------|-----------|
| Interviewer | Requirements elicitation | `context-seeds/SEED_Interviewer.md` |
| PM | User Stories + Acceptance Criteria | `context-seeds/SEED_PM.md` |
| Architect | System design + ADR | `context-seeds/SEED_Architect.md` |
| UX | User flows + HTML Prototype | `context-seeds/SEED_UX.md` |
| Frontend | UI components + design system | `context-seeds/SEED_Frontend.md` |
| Backend | API + business logic | `context-seeds/SEED_Backend.md` |
| DBA | Database schema + migrations | `context-seeds/SEED_DBA.md` |
| DevOps | CI/CD + cloud deployment | `context-seeds/SEED_DevOps.md` |
| QA | Test cases + execution | `context-seeds/SEED_QA.md` |
| Security | Security review + compliance | `context-seeds/SEED_Security.md` |
| Review | Gate reviews + code review | `context-seeds/SEED_Review.md` |

Activate any agent: `讀取 context-seeds/SEED_[Role].md，你現在是 [Role] Agent`

---

## Slash Commands

One-liner shortcuts built into every project (`.claude/commands/`):

| Command | What it does |
|---------|-------------|
| `/init` | First-time project setup: validate structure → fill placeholders → setup team → create F01 |
| `/health` | Run framework integrity check + `tools/workflow-test` suite |
| `/quick` | Quick Mode (GSD §37) for ≤3 file changes with DSV declaration |
| `/progress` | Instant status snapshot from STATE.md + TASKS.md |
| `/pause` | Suspend work session, write `resume_command` to STATE.md |
| `/handoff` | Agent completion handoff: update TASKS.md + STATE.md |
| `/complete-milestone` | Archive after Gate pass + update status + optional git tag |
| `/setup-team` | Interactive TEAM.md configuration (all 11 roles) |

---

## 3-Domain Technical Standards (`10_Standards/`)

Canonical rules enforced by all agents — edit once, respected everywhere.

| Domain | Files | Key Rules |
|--------|-------|-----------|
| **API** | `STD_API_Design.md` · `Error_Code_Standard_v1.0.md` | `/api/v{N}/` versioning · `{ success, data, message, errorCode }` envelope · `AICC-{LAYER}{CODE}` error format |
| **DB** | `STD_DB_Schema.md` · `enum_registry.yaml` · `field_registry_template.yaml` | UUID PKs · `tenant_id NOT NULL` · `pii_` / `log_` / `enc_` prefixes · reversible migrations |
| **UI** | `STD_UI_Design.md` · `Design_Token_Reference.md` | CSS variable-only styling · WCAG 2.1 AA · 44px tap targets · no hardcoded hex |

---

## GSD Mechanics (§32–§41)

Built into every pipeline automatically. No extra setup needed.

| Mechanism | What it does | §Ref |
|-----------|-------------|------|
| Context Health Check | Detects context degradation before handoff | §32 |
| Discuss Phase | Confirms technical preferences at pipeline transitions | §33 |
| Lightweight Plan Check | 5-dimension self-review before marking done | §34 |
| Nyquist Validation | Every AC comes with a testability hint | §35 |
| Auto-Fix Loop | Failed verify → debug → fix → re-verify (max 3 rounds) | §36 |
| Quick Mode | Skip pipeline overhead for tiny changes | §37 |
| STATE.md Memory | Cross-session state snapshot — never lose your place | §38 |
| Wave-Based Parallel | Dependency analysis before parallel agent launch | §39 |
| Model Profiles | quality / balanced / budget switching | §40 |
| map-codebase | 4-agent codebase entry scan for existing repos | §41 |

---

## The 29 Skills

Skills are capability modules that agents automatically invoke. They live in `context-skills/` inside each project.

**Workflow Skills (17):**
`pipeline-orchestrator` · `quality-gates` · `brainstorming` · `systematic-debugging` · `verification-before-completion` · `subagent-driven-development` · `test-driven-development` · `using-git-worktrees` · `finishing-a-development-branch` · `requesting-code-review` · `webapp-testing` · `deep-research` · `frontend-design` · `update-dashboard` · `project-init` · `planning-with-files` · `screenshot-to-code`

**Document Skills (6):**
`docx` · `xlsx` · `pptx` · `pdf` · `doc-coauthoring` · `internal-comms`

**Platform Skills (6):**
`algorithmic-art` · `theme-factory` · `web-artifacts-builder` · `mcp-builder` · `schedule` · `skill-creator`

---

## Quality Gates

Gates are mandatory checkpoints. A pipeline **cannot proceed** until its gate passes.

| Gate | After | Checks | Tool |
|------|-------|--------|------|
| Gate 1 | P01 | Requirements completeness, AC testability, Prototype coverage | `quality-gates` skill |
| Gate 2 | P02 | Architecture viability, ADR completeness, DB schema | `quality-gates` skill |
| G4-ENG | P03 | Cross-layer consistency, GA density, Engineering sign-off | `quality-gates` skill |
| Gate 3 | P04 | Test coverage ≥80%, E2E pass, security review | `quality-gates` skill |

**Important:** Gate Reviews must run in a **separate session** from the pipeline that produced the artifacts. This is the same principle as "the developer doesn't review their own code."

```
# Cowork: open a NEW Cowork task on the same folder
# Claude Code: open a NEW terminal window

First message:
"你是 Review Agent。讀取 CLAUDE.md，執行 Gate [N] 驗收。"
```

---

## Project Setup Details

After running `new-project.sh` (or `/init` command), Claude will:

1. Validate framework structure integrity
2. Fill in product name, type, and tech stack across all files
3. Configure `TEAM.md` with your team members
4. Create the first Feature task (F01) in `TASKS.md`

Then run your first pipeline:
```
執行 Pipeline: 需求訪談
```

---

## Multi-Member Collaboration

`TEAM.md` defines who owns which Agent role, handoff protocols, and branch naming conventions. The `task-master` agent reads `TASKS.md` + `STATE.md` to auto-assign work and route around blockers.

TASKS.md format:
```
| F## | Description | @owner | Status | Blocked by |
```

Cross-feature dependencies:
```
F05 depends_on: F02-API-完成
```

---

## Version

Current: **v2.4.0** — Multi-member collaboration, 8 slash commands, 3-domain Standards, adopt-project workflow, framework health test suite.

See [CHANGELOG.md](./CHANGELOG.md) for full history.

---

## License

MIT — use freely, attribution appreciated.
