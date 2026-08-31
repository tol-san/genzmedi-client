# 13 — Communities & Membership

## Status
- **Client Implementation**: Complete (`CommunityListScreen`, `CommunityDetailScreen`, `CreateCommunityScreen`, `CommunityCardWidget`, `CommunityRepository`, `CommunityListNotifier`, `CommunityDetailNotifier`, `CreateCommunityNotifier`).
- **Backend Endpoints**:
  - `POST /api/v1/communities`
  - `GET /api/v1/communities`
  - `GET /api/v1/communities/me/joined`
  - `GET /api/v1/communities/{community_id}`
  - `PATCH /api/v1/communities/{community_id}`
  - `DELETE /api/v1/communities/{community_id}`
  - `POST /api/v1/communities/{community_id}/cover`
  - `POST /api/v1/communities/{community_id}/join`
  - `DELETE /api/v1/communities/{community_id}/leave`
  - `GET /api/v1/communities/{community_id}/members`
  - `DELETE /api/v1/communities/{community_id}/members/{user_id}`
  - `GET /api/v1/communities/{community_id}/join-requests`
  - `POST /api/v1/communities/{community_id}/join-requests/{request_id}/approve`
  - `POST /api/v1/communities/{community_id}/join-requests/{request_id}/reject`

---

## Community Types & Access Control

### 1. Public Communities
- Anyone can discover, view, and tap **Join** to become an active member immediately.
- Private community details and member lists are visible only to members, owners, and platform administrators. A user with a known ID may request access but cannot read private metadata before approval.
- Once joined, members can publish posts directly to the community feed.

### 2. Private Communities
- Tapping **Request to Join** submits a membership request with `status: pending`.
- **Owner Controls**: The community owner accesses a dedicated **Requests** tab on `CommunityDetailScreen` to **Approve** or **Reject** pending users.
- Approved users automatically transition to active members.

### 3. Roles & Management
- **Owner**:
  - Identified by the Crimson Owner Shield badge.
  - Can kick members via the **Members** tab.
  - Can review and approve/reject join requests.
  - Can upload custom cover banners via `POST /communities/{id}/cover`.
- **Member**:
  - Can view community content and participate in discussions.
  - Can leave anytime with a confirmation dialog.
