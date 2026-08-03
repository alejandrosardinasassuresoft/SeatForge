# Technical Decisions

## 1. Registration lifecycle status model

### Context
The platform needs a consistent interpretation of registration states so that capacity, waitlist ordering, and hold expiration behave consistently across the domain layer and future lifecycle services.

### Decision
SeatForge uses the canonical registration statuses `held`, `confirmed`, `waitlisted`, `cancelled`, and `expired` on the `Registration` model.

### Alternatives considered
- Using separate boolean flags for each lifecycle state.
- Storing lifecycle state in a separate table.

### Why this approach was selected
A single status field keeps the model simple, matches Rails conventions, and makes the query layer explicit and reusable for later services and APIs.

### Trade-offs
The design is intentionally simple and does not yet represent a full transition audit history.

## 2. Capacity and active-registration interpretation

### Context
Capacity must be derived from domain state rather than from a manually editable counter.

### Decision
The system treats `confirmed` registrations and only `held` registrations with `hold_expires_at > Time.current` as capacity consumers. `waitlisted` registrations and expired holds do not consume capacity.

### Alternatives considered
- Persisting an `available_seats` column that could drift from reality.
- Treating all active registrations as capacity consumers.

### Why this approach was selected
This keeps availability derived from the source of truth and prevents stale or inconsistent capacity numbers.

### Trade-offs
The logic depends on the registration status values remaining consistent and well understood by the team.

## 8. Hold confirmation eligibility

### Decision
Only an unexpired `held` registration can transition to `confirmed`. Confirming an already-confirmed registration is idempotent; confirming a hold at or after its expiry returns the `422 hold_expired` error envelope, and confirming waitlisted, cancelled, or expired registrations returns a lifecycle conflict without mutation.

### Why this approach was selected
The Rails service remains the lifecycle authority even when a Vue countdown or button state is stale. This protects capacity and gives every client the same UTC boundary behavior.

## 3. Query API for registration state

### Context
The lifecycle work and later APIs need a stable, reusable way to answer questions such as “who is consuming capacity?”, “who is eligible for promotion?”, and “which holds have expired?”

### Decision
The `Registration` model exposes explicit query scopes for these concerns:
- `active_capacity_consumers`
- `eligible_waitlist_order`
- `expired_holds`

### Alternatives considered
- Scattering SQL fragments in controllers and services.
- Re-implementing the same filters in multiple places.

### Why this approach was selected
The scopes make the semantics clear and keep the domain logic centralized.

### Trade-offs
The implementation prioritizes clarity and reuse over a more abstract query object layer.

## 4. Seed data and reproducibility

### Context
The project needs demo data that is deterministic and can be reloaded without manual database editing.

### Decision
Seed data is defined in `backend/db/seeds.rb` and uses `find_or_create_by!` so the seed process is repeatable from a clean database.

### Alternatives considered
- Hard-coded fixtures only for local development.
- Manual database edits for demos.

### Why this approach was selected
Keeping the data in one seed file makes local setup reproducible and lowers the risk of drift.

### Trade-offs
The seed set is intentionally compact and focused on the required scenarios rather than exhaustive sample data.

## 5. Session cancellation idempotency result

### Context
Organizer cancellation (`POST /api/v1/sessions/:id/cancel`) may be retried because of network failures, double-clicks, or stale client state. The operation must not apply its side effects twice.

### Decision
Cancelling a session is idempotent. Repeating the request on an already-cancelled session returns `200 OK` with the persisted cancellation metadata and a zeroed `cancelled_registrations` count, and enqueues no duplicate notifications. The session is locked for the duration of the cancellation transaction so concurrent cancellations serialize into the same terminal state.

### Alternatives considered
- Rejecting a repeated cancellation with an error that forces the client to reconcile state.
- Allowing repeat cancellation to overwrite the original reason or timestamp.

### Why this approach was selected
Returning the persisted result makes retries safe and matches how clients naturally recover from failed requests. Rejecting duplicates would require clients to handle a non-idempotent terminal operation.

### Trade-offs
The response cannot distinguish a first-time cancellation from a repeated one by status code alone; clients must inspect `cancelled_count` to tell whether this request performed the cancellation.

## 6. Unchanged-status rule for session cancellation

### Context
A cancelled session must leave every affected registration in a consistent terminal state, but already-terminal registrations must not be rewritten or re-counted.

### Decision
`held`, `confirmed`, and `waitlisted` registrations are cancelled together with the session in the same transaction. `expired` and already-`cancelled` registrations are left unchanged, and the response reports cancellation counts only for registrations this request actually cancelled.

### Alternatives considered
- Cancelling every registration on the session regardless of prior status.
- Leaving `held`/`confirmed` registrations intact so attendees keep their seats.

### Why this approach was selected
Rewriting terminal registrations would destroy audit information (original `cancelled_at`/`hold_expires_at`) and inflate the summary counts. Cancelling active registrations is required so capacity and waitlist state cannot outlive a cancelled session.

### Trade-offs
Because the rule is per-registration-status, the service must enumerate registrations by status within the locked transaction rather than issuing a single bulk update.

## 7. Notification eligibility for session cancellation

### Context
Attendees whose active booking is cancelled need to know the session is gone, but not every cancelled registration warrants a notification.

### Decision
The cancellation service enqueues one notification per `held` or `confirmed` registration cancelled by the request. `waitlisted`, `expired`, and already-`cancelled` registrations never trigger a notification, and a repeated (idempotent) cancellation enqueues none.

### Alternatives considered
- Notifying every registration affected by the cancellation, including waitlisted attendees.
- Enqueuing a single session-wide notification with no per-registration routing.

### Why this approach was selected
Only `held` and `confirmed` attendees hold a real seat that the cancellation takes away, so they are the ones with stale booking state. Routing by registration enables the existing per-registration job boundary and keeps payloads precise.

### Trade-offs
Waitlisted attendees are not proactively notified of the session's cancellation, so the catalogue must instead surface the cancelled status, reason, and cancellation time to all attendees.
