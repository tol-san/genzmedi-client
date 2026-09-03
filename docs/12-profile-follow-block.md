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
| `/settings` | `RouteNames.settings` | `AccountSettingsScreen` | Settings hub: Profile, Security, Preferences, Legal & Support, and Sign Out |
| `/settings/change-password` | `RouteNames.changePassword` | `ChangePasswordScreen` | Form to verify current password, enforce 8+ char new password, and revoke session |
| `/settings/blocked-users` | `RouteNames.blockedUsers` | `BlockedUsersScreen` | Paginated list of blocked creators with optimistic unblock action and confirmation dialog |


### Profile presentation

- Personal and public profiles share a responsive overview card so identity,
  verification, social stats, biography, interests, and primary actions remain
  visually consistent.
- The avatar uses a branded accent ring, verified creators receive an explicit
  badge, and follower/following stats remain interactive.
- Edit/follow and profile-link actions use consistent 48 dp touch targets.
- Personal content uses pinned Posts/Saved tabs; public profiles use a clear
  Posts section followed by the creator's grid or empty state.

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

---

## 4. Account Settings & Security Architecture

### Settings Hub (`AccountSettingsScreen`)
- **Account & Profile**: Shortcuts to `EditProfileScreen` and `ChangePasswordScreen`.
- **Privacy & Safety**: Shortcut to `BlockedUsersScreen` with total blocked user visibility.
- **Preferences (Appearance)**: Live theme selector (`ThemeModeNotifier` + `themeModeProvider`) persisting `System Default`, `Light Mode`, and `Dark Mode` via `SharedPreferences`.
- **About & Support**: In-app `LegalSheetWidget` modals for Community Guidelines, Terms of Service, Privacy Policy, and Report Problem feedback handler.
- **Session**: Sign Out with confirmation dialog.

### Change Password (`ChangePasswordScreen`)
- **Endpoint**: `POST /api/v1/auth/change-password`
- **Payload**: `{ "current_password": "...", "new_password": "..." }`
- **Validation**: Current password required; new password minimum 8 characters; distinct from current password; confirm password matching.
- **Post-Action**: Automatic session sign-out requiring re-authentication with the new password.

### Blocked Users Manager (`BlockedUsersScreen`)
- **Endpoint**: `GET /api/v1/users/me/blocked?limit=20&offset=0`
- **Unblock**: `DELETE /api/v1/users/{user_id}/block`
- **Behavior**: Paginated scrolling list with optimistic removal on unblock, safety confirmation dialog, and error rollback.

### Privacy Settings (`PrivacySettingsScreen`)
- **Endpoints**: `GET /api/v1/users/me/privacy`, `PATCH /api/v1/users/me/privacy`
- **Controls**:
  - `is_private`: Toggle account private mode (only approved followers see content).
  - `search_discoverable`: Toggle whether profile appears in discovery / search results.
  - `show_activity_status`: Control online presence indicator.
  - `allow_comments`: Audience selector (`everyone`, `following`, `no_one`).
  - `allow_mentions`: Audience selector (`everyone`, `following`, `no_one`).

### Notification Preferences (`NotificationPreferencesScreen`)
- **Endpoints**: `GET /api/v1/notifications/preferences`, `PATCH /api/v1/notifications/preferences`
- **Controls**:
  - **Interactions**: Post likes, comments, replies & mentions.
  - **Social & Communities**: New follower alerts, community announcements and requests.
  - **Delivery Channels**: Push notifications, email digests & security alerts.
  - **Quiet Hours**: Master toggle and schedule interval (`quiet_hours_start` to `quiet_hours_end`).

### Sessions & Device Management (`SessionsScreen`)
- **Endpoints**:
  - `GET /api/v1/auth/sessions`: List all active sessions.
  - `DELETE /api/v1/auth/sessions/{session_id}`: Revoke a specific device session.
  - `POST /api/v1/auth/sessions/other`: Sign out from all other devices.
- **Behavior**: Highlights current device with "Active Now" badge and metadata (IP address, last active relative time); offers individual revocation and bulk sign-out of other devices.

### Account Management (`AccountManagementScreen`)
- **Endpoints**:
  - `POST /api/v1/users/me/deactivate`: Deactivate account with password confirmation & optional reason.
  - `DELETE /api/v1/users/me`: Permanently delete account, requiring password verification and typing "DELETE" confirmation string.
  - **Data Export**: Request an archive of personal account data.

