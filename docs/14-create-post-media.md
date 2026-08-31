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
  - Compact header titled `Create` with concise heading `What are you posting?`.
  - Four content creation choices tailored for Gen Z:
    - **🎬 Video**: Post a short video (routes to Short Video composer).
    - **🖼️ Photo**: Share one or multiple photos (routes to Photo composer).
    - **💬 Post**: Share a thought, story, or discussion (routes to Text composer).
    - **📊 Poll**: Ask the community (Poll prompt banner).
- **Composer Modes (`CreatePostScreen`)**:
  - **Text**: Multiline content body (max 1000 chars), visibility selector, community selector.
  - **Photos**: Multi-image selector (up to 10 images) via `ImagePicker.pickMultiImage()`, horizontal thumbnail preview list with individual delete buttons, caption.
  - **Short Video**: Video picker via `ImagePicker.pickVideo()`, custom thumbnail picker via `ImagePicker.pickImage()`, file size/name display, caption.

### 2. Media Upload Pipeline & Real-Time Progress Tracking
- Media files are uploaded to MinIO via `POST /api/v1/posts/media` using multipart form data.
- Post objects live in a private bucket. Upload and post responses expose only short-lived signed URLs.
- A post may attach only media under the current user's `posts/{user_id}/...` prefix; declared MIME types are checked against decoded file signatures.
- **Progress Tracking**:
  - Dio's `onSendProgress(int sent, int total)` streams chunk progress directly to `CreatePostNotifier`.
  - Multi-image uploads calculate proportional cumulative progress `(i + fileFraction) / N`.
  - Video and custom thumbnail uploads calculate weighted upload percentages.
  - Real-time `uploadProgress` (`0.0` - `1.0`) and `uploadStatusText` (e.g. *Uploading photo 2 of 4 (50%)*) drive an animated `LinearProgressIndicator` and dynamic percentage indicators in `CreatePostScreen`.
- Returned `MediaUploadModel` (containing URL, thumbnail URL, width, height, and duration) is attached to `MediaItemModel`.
- Post is published atomically via `POST /api/v1/posts` upon completion of media upload.
- Draft preservation and error banners ensure inputs are retained if upload/network fails.
