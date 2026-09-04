# 16 — Saved Posts, Share & Report

# Save

Feature requirement:
- Save / Unsave
- Private saved post list
- Paginated retrieval and destination routing

Documented endpoints:
- `POST /api/v1/posts/{post_id}/save` — Save post
- `DELETE /api/v1/posts/{post_id}/save` — Unsave post
- `GET /api/v1/posts/saved` — Fetch paginated saved posts for authenticated user (`limit`, `offset`)

## Saved UX & Navigation Flow
- **Profile Tab**: Displayed in `MyProfileScreen` under the `Saved` tab. Saved posts are strictly private to the authenticated user.
- **Destination-Specific Navigation**:
  - **Short Video (`postType == 'video'`)**: Routes to `ShortsViewer` (`RouteNames.shortsViewer`).
  - **Multi-Image (`postType == 'image' && media.isNotEmpty`)**: Routes to `MediaViewer` (`RouteNames.mediaViewer`).
  - **Text / General (`postType == 'text'`)**: Routes to `PostDetailScreen` (`RouteNames.postDetail`).
- **Immediate Cross-App Eviction**:
  - When a post is unsaved anywhere in the application (Post Detail, Home Feed, Shorts, Discover), `MyProfileNotifier.removeSavedPost(postId)` immediately evicts the item from `MyProfileState.savedPosts` without requiring a reload.
- **Auto-Refresh on Return**:
  - Returning from the opened post viewer automatically re-queries saved posts to synchronize likes, comments, and save status.
- **Pagination & Infinite Scroll**:
  - `MyProfileNotifier.loadMoreSavedPosts()` fetches subsequent pages with offset pagination when scrolling near the bottom of the grid.
- **Error & Inaccessible Content Handling**:
  - `MyProfileScreen` renders an error card with a `Retry` button if loading saved posts fails.
  - `PostDetailScreen` renders a dedicated `Post Unavailable` / `Private Post` card with clear explanations, a "Go Back" action, and a "Retry" button when a saved post is deleted or no longer accessible.

# Share

Backend feature requirement says:
- generate shareable link;
- increment share counter.

The API endpoint directory does not explicitly list a share endpoint.

Frontend should:
- use implemented backend share/link contract;
- invoke native system share sheet.

Do not invent a share-counter route.

# Report

`POST /api/v1/reports`

Reportable targets:
- user;
- post;
- comment;
- community;
- chat message.

Documented reasons:
- `spam`
- `harassment`
- `inappropriate_content`
- `hate_speech`
- `violence`
- `copyright`
- `other`

## Report sheet

```text
Report
Choose reason
Optional details if schema supports
Submit
```

Flutter uses one reusable `ReportSheet` for accounts, posts, short-video posts,
comments, communities, and chat messages. The sheet requires one supported
reason, accepts up to 1,000 characters of optional context, disables duplicate
submits while the request is running, and preserves backend error messages
(including inaccessible targets and duplicate open reports).

Integrated entry points:

- public profile overflow menu;
- post and short-video option menus;
- comment option menu for comments not authored by the current user;
- community option menu for non-owners.

The generic sheet also accepts `ReportTargetType.chatMessage` and community
scope so a chat-message row can invoke the same real submission flow when the
community chat screen is added.

Do not add unconfirmed fields.

## Success

Use brief acknowledgement:

> Post report submitted for review.

Do not expose moderation outcome immediately unless backend returns it and product wants it.
