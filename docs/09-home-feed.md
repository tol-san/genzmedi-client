# 09 — Home Feed

## Status
- **Client Implementation**: Complete (`HomeFeedScreen`, `HomeFeedNotifier`, `HomeFeedState`, `PostCardWidget`, `FeedVideoPlayerWidget`).
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

### 3. Full-Width Feed & Post Item Component (`PostCardWidget`)
- **Quick Create Entry**: The post list begins with a compact creation panel
  that routes directly to Text, Multi-image, or Short-video composer modes.
- **Focused Post List**: Posts use softly elevated, rounded surfaces with clear
  breathing room between items. Media remains immersive inside the clipped card
  while author, content, counters, and actions retain their existing hierarchy.
- **Inline Video Auto-Play (`FeedVideoPlayerWidget`)**:
  - Automatically initializes and plays inline video feeds with looping.
  - Starts muted with a discrete Mute/Unmute audio toggle badge in the corner.
  - Tap video to toggle play/pause.
  - Displays a clean centered play indicator when paused.
- **Author Header**: Avatar, bold display name, `@username`, relative timestamp, privacy globe icon (`🌐`), and overflow options menu (`...`).
- **Content Typography**: Clean title and body formatting.
- **Edge-to-Edge Media Collage Grid**:
  - Single media item: 16:9 full-width view with inline auto-playing video or image.
  - Two media items: 2 equal side-by-side vertical columns.
  - Three media items: 1 primary hero item + 2 stacked items.
  - Four media items: 2x2 grid.
  - Five+ media items: 2x2 grid with frosted `+N` badge on the 4th item.
- **Reactions & Engagement Counters Row**: Top summary showing like reaction badge, like count, comment count, and share count.
- **Interactive 3-Button Action Bar**: Border divider with touch-friendly **Like**, **Comment**, and **Share** buttons (Save button is moved into the overflow `...` menu to match modern social feed conventions).
