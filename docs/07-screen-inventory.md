# 07 — Screen / View Inventory

Not every item must be a separate Flutter route. Some are sheets, tabs, dialogs, or stateful panels.

## Auth & onboarding
1. Splash / Session Gate
2. Login
3. Register
4. Email Verification state
5. Forgot Password
6. Reset Password
7. Change Password — implemented
8. Interest Onboarding

## Main
9. Home Feed
10. Shorts Feed
11. Create Hub
12. Discover
13. My Profile

## Search
14. Unified Search
15. Search — Users
16. Search — Communities
17. Search — Posts
18. Search — Interests

## Users & Settings
19. Public Profile
20. Edit Profile
21. Followers
22. Following
23. Manage Interests
24. Saved Posts
25. Account Settings Hub — implemented (`/settings`)
26. Change Password — implemented (`/settings/change-password`)
27. Blocked Accounts Management — implemented (`/settings/blocked-users`)
28. Privacy Settings — implemented (`/settings/privacy`)
29. Notification Preferences — implemented (`/settings/notifications`)
30. Active Sessions & Devices — implemented (`/settings/sessions`)
31. Account Management (Deactivation/Deletion) — implemented (`/settings/account-management`)
32. Appearance Theme Selector — implemented (Modal Sheet)
33. Legal & Policy Sheets — implemented (Modal Sheet)


## Communities
25. Community Detail
26. Create Community
27. Edit Community
28. Members
29. Join Requests
30. Owner Management
31. Community Chat
32. Live Room Lobby / Detail
33. Active Live Room

## Content
34. Post Detail — implemented (`/posts/:postId`)
35. Text Composer — implemented (`/create/composer?type=text`)
36. Image Composer — implemented (`/create/composer?type=image`)
37. Short Video Composer — implemented (`/create/composer?type=video`)
38. Edit Post Screen — implemented (`/posts/:postId/edit`)
39. Upload / Publishing State — implemented
40. Comments & Inline Editor — implemented (Modal Sheet & Detail list with inline editing, 1000 char counter, and (edited) tag)
41. Reply Thread / Reply Expansion — implemented
42. Delete Confirmation Dialog — implemented (Dialog)
43. Report Sheet — implemented (Modal Sheet)

## Notifications
43. Notification Center — implemented
44. Notification Filter / unread state — implemented
45. Notification deletion confirmation — implemented

## Moderation
46. Reports List
47. Report Detail
48. Report Status/Resolution Action Sheet

## System states
49. Offline state/banner
50. Full-page error
51. Empty state
52. Permission denied state

## Note

The backend API does not document a standalone endpoint for every view above. Views may compose multiple existing endpoints or represent local UI states.
