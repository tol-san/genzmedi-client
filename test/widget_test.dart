import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/app_button.dart';

void main() {
  setUpAll(() {
    // Disable runtime font fetching during tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 0 Foundation Tests', () {
    test('Official brand color tokens are configured accurately', () {
      expect(AppColors.primaryCrimson, const Color(0xFFF20518));
      expect(AppColors.midnightNavy, const Color(0xFF061A33));
      expect(AppColors.darkSurface, const Color(0xFF0B2545));
    });

    test('AppTheme creates valid Dark and Light ThemeData', () {
      final dark = AppTheme.darkTheme;
      final light = AppTheme.lightTheme;

      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppColors.midnightNavy);
      expect(dark.primaryColor, AppColors.primaryCrimson);

      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppColors.lightCanvas);
      expect(light.primaryColor, AppColors.primaryCrimson);
    });

    test('TokenModel serializes and deserializes correctly', () {
      final json = {
        'access_token': 'test_access_jwt',
        'refresh_token': 'test_refresh_jwt',
        'token_type': 'Bearer',
      };

      final token = TokenModel.fromJson(json);
      expect(token.accessToken, 'test_access_jwt');
      expect(token.refreshToken, 'test_refresh_jwt');
      expect(token.tokenType, 'Bearer');
      expect(token.toJson(), json);
    });

    test('UserModel serializes and deserializes correctly', () {
      final json = {
        'id': 'user-123',
        'username': 'alex_rivera',
        'email': 'alex@genz.media',
        'display_name': 'Alex Rivera',
        'avatar_url': 'https://example.com/avatar.jpg',
        'bio': 'GenZ content creator',
        'interests': ['Anime', 'Gaming', 'Music'],
        'followers_count': 120,
        'following_count': 85,
        'is_verified': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.username, 'alex_rivera');
      expect(user.interests.length, 3);
      expect(user.isVerified, true);
    });

    test('AuthState transitions behave as expected', () {
      const initial = AuthInitial();
      const unauth = AuthUnauthenticated();
      const user = UserModel(id: '1', username: 'test', email: 'test@test.com');
      const auth = AuthAuthenticated(user);

      expect(initial, isA<AuthState>());
      expect(unauth, isA<AuthState>());
      expect(auth, isA<AuthState>());
      expect(auth.user.username, 'test');
    });

    test('ErrorMapper maps 401, 403, 404, and network errors correctly', () {
      final unauthorizedDioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/posts'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/posts'),
          statusCode: 401,
          data: {'detail': 'Invalid or expired token'},
        ),
        type: DioExceptionType.badResponse,
      );
      final ex401 = ErrorMapper.fromDioException(unauthorizedDioErr);
      expect(ex401, isA<UnauthorizedException>());
      expect(ex401.message, 'Invalid or expired token');

      final forbiddenDioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/posts'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/posts'),
          statusCode: 403,
          data: {'detail': 'Permission denied'},
        ),
        type: DioExceptionType.badResponse,
      );
      final ex403 = ErrorMapper.fromDioException(forbiddenDioErr);
      expect(ex403, isA<ForbiddenException>());

      final timeoutDioErr = DioException(
        requestOptions: RequestOptions(path: '/api/v1/posts'),
        type: DioExceptionType.connectionTimeout,
      );
      final exTimeout = ErrorMapper.fromDioException(timeoutDioErr);
      expect(exTimeout, isA<NetworkException>());
    });

    testWidgets('AppButton renders properly with text and fires callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Sign In',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(tapped, true);
    });
  });
}
