# 17 — Notifications

## Backend triggers

- `new_follower`
- `post_like`
- `post_comment`
- `comment_reply`
- `community_join_approved`

Additional chat/live workers may generate notifications according to backend implementation.

## Consumer entry

The Home Feed notification bell is implemented and opens
`/notifications` (`RouteNames.notifications`). The badge renders the live
unread count and caps its label at `99+`.

Badge source:
`GET /api/v1/notifications/unread-count`

## Notification Center

Endpoint:
`GET /api/v1/notifications`

Supports paginated history and `unread_only` filter.

Implemented UI:

```text
Notifications
[ All | Unread ]

Unread notification
Read notification
...
```

The Notification Center includes chronological rows, actor avatars, a visual
event-type badge, unread highlighting, All/Unread segmented filtering,
pull-to-refresh, near-end pagination, loading skeletons, empty states, and
retryable errors. Swipe-to-delete and the row overflow menu both require a
delete confirmation.

## Actions

- `PATCH /api/v1/notifications/{notification_id}/read`
- `POST /api/v1/notifications/read-all`
- `DELETE /api/v1/notifications/{notification_id}`

Read and delete operations update the list and badge optimistically, then roll
back and show the backend error when a request fails. **Read all** is only shown
while unread items exist.

## Real-time options

Backend exposes:
- SSE: `GET /api/v1/notifications/stream`
- WebSocket: request a one-time ticket from `POST /api/v1/notifications/ws-ticket`, then connect to `/api/v1/notifications/ws?ticket=...`. Never place an access token in the URL.

Frontend decision:
- use the ticketed **WebSocket** transport per authenticated session;
- do not subscribe to SSE and WebSocket simultaneously unless deduplication is explicitly designed.

Baseline behavior:
1. REST loads history.
2. real-time transport inserts new events.
3. unread badge increments/reconciles.
4. foreground route may mark/read according to UX.

The client requests a one-time ticket before each connection and never adds an
access token to the socket URL. It sends periodic pings and reconnects with a
capped exponential delay. A real-time event triggers a short debounced REST
reconciliation, so the permanent PostgreSQL record remains the source of truth
and actor data is complete. The socket is disposed when authentication ends.

## Deep links

Only deep-link when notification payload supplies enough target identity/type to route correctly.

Do not infer a target from notification text.

Implemented destinations:

- `user` → actor public profile;
- `post` → post detail;
- `comment` → fetch the comment by ID, then open its owning post/comment thread;
- `community` → community detail.

Missing or deleted resources show a brief unavailable message.

## Reconnect

Real-time disconnect must not lose persistent notification history because REST/PostgreSQL remains available.

Notification preference controls, push/email delivery, quiet hours, and
per-community muting remain unsupported because corresponding backend contracts
do not exist.
