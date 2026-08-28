import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/screens/forgot_password_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ForgotPasswordRequest(email: ''));
  });

  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ForgotPasswordScreen(),
      ),
    );
  }

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('Renders all elements correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Verification Code'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Shows error if submitted with empty email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsAtLeastNWidgets(1));
    });

    testWidgets('Shows error if submitted with invalid email format', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'notanemail');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsAtLeastNWidgets(1));
    });

    testWidgets('Shows API error message when request fails', (tester) async {
      when(() => mockRepository.forgotPassword(any()))
          .thenThrow(const ApiException(message: 'Rate limit exceeded. Please try later.', statusCode: 429));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'alex@example.com');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(find.text('Rate limit exceeded. Please try later.'), findsAtLeastNWidgets(1));
    });
  });
}
