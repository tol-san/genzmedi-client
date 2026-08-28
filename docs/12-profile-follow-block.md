# 12 — Profile, Follow & Block

## Overview
The profile and social relationship architecture powers user identity, discovery, social graphs (followers & following lists), moderation reporting, and account security.

---

## 1. Routes & Screens

| Route | Route Name | Screen | Description |
|---|---|---|---|
| `/profile` | `RouteNames.myProfile` | `MyProfileScreen` | Current user profile with interactive stats, post tabs, saved posts, and profile link copy |
| `/profile/edit` | `RouteNames.editProfile` | `EditProfileScreen` | Avatar picker/remover, Display Name (max 50 chars), Bio (max 160 chars), Dynamic Interests selector |
| `/profile/:username` | `RouteNames.publicProfile` | `PublicProfileScreen` | Public profile view, optimistic follow toggle, report bottom sheet, block modal |
| `/user/:username` | Alias | `PublicProfileScreen` | Canonical user handle alias route |
| `/user/:userId/follow-list` | `RouteNames.followList` | `FollowListScreen` | Tabbed followers/following list with search filtering, pull-to-refresh, and inline follow toggles |

---

## 2. Profile Models & Fields

- `id`: User UUID
- `username`: Unique lowercase user handle (3–30 characters)
- `email`: Authenticated user email
- `display_name`: Creator alias (max 50 characters)
- `avatar_url`: CDN/MinIO hosted avatar image path
- `bio`: Creator biography (max 160 characters)
- `interests`: List of selected interest category slugs/IDs
- `followers_count`: Total users following this account
- `following_count`: Total users followed by this account
- `post_count`: Total posts published
- `is_verified`: Creator verification status

---

## 3. Social Graph & Moderation API Flow

### Follow / Unfollow
- **Follow**: `POST /api/v1/users/{user_id}/follow`
- **Unfollow**: `DELETE /api/v1/users/{user_id}/follow`
- **Followers List**: `GET /api/v1/users/{user_id}/followers?limit=20&offset=0`
- **Following List**: `GET /api/v1/users/{user_id}/following?limit=20&offset=0`
- **Relationship**: `GET /api/v1/users/{user_id}/relationship`

### Block / Unblock
- **Block**: `POST /api/v1/users/{user_id}/block`
- **Unblock**: `DELETE /api/v1/users/{user_id}/block`
- Confirmed via confirmation dialog; severs any mutual follow relationships and updates relationship state.

### Moderation Reporting
- **Endpoint**: `POST /api/v1/reports`
- **Payload**:
  ```json
  {
    "report_type": "user",
    "target_id": "<uuid>",
    "reason": "spam | harassment | inappropriate_content | hate_speech | violence | copyright | other",
    "description": "Optional notes provided by reporter"
  }
  ```
- Handled via `ReportUserSheet` modal widget.
