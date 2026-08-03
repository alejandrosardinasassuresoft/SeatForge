# SeatForge

Workshop and event seat management platform. Rails 7.2 API backend with a Vue 3 frontend.

## Repository Layout

- `backend/` — Rails API (Ruby 4.0, Rails 7.2). All backend commands run from this directory.
- `frontend/` — Vue 3 client.
- `docs/` — Jira user stories, swagger/OpenAPI procedure, Postman collection, and change-request contracts.
- `DECISIONS.md` — Record of technical decisions, including the session-cancellation contract.

## API Overview

Frontend-facing routes live under `/api/v1`. Shared JSON errors use this envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Human readable message",
    "details": []
  }
}
```

See `backend/docs/api_error_contract.md` for the full list of error codes and `backend/swagger/v1/swagger.yaml` for the OpenAPI spec. The generated interactive docs run at `http://localhost:3000/api-docs`.

## Attendee booking flow

Use `GET /api/v1/sessions/:id/availability` to read the authoritative booking counts. It returns `capacity`, `held_seats`, `confirmed_seats`, `waitlist_size`, and `available_seats`; only holds with an expiry later than the current UTC time consume a seat.

Create a booking with `POST /api/v1/sessions/:session_id/registrations` and an `attendee` name/email body. A `held` response includes `hold_expires_at`; confirm it before that UTC time through `POST /api/v1/registrations/:id/confirm`. A full session instead returns a `waitlisted` registration. Confirmation at or after expiry returns `422` with error code `hold_expired`.

For a manual Phase 3 demo, browse or filter the Vue catalogue, open a scheduled session, submit the registration form, and verify the held or waitlisted result. Confirm a held registration, then refresh the detail view or availability endpoint to observe the derived counts. Cancel through My Registrations and verify the history and availability refresh. Finally cancel a session through the API, refresh its detail page, and verify the reason/time and disabled booking controls.

## Session Cancellation

Organizers cancel a scheduled session that has not started through:

```
POST /api/v1/sessions/:id/cancel
```

The request body requires a non-empty cancellation reason:

```json
{
  "cancellation_reason": "Instructor unavailable"
}
```

The operation is transactional and idempotent. A successful cancellation returns `200 OK` with a summary of the session state and, per prior status, the newly cancelled registrations:

```json
{
  "session": {
    "id": 42,
    "status": "cancelled",
    "cancellation_reason": "Instructor unavailable",
    "cancelled_at": "2026-07-30T14:00:00.000Z"
  },
  "cancelled_registrations": {
    "held": 2,
    "confirmed": 1,
    "waitlisted": 0
  },
  "cancelled_count": 3
}
```

- `held`, `confirmed`, and `waitlisted` registrations are cancelled together with the session.
- `expired` and already-`cancelled` registrations are left unchanged and are not counted.
- Repeating the request returns the same summary with zero counts and enqueues no duplicate notifications.
- `held` and `confirmed` registrations cancelled by the request trigger one notification each.

The `GET /api/v1/sessions` catalogue and `GET /api/v1/sessions/:id` detail responses expose the cancellation state through `status`, `cancellation_reason`, and `cancelled_at`. Cancelled sessions are excluded from the catalogue search results.

### Conflict Behavior

Cancelled sessions are closed for registration and lifecycle actions. Attempting to register for a cancelled session returns `409 Conflict` with the established error envelope:

```json
{
  "error": {
    "code": "registration_unavailable",
    "message": "Session is not available for registration",
    "details": []
  }
}
```

Related conflict codes:

| Code | HTTP Status | Use |
| --- | --- | --- |
| `registration_unavailable` | 409 | Session is cancelled, completed, already started, or otherwise closed for registration. |
| `session_cancellation_unavailable` | 409 | Session is completed, already started, or otherwise unavailable for organizer cancellation. |

Stale UI state that submits a registration or confirmation action against a cancelled session receives these errors and must surface them safely to the attendee.
