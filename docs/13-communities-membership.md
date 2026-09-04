# 13 — Communities & Membership

## Status
- **Client Implementation**: Complete (`CommunityListScreen`, `CommunityDetailScreen`, `CreateCommunityScreen`, `EditCommunityScreen`, `DeleteCommunityConfirmDialog`, `CommunityCardWidget`, `CommunityRepository`, `CommunityListNotifier`, `CommunityDetailNotifier`, `CreateCommunityNotifier`).
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
  - Can upload custom cover banners and avatar logos.
- **Member**:
  - Can view community content and participate in discussions.
  - Can leave anytime with a confirmation dialog.

### 4. Edit Community Information (`EditCommunityScreen`)
- **Route**: `/communities/:communityId/edit`
- **Owner Permissions**: Only the community creator/owner or superusers can access.
- **Editable Attributes**:
  - Community name (2–100 characters).
  - Description (up to 1,000 characters).
  - Privacy mode: Dynamically switch between Public and Private.
  - Visual branding: Upload and change cover banner and avatar logo.
- **State Propagation**: Updates `CommunityDetailNotifier` and `CommunityListNotifier` in place.

### 5. Community Deletion & Cascading
- **Destructive Cascade**: Deletes all memberships, community posts, comments, media in storage, and search index records.
- **Typed-Name Confirmation Dialog (`DeleteCommunityConfirmDialog`)**: Requires the owner to type the exact community name to confirm deletion before the delete button activates.
- **State Eviction**: Evicts community from explore and joined feeds and routes back to `/communities`.

### 6. Community Post Creation & Feed Association
- **Access Control**: Restricted to active members and community owners. Non-members and users with pending requests cannot publish community posts.
- **Direct Entry Points**:
  - Quick Post CTA prompt in the community `Posts` tab.
  - Floating Action Button (`Post`) rendered for active members and owners.
- **Locked Destination Safety**:
  - The composer locks the destination to the current community (`Posting to [Community Name] (Locked)`), preventing accidental publication to personal profiles.
  - Community branding (avatar and name) is visually highlighted in the destination banner.
- **Feed & Counter Synchronization**:
  - Newly published posts are optimistically prepended to the community post feed (`CommunityDetailNotifier.addPost`).
  - The community `postCount` increments immediately.
