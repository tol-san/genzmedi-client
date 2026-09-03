# 18 — Report Moderation

## Workflow

```text
PENDING
   ↓
REVIEWING
   ↓
RESOLVED / REJECTED
```

## Resolution actions

- `none`
- `user_suspended`
- `dismissed`

Only `none`, `user_suspended`, and `dismissed` are accepted. Report scope is derived from the target; clients must not invent a `community_id`. Duplicate open reports and reopening terminal reports are rejected, and suspension is platform-admin only.

## Roles

### System Admin
- platform-wide reports;
- suspend/deactivate users;
- close communities.

### Community Owner
- community-scoped reports for owned communities.

## APIs

- `GET /api/v1/reports`
- `GET /api/v1/reports/{report_id}`
- `PATCH /api/v1/reports/{report_id}/status`

## Reports list

Filters documented:
- status;
- type;
- community.

Use backend authorization to determine whether user can access.

## Flutter implementation

- `/moderation/reports` opens the paginated moderation center.
- System administrators enter from the shield action on My Profile.
- Community owners enter through **Manage reports** on a community they own;
  the route supplies that community as the required scope.
- Status and target chips reload the list using backend filters.
- Pull-to-refresh and near-end pagination are supported.
- Empty, loading, permission-error, and retry states are explicit.
- Selecting a card opens `/moderation/reports/:reportId`.

## Report detail

Show:
- report target;
- reporter data if backend returns/permits;
- reason;
- state;
- context;
- permitted resolution actions.

Do not invent fields.

## Status action

```text
Open report
  ↓
Review
  ↓
Choose valid next status/action
  ↓
Submit
  ↓
Refresh
```

Do not allow invalid transitions in UI, but backend remains authoritative.

The detail screen offers **Start review** for pending reports and a completion
sheet for resolving or rejecting. Resolution notes accept up to 1,000
characters. `user_suspended` is only shown to accounts whose authenticated
user payload has `is_superuser: true`; community owners can use `none` or
`dismissed`. Closed reports render read-only and cannot be reopened.
