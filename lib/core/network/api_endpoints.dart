/// API route endpoints matching the GenZ Media backend specification.
abstract class ApiEndpoints {
  // Base URL (Override with flutter config or environment)
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator default

  // Auth & Session
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // Users & Profiles
  static const String myProfile = '/profiles/me';
  static const String myInterests = '/profiles/me/interests';
  static const String userProfile = '/profiles'; // /profiles/{id}
  static const String followUser = '/follows';   // /follows/{user_id}
  static const String blockUser = '/blocks';     // /blocks/{user_id}

  // Interests
  static const String interests = '/interests';

  // Feeds
  static const String homeFeed = '/feeds/home';
  static const String followingFeed = '/feeds/following';
  static const String shortsFeed = '/feeds/shorts';
  static const String discoverFeed = '/feeds/discover';

  // Posts & Media
  static const String posts = '/posts';
  static const String uploadMedia = '/media/upload';

  // Comments & Engagement
  static const String comments = '/comments';
  static const String likes = '/likes';
  static const String saves = '/saves';
  static const String reports = '/reports';

  // Communities
  static const String communities = '/communities';

  // Notifications
  static const String notifications = '/notifications';

  // Search
  static const String search = '/search';
}
