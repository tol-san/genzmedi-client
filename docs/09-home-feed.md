# 09 — Home Feed

## Status
- **Client Implementation**: Complete (`HomeFeedScreen`, `HomeFeedNotifier`, `HomeFeedState`, `PostCardWidget`).
- **Backend Endpoint**: `GET /api/v1/feeds/home?limit=20&offset=0`.

---

## Architecture & Data Flow

### 1. Endpoint & Service
- **Endpoint**: `GET /api/v1/feeds/home`
- **Response**: `PaginatedPostsResponse(items: List[PostModel], total: int, limit: int, offset: int)`
- **Feed Composition**:
  - Followed user posts
  - Joined community posts
  - Interest match recommendations

### 2. Riverpod State Management
- `homeFeedNotifierProvider`: `StateNotifier<HomeFeedState>`
- **Operations**:
  - `loadInitial()`: Loads first page (`limit=20, offset=0`).
  - `refresh()`: Pull-to-refresh reload.
  - `loadMore()`: Infinite scroll listener trigger when approaching bottom.
  - `toggleLike(postId)`: Optimistic like mutation with automatic rollback on network failure.
  - `toggleSave(postId)`: Optimistic bookmark mutation with rollback.
  - `sharePost(postId)`: Increments share counter and copies link to clipboard.

### 3. Post Card Component (`PostCardWidget`)
- Author avatar, display name, username, relative timestamp.
- Post title and text body.
- Multi-image swipeable carousel with page indicator dots, or video thumbnail with play trigger.
- Interactive engagement bar with Like (Crimson), Comment, Save (Mint), and Share.
- Tapping author navigates to `PublicProfileScreen`.
