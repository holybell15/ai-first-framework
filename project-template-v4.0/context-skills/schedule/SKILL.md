---
name: schedule
description: "Schedule automatic or manual tasks. Use this for: 幫我設定一個定時任務, 每天早上自動做這件事, 定期執行, 排程, remind me. Supports recurring schedules (cron), one-time runs, or manual triggers."
---

You are creating a reusable scheduled task. Follow these steps:

## 1. Analyze the Session

Review the session history to identify the core task the user performed or requested. Distill it into a single, repeatable objective.

## 2. Draft a Prompt

The prompt will be used for future autonomous runs — it must be entirely self-contained. Future runs will NOT have access to this session, so never reference "the current conversation," "the above," or any ephemeral context.

Include in the prompt:
- A clear objective statement (what to accomplish)
- Specific steps to execute
- Any relevant file paths, URLs, repositories, or tool names
- Expected output or success criteria
- Any constraints or preferences the user expressed

Write in second-person imperative ("Check the inbox…", "Run the test suite…"). Keep it concise but complete enough that another Claude session could execute it cold.

## 3. Choose a taskId

Pick a short, descriptive name in kebab-case (e.g. "daily-inbox-summary", "weekly-dep-audit", "format-pr-description").

## 4. Determine Scheduling

Pick one:

- **Recurring** ("every morning", "weekdays at 5pm", "hourly") → use `cronExpression`
  - Evaluated in the user's LOCAL timezone, not UTC
  - Format: `minute hour dayOfMonth month dayOfWeek`
  - Examples:
    - "0 9 * * *" = Every day at 9:00 AM
    - "0 9 * * 1-5" = Weekdays at 9:00 AM
    - "30 8 * * 1" = Every Monday at 8:30 AM
    - "0 0 1 * *" = First day of every month at midnight

- **One-time** ("remind me in 5 minutes", "tomorrow at 3pm", "next Friday") → use `fireAt`
  - Compute the exact moment and emit a full ISO 8601 string with timezone offset
  - Format: `2026-03-05T14:30:00-08:00`
  - Task auto-disables after firing
  - Must be in the future

- **Ad-hoc** (no automatic run; user will trigger manually) → omit both `cronExpression` and `fireAt`

- **Ambiguous** → propose a schedule and ask the user to confirm before proceeding

Finally, call the "create_scheduled_task" tool.
