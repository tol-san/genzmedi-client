# 04 — Design System

## Style direction

- clean, minimal, low-saturation light aesthetic (default);
- pure white / neutral surfaces (`#FFFFFF`);
- content-dominant and low chrome;
- clear typography hierarchy;
- selective and restrained use of Primary Crimson (`#F20518`) brand accent;
- modern mobile social feel (Threads/Instagram simplicity).

## Palette (Inspired by Official Brand Assets)

| Token | Hex | Usage |
|---|---:|---|
| Primary Crimson | `#F20518` | Primary brand accent, primary CTA, active tab, likes, live badge |
| Primary Pressed | `#D00415` | Pressed state for primary actions |
| Primary Soft | `#FFE5E7` | Light tint background for badges/tags |
| Midnight Navy (Night 950) | `#061A33` | Brand core, dark mode canvas, Shorts background, header branding |
| Dark Surface (Night 900) | `#0B2545` | Elevated dark cards, sheets, and dialogs |
| Navy Border (Dark) | `#133663` | Subtle dark mode boundaries |
| Canvas (Light) | `#F7F9FC` | Light mode app background |
| Surface (Light) | `#FFFFFF` | Primary light card and sheet surface |
| Text Primary (Light) | `#061A33` | Primary high-contrast text in light mode |
| Text Inverse (Dark) | `#F8FAFC` | Light text on dark/video surfaces |
| Text Muted | `#64748B` | Metadata, timestamps, placeholders |
| Border (Light) | `#E2E8F0` | Subtle boundaries in light mode |
| Signal Mint | `#38E8C6` | Online status, secondary accent |
| Success | `#15803D` | Positive feedback |
| Warning | `#F59E0B` | Cautionary states |
| Error | `#DC2626` | Destructive actions, error alerts |

Do not encode meaning with color only.

## Typography

Recommended UI family: **Inter** or equivalent clean system sans.

| Token | Size / line-height | Weight |
|---|---:|---:|
| Display | 32 / 38 | 700 |
| Heading Large | 28 / 34 | 700 |
| Heading | 24 / 30 | 700 |
| Title | 20 / 26 | 600 |
| Body Large | 17 / 25 | 400–500 |
| Body | 16 / 24 | 400 |
| Body Small | 14 / 20 | 400–500 |
| Label | 14 / 18 | 600 |
| Caption | 12 / 16 | 500 |

## Spacing

```text
4, 8, 12, 16, 24, 32, 48
```

Use 8dp layout rhythm with 4dp fine adjustment.

## Radius

```text
12 → compact controls
16 → cards/media
24–28 → large sheets
```

## Touch targets

Aim around **48dp × 48dp** for primary interactive icons.

## Motion

```text
~120ms micro feedback
~180ms component transition
~240–300ms sheet/navigation transition
```

Subtle spring/haptic may be used for:
- Like
- Follow
- Join
- successful send

Respect reduced-motion preference.

## Component groups

### Foundation
- colors
- type
- spacing
- icons
- safe area
- radius
- motion
- light/dark theme

### Core
- buttons
- icon buttons
- text fields
- password field
- top app bar
- bottom nav
- tabs
- chips
- snackbar
- dialog
- bottom sheet

### Social
- avatar
- author row
- post card
- user card
- community card
- Follow button
- Join state button
- counters
- comments
- media carousel

### Search
- search field
- result tabs/filter chips
- recent query row if locally stored
- empty/no-result state

### Notification
- bell + badge
- notification row
- read/unread marker

### Chat
- message bubble
- composer
- typing indicator
- presence count
- connection banner
- retry/pending/sent state

### Live
- room card
- live badge
- viewer count
- host controls
- join/leave state

### System
- skeleton
- empty state
- error
- offline banner
- pagination loader
