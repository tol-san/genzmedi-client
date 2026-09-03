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
