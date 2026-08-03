# Rails Endpoint Ownership Matrix

This matrix follows the delivery backlog ownership allocation and links each current `/api/v1` Rails route to the merged pull request that delivered its main behavior. Review evidence is the submitted GitHub approval visible on that PR as of 2026-08-03. “Unavailable” means no submitted review exists in GitHub; it is not inferred from merge status.

| Endpoint | Delivery owner | Related PR | Peer-review reference |
| --- | --- | --- | --- |
| `GET /api/v1/health` | Alejandro — API contract | [#1](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/1) | Approved by Josoe and Carlos on #1 |
| `GET /api/v1/workshops` | Carlos — workshop/session API | [#2](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/2) | Approved by Alejandro |
| `POST /api/v1/workshops` | Carlos — workshop/session API | [#2](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/2) | Approved by Alejandro |
| `GET /api/v1/workshops/:id` | Carlos — workshop/session API | [#2](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/2) | Approved by Alejandro |
| `POST /api/v1/workshops/:workshop_id/sessions` | Carlos — workshop/session API | [#2](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/2) | Approved by Alejandro |
| `GET /api/v1/sessions` | Josoe — search/query API | [#9](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/9) | Approved by Alejandro |
| `GET /api/v1/sessions/:id` | Josoe — session-detail query API | [#9](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/9) | Approved by Alejandro |
| `GET /api/v1/sessions/:id/availability` | Carlos — availability contract; Alejandro — Phase 3 hardening | [#17](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/17) | **Unavailable:** #17 has no submitted GitHub review |
| `POST /api/v1/sessions/:id/cancel` | Alejandro — transactional cancellation | [#12](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/12) | Approved by Carlos and Josoe |
| `POST /api/v1/sessions/:session_id/registrations` | Alejandro — allocation/capacity locking | [#7](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/7) | Approved by Carlos and Josoe |
| `POST /api/v1/registrations/:id/confirm` | Josoe — registration lifecycle | [#8](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/8) | Approved by Carlos and Alejandro |
| `POST /api/v1/registrations/:id/cancel` | Josoe — registration lifecycle | [#8](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/8) | Approved by Carlos and Alejandro |
| `GET /api/v1/attendees/:id/registrations` | Josoe — attendee-history query | [#9](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/9) | Approved by Alejandro |
| `GET /api/v1/dashboard` | Josoe — dashboard query | [#9](https://github.com/alejandrosardinasassuresoft/SeatForge/pull/9) | Approved by Alejandro |

## Evidence notes

- PR #16 (SEAT-031 frontend registration and hold-confirmation flow) and PR #17 (Phase 3 integration hardening) were merged without submitted GitHub reviews; the matrix preserves that gap rather than claiming peer review.
- A route can have a delivery owner from the backlog and a later hardening contributor. The availability route is annotated this way because its Phase 3 contract was completed in PR #17.
- Route inventory source: `app/backend/config/routes.rb`. Request/response contract sources: `app/backend/swagger/v1/swagger.yaml`, `app/backend/docs/api_error_contract.md`, and `app/docs/SeatForge.postman_collection.json`.