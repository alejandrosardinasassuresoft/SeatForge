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
The system treats `held` and `confirmed` registrations as capacity consumers. `waitlisted` registrations do not consume capacity.

### Alternatives considered
- Persisting an `available_seats` column that could drift from reality.
- Treating all active registrations as capacity consumers.

### Why this approach was selected
This keeps availability derived from the source of truth and prevents stale or inconsistent capacity numbers.

### Trade-offs
The logic depends on the registration status values remaining consistent and well understood by the team.

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
