# Call Center Domain Map

## 1. Common Modes

- Inbound: customer initiates the interaction
- Outbound: platform or agent initiates the interaction
- Blended: agents handle both inbound and outbound
- Omnichannel: voice plus chat, email, messaging, or social

## 2. Common Roles

- Agent: handles customer interactions
- Supervisor: monitors queue and agent performance
- QA: reviews recordings and scorecards
- Admin: manages configuration, queues, campaigns, permissions
- Campaign Manager: manages outbound lists, scripts, pacing, and results

## 3. Core Concepts

- Queue: waiting area before an interaction is assigned
- Routing: how the system chooses the next agent or team
- IVR: menu / pre-routing flow before an agent picks up
- ACD: automatic call distribution logic
- CTI: computer telephony integration between telephony and business apps
- Softphone: browser or desktop phone interface
- Disposition: outcome code after the interaction
- Wrap-up: post-call work before the agent is available again
- Recording: audio archive tied to an interaction
- Screen pop: automatically opening customer context on answer

## 4. Data / State Boundaries

Keep these separate unless there is a deliberate reason not to:

- Agent State
  Examples: available, busy, wrap-up, paused, offline

- Interaction State
  Examples: queued, ringing, connected, on-hold, transferred, ended, failed

- Queue / Routing Context
  Examples: skill group, priority, campaign, SLA bucket

- Outcome / Audit Context
  Examples: disposition code, QA score, recording id, transfer history

## 5. Typical Workflows

### Inbound

1. Customer calls
2. IVR collects context
3. Interaction enters queue
4. Routing picks target agent
5. Agent answers
6. Hold / transfer / consult may occur
7. Call ends
8. Wrap-up and disposition
9. Recording / audit / CRM updates finalize

### Outbound

1. Lead or callback target selected
2. Dialing rule applies
3. Agent or dialer initiates contact
4. Connection result captured
5. Script / CRM action happens
6. Disposition logged
7. Follow-up task or retry policy applies

## 6. Metrics That Often Matter

- AHT: average handling time
- ASA: average speed of answer
- Service Level: answered within target threshold
- Abandon Rate: callers who leave before answer
- Occupancy: active work time ratio
- FCR: first contact resolution
- QA Score: quality review result

Do not use metric names loosely. Confirm exact formulas per project in `memory/domain_call_center.md`.

## 7. Integration Checklist

- PBX / SIP / telephony vendor
- CTI event source
- CRM / ticketing target
- Recording storage
- SSO / identity provider
- Callback or campaign source

## 8. Common Risks

- Event ordering mismatch between telephony and CRM
- Duplicate callbacks or duplicate interaction records
- Missing recording links
- Agent state drift after reconnect or browser refresh
- Queue metrics computed from incomplete timestamps
- Disposition saved without confirming call end state
- PII exposure in transcripts, notes, or recordings

## 9. Minimum Questions For New Features

- Which role uses this?
- At what point in the interaction lifecycle does it appear?
- Does it change routing, agent state, interaction state, or only display information?
- What external system is source-of-truth?
- What must be auditable later?
- Which KPI could this feature improve or damage?
