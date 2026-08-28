# 21 — API Contract Map

**Base URL:** `/api/v1`  
**Authentication:** `Authorization: Bearer <access_token>`  
**Detailed Request/Response Model Specs:** See [`33-api-request-response-models.md`](33-api-request-response-models.md) for field-by-field definitions, types, examples, and error codes.

---

## 1. Authentication (`/auth`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/auth/register/request-otp` | `SignupOtpRequest` (JSON) | `SignupOtpResponse` (200) | Send 6-digit OTP to email (5-min TTL) |
| POST | `/auth/register/verify-otp` | `SignupVerifyOtpRequest` (JSON) | `TokenResponse` (201) | Verify signup OTP, auto-create user & profile |
| POST | `/auth/register` | `UserRegisterRequest` (JSON) | `UserResponse` (201) | Direct registration (legacy) |
| POST | `/auth/login` | `LoginRequest` (JSON) | `TokenResponse` (200) | Login via email/username & password |
| POST | `/auth/refresh` | `RefreshTokenRequest` (JSON) | `TokenRefreshResponse` (200) | Rotate and refresh access token |
| POST | `/auth/logout` | `RefreshTokenRequest` (JSON, optional) | `MessageResponse` (200) | Revoke refresh token & session |
| POST | `/auth/forgot-password` | `ForgotPasswordRequest` (JSON) | `ForgotPasswordResponse` (200) | Request password reset OTP (5-min TTL) |
| POST | `/auth/verify-otp` | `VerifyOtpRequest` (JSON) | `TokenResponse` (200) | Verify password reset OTP code |
| POST | `/auth/reset-password` | `ResetPasswordRequest` (JSON) | `MessageResponse` (200) | Set new password with reset token |
| POST | `/auth/change-password` | `ChangePasswordRequest` (JSON) | `MessageResponse` (200) | Update password for current user |

---

## 2. Users & Social Graph (`/users`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/users/check-username` | Query param `username` | `CheckUsernameResponse` (200) | Check real-time username availability |
| GET | `/users/{username}` | Path param `username` | `UserPublicResponse` (200) | Get user profile and stats |
| POST | `/users/{user_id}/follow` | Path param `user_id` | `FollowActionResponse` (200) | Follow a user |
| DELETE | `/users/{user_id}/follow` | Path param `user_id` | `FollowActionResponse` (200) | Unfollow a user |
| POST | `/users/{user_id}/block` | Path param `user_id` | `BlockActionResponse` (200) | Block a user |
| DELETE | `/users/{user_id}/block` | Path param `user_id` | `BlockActionResponse` (200) | Unblock a user |
| GET | `/users/{user_id}/followers` | Query `limit`, `offset` | `PaginatedUsersResponse` (200) | List user followers |
| GET | `/users/{user_id}/following` | Query `limit`, `offset` | `PaginatedUsersResponse` (200) | List following users |
| GET | `/users/{user_id}/relationship` | Path param `user_id` | `RelationshipResponse` (200) | Directional follow/block status |
| GET | `/users/me/blocked` | Query `limit`, `offset` | `PaginatedUsersResponse` (200) | List blocked users for auth user |

---

## 3. Profiles & Interests (`/profiles`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/profiles/me` | None | `CurrentUserProfileResponse` (200) | Get auth user profile & stats |
| PATCH | `/profiles/me` | `ProfileUpdateRequest` (JSON) | `CurrentUserProfileResponse` (200) | Update display name, bio, avatar |
| POST | `/profiles/me/avatar` | Multipart `file` | `CurrentUserProfileResponse` (200) | Upload & auto-convert avatar to WebP |
| DELETE | `/profiles/me/avatar` | None | `CurrentUserProfileResponse` (200) | Delete avatar (set to null) |
| GET | `/profiles/me/interests` | None | `UserInterestsResponse` (200) | Get auth user selected interests |
| PUT | `/profiles/me/interests` | `UserInterestsUpdateRequest` | `UserInterestsResponse` (200) | Atomically replace selected interests |

---

## 4. Interests Catalog (`/interests`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/interests` | None | `List[InterestResponse]` (200) | Master catalog of interests |
| POST | `/interests` | `InterestCreateRequest` (JSON) | `InterestResponse` (201) | Create interest (Admin only) |

---

## 5. Communities (`/communities`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/communities` | `CommunityCreateRequest` (JSON) | `CommunityResponse` (201) | Create public/private community |
| GET | `/communities` | Query `search`, `interest_id`, `is_private`, `limit`, `offset` | `PaginatedCommunitiesResponse` (200) | Explore & filter communities |
| GET | `/communities/me/joined` | Query `limit`, `offset` | `PaginatedCommunitiesResponse` (200) | List communities user has joined |
| GET | `/communities/{community_id}` | Path param `community_id` | `CommunityDetailResponse` (200) | Community info & membership context |
| PATCH | `/communities/{community_id}` | `CommunityUpdateRequest` (JSON) | `CommunityResponse` (200) | Update community settings (Owner) |
| DELETE | `/communities/{community_id}` | Path param `community_id` | `{"message": "..."}` (200) | Delete community (Owner) |
| POST | `/communities/{community_id}/cover` | Multipart `file` | `CommunityResponse` (200) | Upload cover banner (Owner) |
| POST | `/communities/{community_id}/join` | Path param `community_id` | `JoinActionResponse` (200) | Join instant or request approval |
| DELETE | `/communities/{community_id}/leave` | Path param `community_id` | `{"message": "..."}` (200) | Leave community |
| GET | `/communities/{community_id}/members` | Query `limit`, `offset` | `PaginatedMembersResponse` (200) | List community members |
| DELETE | `/communities/{community_id}/members/{user_id}` | Path params | `{"message": "..."}` (200) | Kick member (Owner) |
| GET | `/communities/{community_id}/join-requests` | Query `limit`, `offset` | `PaginatedJoinRequestsResponse` (200) | List pending join requests (Owner) |
| POST | `/communities/{community_id}/join-requests/{request_id}/approve` | Path params | `{"message": "..."}` (200) | Approve join request (Owner) |
| POST | `/communities/{community_id}/join-requests/{request_id}/reject` | Path params | `{"message": "..."}` (200) | Reject join request (Owner) |

---

## 6. Posts & Media (`/posts`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/posts/media` | Multipart `file` | `MediaUploadResponse` (200) | Upload image (max 10MB) or video (max 50MB) |
| POST | `/posts` | `PostCreateRequest` (JSON) | `PostResponse` (201) | Create text/image/video post |
| GET | `/posts` | Query `author_id`, `community_id`, `post_type`, `visibility`, `search`, `limit`, `offset` | `PaginatedPostsResponse` (200) | Filter posts by author, community, type |
| GET | `/posts/{post_id}` | Path param `post_id` | `PostResponse` (200) | Get post details and engagement stats |
| PATCH | `/posts/{post_id}` | `PostUpdateRequest` (JSON) | `PostResponse` (200) | Update title, content, visibility |
| DELETE | `/posts/{post_id}` | Path param `post_id` | `{"message": "..."}` (200) | Delete post & media files |
| POST | `/posts/{post_id}/like` | Path param `post_id` | `PostLikeResponse` (200) | Like post (Idempotent) |
| DELETE | `/posts/{post_id}/like` | Path param `post_id` | `PostLikeResponse` (200) | Unlike post (Idempotent) |
| POST | `/posts/{post_id}/save` | Path param `post_id` | `PostSaveResponse` (200) | Bookmark post (Idempotent) |
| DELETE | `/posts/{post_id}/save` | Path param `post_id` | `PostSaveResponse` (200) | Unsave bookmark (Idempotent) |
| POST | `/posts/{post_id}/share` | Path param `post_id` | `PostShareResponse` (200) | Increment share count & get link |

---

## 7. Comments (`/posts/{post_id}/comments` & `/comments`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/posts/{post_id}/comments` | `CommentCreateRequest` (JSON) | `CommentResponse` (201) | Create top-level comment or reply |
| GET | `/posts/{post_id}/comments` | Query `limit`, `offset` | `PaginatedCommentsResponse` (200) | List top-level comments |
| GET | `/comments/{comment_id}` | Path param `comment_id` | `CommentResponse` (200) | Get comment details |
| GET | `/comments/{comment_id}/replies` | Query `limit`, `offset` | `PaginatedCommentsResponse` (200) | List nested replies for comment |
| PATCH | `/comments/{comment_id}` | `CommentUpdateRequest` (JSON) | `CommentResponse` (200) | Edit comment text |
| DELETE | `/comments/{comment_id}` | Path param `comment_id` | `{"message": "..."}` (200) | Delete comment and child replies |

---

## 8. Saved Posts / Bookmarks (`/saved-posts`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/saved-posts` | Query `limit`, `offset` | `PaginatedSavedPostsResponse` (200) | List bookmarked posts (ordered by save time) |

---

## 9. Feeds & Recommendations (`/feeds` & `/recommendations`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/feeds/home` | Query `limit`, `offset` | `PaginatedPostsResponse` (200) | Personalized timeline (following + joined) |
| GET | `/feeds/discover` | Query `limit`, `offset` | `PaginatedPostsResponse` (200) | Trending & interest-matched posts |
| GET | `/feeds/shorts` | Query `limit`, `offset` | `PaginatedPostsResponse` (200) | Vertical short video feed |
| GET | `/recommendations/communities` | Query `limit`, `offset` | `PaginatedRecommendedCommunitiesResponse` (200) | Recommended communities by interest |
| GET | `/recommendations/users` | Query `limit`, `offset` | `PaginatedRecommendedUsersResponse` (200) | Recommended users by mutual interests |

---

## 10. Search Engine (`/search`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/search` | Query `q`, `type` (`all`), `limit`, `offset` | `UnifiedSearchResponse` (200) | Unified search across 4 domains |
| GET | `/search/users` | Query `q`, `limit`, `offset` | `PaginatedUserSearchResponse` (200) | Search users |
| GET | `/search/communities` | Query `q`, `limit`, `offset` | `PaginatedCommunitySearchResponse` (200) | Search communities |
| GET | `/search/posts` | Query `q`, `limit`, `offset` | `PaginatedPostSearchResponse` (200) | Search posts |
| GET | `/search/interests` | Query `q`, `limit`, `offset` | `PaginatedInterestSearchResponse` (200) | Search interests catalog |
| POST | `/search/sync` | None | `SyncIndexResponse` (200) | Sync Meilisearch indexes (Admin) |

---

## 11. Notifications & Realtime (`/notifications`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| GET | `/notifications` | Query `unread_only`, `limit`, `offset` | `PaginatedNotificationsResponse` (200) | List user notifications |
| GET | `/notifications/unread-count` | None | `UnreadCountResponse` (200) | Get unread badge count |
| PATCH | `/notifications/{notification_id}/read` | Path param | `NotificationResponse` (200) | Mark single notification read |
| POST | `/notifications/read-all` | None | `{"message": "...", "count": N}` (200) | Mark all notifications read |
| DELETE | `/notifications/{notification_id}` | Path param | `{"message": "..."}` (200) | Delete notification |
| GET | `/notifications/stream` | Header `Authorization` | `text/event-stream` (SSE) | Real-time notification SSE stream |
| POST | `/notifications/typing` | `TypingIndicatorPayload` (JSON) | `{"status": "ok"}` (200) | Ephemeral typing broadcast |
| WS | `/notifications/ws?token=...` | Query `token` | WebSocket Events | Live notifications WebSocket gateway |

---

## 12. Reports & Moderation (`/reports`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/reports` | `ReportCreateRequest` (JSON) | `ReportResponse` (201) | Submit report |
| GET | `/reports` | Query `status`, `report_type`, `community_id`, `limit`, `offset` | `PaginatedReportsResponse` (200) | List reports (Admin/Owner) |
| GET | `/reports/{report_id}` | Path param | `ReportResponse` (200) | Get report details |
| PATCH | `/reports/{report_id}/status` | `ReportStatusUpdateRequest` (JSON) | `ReportResponse` (200) | Update status & apply resolution |

---

## 13. Community Chat (`/chats`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/chats/ws-ticket` | Query `community_id` | `WsTicketResponse` (200) | Issue one-time 60s WS ticket |
| GET | `/chats/{community_id}/messages` | Query `before` (cursor), `limit` | `ChatHistoryResponse` (200) | Cursor-paginated message history |
| GET | `/chats/{community_id}/presence` | Path param `community_id` | `PresenceResponse` (200) | Online member IDs and count |
| WS | `/chats/ws/{community_id}?ticket=...` | Query `ticket` | WebSocket Protocol | Real-time chat socket |

---

## 14. Live Streaming Rooms (`/live-rooms`)

| Method | Path | Request Body / Params | Response Model | Description |
|---|---|---|---|---|
| POST | `/live-rooms` | Query `community_id`, Body `LiveRoomCreate` | `LiveRoomResponse` (201) | Create room (Owner/Mod) |
| GET | `/live-rooms/{room_id}` | Path param `room_id` | `LiveRoomResponse` (200) | Room details & viewer count |
| PATCH | `/live-rooms/{room_id}` | `LiveRoomUpdate` (JSON) | `LiveRoomResponse` (200) | Update title/description |
| POST | `/live-rooms/{room_id}/start` | Path param `room_id` | `LiveTokenResponse` (200) | Start session & get Host LiveKit token |
| POST | `/live-rooms/{room_id}/end` | Path param `room_id` | `LiveSessionResponse` (200) | End session & save metrics |
| POST | `/live-rooms/{room_id}/token` | Path param `room_id` | `LiveTokenResponse` (200) | Get Viewer LiveKit token |
| GET | `/live-rooms/{room_id}/metrics` | Path param `room_id` | `LiveMetricsResponse` (200) | Real-time / historic session metrics |
| POST | `/live-rooms/{room_id}/reconcile` | Path param `room_id` | `{"reconciled": N}` (200) | Reconcile viewers (Admin) |
| POST | `/live-rooms/webhooks/livekit` | LiveKit Webhook Payload | `{"status": "ok"}` (200) | LiveKit internal webhook (Backend only) |
