# GenZ Media — Flutter Client

> An interest-first social community platform designed for Gen Z, featuring vertical short-form video (Shorts), discovery feeds, interest-based communities, real-time WebSocket chat, live streaming rooms, and modern interactions.

---

## 📱 Navigation & Experience

GenZ Media uses a streamlined, low-chrome bottom navigation structure:

```text
Home  ·  Shorts  ·  Create  ·  Discover  ·  Profile
```

- **Home**: Algorithmic & following feed with rich media, comments, and engagement.
- **Shorts**: High-performance, full-screen vertical short-video feed.
- **Create**: Multi-media composer supporting text, image carousel, and video uploads.
- **Discover**: Meilisearch-powered discovery, trending topics, hashtags, and community search.
- **Profile**: User profiles, activity tabs, saved posts, settings, and relationship management.
- **Contextual Features**: Community Real-Time Chat, Live Streaming Rooms, Notifications Center, and Content Moderation.

---

## 📚 Project Documentation (`docs/`)

Comprehensive technical and UX specifications for the Flutter frontend are available in the [`docs/`](docs/README.md) directory.

### 🧭 Overview & Guidelines
- **[Documentation Hub](docs/README.md)** — Core documentation index & system overview.
- **[Agent Sitemap & Task Routing](docs/00-agent-sitemap.md)** — Guide on required docs per development task.
- **[Agent Rules & Conventions](docs/31-agent-rules.md)** — Strict rules for AI coding agents and contributors.
- **[Testing & Definition of Done](docs/29-testing-definition-of-done.md)** — Acceptance criteria and testing standards.
- **[Development Roadmap](docs/30-development-roadmap.md)** — Implementation order and milestone tracking.

---

### 🎨 Product & Design System
- **[01 — Product Foundation](docs/01-product-foundation.md)** — Product vision, value proposition, and user journey.
- **[02 — Backend Scope & Priorities](docs/02-backend-scope-priority.md)** — P0/P1/P2 feature matrix and scope boundaries.
- **[03 — Frontend Product Decisions](docs/03-frontend-product-decisions.md)** — 2026 UI/UX design and interaction decisions.
- **[04 — Design System & Tokens](docs/04-design-system.md)** — Color palettes, typography, components, and dark/light mode tokens.
- **[05 — Information Architecture](docs/05-information-architecture.md)** — Screen hierarchy and entity relationships.
- **[06 — Navigation Shell](docs/06-navigation.md)** — Bottom navigation, routing, and contextual access points.
- **[07 — Screen Inventory](docs/07-screen-inventory.md)** — Complete inventory of all app screens and dialogs.
- **[28 — User Flows](docs/28-user-flows.md)** — Step-by-step cross-feature end-to-end user journeys.

---

### 🚀 Feature Specifications
- **[08 — Auth & Onboarding](docs/08-auth-onboarding.md)** — Authentication, token refresh, and interest onboarding.
- **[09 — Home Feed](docs/09-home-feed.md)** — Feed consumption, pagination, and interaction patterns.
- **[10 — Shorts Feed](docs/10-shorts-feed.md)** — Vertical video player, prefetching, and gestures.
- **[11 — Discover & Search](docs/11-discover-search.md)** — Search UX, trending tags, and category exploration.
- **[12 — Profile, Follow & Block](docs/12-profile-follow-block.md)** — User profiles, social graphs, and blocking.
- **[13 — Communities & Membership](docs/13-communities-membership.md)** — Community lifecycle, roles, and administration.
- **[14 — Create Post & Media](docs/14-create-post-media.md)** — Post composer, image/video compression, and upload pipeline.
- **[15 — Comments & Engagement](docs/15-post-comments-engagement.md)** — Comment threads, likes, reactions, and shares.
- **[16 — Saved, Share & Report](docs/16-saved-share-report.md)** — Bookmarking, deep linking, and reporting flow.
- **[17 — Notifications](docs/17-notifications.md)** — Real-time notification center and badge management.
- **[18 — Moderation Management](docs/18-moderation.md)** — Owner and admin moderation tools.
- **[19 — Community Chat](docs/19-community-chat.md)** — WebSocket-based real-time community messaging.
- **[20 — Live Rooms](docs/20-live-rooms.md)** — Live stream room lifecycle, viewers, and host management.

---

### ⚙️ Technical Architecture & API Specifications
- **[21 — API Contract Map](docs/21-api-contract-map.md)** — Complete REST API route map for Flutter.
- **[22 — Contract Gaps & OpenAPI Verifications](docs/22-contract-gaps-openapi-checks.md)** — Consistency checks against backend endpoints.
- **[23 — UI State, Error & Loading Patterns](docs/23-ui-state-error-loading.md)** — Async state handling, errors, and retry mechanisms.
- **[24 — Real-time Client Architecture](docs/24-realtime-client-architecture.md)** — WebSocket and SSE lifecycle management.
- **[25 — Flutter Feature-First Architecture](docs/25-flutter-architecture.md)** — State management, layer separation, and DI.
- **[26 — Performance, Caching & Media](docs/26-performance-caching-media.md)** — Cache management, video optimization, and 60fps rendering.
- **[27 — Security & Accessibility](docs/27-security-accessibility.md)** — Secure storage, token handling, and a11y standards.
- **[32 — Backend Source Map](docs/32-backend-source-map.md)** — Mapping of backend specifications to frontend modules.

---

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK**: `^3.13.0` or later
- **Dart SDK**: `^3.1.0` or later
- **Backend API Server**: Running locally or deployed endpoint

### Installation & Run

1. **Clone the repository and navigate to client**:
   ```bash
   cd client
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   # Run on connected device or emulator
   flutter run

   # Or run targeting specific device
   flutter run -d emulator-5554
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

---

## 📐 Source of Truth Order

When implementation details or specifications conflict:
1. **Running backend OpenAPI specification** (`/api/v1/openapi.json`)
2. **Latest backend implementation**
3. **Backend API specifications** (`docs/05-api-specification.md`)
4. **Frontend UX & Architectural specifications** ([`docs/`](docs/README.md))

*Never guess an endpoint or schema: verify against OpenAPI specs before implementation.*
