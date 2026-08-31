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
