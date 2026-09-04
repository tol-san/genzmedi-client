# 11 — Discover & Search

## Status

**Fully implemented.** All Discover and Search features are live end-to-end.

---

## Discover screen (`DiscoverScreen`)

### Entry point

- `lib/features/search/presentation/screens/discover_screen.dart`
- Shown as the **Discover** shell tab.

### What it shows

```text
AppBar: "Discover"

Search field → navigates to DiscoverSearchScreen

── Communities for you ──  (first, compact vertical rows)
   Interest match + member count; Join / Request / Joined action
   "See all" → communityList route

── People with your interests ──  (compact vertical rows)
   Shared interests + Follow / Following action

── Trending for you ──  (vertical PostCardWidget list)
   Engagement-ranked and interest-matched Discover feed
```

The order is intentional: GenZ Media is an interest-first community platform.
Discover should move users from a matched interest into a community, then into
its posts, chat, and live experiences. People and trending content support that
journey rather than replacing it with a creator-first feed. Decorative hero
content, hardcoded topic chips, colored section badges, and oversized carousels
are omitted to keep the interface focused.

### Backend calls

| Data             | Endpoint                          |
|------------------|-----------------------------------|
| Discover posts   | `GET /api/v1/feeds/discover`      |
| Recommended users| `GET /api/v1/recommendations/users` |
| Recommended communities | `GET /api/v1/recommendations/communities` |

### Interactions

- Pull-to-refresh replaces all sections.
- Scroll-to-bottom triggers `loadMorePosts`.
- Community rows open Community Detail; Join / Leave / Request uses optimistic update with revert on error.
- People rows open Public Profile; Follow / Unfollow uses optimistic update with revert on error.
- Like, save, share, comment from post cards.

---

## Search screen (`DiscoverSearchScreen`)

### Entry point

- `lib/features/search/presentation/screens/discover_search_screen.dart`
- Pushed on top of the Discover tab, route name `discoverSearch`.

### Features

```text
AppBar: animated search bar (focus glow ring, clear button)
         + category chip tab bar with live count badges

Body:
  query empty  → recent-searches list (SharedPreferences) or prompt
  loading      → skeleton list
  error        → EmptyStateWidget + Retry
  no results   → EmptyStateWidget + Clear
  has results  → grouped or paginated result list
```

### Categories

| Tab          | API call                            | Pagination |
|--------------|-------------------------------------|------------|
| All          | `GET /api/v1/search` (unified)      | No (top-6 per type) |
| People       | `GET /api/v1/search?type=users`     | Yes |
| Communities  | `GET /api/v1/search?type=communities` | Yes |
| Posts        | `GET /api/v1/search?type=posts`     | Yes |
| Interests    | `GET /api/v1/search?type=interests` | Yes |

### Behavior

- **Real-Time Search-As-You-Type**:
  - Low-latency debounce: **180 ms** after user pauses typing (fast and fluid).
  - Non-destructive updates: existing search results remain on screen while typing, with a slim crimson `LinearProgressIndicator` in the AppBar indicating background query execution (no jarring skeleton flashing).
  - Initial load skeleton: `_SearchSkeleton` is only shown on the very first search when no results have been loaded yet (`isInitialLoading`).
  - Stale query rejection: monotonic request ID tracking (`_searchRequestId`) ensures that out-of-order network responses from earlier keystrokes are automatically discarded.
  - In-memory query caching: recent query responses are cached in memory for **0ms instant retrieval** when the user backspaces or re-enters a recent term.
- **Query submit**: saves to recent-searches history (`SharedPreferences`, max 8) and dismisses keyboard.
- **Recent searches**: shown when query is empty; each entry can be tapped to re-search or removed; "Clear all" removes all.
- **Category switching**: resets scroll to top and reloads results with active count badges.
- **Pagination**: scroll-to-bottom on non-All categories appends next page.
- **Optimistic actions**:
  - Follow/Unfollow user from creator cards with error rollback.
  - Join/Request/Leave community from community cards with error rollback.
  - Like/Unlike post from post cards with instant like count update.
  - Save/Unsave post from post cards.
  - Share post from post cards with link copying.
  - Add/Remove interest from profile from interest tiles.

---

## Result widgets (`discover_result_cards.dart`)

| Widget                  | Shows                                      | Expected Actions |
|-------------------------|--------------------------------------------|------------------|
| `DiscoverCreatorCard`   | Avatar, display name + verified badge, `@handle`, follower count, bio, shared-interest pill, Follow button | Open public profile, follow/unfollow, view followers |
| `DiscoverCommunityCard` | Cover image banner, avatar, name, public/private badge, description, member + post count, matched-interest badge, Join button | Open community, join/request/leave community |
| `DiscoverPostResultCard`| Author avatar + name, post-type badge, community chip, visibility badge, relative creation date, title, content preview, media thumbnail, like + comment counts | Open post details, like, comment, save, share, open author profile, open community |
| `DiscoverInterestTile`  | Colored icon (slug-based), name, description or slug, Add/Added button, explore arrow | View related content, add/remove interest from user profile, discover related creators/communities |

---

## State management

| Provider                              | Type              | Scope |
|---------------------------------------|-------------------|-------|
| `discoverNotifierProvider`            | `StateNotifier`   | global (shell tab) |
| `discoverSearchNotifierProvider(q)` | `autoDispose.family` | per-search session |

---

## Recent-search history

Stored in `SharedPreferences` under key `discover_recent_searches` as a JSON-encoded list of strings (max 8 entries). Managed entirely in the `DiscoverSearchScreen` widget — no server persistence.

---

## Backend search features

- **Typo-tolerant Meilisearch**:
  - Direct full-text search with block-safety filtering for Users and Interests.
  - Two-stage candidate filtering for Communities and Posts: Meilisearch retrieves full-text candidate IDs, followed by PostgreSQL access-control re-verification (visibility, blocks, private community membership).
  - Search highlighting via Meilisearch `_formatted` (`<em>` wrapped tokens) surfaced in `PostSearchResult.highlight`.
- **Enriched search models**:
  - `PostSearchResult`: includes `author_avatar_url`, `thumbnail_url` (derived from first media item for instant previews in `DiscoverPostResultCard`), and `highlight`.
  - `UserSearchResult`: includes `is_following` boolean flag when caller is authenticated, allowing creator cards to render live follow states directly from search.
- **Client parsing**: `postFromSearchJson` injects synthetic media entries from `thumbnail_url` and author avatar URLs for `PostModel` and `PostAuthorModel`.
- **Fallbacks**: Graceful fallback to PostgreSQL `LIKE` queries if Meilisearch service is unreachable or indexing is pending.
- **Pagination**: `limit` + `offset`, max 100 per request.
- **Admin-only search index sync**: `POST /api/v1/search/sync` — synchronizes users, communities, posts, and interests.

---

## Tests

| File | Coverage |
|------|----------|
| `test/unit/features/search/discover_notifier_test.dart` | loadInitial, loadMorePosts, toggleFollow, toggleCommunity, toggleLike, toggleSave, refresh |
| `test/unit/features/search/discover_search_notifier_test.dart` | updateQuery, setCategory, loadMore, error handling, toggleFollow, toggleCommunity, toggleLike, toggleSave, toggleInterest, activeCount |
| `test/widgets/features/search/discover_screen_test.dart` | skeleton, search entry, community-first hierarchy, shared-interest people, trending posts, empty/error states, follow tap |
| `test/widgets/features/search/discover_search_screen_test.dart` | empty prompt, category chips, all-results grouping, user/community/post/interest cards, no-results, error, loading, category switch, recent searches, interactive card actions |
