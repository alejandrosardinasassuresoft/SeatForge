# SeatForge — Thursday Change Request: Session Cancellation

> **Source:** `CD2.1-SeatForge_Thursday_Change_Request.pdf` (July 30, 2026).  
> **Scope:** This addendum preserves the existing consolidated backlog and adds the mandatory change-request work at the end of Phase 2. It uses the same Rails-first contract, UTC timestamps, error envelope, and pull-request workflow. IDs `SEAT-025` to `SEAT-033` avoid reusing the supplemental IDs already reserved in the consolidated backlog.

## Change Summary

Organizers must be able to cancel a scheduled session with a required reason. The operation must be transactional and idempotent: it cancels the session and its held, confirmed, and waitlisted registrations together; leaves expired and already-cancelled registrations unchanged; and notifies affected held/confirmed attendees exactly once. The Vue client must present the cancellation state and prevent registration or confirmation actions.

## Re-prioritization

The team will not reduce capacity, locking, or lifecycle coverage. To absorb this mandatory change within the fixed deadline, the optional automated frontend cancellation tests are replaced by a documented manual-demo path, while the planned Phase 4 cross-browser regression matrix is reduced to critical supported-browser checks. README/API documentation and `DECISIONS.md` updates move into SEAT-033 rather than waiting for final documentation work.

## Phase 2 — Critical Registration Lifecycle (Change Request Additions)

### SEAT-025 — Cancel a Session Transactionally

| Field | Value |
|---|---|
| Phase | 2 — Lifecycle |
| Type | Backend |
| Assignee | Alejandro |
| Priority | Mandatory |
| Story Points | 4 |
| Dependencies | SEAT-010, SEAT-012, SEAT-021, SEAT-022 |

#### Description

As an organizer, I need to cancel a scheduled session safely so that all affected registrations have a consistent terminal state.

#### Acceptance Criteria

- [ ] A reversible migration adds nullable `cancellation_reason` and `cancelled_at` fields to sessions.
- [ ] `POST /api/v1/sessions/:id/cancel` requires a non-empty `cancellation_reason` and returns the existing validation envelope for invalid input.
- [ ] A service locks the session and, in one transaction, marks it cancelled and cancels associated `held`, `confirmed`, and `waitlisted` registrations.
- [ ] `expired` and already `cancelled` registrations are unchanged; the response reports cancellation counts by prior status.
- [ ] Repeating cancellation is idempotent: no state is changed again and the original cancellation result is returned without duplicate side effects.
- [ ] New registration attempts against the cancelled session return the established conflict response.

#### How to Verify

Run request and service specs for a successful cancellation, missing reason, mixed registration states, repeat cancellation, and a rejected new registration.

#### Commit Message

`feat(sessions): cancel sessions and registrations transactionally`

---

### SEAT-026 — Notify Affected Attendees and Protect Lifecycle Regressions

| Field | Value |
|---|---|
| Phase | 2 — Lifecycle |
| Type | Backend / Jobs / Testing |
| Assignee | Carlos |
| Priority | Mandatory |
| Story Points | 4 |
| Dependencies | SEAT-023, SEAT-025 |

#### Description

As an affected attendee, I need a cancellation notification when my held or confirmed registration is cancelled so that I do not rely on stale booking state.

#### Acceptance Criteria

- [ ] The existing replaceable notification boundary enqueues one job for each held or confirmed registration cancelled by SEAT-025.
- [ ] Waitlisted, expired, and already-cancelled registrations do not produce cancellation notifications.
- [ ] Repeat cancellation enqueues no duplicate notifications.
- [ ] Job/service/request specs prove notification eligibility, transaction-safe registration updates, and no regression to hold expiry, confirmation, cancellation, or waitlist-promotion behavior.
- [ ] The backend change is delivered through a focused PR with peer review evidence.

#### How to Verify

Cancel a seeded session containing all registration states, inspect enqueued jobs, repeat the request, and run the lifecycle and job specs.

#### Commit Message

`feat(notifications): notify attendees of session cancellations`

---


## Phase 3 — Vue Integration (Change Request Addition)

### SEAT-033 — Present Cancelled Sessions and Document the Contract

| Field | Value |
|---|---|
| Phase | 3 — Vue Integration |
| Type | Frontend / Documentation |
| Assignee | Josoe |
| Priority | Mandatory |
| Story Points | 4 |
| Dependencies | SEAT-003, SEAT-025, SEAT-026, SEAT-030, SEAT-031 |

#### Description

As an attendee, I need to see why a session was cancelled and be prevented from taking invalid lifecycle actions.

#### Acceptance Criteria

- [ ] Session catalogue/detail and registration-related views show `cancelled` status, reason, and cancellation time from the API.
- [ ] Registration and confirmation controls are disabled or hidden for cancelled sessions; API conflict errors remain safely displayed if stale UI state submits an action.
- [ ] README and API examples document the cancellation endpoint, required request body, summary response, and cancelled-session conflict behavior.
- [ ] `DECISIONS.md` records the idempotency result, the unchanged-status rule, and notification eligibility.
- [ ] A manual demo script proves the cancelled UI state and disabled actions; automated frontend tests are optional under the change request.

#### How to Verify

Cancel a session through the API, refresh the Vue views, confirm the reason is visible, and verify registration/confirmation cannot be initiated.

#### Commit Message

`feat(frontend): present cancelled sessions and disable booking actions`

---

## Summary: Ticket Distribution by Assignee

The original plan assigns 26 points to each engineer. The change request adds one four-point ticket per engineer, preserving exact equity: 30 points and seven tickets each.

### Carlos (Rails foundation, session lifecycle jobs, catalogue)

| ID | Title | Phase | Points |
|---|---|---:|---:|
| Existing backlog | SEAT-001, SEAT-010, SEAT-023, SEAT-030, SEAT-050, SEAT-053 | 0–4 | 26 |
| SEAT-026 | Notify Affected Attendees and Protect Lifecycle Regressions | 2 | 4 |
| **Total** | **7 tickets** | | **30** |

### Alejandro (API contracts, attendee data, registration UI)

| ID | Title | Phase | Points |
|---|---|---:|---:|
| Existing backlog | SEAT-002, SEAT-011, SEAT-021, SEAT-031, SEAT-051, SEAT-054 | 0–4 | 26 |
| SEAT-025 | Cancel a Session Transactionally | 2 | 4 |
| **Total** | **7 tickets** | | **30** |

### Josoe (Vue foundation, domain queries, confirmation/cancellation lifecycle)

| ID | Title | Phase | Points |
|---|---|---:|---:|
| Existing backlog | SEAT-003, SEAT-012, SEAT-022, SEAT-024, SEAT-032, SEAT-052 | 0–4 | 26 |
| SEAT-033 | Present Cancelled Sessions and Document the Contract | 3 | 4 |
| **Total** | **7 tickets** | | **30** |
## Complete Ticket Inventory

| Phase | Tickets | Points |
|---|---:|---:|
| Phase 0: Foundation | SEAT-001 → SEAT-003 (3 tickets) | 9 |
| Phase 1: Rails Domain | SEAT-010 → SEAT-012 (3 tickets) | 14 |
| Phase 2: Lifecycle / Queries | SEAT-021 → SEAT-026 (6 tickets) | 35 |
| Phase 3: Vue Integration | SEAT-030 → SEAT-033 (4 tickets) | 18 |
| Phase 4: Delivery | SEAT-050 → SEAT-054 (5 tickets) | 14 |
| **Total** | **21 tickets** | **90** |
## Dependency Index

| Ticket | Depends on | Ticket | Depends on |
|---|---|---|---|
| SEAT-001 | None | SEAT-002 | SEAT-001 |
| SEAT-003 | None | SEAT-010 | SEAT-001, SEAT-002 |
| SEAT-011 | SEAT-010 | SEAT-012 | SEAT-010, SEAT-011 |
| SEAT-021 | SEAT-011, SEAT-012 | SEAT-022 | SEAT-012, SEAT-021 |
| SEAT-023 | SEAT-012, SEAT-022 | SEAT-024 | SEAT-010, SEAT-012 |
| SEAT-025 | SEAT-010, SEAT-012, SEAT-021, SEAT-022 | SEAT-026 | SEAT-023, SEAT-025 |
| SEAT-030 | SEAT-003, SEAT-010, SEAT-024 | SEAT-031 | SEAT-003, SEAT-021, SEAT-022, SEAT-030 |
| SEAT-032 | SEAT-003, SEAT-022, SEAT-023, SEAT-024 | SEAT-033 | SEAT-003, SEAT-025, SEAT-026, SEAT-030, SEAT-031 |
| SEAT-050 | SEAT-001 through SEAT-033 | SEAT-051 | SEAT-021, SEAT-022, SEAT-023, SEAT-025, SEAT-026 |
| SEAT-052 | SEAT-050, SEAT-051 | SEAT-053 | SEAT-050, SEAT-051, SEAT-052 |
| SEAT-054 | SEAT-030, SEAT-031, SEAT-032, SEAT-033, SEAT-052 | — | — |
## Dependency Graph (Updated Critical Path)

```text
SEAT-001 → SEAT-002 → SEAT-010 → SEAT-011 → SEAT-012
                                             ├→ SEAT-021 → SEAT-022 → SEAT-023
                                             ├→ SEAT-024 → SEAT-030 → SEAT-031
                                             └→ SEAT-025 → SEAT-026 → SEAT-033

SEAT-003 ───────────────────────────────────────→ SEAT-030 / SEAT-031 / SEAT-033

SEAT-023 + SEAT-025 + SEAT-026 + SEAT-033 → SEAT-050 / SEAT-051 → SEAT-052 → SEAT-053
```

**Change-request critical path:** SEAT-010 → SEAT-011 → SEAT-012 → SEAT-021 → SEAT-022 → SEAT-025 → SEAT-026 → SEAT-033 → SEAT-052 → SEAT-053.
## Delivery Sequence

| Order | Work | Owner | Handoff |
|---:|---|---|---|
| 1 | Agree cancellation response/error codes and notification payload | All | Recorded interface before coding |
| 2 | Deliver migration, cancellation service, route, and request specs | Alejandro | SEAT-025 PR merged/reviewed |
| 3 | Add notification eligibility, idempotency, and lifecycle regressions | Carlos | SEAT-026 PR merged/reviewed |
| 4 | Update Vue cancelled state, README/API examples, decisions, and demo script | Josoe | SEAT-033 PR merged/reviewed |
| 5 | Run full suite and final cancellation demo | All | Evidence attached to SEAT-052/SEAT-053 |
