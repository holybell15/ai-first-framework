# Call Center State And Event Model

## 1. Keep These Models Separate

Do not collapse these into one generic `status` unless the project explicitly proves it is safe:

### Agent State

Represents the working availability of the human or seat.

Typical values:

- offline
- available
- reserved
- busy
- wrap_up
- paused

### Interaction State

Represents the lifecycle of a call or contact.

Typical values:

- created
- queued
- routing
- ringing
- connected
- on_hold
- consult
- transferring
- ended
- failed
- abandoned

### Outcome State

Represents the result after the interaction is effectively over.

Typical values:

- disposition_selected
- callback_scheduled
- qa_pending
- recording_pending
- closed

## 2. Why This Separation Matters

- An agent may be `busy` while the call is `ringing`
- An agent may be `wrap_up` after the interaction is already `ended`
- A recording may still be `pending` after the interaction is finished
- A callback may exist without a live connected interaction

If these are collapsed into one field, reporting and routing logic usually becomes wrong.

## 3. Event Sources

Typical event sources in a call-center system:

- PBX / SIP / telephony vendor events
- CTI adapter events
- internal routing engine events
- CRM actions
- QA / supervisor actions
- browser UI actions

Document which source is authoritative for each event type.

## 4. Event Ordering Risks

Common problems:

- `ended` arrives before `connected` due to async processing
- duplicate `ringing` or `connected` events
- transfer emits two separate contact legs
- CRM save succeeds while CTI event is delayed
- browser refresh replays stale state

## 5. Recommended Modeling Checks

For architecture and backend design, make these explicit:

- interaction primary key vs telephony vendor call id
- parent-child relation for transfer legs
- event timestamp source and timezone
- idempotency key or dedupe rule
- retry / replay behavior
- reconciliation job for state drift

## 6. Minimum Audit Trail

At minimum, retain:

- queue entered time
- agent answered time
- hold start / end
- transfer start / target
- interaction end time
- wrap-up start / end
- disposition selection
- recording id or recording failure marker

## 7. KPI-Sensitive Timestamps

These often affect reporting:

- queue_entered_at
- answered_at
- connected_at
- ended_at
- wrap_up_completed_at
- callback_due_at

Be explicit about formula ownership. Different projects define AHT or service level differently.

## 8. Architecture Review Questions

- What is the source of truth for interaction state?
- Can the UI recover from duplicate or out-of-order events?
- How is transfer represented?
- What happens if recording metadata arrives late?
- How do we detect and repair state drift?
