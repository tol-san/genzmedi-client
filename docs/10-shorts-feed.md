# 10 — Shorts Feed

## Status
- **Client Implementation**: Complete (`ShortsFeedScreen`, `ShortsFeedNotifier`, `ShortsFeedState`, `ShortVideoItemWidget`).
- **Backend Endpoint**: `GET /api/v1/feeds/shorts?limit=20&offset=0`.

---

## Architecture & Interaction

### 1. Endpoint & Service
- **Endpoint**: `GET /api/v1/feeds/shorts`
- **Response**: `PaginatedPostsResponse` filtered to short video posts.
- **Ranking**: Interest affinity, likes, saves, and recency.

### 2. Full-Screen Vertical Paging
- **Widget**: `PageView.builder` with `scrollDirection: Axis.vertical`.
- **Playback Model**:
  - `active`: Plays current short video via `VideoPlayerController.networkUrl`.
  - `inactive`: Pauses playback immediately on page swipe.
  - Controls: Tap anywhere on screen to toggle play/pause, top right mute/unmute button.

### 3. Engagement Overlays
- **Right Action Rail**:
  - Author Avatar (navigates to `@username` public profile).
  - Like button with count and crimson toggle.
  - Comment bubble button with count.
  - Bookmark/Save button with mint toggle.
  - Share button with clipboard copy and counter.
- **Bottom Content Overlay**:
  - Creator `@username` and display name.
  - Video title and description / hashtags.
