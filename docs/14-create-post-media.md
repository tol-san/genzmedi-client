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
  - Direct entry point for **Short Video**, **Photo Carousel**, and **Discussion / Thought**.
- **Composer Modes (`CreatePostScreen`)**:
  - **Text**: Optional Title (max 100 chars), multiline content body (max 1000 chars), visibility selector.
  - **Photos**: Multi-image selector (up to 10 images) via `ImagePicker.pickMultiImage()`, horizontal thumbnail preview list with individual delete buttons, caption.
  - **Short Video**: Video picker via `ImagePicker.pickVideo()`, custom thumbnail picker via `ImagePicker.pickImage()`, file size/name display, caption.

### 2. Media Upload Pipeline
- Media files are uploaded to MinIO via `POST /api/v1/posts/media` using multipart form data.
- Returned `MediaUploadModel` (containing URL, thumbnail URL, width, height, and duration) is attached to `MediaItemModel`.
- Post is published atomically via `POST /api/v1/posts` upon completion of media upload.
- Draft preservation and error banners ensure inputs are retained if upload/network fails.
