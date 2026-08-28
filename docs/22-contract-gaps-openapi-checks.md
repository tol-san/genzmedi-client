# 22 — Contract Gaps & Verified Backend Implementation

This document logs the audit and resolution of contract questions between earlier frontend design specifications and the current FastAPI backend implementation (`/api/v1`).

All items below have been **verified directly against the running backend server code and OpenAPI specification**.

---

## Verified Backend Implementations

### 1. Email Verification
- **Status:** **Out of scope for P0/P1 MVP**
- **Verification:** The backend does not implement email verification routes (`/auth/verify-email`). Upon successful `POST /auth/register`, the user account is created with `is_active = true` and the client can immediately authenticate via `POST /auth/login`.

---

### 2. Saved Posts List
- **Status:** **Implemented**
- **Endpoint:** `GET /api/v1/saved-posts`
- **Verification:** Returns `PaginatedSavedPostsResponse` containing `items: List[PostResponse]`, `total`, `limit`, `offset`. Ordered descending by save timestamp.

---

### 3. Share Counter & Link Generation
- **Status:** **Implemented**
- **Endpoint:** `POST /api/v1/posts/{post_id}/share`
- **Verification:** Increments the post's share counter in PostgreSQL and returns `PostShareResponse` with `post_id`, `share_count`, and canonical `share_url`.

---

### 4. Chat WebSocket Ticket
- **Status:** **Implemented**
- **Endpoint:** `POST /api/v1/chats/ws-ticket?community_id={community_id}`
- **Verification:** Enforces community membership, stores one-time random ticket in Redis with a 60-second TTL, and returns `WsTicketResponse` (`ticket`, `expires_in_seconds`). Ticket is consumed (`getdel`) during WebSocket handshake.

---

### 5. Chat Message Deletion & Moderation
- **Status:** **Implemented**
- **Verification:** Chat messages are marked deleted via the chat service. In addition, user content can be reported via `POST /api/v1/reports` (`report_type: "chat_message"`). Kicking a member via `DELETE /api/v1/communities/{community_id}/members/{user_id}` publishes a `membership.revoked` control event over Redis Pub/Sub, terminating their active WebSocket session.

---

### 6. Chat Typing Signals
- **Status:** **Implemented via Two Channels**
  1. **WebSocket:** Send `{ "type": "typing.start" }` / `{ "type": "typing.stop" }` over active chat socket.
  2. **REST / Redis PubSub:** Send `POST /api/v1/notifications/typing` with `{ "channel": "chat:<comm_id>", "is_typing": true }`.

---

### 7. Live Room Start & Host Token
- **Status:** **Implemented**
- **Endpoint:** `POST /api/v1/live-rooms/{room_id}/start`
- **Verification:** Initializes a live streaming session, transitions room status to `LIVE`, and returns `LiveTokenResponse` with `token`, `livekit_url`, `room_name`, `is_host: true`, `session_id`.

---

### 8. LiveKit Webhooks
- **Status:** **Backend Infrastructure Only**
- **Endpoint:** `POST /api/v1/live-rooms/webhooks/livekit`
- **Verification:** LiveKit media server signs and invokes this webhook to notify the backend of participant joins/leaves and room teardown. **The Flutter client does not call this endpoint.**

---

### 9. Live Reconcile Endpoint
- **Status:** **Implemented as Admin POST**
- **Endpoint:** `POST /api/v1/live-rooms/{room_id}/reconcile`
- **Verification:** Admin endpoint that synchronizes Redis real-time viewer sets with the LiveKit server participant registry.

---

### 10. Media Upload Contracts
- **Status:** **Direct Multipart/Form-Data Uploads to Backend (Stored in MinIO)**
- **Verification:** 
  - **Avatars:** `POST /api/v1/profiles/me/avatar` (multipart `file`, max 5MB, auto-WebP conversion).
  - **Community Covers:** `POST /api/v1/communities/{community_id}/cover` (multipart `file`, max 5MB, auto-WebP conversion).
  - **Post Images & Videos:** `POST /api/v1/posts/media` (multipart `file`, images max 10MB, videos max 50MB). Returns `MediaUploadResponse` with `url`, `media_type`, `thumbnail_url`, `width`, `height`, `duration`.

---

### 11. Community Listing & Exploration
- **Status:** **Implemented**
- **Endpoints:**
  - `GET /api/v1/communities` — Query params: `search`, `interest_id`, `is_private`, `limit`, `offset`.
  - `GET /api/v1/communities/me/joined` — Joined communities for current user.
  - `GET /api/v1/recommendations/communities` — Interest-matched community recommendations.

---

### 12. Post Filtering by Author & Community
- **Status:** **Implemented**
- **Endpoint:** `GET /api/v1/posts`
- **Verification:** Supports rich query parameters:
  - `author_id: UUID` (to fetch posts for a user profile)
  - `community_id: UUID` (to fetch posts inside a specific community)
  - `post_type: string` (`text`, `image`, `video`)
  - `visibility: string` (`public`, `followers_only`, `private`)
  - `search: string`
  - `limit: int`, `offset: int`

---

## Complete Reference Links
- See [`21-api-contract-map.md`](21-api-contract-map.md) for the complete endpoint index.
- See [`33-api-request-response-models.md`](33-api-request-response-models.md) for exhaustive field names, types, constraints, and JSON examples.
