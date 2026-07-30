# API Error Contract

SeatForge API endpoints under `/api/v1` return JSON errors with a stable envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "param is missing or the value is empty or invalid: name",
    "details": []
  }
}
```

## Error Codes

| Code | HTTP Status | Use |
| --- | --- | --- |
| `validation_error` | 422 | Invalid or missing request input. |
| `not_found` | 404 | Requested resource does not exist. |
| `registration_conflict` | 409 | Request conflicts with current registration state. |
| `registration_unavailable` | 409 | Session is cancelled, completed, already started, or otherwise closed for registration. |
| `duplicate_registration` | 409 | Attendee already has an active registration for the requested session. |
| `registration_schedule_conflict` | 409 | Attendee has a held or confirmed registration for another overlapping session. |
| `hold_expired` | 422 | Registration hold expired before confirmation. |

`details` is always an array. Validation errors may include field-level messages when they are available.

## Registration Allocation

`POST /api/v1/sessions/:session_id/registrations` accepts an attendee identity and returns a persisted registration:

```json
{
  "attendee": {
    "name": "Alejandro Sardinas",
    "email": "alejandro@example.com"
  }
}
```

Available capacity returns `201 Created` with status `held` and a UTC `hold_expires_at` ten minutes ahead. Full capacity returns `201 Created` with status `waitlisted` and no hold expiration. Allocation conflicts use the shared error envelope and the `409` codes listed above.
