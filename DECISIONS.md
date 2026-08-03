# SeatForge Technical Decisions

This record captures the architectural choices that govern the delivered lifecycle. Timestamps and comparisons below use UTC unless stated otherwise.

## 1. Derive capacity under the session locking boundary

### Context
Several attendees can allocate, confirm, cancel, or be promoted at the same time. A mutable `available_seats` counter can drift from registrations and allows race conditions when read/update steps are split.

### Alternatives considered

- Persist and decrement/increment an `available_seats` column.
- Count all non-terminal registrations as capacity consumers.
- Derive counts while serializing requests with application-only locks.

### Decision and rationale

Capacity is derived as `capacity - (confirmed + unexpired held)`. A held registration consumes a seat only when its `hold_expires_at` is later than the current UTC time. Allocation and state transitions lock the session row inside the database transaction, making the persisted registration records the single source of truth.

### Trade-offs

Availability queries perform counts rather than reading one counter, and the lifecycle code must consistently use the shared query/service boundary. The cost is acceptable for challenge-scale sessions and prevents stale capacity.

## 2. Model lifecycle as explicit statuses with safe, idempotent transitions

### Context
Attendee requests can be retried after a timeout or submitted from stale Vue state. Confirmation, cancellation, promotion, and expiry need a consistent state model.

### Alternatives considered

- Use separate boolean columns for every state.
- Permit controllers or the client to decide whether a transition is valid.
- Return an error for every repeated terminal request.

### Decision and rationale

Registrations use `held`, `confirmed`, `waitlisted`, `cancelled`, and `expired`. Services own transitions under the session lock. Confirmation accepts only an unexpired hold; already-confirmed behavior is idempotent, expired holds return `422 hold_expired`, and ineligible statuses do not mutate. Session cancellation is also idempotent and returns its persisted cancellation metadata on repeat.

### Trade-offs

Clients must reconcile response state rather than infer success from a button click, and some repeat requests need response inspection to distinguish first execution from a no-op. In return, retries preserve data integrity.

## 3. Separate job discovery, lifecycle mutation, and notification delivery

### Context
Expired holds must release capacity and promote a waitlisted attendee without external delivery failures changing registration state.

### Alternatives considered

- Run the expiry transition directly in a controller or notification job.
- Send notifications synchronously inside the database transaction.
- Require a concrete third-party provider to run local tests.

### Decision and rationale

`Registrations::ExpireHoldsJob` discovers expired holds, locks each session, expires eligible holds, and promotes the oldest waitlisted registration. `Registrations::SendNotificationJob` runs after the state change through a replaceable `NotificationAdapter`. Confirmation, promotion, and eligible session cancellation enqueue notifications only after lifecycle persistence succeeds.

### Trade-offs

The repository requires a deployment-selected scheduler and queue adapter; it intentionally does not include production scheduler/provider configuration. Notification delivery is eventually consistent, while lifecycle correctness is immediate and testable without credentials.

## 4. Use UTC as the lifecycle time boundary

### Context
Holds, confirmation, cancellation, and background jobs can run from hosts or browsers in different time zones. A local-time comparison makes expiration behavior ambiguous at the boundary.

### Alternatives considered

- Compare browser-local timestamps.
- Store local workshop times without a canonical comparison zone.
- Treat a hold as valid at its exact expiry instant.

### Decision and rationale

Rails persists and returns timestamps in UTC, and lifecycle rules compare against `Time.current` at the service/job boundary. A hold is valid only when `hold_expires_at > current_time`; equality is expired. The Vue client displays backend-provided timestamps and the backend remains authoritative for stale actions.

### Trade-offs

Presenters and users must interpret API timestamps as UTC unless the UI converts them for display. The explicit boundary eliminates timezone-dependent capacity results.

## 5. Keep cancellation transactional while preserving terminal history

### Context
Thursday's change request requires organizers to cancel a scheduled session with a reason, without leaving registrations or notification effects inconsistent.

### Alternatives considered

- Cancel the session and registrations in separate requests.
- Rewrite every registration status during cancellation.
- Reject duplicate cancellation calls.

### Decision and rationale

`POST /api/v1/sessions/:id/cancel` locks the session and updates the session plus held, confirmed, and waitlisted registrations in one transaction. Expired and already-cancelled registrations remain unchanged. Held/confirmed attendees receive one queued cancellation notification; waitlisted/terminal registrations do not. Repeated cancellation returns the original metadata and no new side effects.

### Trade-offs

The service has explicit per-status handling and reports counts for registrations changed by that call. This is more detailed than a bulk update but preserves audit meaning and retry safety.

## Thursday change-control record — session cancellation

### Trigger and impact

The Thursday change request introduced mandatory organizer session cancellation, cancellation notifications, and attendee-facing cancelled-session presentation. It affected shared session/registration lifecycle behavior, the API contract, OpenAPI/Postman examples, Vue action availability, and final delivery documentation.

### Ticket updates and owners

| Ticket | Accepted update | Owner |
| --- | --- | --- |
| SEAT-025 | Transactional, idempotent session cancellation with reason and registration updates | Alejandro |
| SEAT-026 | Notification eligibility and lifecycle regression protection | Carlos |
| SEAT-033 | Cancelled-session presentation, disabled invalid actions, README/API/demo updates | Josoe |

Alejandro owned the backend contract and coordinated the lifecycle impact; Carlos owned job/notification safeguards; Josoe owned the Vue presentation handoff.

### Accepted scope

- Add the cancellation fields, route, error handling, locking transaction, and idempotent response.
- Cancel held/confirmed/waitlisted registrations while preserving expired/already-cancelled history.
- Enqueue notifications only for held/confirmed registrations affected by the first cancellation.
- Present cancellation reason/time in Vue and prevent invalid registration/confirmation actions.
- Update Swagger, Postman, README, decisions, and the manual demo path.

### Deferred scope

- Optional automated frontend cancellation tests were replaced by a documented manual demo path for the fixed deadline.
- The Phase 4 cross-browser regression matrix was reduced to critical supported-browser checks.
- Authentication/authorization, external notification credentials, and a production scheduler remain outside this challenge scope.

### Scope-control outcome

The team preserved the capacity, locking, UTC, and lifecycle test boundaries. The change was delivered as focused, reviewed PRs rather than broadening the underlying API contract or duplicating lifecycle decisions in the frontend.