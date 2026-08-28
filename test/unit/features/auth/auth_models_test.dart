import 'package:flutter_test/flutter_test.dart';
import 'package:client/core/auth/token_model.dart';
import 'package:client/core/auth/user_model.dart';
import 'package:client/features/auth/data/models/auth_models.dart';

void main() {
  group('Auth Models Unit Tests', () {
    test('LoginRequest serializes to JSON', () {
      const req = LoginRequest(username: 'alex', password: 'Password123!');
      expect(req.toJson(), {
        'username': 'alex',
        'password': 'Password123!',
      });
      expect(req, equals(const LoginRequest(username: 'alex', password: 'Password123!')));
    });

    test('RegisterRequest serializes to JSON', () {
      const req = RegisterRequest(
        username: 'alex',
        email: 'alex@example.com',
        password: 'Password123!',
      );
      expect(req.toJson(), {
        'username': 'alex',
        'email': 'alex@example.com',
        'password': 'Password123!',
      });
    });

    test('ForgotPasswordRequest serializes to JSON', () {
      const req = ForgotPasswordRequest(email: 'alex@example.com');
      expect(req.toJson(), {'email': 'alex@example.com'});
    });

    test('VerifyOtpRequest serializes to JSON', () {
      const req = VerifyOtpRequest(email: 'alex@example.com', otp: '123456');
      expect(req.toJson(), {
        'email': 'alex@example.com',
        'otp': '123456',
      });
      expect(req, equals(const VerifyOtpRequest(email: 'alex@example.com', otp: '123456')));
    });

    test('ResetPasswordRequest serializes to JSON with optional email', () {
      const reqWithEmail = ResetPasswordRequest(
        token: 'tok_123',
        newPassword: 'NewPassword123!',
        email: 'alex@example.com',
      );
      expect(reqWithEmail.toJson(), {
        'token': 'tok_123',
        'new_password': 'NewPassword123!',
        'email': 'alex@example.com',
      });

      const reqWithoutEmail = ResetPasswordRequest(
        token: 'tok_123',
        newPassword: 'NewPassword123!',
      );
      expect(reqWithoutEmail.toJson(), {
        'token': 'tok_123',
        'new_password': 'NewPassword123!',
      });
    });

    test('InterestModel serializes and deserializes from JSON', () {
      final json = {
        'id': 'int_1',
        'name': 'Gaming',
        'slug': 'gaming',
        'icon': '🎮',
      };
      final model = InterestModel.fromJson(json);
      expect(model.id, 'int_1');
      expect(model.name, 'Gaming');
      expect(model.slug, 'gaming');
      expect(model.icon, '🎮');
      expect(model.toJson(), json);
    });

    test('TokenModel serializes and deserializes correctly', () {
      final json = {
        'access_token': 'access_123',
        'refresh_token': 'refresh_123',
        'token_type': 'Bearer',
      };
      final token = TokenModel.fromJson(json);
      expect(token.accessToken, 'access_123');
      expect(token.refreshToken, 'refresh_123');
      expect(token.tokenType, 'Bearer');
      expect(token.toJson(), json);
    });

    test('UserModel serializes and deserializes correctly', () {
      final json = {
        'id': 'user_1',
        'email': 'user@example.com',
        'username': 'genzuser',
        'interests': ['gaming', 'music'],
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 'user_1');
      expect(user.email, 'user@example.com');
      expect(user.username, 'genzuser');
      expect(user.interests, ['gaming', 'music']);
    });
  });
}
