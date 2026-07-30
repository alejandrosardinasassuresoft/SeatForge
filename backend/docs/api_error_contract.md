# API Error Contract

SeatForge API endpoints under `/api/v1` return JSON errors with a stable envelope:

```json
{
  "error": {
    "code": "validation_error",
    "message": "param is missing or the value is empty: name",
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
| `hold_expired` | 422 | Registration hold expired before confirmation. |

`details` is always an array. Validation errors may include field-level messages when they are available.
