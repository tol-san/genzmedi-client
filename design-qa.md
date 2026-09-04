# Discover Community UI — Design QA

- Source visual truth: user-provided conversation attachment (467 × 628 px); the attachment is not exposed as a local file path.
- Implementation screenshot: `test/widgets/features/search/goldens/discover_communities.png`
- Implementation viewport: 393 × 650 logical px at devicePixelRatio 1.
- State: light theme; five community fixtures; first featured page; no live network imagery in the widget-test renderer.
- Density normalization: implementation captured at 1×. Source cannot be locally opened or normalized.

## Full-view comparison evidence

The rendered Flutter baseline confirms the final composition: bordered search field, featured heading and partial-width carousel, compact blue page indicator, More communities heading, and a two-column rounded-card grid. The source attachment and implementation screenshot could not be placed into the required combined comparison input because the conversation attachment has no local resource path and Computer Use exposes no app or browser surface.

## Focused-region comparison evidence

Search, featured-card, indicator, and grid regions are all visible in the implementation baseline. Exact typography and source-image crop comparison is blocked: Flutter widget tests render text with the deterministic Ahem test font, and the fixtures intentionally do not perform live image requests.

## Findings

- [P1] Exact visual comparison is unavailable.
  - Location: full Discover screen.
  - Evidence: implementation baseline exists, but the source attachment cannot be opened locally or combined with it; no emulator/browser surface is available through Computer Use.
  - Impact: typography, live cover crops, and final pixel-level spacing cannot be signed off.
  - Fix: capture the hot-restarted app on the same device and compare it with a locally accessible copy of the reference.

- [P2] Golden capture does not exercise live community cover imagery.
  - Location: featured carousel and More communities grid.
  - Evidence: deterministic widget fixtures render the production fallback surface; production cards use `cover_image_url` through `CachedNetworkImage`.
  - Impact: live crop and contrast treatment remain unverified.
  - Fix: inspect the running app with seeded community cover URLs.

## Required fidelity surfaces

- Fonts and typography: hierarchy and sizes implemented; exact visual fidelity blocked by Ahem in the test renderer.
- Spacing and layout rhythm: 20 px page inset, 16–24 px section spacing, 132 px carousel, and two-column grid confirmed in the rendered baseline.
- Colors and visual tokens: pale canvas, white bordered search, navy image fallback, white overlays, and blue indicator confirmed.
- Image quality and asset fidelity: production uses real community cover URLs; live crops are not visible in the deterministic baseline.
- Copy and content: Search communities, Featured for you, More communities, Join/Joined, and member counts match the selected direction.

## Comparison history

- Iteration 1: replaced the previous list/feed composition with a featured carousel, page indicator, and cover-card grid; added joined-community merge so the design does not collapse to an empty creator feed.
- Iteration 2: removed the locally inferred interest-filter UI and its extra catalog request; normalized the visual baseline to 393 × 650.
- Post-fix evidence: `test/widgets/features/search/goldens/discover_communities.png`.

## Implementation checklist

- Hot restart the running Flutter app.
- Capture Discover at the same visual state as the reference.
- Compare source and runtime captures together.
- Adjust any remaining P1/P2 typography, crop, or spacing differences.

final result: blocked
