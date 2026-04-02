# Call Center Test Scenarios

## 1. Minimum Main Flow

For every core call-center feature, cover at least:

1. queue / trigger enters system
2. routing selects target
3. interaction reaches the correct user context
4. action completes
5. wrap-up / outcome is recorded

## 2. Core Scenario Library

### Routing / Queue

- correct queue selected by channel, skill, or priority
- queue overflow or timeout fallback
- unavailable agent is not assigned
- reserved agent becomes disconnected before answer

### Interaction Lifecycle

- ringing -> connected -> ended
- queued -> abandoned
- connected -> hold -> resume -> ended
- connected -> transfer -> new leg created -> original leg closed
- connected -> consult -> complete transfer / cancel transfer

### Agent State

- available -> busy -> wrap_up -> available
- pause during idle
- pause request during active interaction
- browser refresh while busy / wrap_up
- logout blocked when unfinished work exists

### Recording / Audit

- recording link available after interaction
- recording delayed but eventually attached
- recording failure creates visible alert or audit flag
- disposition change is audited

### CRM / Screen Pop

- customer record screen pop matches interaction
- missing CRM record fallback
- duplicate customer match fallback
- CRM unavailable but telephony still active

### Outbound / Campaign

- preview dial accepted / rejected
- no-answer / busy / voicemail outcomes
- retry policy and callback scheduling
- disposition rules by campaign

## 3. Edge Cases Review Must Ask About

- out-of-order events
- duplicate events
- missed recording
- transfer to invalid target
- agent state drift after reconnect
- KPI timestamp missing or overwritten
- wrap-up submitted twice

## 4. Lite Mode Minimum Evidence

If running Lite Mode, keep at least:

- 1 main-flow validation
- 1 critical failure-path validation
- 1 audit / recording / disposition validation

## 5. Suggested Test Report Section

For call-center features, include a short section:

```markdown
## Call Center Domain Coverage

- Routing covered: [yes/no]
- State transitions covered: [list]
- Recording / audit covered: [yes/no]
- External integration fallback covered: [yes/no]
- KPI-sensitive timestamps checked: [yes/no]
```
