# 16 — Saved Posts, Share & Report

# Save

Feature requirement:
- Save / Unsave
- private saved post list

Documented mutation endpoints:
- `POST /api/v1/posts/{post_id}/save`
- `DELETE /api/v1/posts/{post_id}/save`

The endpoint directory does not explicitly document the list endpoint for Saved Posts.

See `22-contract-gaps-openapi-checks.md`.

## Saved UX

Profile → Saved Posts

Other users must not see who saved a post.

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
