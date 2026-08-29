# 15 — Posts, Comments & Engagement

## Status
- **Client Implementation**: Complete (`PostDetailScreen`, `PostDetailNotifier`, `PostDetailState`, `CommentTileWidget`, `CommentInputBar`, `CommentRepository`).
- **Backend Endpoints**:
  - `GET /api/v1/posts/{post_id}`
  - `GET /api/v1/posts/{post_id}/comments`
  - `POST /api/v1/posts/{post_id}/comments`
  - `GET /api/v1/comments/{comment_id}/replies`
  - `DELETE /api/v1/comments/{comment_id}`

---

## Architecture & Hierarchy

### 1. Post Detail View (`PostDetailScreen`)
- **Route**: `/posts/:postId`
- **Header**: Author avatar, username, display name, relative timestamp.
- **Content**: Post title, full multiline content body, and media carousel with active page indicator dots.
- **Engagement Bar**: Like (Crimson), Bookmark/Save (Mint), and Share (copies URL to clipboard).

### 2. Discussion & Comment Thread
- **Top-Level Comments**: Paginated list of top-level comments.
- **Nested Replies**:
  - 1 visual level of indentation on mobile.
  - "View X replies" / "Hide replies" expandable toggle calling `GET /api/comments/{commentId}/replies`.
- **Comment Deletion**: Comment author can delete comments/replies with instantaneous local tree update and post comment count synchronization.

### 3. Sticky Comment Composer (`CommentInputBar`)
- Attached pinned above keyboard with `MediaQuery.of(context).viewInsets.bottom`.
- Reply context banner with cancel action when replying to specific comment (`@username`).
- Debounced send button with loading progress indicator.
