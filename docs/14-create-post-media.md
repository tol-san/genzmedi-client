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
  - Streamlined format-picker with three focused, distraction-free creation cards.
  - **Text post** starts a long-form text composer.
  - **Multi-image post** starts a carousel composer for photos.
  - **Short video** starts a vertical-video composer with optional cover image.
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
- Feed responses preserve externally hosted HTTP(S) URLs on seeded or legacy posts; only application-owned MinIO objects are presigned.
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
- **Navigation**: Opening the composer from `CommunityDetailScreen` propagates `communityId`, `communityName`, `communityAvatarUrl`, and `isLocked: 'true'` via query parameters.
- **Locked Destination Banner**:
  - Displays the community avatar logo and name: `Posting to: [Community Name]`.
  - Displays a prominent `Locked` badge (`Icons.lock_outline_rounded`), strictly preventing accidental publication to personal profiles when started from inside a community context.
- **Global Destination Picker**:
  - When opened from the global creation hub (`communityId == null`), displays `Destination: My Profile (Default)`.
  - An interactive `Change` button opens a modal sheet allowing selection of any joined community (`joinedCommunities`), or resetting back to personal profile.
- **Submission & Feed Integration**:
  - Binds `community_id` to `PostCreateRequestModel`.
  - Returns the newly created `PostModel` on pop, which `CommunityDetailNotifier.addPost()` immediately prepends to the community post feed while incrementing `community.postCount`.

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

### 8. Photo Viewer & Gallery Download Pipeline (`PostPhotoViewerScreen`)
- **Engine**: Dedicated `PhotoDownloadService` (`photoDownloadServiceProvider`) backed by Dio byte streaming and native `gal` gallery write integration.
- **Workflow & Actions**:
  - Full-screen lightbox with pan, zoom, author attribution, engagement actions, and options menu (`Icons.more_vert_rounded`).
  - **Single Photo**: "Save to phone" downloads the currently viewed photo.
  - **Multi-Photo Posts**: Discloses both "Save this photo" and "Save all photos (N)" options.
- **Permission Flow**:
  - Android: Modern Scoped Storage MediaStore API (Android 10+ requires zero storage permissions); legacy fallback `WRITE_EXTERNAL_STORAGE` and `READ_MEDIA_IMAGES` configured in `AndroidManifest.xml`.
  - iOS: `PHPhotoLibrary` permission checks with `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription` in `Info.plist`.
  - **Permanently Denied Action**: If gallery permissions are permanently blocked, displays an actionable SnackBar button (`Settings`) navigating directly to system app permissions via `permission_handler`'s `openAppSettings()`.
- **Download Lifecycle & UI States**:
  - **Duplicate Tap Prevention**: Disables download triggers and guards methods while `_isDownloading == true`.
  - **Progress Overlay Banner**: Displays animated floating overlay containing a circular indicator, linear progress track, and live status (e.g. *Downloading photo (65%)*, *Saving to device gallery...*).
  - **Unique Filename Generation**: Generates collision-resistant identifiers `genz_{shortPostId}_{mediaId}.{ext}`, inferring extensions from Content-Type or URI path.
  - **Error & Retry**: Surfaces network timeouts or download errors with a SnackBar containing a `Retry` callback.
