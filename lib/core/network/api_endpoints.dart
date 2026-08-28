import 'package:flutter/foundation.dart';

/// API route endpoints matching the GenZ Media backend specification (`/api/v1`).
abstract class ApiEndpoints {
  // Base URL (Configurable via --dart-define=API_BASE_URL=... with automatic platform defaults)
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Auth & Session (`/auth`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Users & Social Graph (`/users`)
  // ─────────────────────────────────────────────────────────────────────────────
  static String userProfile(String username) => '/users/$username';
  static String followUser(String userId) => '/users/$userId/follow';
  static String blockUser(String userId) => '/users/$userId/block';
  static String userFollowers(String userId) => '/users/$userId/followers';
  static String userFollowing(String userId) => '/users/$userId/following';
  static String userRelationship(String userId) => '/users/$userId/relationship';
  static const String myBlockedUsers = '/users/me/blocked';

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Profiles & Interests (`/profiles`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String myProfile = '/profiles/me';
  static const String myAvatar = '/profiles/me/avatar';
  static const String myInterests = '/profiles/me/interests';

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Interests Catalog (`/interests`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String interests = '/interests';

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Communities (`/communities`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String communities = '/communities';
  static const String myJoinedCommunities = '/communities/me/joined';
  static String communityDetail(String communityId) => '/communities/$communityId';
  static String communityCover(String communityId) => '/communities/$communityId/cover';
  static String joinCommunity(String communityId) => '/communities/$communityId/join';
  static String leaveCommunity(String communityId) => '/communities/$communityId/leave';
  static String communityMembers(String communityId) => '/communities/$communityId/members';
  static String kickCommunityMember(String communityId, String userId) =>
      '/communities/$communityId/members/$userId';
  static String communityJoinRequests(String communityId) =>
      '/communities/$communityId/join-requests';
  static String approveJoinRequest(String communityId, String requestId) =>
      '/communities/$communityId/join-requests/$requestId/approve';
  static String rejectJoinRequest(String communityId, String requestId) =>
      '/communities/$communityId/join-requests/$requestId/reject';

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. Posts & Media (`/posts`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String posts = '/posts';
  static const String uploadMedia = '/posts/media';
  static String postDetail(String postId) => '/posts/$postId';
  static String likePost(String postId) => '/posts/$postId/like';
  static String savePost(String postId) => '/posts/$postId/save';
  static String sharePost(String postId) => '/posts/$postId/share';

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. Comments & Discussions (`/posts/{post_id}/comments` & `/comments`)
  // ─────────────────────────────────────────────────────────────────────────────
  static String postComments(String postId) => '/posts/$postId/comments';
  static String commentDetail(String commentId) => '/comments/$commentId';
  static String commentReplies(String commentId) => '/comments/$commentId/replies';

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. Saved Posts (`/saved-posts`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String savedPosts = '/saved-posts';

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. Feeds & Recommendations (`/feeds` & `/recommendations`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String homeFeed = '/feeds/home';
  static const String discoverFeed = '/feeds/discover';
  static const String shortsFeed = '/feeds/shorts';
  static const String recommendCommunities = '/recommendations/communities';
  static const String recommendUsers = '/recommendations/users';

  // ─────────────────────────────────────────────────────────────────────────────
  // 10. Search Engine (`/search`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String search = '/search';
  static const String searchUsers = '/search/users';
  static const String searchCommunities = '/search/communities';
  static const String searchPosts = '/search/posts';
  static const String searchInterests = '/search/interests';

  // ─────────────────────────────────────────────────────────────────────────────
  // 11. Notifications (`/notifications`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String unreadNotificationCount = '/notifications/unread-count';
  static String markNotificationRead(String notificationId) =>
      '/notifications/$notificationId/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String notificationId) =>
      '/notifications/$notificationId';
  static const String notificationStreamSse = '/notifications/stream';
  static const String notificationTyping = '/notifications/typing';
  static const String notificationWs = '/notifications/ws';

  // ─────────────────────────────────────────────────────────────────────────────
  // 12. Reports & Moderation (`/reports`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String reports = '/reports';
  static String reportDetail(String reportId) => '/reports/$reportId';
  static String reportStatus(String reportId) => '/reports/$reportId/status';

  // ─────────────────────────────────────────────────────────────────────────────
  // 13. Community Chat (`/chats`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String chatWsTicket = '/chats/ws-ticket';
  static String chatHistory(String communityId) => '/chats/$communityId/messages';
  static String chatPresence(String communityId) => '/chats/$communityId/presence';
  static String chatWs(String communityId, String ticket) =>
      '/chats/ws/$communityId?ticket=$ticket';

  // ─────────────────────────────────────────────────────────────────────────────
  // 14. Live Rooms (`/live-rooms`)
  // ─────────────────────────────────────────────────────────────────────────────
  static const String liveRooms = '/live-rooms';
  static String liveRoomDetail(String roomId) => '/live-rooms/$roomId';
  static String startLiveSession(String roomId) => '/live-rooms/$roomId/start';
  static String endLiveSession(String roomId) => '/live-rooms/$roomId/end';
  static String liveViewerToken(String roomId) => '/live-rooms/$roomId/token';
  static String liveMetrics(String roomId) => '/live-rooms/$roomId/metrics';
}
