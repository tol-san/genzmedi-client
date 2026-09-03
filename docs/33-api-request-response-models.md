# 33 — API Request & Response Data Models Reference

This document provides the complete, authoritative specification of all HTTP request schemas, query parameters, multipart form uploads, response models, error formats, and WebSocket / SSE protocols in the FastAPI backend (`/api/v1`).

---

## 1. Global Standards & Protocol Rules

### Base URLs & Headers
- **Base Path:** `/api/v1`
- **Default Headers (JSON endpoints):**
  ```http
  Content-Type: application/json
  Accept: application/json
  ```
- **Authenticated Headers:**
  ```http
  Authorization: Bearer <access_token>
  ```
- **Multipart Upload Headers:**
  ```http
  Content-Type: multipart/form-data
  ```

---

### Standard Error Response Formats

#### 1. Application Exception Format (`400`, `401`, `403`, `404`, `409`)
All backend application errors return a structured JSON object:
```json
{
  "detail": "Descriptive error message for the user or developer.",
  "error_code": "BAD_REQUEST"
}
```
**Common `error_code` values:**
- `BAD_REQUEST` (400) — Validation failure or invalid action (e.g. owner leaving community)
- `UNAUTHORIZED` (401) — Missing, invalid, or expired JWT access token
- `FORBIDDEN` (403) — Insufficient permissions (e.g., non-owner modifying community)
- `NOT_FOUND` (404) — Requested resource UUID or slug does not exist
- `EMAIL_ALREADY_EXISTS` (409) — Email already in use during registration
- `USERNAME_ALREADY_EXISTS` (409) — Username already taken during registration

#### 2. Validation Exception Format (`422 Unprocessable Entity`)
Pydantic model validation errors returned automatically by FastAPI:
```json
{
  "detail": [
    {
      "loc": ["body", "password"],
      "msg": "String should have at least 8 characters",
      "type": "string_too_short"
    }
  ]
}
```

---

### Standard Pagination Schemes

#### 1. Offset/Limit Pagination (Default)
Used across Feeds, Communities, Members, Comments, Notifications, Reports, and Search:
```json
{
  "items": [ /* List of entity objects */ ],
  "total": 120,
  "limit": 20,
  "offset": 0
}
```
- Query Parameters: `?limit=20&offset=0` (Limit: `1 <= limit <= 100`, default `20`)

#### 2. Cursor/Keyset Pagination (Chat Messages)
Used for high-frequency chat message history (`GET /chats/{community_id}/messages`):
```json
{
  "items": [ /* List of chat message objects */ ],
  "next_cursor": "eyJjcmVhdGVkX2F0IjogIjIwMjYt...In0=",
  "has_more": true
}
```
- Query Parameters: `?before=<next_cursor>&limit=50`

---

## 2. Authentication & Session (`/auth`)

### 2.1 Register User
- **Endpoint:** `POST /api/v1/auth/register`
- **Status:** `201 Created`
- **Auth:** None (Public)

**Request Body (`UserRegisterRequest`):**
```json
{
  "email": "user@example.com",
  "username": "cool_user99",
  "password": "StrongPassword123!",
  "display_name": "Cool User"
}
```
| Field | Type | Required | Constraints / Description |
|---|---|---|---|
| `email` | `string` | Yes | Valid email format |
| `username` | `string` | Yes | 3–30 chars, pattern `^[a-z0-9_-]+$` |
| `password` | `string` | Yes | 8–100 chars |
| `display_name` | `string` | No | Max 100 chars (defaults to `username` if omitted) |

**Response Body (`UserResponse`):**
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "user@example.com",
  "username": "cool_user99",
  "is_active": true,
  "created_at": "2026-08-28T12:00:00Z",
  "profile": {
    "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "display_name": "Cool User",
    "bio": null,
    "avatar_url": null,
    "follower_count": 0,
    "following_count": 0,
    "post_count": 0,
    "created_at": "2026-08-28T12:00:00Z",
    "updated_at": "2026-08-28T12:00:00Z"
  }
}
```

---

### 2.2 User Login
- **Endpoint:** `POST /api/v1/auth/login`
- **Status:** `200 OK`
- **Auth:** None (Public)

**Request Body (`LoginRequest`):**
```json
{
  "identifier": "user@example.com",
  "password": "StrongPassword123!"
}
```
| Field | Type | Required | Description |
|---|---|---|---|
| `identifier` | `string` | Yes | Email address or username (aliases: `username`, `email`, `username_or_email`) |
| `password` | `string` | Yes | User password |

**Response Body (`TokenResponse`):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900,
  "user": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "user@example.com",
    "username": "cool_user99",
    "is_active": true,
    "created_at": "2026-08-28T12:00:00Z",
    "profile": {
      "id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "display_name": "Cool User",
      "bio": "Bio description",
      "avatar_url": "https://storage.../avatar.webp",
      "follower_count": 10,
      "following_count": 5,
      "post_count": 3,
      "created_at": "2026-08-28T12:00:00Z",
      "updated_at": "2026-08-28T12:00:00Z"
    }
  }
}
```

---

### 2.3 Refresh Token
- **Endpoint:** `POST /api/v1/auth/refresh`
- **Status:** `200 OK`
- **Auth:** None (Body contains token)

**Request Body (`RefreshTokenRequest`):**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response Body (`TokenRefreshResponse`):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

### 2.4 User Logout
- **Endpoint:** `POST /api/v1/auth/logout`
- **Status:** `200 OK`

**Request Body (`RefreshTokenRequest`):**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response Body (`MessageResponse`):**
```json
{
  "message": "Successfully logged out."
}
```

---

### 2.5 Forgot Password
- **Endpoint:** `POST /api/v1/auth/forgot-password`
- **Status:** `200 OK`

**Request Body (`ForgotPasswordRequest`):**
```json
{
  "email": "user@example.com"
}
```

**Response Body (`ForgotPasswordResponse`):**
```json
{
  "message": "If this email is registered, password reset instructions have been generated.",
  "reset_token": null
}
```

---

### 2.6 Verify Password-Reset OTP
- **Endpoint:** `POST /api/v1/auth/verify-otp`
- **Status:** `200 OK`

```json
{
  "reset_token": "one-time-password-reset-jwt",
  "expires_in": 420
}
```

No access or refresh token is issued by this endpoint.

### 2.7 Reset Password
- **Endpoint:** `POST /api/v1/auth/reset-password`
- **Status:** `200 OK`

**Request Body (`ResetPasswordRequest`):**
```json
{
  "token": "reset_token_from_verify_otp",
  "new_password": "NewSecurePassword123!"
}
```

**Response Body (`MessageResponse`):**
```json
{
  "message": "Password has been successfully reset. You can now login."
}
```

---

### 2.8 Change Password
- **Endpoint:** `POST /api/v1/auth/change-password`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`ChangePasswordRequest`):**
```json
{
  "current_password": "OldPassword123!",
  "new_password": "NewSecurePassword123!"
}
```

**Response Body (`MessageResponse`):**
```json
{
  "message": "Password changed successfully."
}
```

---

## 3. Users & Social Graph (`/users`)

### 3.1 Get Public User Profile by Username
- **Endpoint:** `GET /api/v1/users/{username}`
- **Status:** `200 OK`

**Response Body (`UserPublicResponse`):**
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "alex_tech",
  "display_name": "Alex Rivers",
  "bio": "Building the future of Flutter & Python.",
  "avatar_url": "https://storage.genzmedia.app/avatars/alex.webp",
  "follower_count": 1420,
  "following_count": 312,
  "post_count": 48,
  "created_at": "2026-01-15T08:30:00Z"
}
```

---

### 3.2 Follow User
- **Endpoint:** `POST /api/v1/users/{user_id}/follow`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`FollowActionResponse`):**
```json
{
  "is_following": true,
  "message": "You are now following alex_tech."
}
```

---

### 3.3 Unfollow User
- **Endpoint:** `DELETE /api/v1/users/{user_id}/follow`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`FollowActionResponse`):**
```json
{
  "is_following": false,
  "message": "You have unfollowed alex_tech."
}
```

---

### 3.4 Block User
- **Endpoint:** `POST /api/v1/users/{user_id}/block`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`BlockActionResponse`):**
```json
{
  "is_blocking": true,
  "message": "User alex_tech has been blocked."
}
```

---

### 3.5 Unblock User
- **Endpoint:** `DELETE /api/v1/users/{user_id}/block`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`BlockActionResponse`):**
```json
{
  "is_blocking": false,
  "message": "User alex_tech has been unblocked."
}
```

---

### 3.6 Get User Followers
- **Endpoint:** `GET /api/v1/users/{user_id}/followers?limit=20&offset=0`
- **Status:** `200 OK`

**Response Body (`PaginatedUsersResponse`):**
```json
{
  "items": [
    {
      "id": "4da75f64-5717-4562-b3fc-2c963f66afa7",
      "username": "sarah_c",
      "display_name": "Sarah Connor",
      "avatar_url": "https://storage.../avatar.webp",
      "bio": "AI Researcher",
      "follower_count": 850,
      "following_count": 120
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

---

### 3.7 Get User Following
- **Endpoint:** `GET /api/v1/users/{user_id}/following?limit=20&offset=0`
- **Status:** `200 OK`

**Response Body (`PaginatedUsersResponse`):** Structure identical to `3.6`.

---

### 3.8 Get Relationship Status
- **Endpoint:** `GET /api/v1/users/{user_id}/relationship`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`RelationshipResponse`):**
```json
{
  "is_following": true,
  "is_followed_by": false,
  "is_blocking": false,
  "is_blocked_by": false
}
```

---

### 3.9 Get My Blocked Users
- **Endpoint:** `GET /api/v1/users/me/blocked?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedUsersResponse`):** Structure identical to `3.6`.

---

## 4. Current Profile & Interests (`/profiles`)

### 4.1 Get Current User Profile
- **Endpoint:** `GET /api/v1/profiles/me`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`CurrentUserProfileResponse`):**
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "user@example.com",
  "username": "cool_user99",
  "is_active": true,
  "display_name": "Cool User",
  "bio": "Building with Flutter & FastAPI",
  "avatar_url": "https://minio.../avatar_123.webp",
  "follower_count": 150,
  "following_count": 80,
  "post_count": 12,
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-08-28T10:00:00Z"
}
```

---

### 4.2 Update Profile Information
- **Endpoint:** `PATCH /api/v1/profiles/me`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`ProfileUpdateRequest`):**
```json
{
  "display_name": "Updated Name",
  "bio": "Updated bio text...",
  "avatar_url": "https://custom-avatar-url.com/img.webp"
}
```
| Field | Type | Required | Constraints |
|---|---|---|---|
| `display_name` | `string` | No | 1–100 chars |
| `bio` | `string` | No | Max 500 chars |
| `avatar_url` | `string` | No | Max 500 chars |

**Response Body (`CurrentUserProfileResponse`):** Updated profile object.

---

### 4.3 Upload Avatar Image
- **Endpoint:** `POST /api/v1/profiles/me/avatar`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`
- **Content-Type:** `multipart/form-data`

**Request Multipart Fields:**
| Field Name | Type | Description |
|---|---|---|
| `file` | Binary File | Image file (JPEG, PNG, WebP, GIF, max 5MB). Auto-converted by backend to WebP. |

**Response Body (`CurrentUserProfileResponse`):** Updated profile object with new `avatar_url`.

---

### 4.4 Delete Avatar Image
- **Endpoint:** `DELETE /api/v1/profiles/me/avatar`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`CurrentUserProfileResponse`):** Profile with `avatar_url: null`.

---

### 4.5 Get Current User Interests
- **Endpoint:** `GET /api/v1/profiles/me/interests`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`UserInterestsResponse`):**
```json
{
  "items": [
    {
      "id": "e4d3c2b1-1234-5678-9abc-def012345678",
      "name": "Gaming",
      "slug": "gaming",
      "icon_url": "https://.../gaming.png",
      "description": "Video games and esports"
    }
  ],
  "total": 1
}
```

---

### 4.6 Update User Interests (Atomic Replace)
- **Endpoint:** `PUT /api/v1/profiles/me/interests`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`UserInterestsUpdateRequest`):**
```json
{
  "interest_ids": [
    "e4d3c2b1-1234-5678-9abc-def012345678",
    "a1b2c3d4-5678-90ab-cdef-1234567890ab"
  ]
}
```
| Field | Type | Required | Constraints |
|---|---|---|---|
| `interest_ids` | `List[UUID]` | Yes | Max 20 UUID items |

**Response Body (`UserInterestsResponse`):** Updated interests list.

---

## 5. Interests Catalog (`/interests`)

### 5.1 List All Available Interests
- **Endpoint:** `GET /api/v1/interests`
- **Status:** `200 OK`
- **Auth:** None (Public)

**Response Body (`List[InterestResponse]`):**
```json
[
  {
    "id": "e4d3c2b1-1234-5678-9abc-def012345678",
    "name": "Tech & AI",
    "slug": "tech-ai",
    "icon_url": "https://.../tech.png",
    "description": "Artificial intelligence, software, and hardware innovations"
  }
]
```

---

## 6. Communities & Memberships (`/communities`)

### 6.1 Create Community
- **Endpoint:** `POST /api/v1/communities`
- **Status:** `201 Created`
- **Auth:** `Bearer <access_token>`

**Request Body (`CommunityCreateRequest`):**
```json
{
  "name": "Flutter Developers",
  "slug": "flutter-devs",
  "description": "A place for cross-platform app engineers.",
  "interest_id": "e4d3c2b1-1234-5678-9abc-def012345678",
  "cover_image_url": "https://.../cover.webp",
  "avatar_url": "https://.../avatar.webp",
  "is_private": false
}
```
| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | 2–100 chars |
| `slug` | `string` | No | 2–100 chars (auto-generated if omitted) |
| `description` | `string` | No | Max 1000 chars |
| `interest_id` | `UUID` | No | Associated interest category |
| `cover_image_url` | `string` | No | Max 500 chars |
| `avatar_url` | `string` | No | Max 500 chars |
| `is_private` | `boolean`| No | Default `false`. If `true`, requires join approval. |

**Response Body (`CommunityResponse`):**
```json
{
  "id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "owner_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "interest_id": "e4d3c2b1-1234-5678-9abc-def012345678",
  "name": "Flutter Developers",
  "slug": "flutter-devs",
  "description": "A place for cross-platform app engineers.",
  "cover_image_url": "https://.../cover.webp",
  "avatar_url": "https://.../avatar.webp",
  "is_private": false,
  "member_count": 1,
  "post_count": 0,
  "created_at": "2026-08-28T12:00:00Z"
}
```

---

### 6.2 Explore / Filter Communities
- **Endpoint:** `GET /api/v1/communities?search=flutter&interest_id=...&is_private=false&limit=20&offset=0`
- **Status:** `200 OK`

**Query Parameters:**
| Param | Type | Required | Description |
|---|---|---|---|
| `search` | `string` | No | Query name or description |
| `interest_id` | `UUID` | No | Filter by category |
| `is_private` | `boolean` | No | Filter public (`false`) vs private (`true`) |
| `limit` | `int` | No | Items per page (default 20, max 100) |
| `offset` | `int` | No | Offset (default 0) |

**Response Body (`PaginatedCommunitiesResponse`):**
```json
{
  "items": [ /* List of CommunityResponse */ ],
  "total": 15,
  "limit": 20,
  "offset": 0
}
```

---

### 6.3 Get Joined Communities for Authenticated User
- **Endpoint:** `GET /api/v1/communities/me/joined?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedCommunitiesResponse`):** List of communities user has joined.

---

### 6.4 Get Community Details (with Membership Context)
- **Endpoint:** `GET /api/v1/communities/{community_id}`
- **Status:** `200 OK`

**Response Body (`CommunityDetailResponse`):**
```json
{
  "id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "owner_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "interest_id": "e4d3c2b1-1234-5678-9abc-def012345678",
  "name": "Flutter Developers",
  "slug": "flutter-devs",
  "description": "A place for cross-platform app engineers.",
  "cover_image_url": "https://.../cover.webp",
  "avatar_url": "https://.../avatar.webp",
  "is_private": false,
  "member_count": 145,
  "post_count": 62,
  "created_at": "2026-08-28T12:00:00Z",
  "is_member": true,
  "is_owner": false,
  "membership_role": "member",
  "join_request_status": null
}
```

---

### 6.5 Update Community (Owner Only)
- **Endpoint:** `PATCH /api/v1/communities/{community_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`CommunityUpdateRequest`):**
```json
{
  "name": "Flutter & Dart Masters",
  "description": "Updated description",
  "is_private": false
}
```

**Response Body (`CommunityResponse`):** Updated community object.

---

### 6.6 Delete Community (Owner Only)
- **Endpoint:** `DELETE /api/v1/communities/{community_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body:**
```json
{
  "message": "Community 'Flutter Developers' has been deleted."
}
```

---

### 6.7 Upload Community Cover Banner
- **Endpoint:** `POST /api/v1/communities/{community_id}/cover`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Owner only)
- **Content-Type:** `multipart/form-data`

**Request Multipart Fields:**
| Field Name | Type | Description |
|---|---|---|
| `file` | Binary File | Cover image (JPEG, PNG, WebP, max 5MB). Scaled to 1200px WebP. |

**Response Body (`CommunityResponse`):** Updated community object with `cover_image_url`.

---

### 6.8 Join Community
- **Endpoint:** `POST /api/v1/communities/{community_id}/join`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`JoinActionResponse`):**
```json
{
  "status": "joined",
  "message": "You have joined Flutter Developers.",
  "is_member": true
}
```
*(If community is private: `status: "pending"`, `is_member: false`)*

---

### 6.9 Leave Community
- **Endpoint:** `DELETE /api/v1/communities/{community_id}/leave`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body:**
```json
{
  "message": "You have left Flutter Developers."
}
```

---

### 6.10 List Community Members
- **Endpoint:** `GET /api/v1/communities/{community_id}/members?limit=20&offset=0`
- **Status:** `200 OK`

**Response Body (`PaginatedMembersResponse`):**
```json
{
  "items": [
    {
      "id": "m1a2b3c4-5678-90ab-cdef-1234567890ab",
      "user_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "username": "cool_user99",
      "display_name": "Cool User",
      "avatar_url": "https://.../avatar.webp",
      "role": "owner",
      "joined_at": "2026-08-28T12:00:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

---

### 6.11 Kick Community Member (Owner Only)
- **Endpoint:** `DELETE /api/v1/communities/{community_id}/members/{user_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body:**
```json
{
  "message": "Member has been removed from the community."
}
```

---

### 6.12 List Join Requests (Owner Only)
- **Endpoint:** `GET /api/v1/communities/{community_id}/join-requests?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedJoinRequestsResponse`):**
```json
{
  "items": [
    {
      "id": "r1a2b3c4-5678-90ab-cdef-1234567890ab",
      "user_id": "7fa85f64-5717-4562-b3fc-2c963f66afa9",
      "username": "applicant_dev",
      "display_name": "Applicant",
      "avatar_url": null,
      "status": "pending",
      "created_at": "2026-08-28T12:30:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

---

### 6.13 Approve / Reject Join Request (Owner Only)
- **Approve:** `POST /api/v1/communities/{community_id}/join-requests/{request_id}/approve`
- **Reject:** `POST /api/v1/communities/{community_id}/join-requests/{request_id}/reject`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (Approve):**
```json
{
  "message": "Join request approved. User is now a member."
}
```
**Response Body (Reject):**
```json
{
  "message": "Join request rejected."
}
```

---

## 7. Posts & Media (`/posts`)

### 7.1 Upload Post Media File (Image / Video)
- **Endpoint:** `POST /api/v1/posts/media`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`
- **Content-Type:** `multipart/form-data`

**Request Multipart Fields:**
| Field Name | Type | Constraints / Description |
|---|---|---|
| `file` | Binary File | Images (JPEG/PNG/WebP, max 10MB) or Videos (MP4/MOV/WebM, max 50MB) |

**Response Body (`MediaUploadResponse`):**
```json
{
  "url": "https://storage.genzmedia.app/posts/media_9b1deb4d.webp",
  "media_type": "image",
  "thumbnail_url": null,
  "width": 1080,
  "height": 1350,
  "duration": null
}
```

---

### 7.2 Create Post
- **Endpoint:** `POST /api/v1/posts`
- **Status:** `201 Created`
- **Auth:** `Bearer <access_token>`

**Request Body (`PostCreateRequest`):**
```json
{
  "post_type": "image",
  "title": "My Flutter Setup 2026",
  "content": "Check out my dark mode workspace setup!",
  "visibility": "public",
  "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "media": [
    {
      "media_type": "image",
      "url": "https://storage.../media_9b1deb4d.webp",
      "thumbnail_url": null,
      "duration": null,
      "width": 1080,
      "height": 1350,
      "order": 0
    }
  ]
}
```
| Field | Type | Required | Constraints |
|---|---|---|---|
| `post_type` | `string` | Yes | `"text"`, `"image"`, or `"video"` |
| `title` | `string` | No | Max 255 chars |
| `content` | `string` | No | Text body or caption |
| `visibility` | `string` | Yes | `"public"`, `"followers_only"`, or `"private"` |
| `community_id` | `UUID` | No | Community UUID if posting to community |
| `media` | `List[MediaItemCreate]` | No | List of media items with order and dimensions |

**Response Body (`PostResponse`):**
```json
{
  "id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "author": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "username": "cool_user99",
    "display_name": "Cool User",
    "avatar_url": "https://.../avatar.webp"
  },
  "community": {
    "id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
    "name": "Flutter Developers",
    "slug": "flutter-devs",
    "avatar_url": "https://.../avatar.webp"
  },
  "post_type": "image",
  "title": "My Flutter Setup 2026",
  "content": "Check out my dark mode workspace setup!",
  "visibility": "public",
  "media": [
    {
      "id": "m1a2b3c4-5678-90ab-cdef-1234567890ab",
      "media_type": "image",
      "url": "https://storage.../media_9b1deb4d.webp",
      "thumbnail_url": null,
      "duration": null,
      "width": 1080,
      "height": 1350,
      "order": 0
    }
  ],
  "like_count": 0,
  "comment_count": 0,
  "share_count": 0,
  "save_count": 0,
  "created_at": "2026-08-28T12:00:00Z"
}
```

---

### 7.3 List and Filter Posts
- **Endpoint:** `GET /api/v1/posts?author_id=...&community_id=...&post_type=...&visibility=...&search=...&limit=20&offset=0`
- **Status:** `200 OK`

**Query Parameters:**
| Param | Type | Description |
|---|---|---|
| `author_id` | `UUID` | Filter by author ID |
| `community_id` | `UUID` | Filter by community ID |
| `post_type` | `string` | Filter: `text`, `image`, `video` |
| `visibility` | `string` | Filter: `public`, `followers_only`, `private` |
| `search` | `string` | Search in post title/content |
| `limit` | `int` | Items per page (default 20) |
| `offset` | `int` | Offset (default 0) |

**Response Body (`PaginatedPostsResponse`):**
```json
{
  "items": [ /* List of PostResponse */ ],
  "total": 45,
  "limit": 20,
  "offset": 0
}
```

---

### 7.4 Get Single Post Details
- **Endpoint:** `GET /api/v1/posts/{post_id}`
- **Status:** `200 OK`

**Response Body (`PostResponse`):** Complete post object as in `7.2`.

---

### 7.5 Update Post
- **Endpoint:** `PATCH /api/v1/posts/{post_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Author only)

**Request Body (`PostUpdateRequest`):**
```json
{
  "title": "Updated Post Title",
  "content": "Updated caption or body",
  "visibility": "public"
}
```

**Response Body (`PostResponse`):** Updated post object.

---

### 7.6 Delete Post
- **Endpoint:** `DELETE /api/v1/posts/{post_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Author, Community Owner, or Superuser)

**Response Body:**
```json
{
  "message": "Post has been deleted successfully."
}
```

---

### 7.7 Like / Unlike Post (Idempotent)
- **Like:** `POST /api/v1/posts/{post_id}/like`
- **Unlike:** `DELETE /api/v1/posts/{post_id}/like`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PostLikeResponse`):**
```json
{
  "post_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "liked": true,
  "like_count": 42
}
```

---

### 7.8 Save / Unsave Post Bookmark (Idempotent)
- **Save:** `POST /api/v1/posts/{post_id}/save`
- **Unsave:** `DELETE /api/v1/posts/{post_id}/save`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PostSaveResponse`):**
```json
{
  "post_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "saved": true,
  "save_count": 15
}
```

---

### 7.9 Share Post
- **Endpoint:** `POST /api/v1/posts/{post_id}/share`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PostShareResponse`):**
```json
{
  "post_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "share_count": 8,
  "share_url": "https://genzmedia.app/posts/p1a2b3c4-5678-90ab-cdef-1234567890ab"
}
```

---

## 8. Comments & Discussions

### 8.1 Create Top-Level Comment or Reply
- **Endpoint:** `POST /api/v1/posts/{post_id}/comments`
- **Status:** `201 Created`
- **Auth:** `Bearer <access_token>`

**Request Body (`CommentCreateRequest`):**
```json
{
  "content": "This is an insightful post! Thanks for sharing.",
  "parent_id": null
}
```
*(To reply to another comment, pass parent UUID in `parent_id`)*

**Response Body (`CommentResponse`):**
```json
{
  "id": "cm1a2b3c-5678-90ab-cdef-1234567890ab",
  "post_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "parent_id": null,
  "author": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "username": "cool_user99",
    "display_name": "Cool User",
    "avatar_url": "https://.../avatar.webp"
  },
  "content": "This is an insightful post! Thanks for sharing.",
  "like_count": 0,
  "reply_count": 0,
  "is_edited": false,
  "created_at": "2026-08-28T12:05:00Z",
  "updated_at": "2026-08-28T12:05:00Z"
}
```

---

### 8.2 List Post Comments
- **Endpoint:** `GET /api/v1/posts/{post_id}/comments?limit=20&offset=0`
- **Status:** `200 OK`

**Response Body (`PaginatedCommentsResponse`):**
```json
{
  "items": [ /* List of CommentResponse */ ],
  "total": 12,
  "limit": 20,
  "offset": 0
}
```

---

### 8.3 List Comment Replies
- **Endpoint:** `GET /api/v1/comments/{comment_id}/replies?limit=20&offset=0`
- **Status:** `200 OK`

**Response Body (`PaginatedCommentsResponse`):** List of replies under `comment_id`.

---

### 8.4 Edit Comment
- **Endpoint:** `PATCH /api/v1/comments/{comment_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Comment author only)

**Request Body (`CommentUpdateRequest`):**
```json
{
  "content": "Updated comment content."
}
```

**Response Body (`CommentResponse`):** Comment with `is_edited: true`.

---

### 8.5 Delete Comment
- **Endpoint:** `DELETE /api/v1/comments/{comment_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Comment Author, Post Author, Community Owner, or Platform Admin)

**Response Body:**
```json
{
  "message": "Comment has been deleted successfully."
}
```

---

## 9. Saved Posts / Bookmarks (`/saved-posts`)

### 9.1 List Saved Posts
- **Endpoint:** `GET /api/v1/saved-posts?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedSavedPostsResponse`):**
```json
{
  "items": [ /* List of PostResponse in descending save time order */ ],
  "total": 8,
  "limit": 20,
  "offset": 0
}
```

---

## 10. Feeds & Recommendations

### 10.1 Home Feed (Personalized Timeline)
- **Endpoint:** `GET /api/v1/feeds/home?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedPostsResponse`):** Posts from followed users and joined communities.

---

### 10.2 Discover Feed (Trending & Explore)
- **Endpoint:** `GET /api/v1/feeds/discover?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedPostsResponse`):** Scored by engagement and user interest category relevance.

---

### 10.3 Shorts Video Feed
- **Endpoint:** `GET /api/v1/feeds/shorts?limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedPostsResponse`):** Vertical video posts (`post_type == "video"`).

---

### 10.4 Recommended Communities
- **Endpoint:** `GET /api/v1/recommendations/communities?limit=10&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedRecommendedCommunitiesResponse`):**
```json
{
  "items": [
    {
      "id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
      "name": "AI Builders",
      "slug": "ai-builders",
      "description": "Discussing LLMs and agent architectures",
      "avatar_url": "https://.../ai.webp",
      "cover_image_url": "https://.../cover.webp",
      "is_private": false,
      "member_count": 820,
      "post_count": 210,
      "interest_id": "e4d3c2b1-1234-5678-9abc-def012345678",
      "interest_name": "Tech & AI",
      "is_matched_interest": true
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

---

### 10.5 Recommended Users
- **Endpoint:** `GET /api/v1/recommendations/users?limit=10&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedRecommendedUsersResponse`):**
```json
{
  "items": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "username": "emma_design",
      "display_name": "Emma Watson",
      "avatar_url": "https://.../emma.webp",
      "bio": "Product Designer @ GenZ",
      "follower_count": 450,
      "mutual_interest_count": 3,
      "shared_interests": ["UI/UX", "Tech & AI", "Design"]
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

---

## 11. Search Engine (`/search`)

### 11.1 Unified Search (Multi-Entity)
- **Endpoint:** `GET /api/v1/search?q=flutter&type=all&limit=20&offset=0`
- **Status:** `200 OK`

**Query Parameters:**
| Param | Type | Required | Values |
|---|---|---|---|
| `q` | `string` | Yes | Search query keyword |
| `type` | `string` | No | `"all"`, `"users"`, `"communities"`, `"posts"`, `"interests"` (default `"all"`) |

**Response Body (`UnifiedSearchResponse` for `type=all`):**
```json
{
  "query": "flutter",
  "users": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "username": "flutter_guru",
      "display_name": "Flutter Guru",
      "avatar_url": "https://.../guru.webp",
      "bio": "Dart & Flutter Expert",
      "follower_count": 1200,
      "is_following": false
    }
  ],
  "communities": [
    {
      "id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
      "name": "Flutter Developers",
      "slug": "flutter-devs",
      "description": "Community for Flutter devs",
      "avatar_url": "https://.../flutter.webp",
      "cover_image_url": "https://.../cover.webp",
      "is_private": false,
      "member_count": 145,
      "post_count": 62
    }
  ],
  "posts": [
    {
      "id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
      "title": "Flutter 3.28 Roadmap",
      "content": "Exciting updates in Flutter!",
      "post_type": "image",
      "visibility": "public",
      "author_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "author_username": "flutter_guru",
      "author_avatar_url": "https://.../guru.webp",
      "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
      "community_name": "Flutter Developers",
      "like_count": 35,
      "comment_count": 12,
      "thumbnail_url": "https://.../roadmap_thumb.webp",
      "highlight": {
        "title": "<em>Flutter</em> 3.28 Roadmap",
        "content": "Exciting updates in <em>Flutter</em>!"
      },
      "created_at": "2026-08-28T10:00:00Z"
    }
  ],
  "interests": [
    {
      "id": "e4d3c2b1-1234-5678-9abc-def012345678",
      "name": "Flutter Development",
      "slug": "flutter-dev",
      "description": "Cross platform app framework",
      "icon_url": "https://.../flutter_icon.png"
    }
  ],
  "total_results": 4
}
```

---

### 11.2 Domain-Specific Search Endpoints
- `GET /api/v1/search/users?q=...&limit=20&offset=0` → Returns `PaginatedUserSearchResponse` (`items: List[UserSearchResult]`, `total`, `limit`, `offset`)
- `GET /api/v1/search/communities?q=...&limit=20&offset=0` → Returns `PaginatedCommunitySearchResponse` (`items: List[CommunitySearchResult]`, `total`, `limit`, `offset`)
- `GET /api/v1/search/posts?q=...&limit=20&offset=0` → Returns `PaginatedPostSearchResponse` (`items: List[PostSearchResult]`, `total`, `limit`, `offset`)
- `GET /api/v1/search/interests?q=...&limit=20&offset=0` → Returns `PaginatedInterestSearchResponse` (`items: List[InterestSearchResult]`, `total`, `limit`, `offset`)

---

## 12. Notifications & Real-Time Signals (`/notifications`)

### 12.1 List Notifications
- **Endpoint:** `GET /api/v1/notifications?unread_only=false&limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedNotificationsResponse`):**
```json
{
  "items": [
    {
      "id": "n1a2b3c4-5678-90ab-cdef-1234567890ab",
      "recipient_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "actor_id": "7fa85f64-5717-4562-b3fc-2c963f66afa9",
      "actor": {
        "id": "7fa85f64-5717-4562-b3fc-2c963f66afa9",
        "username": "sarah_c",
        "display_name": "Sarah Connor",
        "avatar_url": "https://.../sarah.webp"
      },
      "notification_type": "post_like",
      "title": "New Like",
      "message": "sarah_c liked your post.",
      "entity_type": "post",
      "entity_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
      "is_read": false,
      "read_at": null,
      "created_at": "2026-08-28T12:10:00Z"
    }
  ],
  "total": 24,
  "unread_count": 3,
  "limit": 20,
  "offset": 0
}
```

---

### 12.2 Get Unread Notification Count
- **Endpoint:** `GET /api/v1/notifications/unread-count`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`UnreadCountResponse`):**
```json
{
  "unread_count": 3
}
```

---

### 12.3 Mark Single Notification as Read
- **Endpoint:** `PATCH /api/v1/notifications/{notification_id}/read`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`NotificationResponse`):** Notification object with `is_read: true`.

---

### 12.4 Mark All Notifications as Read
- **Endpoint:** `POST /api/v1/notifications/read-all`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body:**
```json
{
  "message": "Marked 3 notifications as read.",
  "count": 3
}
```

---

### 12.5 Delete Notification
- **Endpoint:** `DELETE /api/v1/notifications/{notification_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body:**
```json
{
  "message": "Notification deleted successfully."
}
```

---

### 12.6 Server-Sent Events (SSE) Stream
- **Endpoint:** `GET /api/v1/notifications/stream`
- **Auth:** `Bearer <access_token>`
- **Response Format:** `text/event-stream`
- **Events:**
  - `event: ping` -> `data: {"status": "connected"}`
  - `event: notification` -> `data: { /* JSON NotificationResponse */ }`

---

### 12.7 Ephemeral Typing Indicator
- **Endpoint:** `POST /api/v1/notifications/typing`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`TypingIndicatorPayload`):**
```json
{
  "channel": "chat:community-id",
  "is_typing": true
}
```

---

## 13. Reports & Moderation (`/reports`)

### 13.1 Submit Report
- **Endpoint:** `POST /api/v1/reports`
- **Status:** `201 Created`
- **Auth:** `Bearer <access_token>`

**Request Body (`ReportCreateRequest`):**
```json
{
  "report_type": "post",
  "target_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "reason": "spam",
  "description": "Promotional link spam without relevant context."
}
```
| Field | Type | Required | Allowed Values / Constraints |
|---|---|---|---|
| `report_type` | `string` | Yes | `"user"`, `"post"`, `"comment"`, `"community"`, `"chat_message"` |
| `target_id` | `UUID` | Yes | Target entity UUID |
| `community_id` | `UUID` | No | Scoped community UUID |
| `reason` | `string` | Yes | `"spam"`, `"harassment"`, `"inappropriate_content"`, `"hate_speech"`, `"violence"`, `"copyright"`, `"other"` |
| `description` | `string` | No | Max 1000 chars |

**Response Body (`ReportResponse`):**
```json
{
  "id": "rep1a2b3-5678-90ab-cdef-1234567890ab",
  "reporter_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "reporter_username": "cool_user99",
  "report_type": "post",
  "target_id": "p1a2b3c4-5678-90ab-cdef-1234567890ab",
  "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "reason": "spam",
  "description": "Promotional link spam without relevant context.",
  "status": "PENDING",
  "resolution_action": null,
  "resolution_notes": null,
  "reviewed_by": null,
  "reviewed_at": null,
  "created_at": "2026-08-28T12:15:00Z",
  "updated_at": "2026-08-28T12:15:00Z"
}
```

---

### 13.2 List Reports (Moderators / Community Owners)
- **Endpoint:** `GET /api/v1/reports?status=PENDING&report_type=post&community_id=...&limit=20&offset=0`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PaginatedReportsResponse`):**
```json
{
  "items": [ /* List of ReportResponse */ ],
  "total": 5,
  "limit": 20,
  "offset": 0
}
```

---

### 13.3 Update Report Status & Action
- **Endpoint:** `PATCH /api/v1/reports/{report_id}/status`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Request Body (`ReportStatusUpdateRequest`):**
```json
{
  "status": "RESOLVED",
  "resolution_action": "dismissed",
  "resolution_notes": "Spam verified and post deleted."
}
```
| Field | Type | Required | Allowed Values |
|---|---|---|---|
| `status` | `string` | Yes | `"PENDING"`, `"REVIEWING"`, `"RESOLVED"`, `"REJECTED"` |
| `resolution_action` | `string` | No | `"none"`, `"user_suspended"`, `"dismissed"` |
| `resolution_notes` | `string` | No | Max 1000 chars |

---

## 14. Community Real-Time Chat (`/chats`)

### 14.1 Issue One-Time WebSocket Ticket
- **Endpoint:** `POST /api/v1/chats/ws-ticket?community_id={community_id}`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Must be a community member)

**Response Body (`WsTicketResponse`):**
```json
{
  "ticket": "8c45cf70-55e1-4560-bfbc-63a56214df92",
  "expires_in_seconds": 60
}
```

---

### 14.2 Get Chat Message History (Cursor-Paginated)
- **Endpoint:** `GET /api/v1/chats/{community_id}/messages?before={next_cursor}&limit=50`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`ChatHistoryResponse`):**
```json
{
  "items": [
    {
      "id": "cm1a2b3c-5678-90ab-cdef-1234567890ab",
      "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
      "sender": {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "username": "cool_user99",
        "display_name": "Cool User",
        "avatar_url": "https://.../avatar.webp"
      },
      "client_message_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "message_type": "TEXT",
      "content": "Hello everyone in the community chat!",
      "reply_to_message_id": null,
      "created_at": "2026-08-28T12:20:00Z",
      "edited_at": null,
      "is_deleted": false
    }
  ],
  "next_cursor": "eyJjcmVhdGVkX2F0IjogIjIwMjYtMDgtMjhUMTI6MjA6MDAifQ==",
  "has_more": true
}
```

---

### 14.3 Get Online Members Presence
- **Endpoint:** `GET /api/v1/chats/{community_id}/presence`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`PresenceResponse`):**
```json
{
  "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "online_user_ids": [
    "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "7fa85f64-5717-4562-b3fc-2c963f66afa9"
  ],
  "online_count": 2
}
```

---

### 14.4 WebSocket Gateway Protocol
- **Connection URL:** `ws://<host>:8000/api/v1/chats/ws/{community_id}?ticket={ticket}`
- **Protocol Envelope (Client -> Server `WsIncoming`):**
  ```json
  {
    "type": "message.send",
    "request_id": "req-12345",
    "payload": {
      "content": "Hey team!",
      "client_message_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "reply_to_message_id": null
    }
  }
  ```
- **Typing Start/Stop:**
  ```json
  { "type": "typing.start" }
  { "type": "typing.stop" }
  ```
- **Heartbeat:**
  ```json
  { "type": "heartbeat" }
  ```
- **Protocol Envelope (Server -> Client `WsOutgoing`):**
  - **ACK:** `{ "type": "ack", "request_id": "req-12345", "payload": { /* ChatMessageResponse */ } }`
  - **Message Created:** `{ "type": "message.created", "payload": { /* ChatMessageResponse */ } }`
  - **Presence Joined:** `{ "type": "presence.joined", "payload": { "user_id": "...", "community_id": "..." } }`
  - **Presence Left:** `{ "type": "presence.left", "payload": { "user_id": "...", "community_id": "..." } }`
  - **Membership Revoked:** `{ "type": "membership.revoked", "payload": { "reason": "kicked" } }`

---

## 15. Live Streaming Rooms (`/live-rooms`)

### 15.1 Create Live Room
- **Endpoint:** `POST /api/v1/live-rooms?community_id={community_id}`
- **Status:** `201 Created`
- **Auth:** `Bearer <access_token>` (Owner or Moderator)

**Request Body (`LiveRoomCreate`):**
```json
{
  "title": "Flutter 3.28 Live Coding Q&A",
  "description": "Building live Riverpod and animations."
}
```

**Response Body (`LiveRoomResponse`):**
```json
{
  "id": "lr1a2b3c-5678-90ab-cdef-1234567890ab",
  "community_id": "c1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c",
  "created_by": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "title": "Flutter 3.28 Live Coding Q&A",
  "description": "Building live Riverpod and animations.",
  "provider": "LIVEKIT",
  "provider_room_name": "room_lr1a2b3c",
  "status": "READY",
  "current_viewers": 0,
  "created_at": "2026-08-28T12:00:00Z",
  "updated_at": "2026-08-28T12:00:00Z"
}
```

---

### 15.2 Start Live Session (Host Flow)
- **Endpoint:** `POST /api/v1/live-rooms/{room_id}/start`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Host only)

**Response Body (`LiveTokenResponse`):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.livekit_token...",
  "livekit_url": "wss://livekit.genzmedia.app",
  "room_name": "room_lr1a2b3c",
  "participant_identity": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "is_host": true,
  "session_id": "ls1a2b3c-5678-90ab-cdef-1234567890ab"
}
```

---

### 15.3 Request Viewer Token (Audience Flow)
- **Endpoint:** `POST /api/v1/live-rooms/{room_id}/token`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>`

**Response Body (`LiveTokenResponse`):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.livekit_viewer_token...",
  "livekit_url": "wss://livekit.genzmedia.app",
  "room_name": "room_lr1a2b3c",
  "participant_identity": "7fa85f64-5717-4562-b3fc-2c963f66afa9",
  "is_host": false,
  "session_id": "ls1a2b3c-5678-90ab-cdef-1234567890ab"
}
```

---

### 15.4 End Live Session (Host Flow)
- **Endpoint:** `POST /api/v1/live-rooms/{room_id}/end`
- **Status:** `200 OK`
- **Auth:** `Bearer <access_token>` (Host only)

**Response Body (`LiveSessionResponse`):**
```json
{
  "id": "ls1a2b3c-5678-90ab-cdef-1234567890ab",
  "room_id": "lr1a2b3c-5678-90ab-cdef-1234567890ab",
  "host_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "started_at": "2026-08-28T12:00:00Z",
  "ended_at": "2026-08-28T12:45:00Z",
  "duration_seconds": 2700,
  "peak_viewers": 156,
  "unique_viewers": 310,
  "total_joins": 420
}
```

---

### 15.5 Get Live Room Metrics
- **Endpoint:** `GET /api/v1/live-rooms/{room_id}/metrics`
- **Status:** `200 OK`

**Response Body (`LiveMetricsResponse`):**
```json
{
  "room_id": "lr1a2b3c-5678-90ab-cdef-1234567890ab",
  "session_id": "ls1a2b3c-5678-90ab-cdef-1234567890ab",
  "status": "LIVE",
  "current_viewers": 142,
  "peak_viewers": 156,
  "unique_viewers": 310,
  "total_joins": 420,
  "started_at": "2026-08-28T12:00:00Z",
  "duration_seconds": 1800
}
```
