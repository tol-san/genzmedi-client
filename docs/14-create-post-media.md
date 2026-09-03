# 14 — Create Post & Media

## Status
- **Client Implementation**: Complete (`CreateHubScreen`, `CreatePostScreen`, `CreatePostNotifier`, `CreatePostState`, `PostRepository`).
- **Backend Endpoints**:
  - `POST /api/v1/posts`
  - `POST /api/v1/posts/media`

---

## Architecture & Creation Flow

### 1. Creation Hub & Modes
- **Hub Navigation (`CreateHubScreen`)**:
  - Branded format-picker hero with three focused creation cards.
  - **Text post** starts a long-form text composer.
  - **Multi-image post** starts a carousel composer for up to 10 photos.
  - **Short video** starts a vertical-video composer with optional cover image.
  - Poll remains visible as a clearly disabled coming-soon option.
- **Composer Modes (`CreatePostScreen`)**:
  - A fixed publish action, persistent draft cue, responsive format switcher,
    accessible audience controls, and mode-specific titles are shared by all
    composers.
  - **Text**: Enlarged multiline content body (max 1000 chars) and visibility selector.
  - **Photos**: Multi-image selector (up to 10 images) via `ImagePicker.pickMultiImage()`, numbered horizontal thumbnail previews with individual delete buttons, live selection count, and caption.
  - **Short Video**: Purpose-built vertical video picker via `ImagePicker.pickVideo()`, custom thumbnail picker via `ImagePicker.pickImage()`, file status, and caption.

### 2. Media Upload Pipeline & Real-Time Progress Tracking
- Media files are uploaded to MinIO via `POST /api/v1/posts/media` using multipart form data.
- Post objects live in a private bucket. Upload and post responses expose only short-lived signed URLs.
- A post may attach only media under the current user's `posts/{user_id}/...` prefix; declared MIME types are checked against decoded file signatures.
- **Progress Tracking**:
  - Dio's `onSendProgress(int sent, int total)` streams chunk progress directly to `CreatePostNotifier`.
  - Multi-image uploads calculate proportional cumulative progress `(i + fileFraction) / N`.
  - Video and custom thumbnail uploads calculate weighted upload percentages.
  - Real-time `uploadProgress` (`0.0` - `1.0`) and `uploadStatusText` (e.g. *Uploading photo 2 of 4 (50%)*) drive a prominent publishing card, animated progress bar, exact percentage, phase description, and protected disabled publish state in `CreatePostScreen`.
- Returned `MediaUploadModel` (containing URL, thumbnail URL, width, height, and duration) is attached to `MediaItemModel`.
- Post is published atomically via `POST /api/v1/posts` upon completion of media upload.
- Draft preservation and error banners ensure inputs are retained if upload/network fails.

---

## Post Lifecycle & Management Flow

### 3. Post Editing (`EditPostScreen`)
- **Route**: `/posts/:postId/edit`
- **Backend Endpoint**: `PATCH /api/v1/posts/{post_id}`
- **Capabilities**:
  - Title editing (optional, max 120 chars).
  - Content / Caption editing (max 2000 chars).
  - **Post-Publishing Visibility Change**: Switch dynamically between `public`, `followers_only`, and `private`.
  - **Media Immutability Notice**: Clearly communicates that attached media items cannot be modified post-publishing.
  - Form validation, error handling, and optimistic feed / detail updates via `HomeFeedNotifier.updatePost()` and `PostDetailNotifier.updatePost()`.

### 4. Post Deletion & Confirmation
- **Backend Endpoint**: `DELETE /api/v1/posts/{post_id}`
- **Authorization**: Post author, community owner, or platform administrator (`isSuperuser`).
- **Confirmation**: Safety dialog (`Delete Post? This action cannot be undone.`) prevents accidental loss.
- **State Eviction**: Seamlessly evicts the deleted post from active feeds via `HomeFeedNotifier.removePost(postId)` and navigates away from `PostDetailScreen`.

### 5. Post Reporting & Moderation
- **Backend Endpoint**: `POST /api/v1/reports`
- **Interface**: `ReportSheet` modal sheet accessible from both `PostCardWidget` and `PostDetailScreen`.
- **Payload**: `report_type: post`, `target_id: postId`, `reason`, `description`, optional `community_id`.

### 6. Community Context & Assignment
- **Navigation**: Opening the composer from `CommunityDetailScreen` propagates `communityId` and `communityName` via query parameters.
- **Composer Badge**: Displays an active community chip (`Posting to: [Community Name]`) in `CreatePostScreen` with an interactive clear button.
- **Submission**: Binds `community_id` to `PostCreateRequestModel` for verified community feed inclusion.

### 7. Comment & Reply Editing (`CommentTileWidget`)
- **Backend Endpoint**: `PATCH /api/v1/comments/{comment_id}`
- **Scope**: Top-level comments and nested comment replies share the identical update pipeline.
- **Permissions**: Authorized for the original comment author or platform administrators (`isSuperuser`). Community owners cannot edit other members' text (only delete/moderate).
- **Inline Editor**:
  - Activates inline via the comment options menu (`Edit comment`).
  - Auto-expanding text input pre-filled with current text.
  - Live character counter (max 1,000 characters).
  - Client-side validation prevents empty/whitespace-only submissions.
  - "Cancel" button restores original content; "Save" button provides progress indicator and double-submission protection.
- **State Preservation**:
  - `PostDetailNotifier.updateComment` updates local and feed comments seamlessly without reloading.
  - Preserves existing child replies, reply counts, and expanded/collapsed state.
  - Displays persistent `(edited)` tag next to the timestamp once updated (`is_edited: true`).
