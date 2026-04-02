---
name: call-center-domain
description: >
  Use this skill whenever the product or feature belongs to a Call Center / Contact Center domain:
  inbound, outbound, blended contact center, CTI, IVR, queueing, agent desktop, recordings, QA scorecards,
  campaigns, dialers, CRM screen pop, or omnichannel service workflows.

  Trigger when the user mentions call center, contact center, AICC, queue, agent status, IVR, SIP, PBX,
  softphone, disposition, wrap-up, recording, campaign, or service-level metrics such as AHT / ASA / SL.

  This skill provides domain grounding so PM, Architect, Backend, QA, Review, and Task-Master do not treat
  a call-center product like a generic CRUD SaaS.
---

# Call Center Domain Skill

## What This Skill Is For

Use this skill to add domain judgment, not to replace the normal Agent workflow.

- Agents still keep their original roles
- This skill supplies contact-center vocabulary, workflow checks, risk prompts, and review heuristics
- Use it together with the current pipeline, especially for PM, Architect, Backend, QA, and Review work

## Quick Start

When a feature is clearly in the call-center domain:

1. Read `memory/domain_call_center.md` if it exists
2. Read [references/domain-map.md](references/domain-map.md)
3. Read [references/state-and-event-model.md](references/state-and-event-model.md) when the feature changes status, routing, CTI, or recordings
4. Read [references/test-scenarios.md](references/test-scenarios.md) when designing ACs, test cases, or review checks
5. Read `10_Standards/DOMAIN/STD_Call_Center_Engineering.md` if the project adopts the call-center engineering standard
6. Apply the role-specific checks below
7. Write down any project-specific terms or exceptions back into `memory/domain_call_center.md`

## Role-Specific Guidance

### Interviewer / PM

Always clarify:

- Is this inbound, outbound, blended, or omnichannel?
- What is the user role: agent, supervisor, QA, admin, campaign manager?
- What starts the interaction: incoming call, preview dial, callback, transfer, queue event?
- What KPIs matter: AHT, ASA, service level, abandon rate, occupancy, QA score?
- What compliance rules matter: recording, masking, retention, consent, audit trail?
- What external systems are involved: PBX, SIP trunk, CTI, CRM, ticketing, SSO?
- What exact event or status transition should trigger the feature?
- Which edge case matters most: abandon, hold, transfer, callback, reconnect, or duplicate events?

Do not stop at CRUD wording like "建立通話資料". Ask for the real workflow and edge cases.

### Architect / Backend / DBA

Check the design for:

- Call state vs agent state are modeled separately
- Queueing and routing rules are explicit
- Event ordering and reconciliation strategy exist
- CTI / PBX / CRM failures have degradation paths
- Recording, transcript, and audit references are traceable
- Tenant, campaign, queue, and agent boundaries are explicit
- KPI-impacting timestamps are explicit and auditable
- Supervisor, QA, and agent views do not silently reuse conflicting meanings

Do not assume the system is only request/response. Many contact-center features are event-driven and real-time.

### QA

Minimum scenarios to consider:

- queue wait -> answer -> hold -> transfer -> wrap-up
- missed call / abandon / callback
- agent pause / resume / logout during active or pending work
- screen pop mismatch
- recording missing / delayed / masked incorrectly
- duplicate events or out-of-order events
- reconnect / refresh during active interaction
- state mismatch between CTI source and application UI

### Review

Look for common domain mistakes:

- agent state and call state collapsed into one field
- queue assignment treated as static CRUD data
- no disposition / wrap-up handling
- no audit trail for transfer, pause reason, or recording linkage
- only happy path tested; no routing or telephony failure path covered

## Deliverable Expectations

For call-center features, prefer explicit domain notes in the normal artifacts:

- PM: actors, workflows, SLA/KPI assumptions, edge cases
- Architect: event flow, state model, external integration boundaries
- Backend: event sources, idempotency, reconciliation, audit data
- QA: routing, state transitions, timing-sensitive scenarios
- Review: domain correctness, not only code cleanliness

If the feature is high-impact, add a short section named `Call Center Domain Notes` to the main artifact and capture:

- relevant role
- relevant queue / campaign / channel
- state transitions touched
- external systems involved
- KPI or compliance impact

## Project Memory

This skill works best when the project keeps a local domain file:

- `memory/domain_call_center.md`

Use it to record:

- your product's specific terminology
- supported channels
- PBX / CTI / CRM integration facts
- KPI definitions
- compliance and retention rules
- domain exceptions that differ from the generic references

## When To Extend

If the same rules keep recurring, move them into one of these places:

- project-specific facts -> `memory/domain_call_center.md`
- stable engineering constraints -> `10_Standards/`
- workflow heuristics shared across projects -> this skill's references
