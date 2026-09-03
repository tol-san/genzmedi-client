# 06 — Navigation

## Bottom navigation

```text
Home | Shorts | Create | Discover | Profile
```

## Home
Default post feed.

## Shorts
Dedicated full-height vertical feed.

## Create
Action destination, not feed content.

## Discover
Discovery modules + global search.

## Profile
Identity and account.

## Top app bar

Recommended:
- screen identity/logo where appropriate;
- notification bell with unread badge on major social screens.

Do not duplicate the notification bell on immersive Shorts if it creates excessive overlay.

## Contextual routes

### Community
```text
Discover/Home/Search
      ↓
Community Detail
  ├── Chat
  └── Live Room
```

### Search
```text
Discover
  ↓
Search
  ↓
Result
  ├── User Profile
  ├── Community
  ├── Post Detail
  └── Interest-filtered discovery
```

### Notification deep link
A notification may navigate to the target entity only if target data/route is provided by the backend contract.

The Home bell opens `/notifications`. Notification rows route to public
profiles, post details, comment threads, or communities from `entity_type` and
`entity_id`. Comment IDs are resolved through the comment-detail endpoint to
obtain the owning post before navigation.

## Back behavior

- restore previous tab/screen context;
- preserve scroll position where practical;
- confirm before discarding non-empty drafts;
- logout must clear authenticated navigation stack.

## Full-screen exceptions

Bottom nav can hide on:
- auth;
- full-screen composer;
- media preview;
- chat if needed for keyboard space;
- active Live Room;
- some Post Detail flows.

Shorts can visually blend navigation into dark media.
