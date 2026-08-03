# SeatForge

SeatForge is a limited-capacity workshop-booking application. A Rails 7 JSON API and PostgreSQL own the registration lifecycle; a Vue 3 + Vite client lets attendees browse sessions, register, confirm holds, cancel registrations, and review their history.

## Repository layout

| Path | Purpose |
| --- | --- |
| `backend/` | Rails API, database migrations/seeds, RSpec suite, and RSwag/OpenAPI output. |
| `frontend/` | Vue 3 + Vite application and Vitest suite. |
| `docs/` | Backlog, Postman collection, ownership matrix, and demo narrative. |
| `DECISIONS.md` | Technical decisions and Thursday change-control record. |

## Prerequisites

- Ruby version supported by `backend/Gemfile` (Rails `~> 7.2.3`)
- Bundler
- Node.js and npm
- Docker Desktop / Docker Compose

PostgreSQL is supplied by Docker on port `5432`; the backend defaults to port `3000` and Vite to port `5173`.

## Run from a clean clone

### 1. Prepare and start the API

```powershell
cd backend
Copy-Item .env.example .env
bundle install
docker compose up -d db
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

`db:prepare` creates/migrates the local database. The idempotent seeds add four workshops, eight scheduled sessions, attendees, lifecycle examples, and a full session with waitlisted registrations. Rerun `bin/rails db:seed` safely to restore missing demo records.

### 2. Start the Vue client

In another terminal from the project root:

```powershell
cd frontend
npm install
npm run dev
```

Open the Vite URL printed by the command (normally `http://localhost:5173`). The API is available at `http://localhost:3000`; use `/up` or `/api/v1/health` for a health check and `/api-docs` for generated API documentation.

`FRONTEND_ORIGIN` in `backend/.env` controls the allowed local CORS origin and defaults to `http://localhost:5173`.

## Verify the project

Run backend commands from `backend`:

```powershell
bundle exec rspec
bin/rubocop
bundle exec rails rswag:specs:swaggerize
```

Run frontend commands from `frontend`:

```powershell
npm test
npm run build
```

Import `docs/SeatForge.postman_collection.json` into Postman for manual API requests. API contract error codes and examples are in `backend/docs/api_error_contract.md`.

## API endpoints

All public routes are under `/api/v1` and use JSON.

| Area | Endpoints |
| --- | --- |
| Health | `GET /health` |
| Workshops | `GET, POST /workshops`; `GET /workshops/:id` |
| Sessions | `POST /workshops/:workshop_id/sessions`; `GET /sessions`; `GET /sessions/:id`; `GET /sessions/:id/availability`; `POST /sessions/:id/cancel` |
| Registrations | `POST /sessions/:session_id/registrations`; `POST /registrations/:id/confirm`; `POST /registrations/:id/cancel` |
| Read models | `GET /attendees/:id/registrations`; `GET /dashboard` |

Errors preserve a single envelope:

```json
{ "error": { "code": "validation_error", "message": "…", "details": [] } }
```

See the generated `/api-docs`, the Postman collection, and the [ownership matrix](docs/OWNERSHIP_MATRIX.md) for endpoint-level evidence.

## Domain and capacity strategy

Registration states are `held`, `confirmed`, `waitlisted`, `cancelled`, and `expired`.

- Only confirmed registrations and held registrations whose `hold_expires_at` is later than the current UTC time consume capacity.
- Availability is derived, never stored as a mutable seat counter.
- Allocation and lifecycle transitions run within a database transaction while locking the session row, so concurrent requests cannot oversubscribe capacity.
- A newly allocated hold expires after ten minutes. Confirmation is valid only before that UTC expiration boundary. A full session produces a waitlisted registration.
- Cancelling an active registration or expiring a hold can promote the oldest waitlisted registration to a new hold. Session cancellation is transactional and idempotent.

## Jobs and notifications

`Registrations::ExpireHoldsJob` finds expired holds and, under the session locking boundary, expires them and promotes eligible waitlist entries. `Registrations::SendNotificationJob` delegates to a replaceable notification adapter after confirmation, promotion, or eligible session cancellation.

The repository intentionally has no production scheduler configuration. Run the expiry job from the deployment scheduler/queue adapter selected by the host; it is safe to run repeatedly. In development and test, verify behavior through the job specs rather than relying on a local daemon.

## Limitations

- Authentication and organizer authorization are out of scope; organizer endpoints are exposed for the challenge workflow.
- Notification delivery uses a replaceable adapter, not a configured external email/SMS provider.
- The repository does not ship a production queue adapter or recurring-job scheduler.
- Seed timestamps are relative to the execution date, so regenerated demo data is intentionally time-sensitive.

## Delivery documents

- [Ownership matrix](docs/OWNERSHIP_MATRIX.md)
- [Team demo narrative](docs/DEMO_NARRATIVE.md)
- [Technical decisions and Thursday change control](DECISIONS.md)
- [Consolidated user stories](docs/SEATFORGE_JIRA_USER_STORIES_CONSOLIDATED.md)
- [Thursday change request](docs/SEATFORGE_JIRA_USER_STORIES_CHANGE_REQUEST_SESSION_CANCELLATION.md)

## AI-assistance disclosure

The team used AI assistance for planning, documentation drafting, and implementation support. Team members reviewed the generated changes, retained responsibility for architecture and API decisions, and validated the documented backend/frontend commands before delivery.