# SeatForge — User Stories for JIRA

> JIRA-ready delivery backlog for the SeatForge limited-capacity workshop booking platform.
> **Team:** Alejandro, Josoe, Carlos · **Stack:** Rails 7 API + PostgreSQL + Vue 3 · **Window:** July 29–31, 2026.
>
> The allocation is deliberately Rails-heavy: **49 of 78 points (63%)** are Rails, database, API, job, or backend-test work. Every engineer owns a business-critical Rails endpoint end to end and contributes outside a controller.

---

## Working Agreements

### Estimation and ownership

| Engineer | Tickets | Points | Rails-focused points | Personally owned Rails endpoint(s) |
|---|---:|---:|---:|---|
| Carlos | 6 | 26 | 15 | `POST /workshops/:workshop_id/sessions`, `GET /sessions/:id/availability` |
| Alejandro | 6 | 26 | 15 | `POST /sessions/:session_id/registrations` |
| Josoe | 6 | 26 | 19 | `POST /registrations/:id/confirm`, `POST /registrations/:id/cancel` |
| **Total** | **18** | **78** | **49** | |

Each endpoint owner delivers its route, controller, domain/service logic, persistence interaction, error response, and request specs in their own PR. A ticket may name collaborators, but the assignee remains accountable for the Definition of Done.

### Common Definition of Done

- Feature branch, focused PR, meaningful commits, and one peer review from another team member.
- Rails code follows the versioned `/api/v1` JSON contract and uses UTC / ISO 8601 timestamps.
- Request/service/model/job tests cover successful and relevant failure paths; the documented backend suite passes.
- No credentials or generated dependency directories are committed.
- API changes include sample request/response or an update to the endpoint summary in `README.md`.

### Integration contract to agree before implementation

| Concern | Team agreement |
|---|---|
| Active capacity | `held` registrations with a future `hold_expires_at` plus `confirmed` registrations. Availability is derived, never stored. |
| Statuses | Session: `scheduled`, `cancelled`, `completed`. Registration: `held`, `confirmed`, `waitlisted`, `cancelled`, `expired`. |
| Error body | `{ "error": { "code": "machine_code", "message": "Human-readable message", "details": [] } }` with validation errors distinct from conflicts. |
| Concurrency boundary | Lifecycle services lock the session row in a DB transaction before calculating capacity or promoting a waitlisted registration. |
| Time | Persist and exchange UTC / ISO 8601; test clock-sensitive behavior with Rails time helpers. |
| Notification boundary | A replaceable notification adapter is invoked by an ActiveJob; it may persist/log locally but has no real provider dependency. |

---

## Phase 0 — Foundation and Team Contracts

### SEAT-001 — Initialize Rails API, PostgreSQL, and Backend Test Baseline

| Field | Value |
|---|---|
| Phase | 0 — Foundation |
| Type | Backend / DevOps |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | None |

#### Description

As a team, we need a runnable Rails API with PostgreSQL and RSpec so that lifecycle work is built and tested on the required platform.

#### Acceptance Criteria

- [ ] `backend/` is a Rails 7 API application using Ruby 3.x and PostgreSQL for development and test.
- [ ] RSpec, FactoryBot, and test-time helpers are configured; one documented command runs the suite.
- [ ] `GET /up` returns `200`; `.env.example` documents non-secret settings.
- [ ] Repository ignores credentials, local env files, logs, temp files, and dependency directories.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Own only backend bootstrap/config and testing configuration. Do not add domain models in this ticket.

#### How to Verify

Run the README setup, `rails db:prepare`, `bundle exec rspec`, and `curl http://localhost:3000/up`.

#### Commit Message

`chore(backend): initialize Rails API with PostgreSQL and RSpec`

---

### SEAT-002 — Establish API Contract, CORS, and Error Rendering

| Field | Value |
|---|---|
| Phase | 0 — Foundation |
| Type | Backend |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-001 |

#### Description

As a frontend consumer, I need consistent versioned JSON API responses and errors so that user-visible state and conflicts can be handled reliably.

#### Acceptance Criteria

- [ ] `/api/v1` routing namespace exists and CORS permits the local Vue origin.
- [ ] Validation, not-found, and domain-conflict errors use the agreed error envelope and appropriate 4xx codes.
- [ ] Request specs prove the error structure for at least one validation and one conflict case.
- [ ] Error codes are documented for frontend use.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Provide reusable application-level rendering only; lifecycle-specific conflict decisions stay with the owner of the lifecycle ticket.

#### How to Verify

Run the error request specs and invoke representative invalid JSON requests.

#### Commit Message

`feat(api): add v1 JSON error contract and CORS`

---

### SEAT-003 — Initialize Vue 3 Application and Shared API Boundary

| Field | Value |
|---|---|
| Phase | 0 — Foundation |
| Type | Frontend |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | None |

#### Description

As a developer, I need a Vue 3 application with an isolated API client so that views do not duplicate HTTP and error-handling logic.

#### Acceptance Criteria

- [ ] `frontend/` contains a Vue 3 + Vite application with a documented start command.
- [ ] Environment-based API base URL and development proxy target Rails locally.
- [ ] API client centralizes JSON requests and maps the agreed backend error envelope.
- [ ] Base loading, empty, success, and error presentation components exist.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Do not hard-code lifecycle rules in Vue; Rails responses remain the source of truth.

#### How to Verify

Start both applications and confirm a sample API request is visible in the UI or browser network panel.

#### Commit Message

`chore(frontend): initialize Vue app and API client boundary`

---

## Phase 1 — Rails Domain and Data Integrity

### SEAT-010 — Build Workshop and Session Domain with Availability Endpoint

| Field | Value |
|---|---|
| Phase | 1 — Rails Domain |
| Type | Backend |
| Assignee | Carlos |
| Priority | High |
| Story Points | 6 |
| Dependencies | SEAT-001, SEAT-002 |

#### Description

As an organizer and attendee, I need workshops and scheduled sessions, including trustworthy availability, so that sessions can be published and booked without a mutable seat counter.

#### Acceptance Criteria

- [ ] Migrations/models implement Workshop and Session associations and allowed statuses.
- [ ] Workshop title/topic are required; session capacity is positive and `starts_at < ends_at`.
- [ ] `POST /api/v1/workshops`, `GET /api/v1/workshops`, `GET /api/v1/workshops/:id`, and `POST /api/v1/workshops/:workshop_id/sessions` work with documented JSON.
- [ ] Owned business-critical `GET /api/v1/sessions/:id/availability` returns capacity, held seats, confirmed seats, waitlist size, and derived available seats.
- [ ] Model and request specs cover invalid dates/capacity, status behavior, and availability response shape.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Expose a single reusable availability query/method. The later Registration model supplies counts; coordinate its interface with SEAT-012 before merging.

#### How to Verify

Create a workshop/session, request its availability, and run related RSpec files.

#### Commit Message

`feat(workshops): add sessions and derived availability API`

---

### SEAT-011 — Build Attendee Identity and Registration Persistence Rules

| Field | Value |
|---|---|
| Phase | 1 — Rails Domain |
| Type | Backend |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 4 |
| Dependencies | SEAT-010 |

#### Description

As the booking workflow, I need reliable attendee identity and registration persistence rules so that duplicates cannot undermine lifecycle logic.

#### Acceptance Criteria

- [ ] Attendee migration/model requires name and case-insensitively unique email, backed by an appropriate database index.
- [ ] Registration belongs to attendee and session and stores status plus hold/confirmation/cancellation timestamps.
- [ ] Database/model rules prevent more than one active registration for the same attendee and session.
- [ ] Associations, status constraints, and uniqueness behavior have model specs.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Define active statuses jointly with SEAT-012. This ticket owns attendee identity and the structural registration schema; it must not implement lifecycle services.

#### How to Verify

Run model specs that attempt mixed-case duplicate emails and duplicate active registrations.

#### Commit Message

`feat(registrations): add attendee identity and persistence rules`

---

### SEAT-012 — Define Registration State Query Layer, Seeds, and Referential Decisions

| Field | Value |
|---|---|
| Phase | 1 — Rails Domain |
| Type | Backend |
| Assignee | Josoe |
| Priority | High |
| Story Points | 4 |
| Dependencies | SEAT-010, SEAT-011 |

#### Description

As a Rails developer, I need clear registration state scopes and reproducible data so that lifecycle services, APIs, and demonstrations use one definition of capacity and eligibility.

#### Acceptance Criteria

- [ ] Registration scopes/query methods express active capacity consumers, eligible waitlist order, and expired holds.
- [ ] Referential deletion/archive behavior for dependent records is selected and recorded in `DECISIONS.md`.
- [ ] Seeds create at least four workshops, eight upcoming sessions, eight attendees, all registration statuses, a full session, and a visible waitlist.
- [ ] Seed setup is deterministic and does not require manual database edits.
- [ ] Query/model specs cover scope semantics.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Publish the stable query API used by SEAT-021, SEAT-022, SEAT-023, and SEAT-024. Keep seed data in `db/seeds.rb` only.

#### How to Verify

Run `rails db:seed` from a clean database and inspect the required scenario through Rails console/API.

#### Commit Message

`feat(domain): add registration state queries and reproducible seeds`

---

## Phase 2 — Critical Registration Lifecycle

### SEAT-021 — Create Held or Waitlisted Registration with Capacity Locking

| Field | Value |
|---|---|
| Phase | 2 — Lifecycle |
| Type | Backend |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 8 |
| Dependencies | SEAT-011, SEAT-012 |

#### Description

As an attendee, I want to register for a session so that I receive a ten-minute seat hold when capacity exists or a waitlist position when it does not.

#### Acceptance Criteria

- [ ] Owned endpoint `POST /api/v1/sessions/:session_id/registrations` finds/creates attendee identity and returns held or waitlisted registration JSON.
- [ ] A service object performs validation and seat allocation in a transaction while locking the session (or an approved equivalent).
- [ ] It rejects cancelled, completed, started, duplicate-active, and overlapping held/confirmed-session cases with distinguishable errors.
- [ ] Available capacity creates `held` with a UTC expiration ten minutes ahead; full capacity creates `waitlisted`.
- [ ] Request and service specs cover each transition/error plus a repeated/near-concurrent capacity test showing active registrations never exceed capacity.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

This is Alejandro’s complete Rails defense slice: route, controller, service, persistence, error translation, and API tests. Reuse SEAT-012 scopes; do not calculate counts in the controller.

#### How to Verify

Use seeded full and available sessions; run the lifecycle specs, including the capacity protection example.

#### Commit Message

`feat(registrations): allocate held seats or waitlist safely`

---

### SEAT-022 — Confirm, Cancel, and Promote Registrations Idempotently

| Field | Value |
|---|---|
| Phase | 2 — Lifecycle |
| Type | Backend |
| Assignee | Josoe |
| Priority | High |
| Story Points | 8 |
| Dependencies | SEAT-012, SEAT-021 |

#### Description

As an attendee, I want to confirm or cancel my registration so that my booking status is accurate and released seats are offered fairly to the oldest eligible waitlisted attendee.

#### Acceptance Criteria

- [ ] Owned endpoints `POST /api/v1/registrations/:id/confirm` and `/cancel` return consistent JSON and status codes.
- [ ] Confirmation only succeeds for unexpired holds, sets `confirmed_at`, clears `hold_expires_at`, and safely repeats without duplicate effects.
- [ ] Cancellation supports held, confirmed, and waitlisted registrations; sets `cancelled_at` and is idempotent.
- [ ] Releasing a held/confirmed seat locks the session and promotes the oldest eligible waitlisted registration to a new ten-minute hold in the same workflow.
- [ ] Service and request specs cover valid/invalid transitions, idempotency, promotion ordering, and notification enqueueing.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Extract confirmation/cancellation/promotion services; coordinate notification adapter calls with SEAT-023. Do not modify the registration-creation allocation logic owned by SEAT-021.

#### How to Verify

Seed a full session with a waitlist, cancel a confirmed booking, and confirm the first waitlisted attendee becomes held exactly once.

#### Commit Message

`feat(lifecycle): confirm cancel and promote registrations safely`

---

### SEAT-023 — Expire Holds and Deliver Replaceable Notifications

| Field | Value |
|---|---|
| Phase | 2 — Lifecycle |
| Type | Backend |
| Assignee | Carlos |
| Priority | High |
| Story Points | 6 |
| Dependencies | SEAT-012, SEAT-022 |

#### Description

As an organizer, I need abandoned holds to expire and waitlisted attendees to be notified so that capacity returns automatically without real-provider dependencies.

#### Acceptance Criteria

- [ ] An ActiveJob/service finds holds past `hold_expires_at`, marks them expired, and no longer counts them as capacity consumers.
- [ ] Each released seat triggers safe oldest-eligible waitlist promotion using the shared locking workflow.
- [ ] Repeated expiration execution is idempotent and cannot double-promote a seat.
- [ ] Confirmation and promotion notifications enqueue a job through a replaceable adapter that is testable without credentials.
- [ ] Job/service specs cover expiration, safe repeat runs, promotion, and notification enqueueing.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Agree with Josoe on a small callable promotion boundary rather than copying promotion logic. Document how the job is invoked locally/scheduled.

#### How to Verify

Use time travel to expire a seeded hold, perform the job twice, and prove only one promotion occurs.

#### Commit Message

`feat(jobs): expire holds and enqueue lifecycle notifications`

---

### SEAT-024 — Deliver Session Search, Details, Attendee History, and Dashboard Queries

| Field | Value |
|---|---|
| Phase | 2 — API Queries |
| Type | Backend |
| Assignee | Josoe |
| Priority | High |
| Story Points | 5 |
| Dependencies | SEAT-010, SEAT-012 |

#### Description

As an attendee or organizer, I need searchable session data, my registration history, and operational metrics so that I can choose sessions and understand booking operations.

#### Acceptance Criteria

- [ ] `GET /api/v1/sessions` supports date range, topic, available-only filters, documented sort options, pagination, and a maximum page size.
- [ ] `GET /api/v1/sessions/:id` returns session, workshop, derived availability, and relevant counts without obvious N+1 queries.
- [ ] `GET /api/v1/attendees/:attendee_id/registrations` returns persisted status history.
- [ ] `GET /api/v1/dashboard` returns all required metrics, full sessions, and top three sessions by waitlist size.
- [ ] Query/request specs cover filters, pagination boundaries, response structure, and metric correctness.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Implementation Notes

Use named scopes/query objects and eager loading. This ticket owns read-only API controllers and query objects, not lifecycle transitions.

#### How to Verify

Load seeds and exercise the documented example query strings; inspect SQL/logs for avoidable N+1 behavior.

#### Commit Message

`feat(api): add session search attendee history and dashboard queries`

---

## Phase 3 — Vue Integration and Evidence

### SEAT-030 — Build Workshop Catalog and Session Detail Experience

| Field | Value |
|---|---|
| Phase | 3 — Vue Integration |
| Type | Frontend |
| Assignee | Carlos |
| Priority | Medium |
| Story Points | 5 |
| Dependencies | SEAT-003, SEAT-010, SEAT-024 |

#### Description

As an attendee, I need a catalog and session detail view so that I can discover upcoming workshops and see backend-derived capacity before registering.

#### Acceptance Criteria

- [ ] Catalog displays active workshops/upcoming sessions and date/topic/availability filters.
- [ ] Detail displays schedule, capacity, held/confirmed counts, waitlist size, and available seats.
- [ ] Views use the shared API client and show loading, empty, and API-specific error states.
- [ ] Navigation and browser refresh work from persisted backend data.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`feat(frontend): add workshop catalog and session detail views`

---

### SEAT-031 — Build Registration and Hold-Confirmation Flow

| Field | Value |
|---|---|
| Phase | 3 — Vue Integration |
| Type | Full-Stack Integration |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 5 |
| Dependencies | SEAT-003, SEAT-021, SEAT-022, SEAT-030 |

#### Description

As an attendee, I need a clear registration and confirmation flow so that I understand whether I hold a seat or joined the waitlist and can act before expiry.

#### Acceptance Criteria

- [ ] Form collects name/email and creates registrations against the selected session.
- [ ] Held and waitlisted responses are visibly distinct; backend conflict messages are preserved.
- [ ] Held registration shows backend-provided expiration and permits confirmation only when the backend allows it.
- [ ] Availability/detail data refresh after creation or confirmation.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`feat(frontend): add registration and hold confirmation flow`

---

### SEAT-032 — Build My Registrations and Operations Dashboard Experience

| Field | Value |
|---|---|
| Phase | 3 — Vue Integration |
| Type | Frontend |
| Assignee | Josoe |
| Priority | Medium |
| Story Points | 4 |
| Dependencies | SEAT-003, SEAT-022, SEAT-023, SEAT-024 |

#### Description

As an attendee or organizer, I need my registrations and operational metrics presented clearly so that I can cancel allowed registrations and monitor waitlist/capacity state.

#### Acceptance Criteria

- [ ] Attendee lookup shows registrations/statuses and only actions allowed by the current backend state.
- [ ] Cancellation displays backend errors and refreshes registration and capacity data after success.
- [ ] Dashboard renders every required metric and top waitlisted sessions.
- [ ] All views support loading, empty, success, and error states.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`feat(frontend): add registrations and operations dashboard views`

---

## Phase 4 — Delivery Readiness, Documentation, and Quality

### SEAT-050 — Produce README, Ownership Matrix, and Demo Narrative

| Field | Value |
|---|---|
| Phase | 4 — Delivery |
| Type | Docs / QA |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-001 through SEAT-032 |

#### Description

As a reviewer, I need reproducible setup, endpoint, ownership, and demo documentation so that I can assess the application from a clean clone.

#### Acceptance Criteria

- [ ] README covers product, prerequisites, setup, seeds, start/test commands, endpoints, domain, capacity strategy, jobs, limitations, and AI-assistance disclosure.
- [ ] Ownership matrix identifies each Rails endpoint owner, related PR, and peer review reference.
- [ ] A concise team demo narrative covers hold, waitlist, confirm, cancel, promotion, expiration, filters, dashboard, and individual defenses.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`docs: add reproducible setup ownership matrix and demo guide`

---

### SEAT-051 — Record Technical Decisions and Thursday Change-Control Process

| Field | Value |
|---|---|
| Phase | 4 — Delivery |
| Type | Docs / Process |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-021, SEAT-022, SEAT-023 |

#### Description

As a reviewer, I need defensible technical decisions and visible scope control so that the team’s lifecycle and delivery trade-offs are understandable.

#### Acceptance Criteria

- [ ] `DECISIONS.md` documents at least four decisions with context, alternatives, rationale, and trade-offs.
- [ ] At least two decisions cover locking/capacity, lifecycle/idempotency, jobs/notifications, or UTC time handling.
- [ ] A change-request section records impact, ticket updates, accepted/deferred scope, and owner when Thursday’s request arrives.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`docs: record lifecycle decisions and change-control process`

---

### SEAT-052 — Perform Backend Quality Gate and Clean-Clone Validation

| Field | Value |
|---|---|
| Phase | 4 — Delivery |
| Type | Backend / QA |
| Assignee | Josoe |
| Priority | High |
| Story Points | 2 |
| Dependencies | SEAT-050, SEAT-051 |

#### Description

As the team, we need a final backend quality gate so that the submitted main branch is runnable, tested, and honest about remaining limitations.

#### Acceptance Criteria

- [ ] Clean-clone setup succeeds using README instructions, including database preparation, seeds, backend tests, and frontend start.
- [ ] Backend suite includes at least 10 model/service/job and 10 request/API examples, with all critical lifecycle rules represented.
- [ ] Final regression exercises capacity protection, idempotency, expiration, promotion, filters, and dashboard.
- [ ] Known limitations and any unfinished requirements are documented; discovered defects are fixed or entered as explicit follow-up issues.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`test: validate clean clone and critical booking lifecycle`

---

### SEAT-053 — Execute Final Integration, PR Review, and Release Checklist

| Field | Value |
|---|---|
| Phase | 4 — Delivery |
| Type | Integration / QA |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-050, SEAT-051, SEAT-052 |

#### Description

As a team, we need a reviewed integration checkpoint so that main remains runnable and final ownership/PR evidence meets the assessment requirements.

#### Acceptance Criteria

- [ ] Every engineer has reviewed at least one meaningful PR with a useful comment, question, or approval rationale.
- [ ] Each owner can trace their endpoint through route, controller, service/query/job, persistence, and request specs.
- [ ] Main branch runs the full demo flow and contains no unresolved critical integration defect.
- [ ] Final submission checklist contains repository URL, main commit hash, documentation, migrations/seeds, tests, task evidence, PRs/reviews, ownership matrix, and limitations.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`chore(release): complete final integration and submission checklist`

---

## Summary: Ticket Distribution by Assignee

### Carlos — Rails foundation, workshop/session API, expiration jobs, catalog

| ID | Title | Phase | Points |
|---|---|---:|---:|
| SEAT-001 | Initialize Rails API, PostgreSQL, and Backend Test Baseline | 0 | 3 |
| SEAT-010 | Build Workshop and Session Domain with Availability Endpoint | 1 | 6 |
| SEAT-023 | Expire Holds and Deliver Replaceable Notifications | 2 | 6 |
| SEAT-030 | Build Workshop Catalog and Session Detail Experience | 3 | 5 |
| SEAT-050 | Produce README, Ownership Matrix, and Demo Narrative | 4 | 3 |
| SEAT-053 | Execute Final Integration, PR Review, and Release Checklist | 4 | 3 |
| **Total** | | | **26** |

### Alejandro — API contracts, attendee data, safe seat allocation, registration UI

| ID | Title | Phase | Points |
|---|---|---:|---:|
| SEAT-002 | Establish API Contract, CORS, and Error Rendering | 0 | 3 |
| SEAT-011 | Build Attendee Identity and Registration Persistence Rules | 1 | 4 |
| SEAT-021 | Create Held or Waitlisted Registration with Capacity Locking | 2 | 8 |
| SEAT-031 | Build Registration and Hold-Confirmation Flow | 3 | 5 |
| SEAT-051 | Record Technical Decisions and Thursday Change-Control Process | 4 | 3 |
| SEAT-054 | Cross-Browser API Contract Regression and Handoff | 4 | 3 |
| **Total** | | | **26** |

### Josoe — Vue foundation, domain queries, confirm/cancel lifecycle, dashboard

| ID | Title | Phase | Points |
|---|---|---:|---:|
| SEAT-003 | Initialize Vue 3 Application and Shared API Boundary | 0 | 3 |
| SEAT-012 | Define Registration State Query Layer, Seeds, and Referential Decisions | 1 | 4 |
| SEAT-022 | Confirm, Cancel, and Promote Registrations Idempotently | 2 | 8 |
| SEAT-024 | Deliver Session Search, Details, Attendee History, and Dashboard Queries | 2 | 5 |
| SEAT-032 | Build My Registrations and Operations Dashboard Experience | 3 | 4 |
| SEAT-052 | Perform Backend Quality Gate and Clean-Clone Validation | 4 | 2 |
| **Total** | | | **26** |

> **Note:** SEAT-054 is defined immediately after this allocation so the three-way ticket/point balance remains explicit.

### SEAT-054 — Cross-Browser API Contract Regression and Handoff

| Field | Value |
|---|---|
| Phase | 4 — Delivery |
| Type | Frontend / QA |
| Assignee | Alejandro |
| Priority | Medium |
| Story Points | 3 |
| Dependencies | SEAT-030, SEAT-031, SEAT-032, SEAT-052 |

#### Description

As the team, we need a final browser-to-API contract pass so that the released Vue flows faithfully display Rails-derived lifecycle state after refresh and errors.

#### Acceptance Criteria

- [ ] Exercise catalog, registration, confirmation, cancellation, attendee history, and dashboard against the final API.
- [ ] Confirm conflict/error codes are shown as useful messages and no view assumes a client-side state transition.
- [ ] Record final handoff findings in the README/known limitations and fix release-blocking integration defects.


## Edge Cases

- [ ] Invalid or missing input returns the agreed API error contract.
- [ ] Repeated/concurrent execution preserves data integrity.
- [ ] Empty, time-boundary, and unavailable-dependency behavior is verified where applicable.
#### Commit Message

`test(frontend): verify final API contract and lifecycle handoff`

---

## Dependency Graph and Critical Path

```text
SEAT-001 ──> SEAT-002 ──> SEAT-010 ──┬──> SEAT-011 ──> SEAT-012 ──> SEAT-021 ──> SEAT-022 ──> SEAT-023
                                     │                                      │               │
SEAT-003 ────────────────────────────┘                                      │               └──> SEAT-032
                                                                            │
SEAT-024 <─────────────────────────────────────────────────────────────────┘
     │                 │
     └──> SEAT-030 ────┴──> SEAT-031 ──> SEAT-054

SEAT-023 + SEAT-030 + SEAT-031 + SEAT-032 ──> SEAT-050 / SEAT-051 ──> SEAT-052 ──> SEAT-053
```

**Critical path:** SEAT-001 → SEAT-010 → SEAT-011 → SEAT-012 → SEAT-021 → SEAT-022 → SEAT-023 → SEAT-052 → SEAT-053.

## Merge-Conflict Prevention and Integration Rules

| Area / files | Primary editor | Contributors | Rule |
|---|---|---|---|
| Rails bootstrap, Gemfile, config, RSpec setup | Carlos | Everyone via review | Freeze after SEAT-001; later config edits require Carlos review. |
| Routes and application-wide error contract | Alejandro | Endpoint owners | Endpoint owner proposes route additions; Alejandro batches route/error-contract changes in a short integration PR. |
| Workshop/Session models, migrations, availability query | Carlos | Josoe consumes | Carlos adds new migrations for this aggregate; never edit an already-merged migration. |
| Attendee/Registration schema | Alejandro | Josoe adds scopes | Alejandro owns schema migrations; Josoe adds query scopes in a separate commit after merge. |
| Lifecycle services | Alejandro: create; Josoe: confirm/cancel/promotion; Carlos: expiration/job | Shared interface by agreement | One service class per workflow; share a small promotion method rather than editing each other’s service. |
| Read-only queries/controllers | Josoe | Carlos supplies availability contract | Josoe owns search/dashboard/history; avoid touching lifecycle controllers. |
| Vue API client/base components | Josoe | Carlos/Alejandro use it | Public API client changes are announced before merge; views stay in feature-specific folders. |
| Vue catalog/detail | Carlos | — | No lifecycle form code in these components. |
| Vue registration/confirmation | Alejandro | — | Uses shared client and route names; no direct Axios calls inside components. |
| Vue attendee/dashboard | Josoe | — | Uses shared client and route names; no direct Axios calls inside components. |
| README / DECISIONS | Carlos / Alejandro | All provide content | Append or edit assigned sections only; one docs PR at a time near final delivery. |

Operational rules:

1. Create migrations only on the latest `main`; use a new migration to amend any merged schema decision.
2. Keep PRs narrow: one ticket unless a tiny dependent contract change is explicitly called out.
3. Rebase immediately before requesting review; the next ticket starts only after its listed dependency is merged or a stable interface is agreed in writing.
4. When a shared contract changes, update the relevant ticket acceptance criteria and notify all three developers before code changes.
5. Pair/review the locking and promotion boundary: those changes affect the capacity invariant and require a second set of eyes.

## Suggested Delivery Sequence

| Checkpoint | Carlos | Alejandro | Josoe |
|---|---|---|---|
| Wednesday morning | SEAT-001 | Plan SEAT-002 contract | SEAT-003 |
| Wednesday afternoon | SEAT-010 | SEAT-002, then SEAT-011 | Plan/implement SEAT-012 after schema merge |
| Thursday morning | Start SEAT-023 interface review | SEAT-021 | SEAT-022 design and SEAT-024 query scaffolding |
| Thursday afternoon | SEAT-023 | SEAT-031 | SEAT-022, SEAT-024 |
| Friday morning | SEAT-030, SEAT-050 | SEAT-031, SEAT-051 | SEAT-032, SEAT-052 |
| Friday afternoon | SEAT-053 | SEAT-054 | Support regression, peer reviews, and defense rehearsal |

## Complete Ticket Inventory

| Phase | Tickets | Points |
|---|---:|---:|
| Phase 0 — Foundation | SEAT-001 → SEAT-003 | 9 |
| Phase 1 — Rails Domain | SEAT-010 → SEAT-012 | 14 |
| Phase 2 — Lifecycle / Queries | SEAT-021 → SEAT-024 | 27 |
| Phase 3 — Vue Integration | SEAT-030 → SEAT-032 | 14 |
| Phase 4 — Delivery | SEAT-050 → SEAT-054 | 14 |
| **Total** | **18 tickets** | **78** |



## Added Architecture and Quality Stories

---

### SEAT-013 � Implement AvailabilityQuery

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-010, SEAT-012 |

#### Description

As a delivery team, we need Reusable capacity counts for availability, detail, search, and dashboard consumers.

#### Acceptance Criteria

- [ ] AvailabilityQuery returns derived capacity; excludes expired holds; query specs cover collection performance.

## Edge Cases

- [ ] No registrations; expiry boundary; unknown session.

#### Rails Components

app/queries/availability_query.rb

#### Commit Message

`feat(architecture): deliver 013` 

---

### SEAT-014 � Document Application Architecture and Layering Rules

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-001, SEAT-003 |

#### Description

As a delivery team, we need Define Rails and Vue responsibilities before lifecycle implementation.

#### Acceptance Criteria

- [ ] ARCHITECTURE.md documents controllers, services, queries, jobs, adapters, models, serializers, Vue folders, and dependency rules.

## Edge Cases

- [ ] Controller orchestration; query mutation boundary; refresh after conflict.

#### Rails Components

ARCHITECTURE.md

#### Commit Message

`feat(architecture): deliver 014` 

---

### SEAT-025 � Implement PromoteWaitlistService

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-012, SEAT-013 |

#### Description

As a delivery team, we need Promote the oldest eligible waitlist entry when a seat is released.

#### Acceptance Criteria

- [ ] Service accepts locked session; creates ten-minute hold; transaction/order/no-op specs pass.

## Edge Cases

- [ ] Empty waitlist; ineligible oldest entry; concurrent release.

#### Rails Components

app/services/promote_waitlist_service.rb

#### Commit Message

`feat(architecture): deliver 025` 

---

### SEAT-026 � Implement ExpireHoldService

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-012, SEAT-025 |

#### Description

As a delivery team, we need Expire a single abandoned hold independently from scheduling.

#### Acceptance Criteria

- [ ] Service expires only past-due holds; locks session; promotes in same transaction; time-helper tests pass.

## Edge Cases

- [ ] Exact expiry; already non-held; session lock contention.

#### Rails Components

app/services/expire_hold_service.rb

#### Commit Message

`feat(architecture): deliver 026` 

---

### SEAT-027 � Implement ExpireHoldsJob

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-026 |

#### Description

As a delivery team, we need Process abandoned holds in background.

#### Acceptance Criteria

- [ ] ActiveJob delegates candidates to ExpireHoldService; schedule is documented; retry-safe job specs pass.

## Edge Cases

- [ ] State changes after selection; one execution fails; overlapping lifecycle job.

#### Rails Components

app/jobs/expire_holds_job.rb

#### Commit Message

`feat(architecture): deliver 027` 

---

### SEAT-028 � Implement Notification Adapter and Job

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-022, SEAT-025 |

#### Description

As a delivery team, we need Deliver confirmation and promotion notifications behind a replaceable boundary.

#### Acceptance Criteria

- [ ] Fake adapter and notification job exist; no credentials required; enqueue/delivery tests pass.

## Edge Cases

- [ ] Missing record; transient adapter error; replayed event.

#### Rails Components

app/adapters/, app/jobs/registration_notification_job.rb

#### Commit Message

`feat(architecture): deliver 028` 

---

### SEAT-029 � Implement CreateRegistrationService

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 5 |
| Dependencies | SEAT-011, SEAT-012, SEAT-013 |

#### Description

As a delivery team, we need Isolate locking, conflict checks, hold creation, and waitlisting from controller code.

#### Acceptance Criteria

- [ ] Service returns held/waitlisted or typed error; locks session; tests prove no overbooking.

## Edge Cases

- [ ] Final-seat race; duplicate retry; case-insensitive email.

#### Rails Components

app/services/create_registration_service.rb

#### Commit Message

`feat(architecture): deliver 029` 

---

### SEAT-033 � Implement ConfirmRegistrationService

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-012, SEAT-028 |

#### Description

As a delivery team, we need Confirm an eligible hold idempotently.

#### Acceptance Criteria

- [ ] Service clears hold expiry, sets confirmation, queues one notification, and has service tests.

## Edge Cases

- [ ] Expiry during request; already confirmed; enqueue failure.

#### Rails Components

app/services/confirm_registration_service.rb

#### Commit Message

`feat(architecture): deliver 033` 

---

### SEAT-034 � Implement CancelRegistrationService

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-012, SEAT-025 |

#### Description

As a delivery team, we need Cancel a registration and release/promote safely.

#### Acceptance Criteria

- [ ] Service supports allowed statuses; locks and promotes in same transaction; repeat tests pass.

## Edge Cases

- [ ] Already cancelled; promotion becomes ineligible; waitlist cancel.

#### Rails Components

app/services/cancel_registration_service.rb

#### Commit Message

`feat(architecture): deliver 034` 

---

### SEAT-035 � Implement SessionSearchQuery

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-010, SEAT-013 |

#### Description

As a delivery team, we need Provide reusable session filtering, sorting, pagination, and eager loading.

#### Acceptance Criteria

- [ ] Query supports required filters/sorts/page cap; controller has no complex SQL; specs cover behavior/performance.

## Edge Cases

- [ ] Invalid date range; unsupported sort; page beyond results.

#### Rails Components

app/queries/session_search_query.rb

#### Commit Message

`feat(architecture): deliver 035` 

---

### SEAT-036 � Implement Dashboard and Registration History Queries

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Josoe |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-012, SEAT-013 |

#### Description

As a delivery team, we need Provide efficient read models for dashboard and attendee history.

#### Acceptance Criteria

- [ ] DashboardQuery and RegistrationHistoryQuery return required data; SEAT-024 consumes them; specs prove accuracy.

## Edge Cases

- [ ] Zero data; tie at top-three boundary; unknown attendee.

#### Rails Components

app/queries/dashboard_query.rb, app/queries/registration_history_query.rb

#### Commit Message

`feat(architecture): deliver 036` 

---

### SEAT-055 � Create OpenAPI Foundation and Shared Schemas

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-002, SEAT-014 |

#### Description

As a delivery team, we need Define reusable API documentation before endpoint integration.

#### Acceptance Criteria

- [ ] OpenAPI 3.x has server/tags/common errors/pagination/timestamps/status enums; README explains validation.

## Edge Cases

- [ ] Invalid timestamp; evolving code; undocumented response.

#### Rails Components

openapi/seatforge.yaml

#### Commit Message

`feat(architecture): deliver 055` 

---

### SEAT-056 � Document and Validate OpenAPI Endpoint Contracts

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Carlos |
| Priority | High |
| Story Points | 2 |
| Dependencies | SEAT-010, SEAT-021, SEAT-022, SEAT-024, SEAT-055 |

#### Description

As a delivery team, we need Document mandatory endpoints and prevent contract drift.

#### Acceptance Criteria

- [ ] All required paths, parameters, responses, and lifecycle examples exist; validator passes.

## Edge Cases

- [ ] Invalid filters; conflict vs validation; schema drift.

#### Rails Components

openapi/seatforge.yaml, validation command

#### Commit Message

`feat(architecture): deliver 056` 

---

### SEAT-058 � Add Vue Component and API Integration Tests

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-030, SEAT-031, SEAT-032 |

#### Description

As a delivery team, we need Verify critical Vue rendering and API-result handling.

#### Acceptance Criteria

- [ ] Tests cover availability, registration results, dashboard errors, API envelope, and unavailable API.

## Edge Cases

- [ ] Conflict envelope; unmount during request; zero metrics.

#### Rails Components

frontend tests

#### Commit Message

`feat(architecture): deliver 058` 

---

### SEAT-060 � Add Critical Vue User-Flow Regression Tests

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 4 |
| Dependencies | SEAT-031, SEAT-032, SEAT-058 |

#### Description

As a delivery team, we need Verify end-to-end browser flows remain driven by Rails state.

#### Acceptance Criteria

- [ ] Tests cover held/waitlisted, confirm/cancel refresh, history, dashboard; documented command blocks release.

## Edge Cases

- [ ] Hold expires; availability changes; browser refresh.

#### Rails Components

frontend flow tests

#### Commit Message

`feat(architecture): deliver 060` 

---

### SEAT-061 � Final Architecture and Contract Review

| Field | Value |
|---|---|
| Phase | Architecture / Lifecycle / Quality |
| Type | Backend / Docs / Testing |
| Assignee | Alejandro |
| Priority | High |
| Story Points | 3 |
| Dependencies | SEAT-014, SEAT-056, SEAT-053 |

#### Description

As a delivery team, we need Review service/query/job/API boundaries before delivery.

#### Acceptance Criteria

- [ ] Architecture docs, OpenAPI, and final code have no unresolved ownership or dependency mismatch; peer-review evidence exists.

## Edge Cases

- [ ] Late scope change; missing review; mismatch between docs and code.

#### Rails Components

ARCHITECTURE.md, OpenAPI, PR checklist

#### Commit Message

`feat(architecture): deliver 061` 

## Enhanced Summary

| Engineer | Tickets | Points |
|---|---:|---:|
| Carlos | 12 | 43 |
| Alejandro | 11 | 44 |
| Josoe | 11 | 41 |
| **Total** | **34** | **128** |

The original allocation remains intact; added architecture work is intentionally Rails-heavy. The original dependency graph remains valid, with the new service/query/job tickets inserted ahead of their consuming endpoints/jobs.

## Enhanced Definition of Done

Relevant service, query, job, OpenAPI, and Vue-flow boundaries are documented and tested. The OpenAPI validator and critical Vue tests pass before release.
---

# Consolidated Architecture and Delivery Amendments

> This section is part of the consolidated backlog and supersedes any earlier duplicate summary where it conflicts. It incorporates the applicable strengths of Carlos's review without changing SeatForge scope, its Rails-first architecture, existing story IDs, or the 34-story decomposition.

## Final Ownership and Equity Check

| Engineer | Tickets | Points | Critical Rails ownership |
|---|---:|---:|---|
| Carlos | 12 | 43 | Workshop/session creation and availability; availability query; expiration service/job; notification boundary |
| Alejandro | 11 | 44 | API contract; attendee persistence; create-registration service and endpoint; OpenAPI; frontend flow tests |
| Josoe | 11 | 41 | Registration-state queries; confirm/cancel endpoints; promotion, confirmation, cancellation, and read-query services |
| **Total** | **34** | **128** | |

34 cannot divide equally by three; the 12/11/11 ticket split is the closest possible. The three-point maximum story-point difference is acceptable because each engineer owns a complete critical Rails endpoint and has comparable lifecycle/domain responsibility.

## Architecture Decisions Applied to Existing Stories

| Existing stories | Consolidated decision / deliverable |
|---|---|
| SEAT-001 | Use Rails 7 API mode, PostgreSQL, RSpec, FactoryBot, Rails transactional tests, and time helpers. DatabaseCleaner and Shoulda Matchers remain optional rather than mandatory. |
| SEAT-002, SEAT-055, SEAT-056 | Standard error codes are `validation_error` (422), `registration_conflict` (409), `not_found` (404), and `hold_expired` (422). OpenAPI is the published contract and includes these reusable responses. |
| SEAT-010, SEAT-013 | Derived availability is `capacity - (confirmed + valid held)`. A valid held registration is `held` with `hold_expires_at > Time.current`; availability is never persisted as writable state. |
| SEAT-011, SEAT-012 | Enforce case-insensitive attendee email with a PostgreSQL `LOWER(email)` unique index. Treat `held`, `confirmed`, and `waitlisted` as active for duplicate-registration protection; record this explicit interpretation in `DECISIONS.md`. |
| SEAT-021, SEAT-029 | The controller remains thin and delegates to `Registrations::CreateService`. The service performs the entire decision under a transaction with the session row locked using `session.lock!` / `with_lock`. |
| SEAT-022, SEAT-025, SEAT-033, SEAT-034 | Keep confirmation, cancellation, and promotion separate service objects. Cancellation/expiration call the shared promotion service; no workflow duplicates promotion logic. |
| SEAT-023, SEAT-026, SEAT-027, SEAT-028 | The expiration job discovers candidates only; `ExpireHoldService` performs the transition. Notifications are post-state-change ActiveJob work through a replaceable adapter and never alter lifecycle state. |
| SEAT-024, SEAT-035, SEAT-036 | Controllers consume query objects. Search sorting is whitelisted, `per_page` has a documented maximum of 50, and detail/list queries use eager loading where needed. |
| SEAT-030, SEAT-031, SEAT-032, SEAT-058, SEAT-060 | Vue consumes Rails state through the shared API client. Suggested ownership-safe files are `CatalogView.vue`, `SessionDetailView.vue`, `RegistrationForm.vue`, `HoldConfirmation.vue`, `MyRegistrationsView.vue`, and `DashboardView.vue`. |
| SEAT-052 | Verify N+1 prevention through query/request tests and query inspection; do not require a tool-specific claim of “zero warnings.” |

## Detailed Acceptance Amendments

### SEAT-010 / SEAT-013 — Availability Contract

Add these acceptance checks:

- [ ] `GET /api/v1/sessions/:id/availability` returns `capacity`, `held_seats`, `confirmed_seats`, `waitlist_size`, and `available_seats`.
- [ ] `AvailabilityQuery` is the only capacity-calculation boundary used by availability, detail, search, and dashboard consumers.
- [ ] The implementation handles an empty registration set and excludes expired holds without a cleanup job having run first.

#### Gherkin Acceptance Scenario

```gherkin
Scenario: Querying derived session availability
  Given a session with capacity 10, 3 confirmed registrations, and 2 unexpired held registrations
  When I request GET /api/v1/sessions/:id/availability
  Then the response contains capacity 10, confirmed_seats 3, held_seats 2, and available_seats 5
```

### SEAT-021 / SEAT-029 — Capacity-Protection Contract

Add these acceptance checks:

- [ ] The `POST /api/v1/sessions/:session_id/registrations` controller delegates to `Registrations::CreateService` and contains no capacity SQL.
- [ ] The service locks the session before counting active capacity and creating a held/waitlisted registration.
- [ ] Cancelled, completed, or started sessions are rejected; duplicate or overlapping active registrations return `409 registration_conflict`.
- [ ] A full session returns a persisted waitlisted registration rather than an error.

#### Gherkin Acceptance Scenario

```gherkin
Scenario: Concurrent requests for the final seat
  Given a session with capacity 5 and 4 confirmed registrations
  When 3 attendees submit registration requests concurrently
  Then exactly 1 registration is held with a ten-minute expiry
  And the remaining registrations are waitlisted
  And held plus confirmed registrations never exceed 5
```

### SEAT-022 / SEAT-025 / SEAT-033 / SEAT-034 — Transition Contract

Add these acceptance checks:

- [ ] `ConfirmRegistrationService` returns a stable success outcome for an already-confirmed registration and queues notification only for the first transition.
- [ ] An expired hold returns `422 hold_expired` and cannot be confirmed.
- [ ] `CancelRegistrationService` is idempotent for held, confirmed, and waitlisted registrations.
- [ ] A cancellation releasing capacity invokes `PromoteWaitlistService` under the same session lock; the oldest eligible `created_at ASC` waitlist entry receives a fresh ten-minute hold.
- [ ] Cancelling a waitlisted registration does not release capacity or trigger promotion.

### SEAT-026 / SEAT-027 / SEAT-028 — Background-Work Contract

Add these acceptance checks:

- [ ] `ExpireHoldsJob` selects records where `status = held` and `hold_expires_at <= Time.current`, then delegates each record to `ExpireHoldService`.
- [ ] Re-running expiration is safe: already-expired records are no-ops and no released seat is promoted twice.
- [ ] `RegistrationNotificationJob` accepts a persisted event payload and invokes an adapter; an adapter failure is observable/retryable but does not reverse a committed registration state.
- [ ] Job tests cover no candidates, multiple candidates, repeated runs, a state change after candidate selection, and adapter failure.

### SEAT-024 / SEAT-035 / SEAT-036 — Read-Model Contract

Add these acceptance checks:

- [ ] `SessionSearchQuery` accepts `from`, `to`, `topic`, `available`, `sort`, `page`, and `per_page`; unsupported sort values and `from > to` are validation errors.
- [ ] `per_page` is capped at 50 and pagination returns a valid empty response when the requested page has no records.
- [ ] `DashboardQuery` returns all mandated metrics and deterministic top-three waitlist results; `RegistrationHistoryQuery` returns persisted statuses in a documented order.
- [ ] Query specs demonstrate eager-loading or equivalent behavior for collection consumers to avoid obvious N+1 queries.

### SEAT-055 / SEAT-056 — OpenAPI Definition of Done

Add these acceptance checks:

- [ ] `openapi/seatforge.yaml` is OpenAPI 3.x and documents workshop, session, availability, registration, attendee-history, and dashboard paths.
- [ ] Shared schemas cover error envelope, pagination metadata, UTC ISO 8601 timestamps, and all session/registration status enums.
- [ ] Registration examples show held, waitlisted, confirmed, cancelled, and conflict/expired-hold responses.
- [ ] A documented OpenAPI validation command passes before final release.

### SEAT-058 / SEAT-060 — Frontend Verification Contract

Add these acceptance checks:

- [ ] Component/API-client tests cover loading, empty, success, conflict, validation-error, and unavailable-API states.
- [ ] Critical-flow tests cover registration to held/waitlisted result, confirmation, cancellation with refreshed availability, attendee history, and dashboard navigation.
- [ ] A countdown is presentation only; each action is reconciled from the Rails response and remains correct after browser refresh.

## Consolidated Verification Commands

| Area | Required command or check |
|---|---|
| Backend suite | `bundle exec rspec` |
| Create-registration service and request contract | `bundle exec rspec spec/services/registrations/create_service_spec.rb spec/requests/api/v1/registrations_create_spec.rb` |
| Lifecycle jobs | `bundle exec rspec spec/jobs` |
| Frontend build | `npm run build` |
| Frontend focused tests | Document the project-selected `npm run test` command in README |
| OpenAPI | Document and run the selected validator command in README/CI |

## Merge-Safety Clarifications

- Alejandro owns registration schema/error-contract changes and the Create Registration service boundary.
- Josoe owns confirm/cancel/promotion and read-query implementation; changes to shared registration scopes require Alejandro review.
- Carlos owns availability, expiration/job/adapter boundaries and architecture/OpenAPI validation; changes to shared locking/promotion behavior require Josoe review.
- Every lifecycle PR must state the affected service/query/job contract and include the corresponding request/service/job tests.

