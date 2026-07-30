# SeatForge Backend

Rails API backend for SeatForge. Run backend commands from this directory.

## Local Setup

```powershell
bundle install
docker compose up -d db
bin/rails db:prepare
bin/rails server
```

Copy `.env.example` to `.env` for local settings. `FRONTEND_ORIGIN` controls which Vue development origin can call `/api/*` through CORS and defaults to `http://localhost:5173`.

## API Contract

Frontend-facing API routes belong under `/api/v1`. Shared JSON error responses use this envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Human readable message",
    "details": []
  }
}
```

See `docs/api_error_contract.md` for the current error codes and statuses.

## Verification

```powershell
bundle exec rspec
bin/rubocop
```