# SeatForge Team Demo Narrative

Use a freshly prepared local database (`bin/rails db:prepare; bin/rails db:seed`) and keep the Rails server, Vue client, and Postman collection available. All timestamps shown by the API are UTC.

## 1. Catalogue and filters — Carlos

1. Open the Vue catalogue and filter by a topic, date, and available-session state.
2. Show loading/result/empty behavior, then open a session detail page.
3. Point out authoritative availability and the workshop/session metadata returned by the API.

**Defense:** why filters are passed through the shared API client and why availability is calculated on the server.

## 2. Hold and waitlist — Alejandro

1. Select a session with seats and submit a new attendee name/email.
2. Show the distinct held result and the backend-supplied UTC `hold_expires_at`.
3. Use a full seeded session or fill a small-capacity session, then register another attendee and show the visibly different waitlist outcome.

**Defense:** allocation locks the session row; only confirmed and unexpired held registrations consume capacity, preventing oversubscription under concurrent requests.

## 3. Confirm, cancel, and promotion — Josoe

1. Confirm the held registration before expiry and show the confirmed state plus refreshed session availability.
2. Cancel a confirmed registration and show the registration/history refresh.
3. Run the expiry scenario against a local held registration (or use the job spec/manual job invocation) and show the oldest waitlisted registration becoming a new hold.

**Defense:** confirmation/cancellation are lifecycle transitions, repeated terminal actions are idempotent or safely rejected, and promotion uses the same server lifecycle boundary.

## 4. Expiration boundary — Carlos

1. Show a hold whose expiration is at or before the current UTC time.
2. Attempt confirmation and show the preserved `422 hold_expired` error envelope.
3. Refresh availability to show that the expired hold no longer consumes a seat.

**Defense:** the exact `hold_expires_at > current UTC time` rule is used in both capacity reads and confirmation eligibility.

## 5. Session cancellation change request — Alejandro and Josoe

1. In Postman, cancel a scheduled session with `POST /api/v1/sessions/:id/cancel` and a non-empty `cancellation_reason`.
2. Repeat the call to demonstrate the idempotent response and zero new cancellation side effects.
3. Refresh the Vue catalogue/detail page: show cancelled status, reason, and time; registration and confirmation controls are unavailable.

**Defense:** the cancellation transaction changes held, confirmed, and waitlisted registrations together; expired/already-cancelled records remain intact. Notifications are queued only for affected held/confirmed attendees.

## 6. Dashboard and attendee history — Josoe

1. Open My Registrations for a known attendee and show lifecycle history.
2. Open the operations dashboard and relate its counts to the same derived registration state.

**Defense:** read models use dedicated query boundaries instead of duplicating database logic in controllers or views.

## Close-out checklist

- Mention the shared JSON error envelope and show one validation or conflict response.
- Point reviewers to `/api-docs`, the Postman collection, the README, ownership matrix, and `DECISIONS.md`.
- Each presenter owns the defense topic identified above; do not claim unconfigured external notification delivery or a production scheduler.