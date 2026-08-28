import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/app_text_field.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTextField Widget Tests', () {
    testWidgets('renders label, hint text, and accepts input', (tester) async {
      final controller = TextEditingController();
      String changedText = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Username',
              hintText: 'Enter your username',
              onChanged: (val) => changedText = val,
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Enter your username'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'johndoe');
      expect(changedText, 'johndoe');
      expect(controller.text, 'johndoe');
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Email',
              errorText: 'Invalid email address format',
            ),
          ),
        ),
      );

      expect(find.text('Invalid email address format'), findsOneWidget);
    });

    testWidgets('toggles obscureText when password eye icon is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Password',
              isPassword: true,
            ),
          ),
        ),
      );

      // Initially obscureText is true (visibility_off icon is shown)
      final eyeButton = find.byType(IconButton);
      expect(eyeButton, findsOneWidget);

      final textFieldBefore = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldBefore.obscureText, isTrue);

      await tester.tap(eyeButton);
      await tester.pump();

      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.obscureText, isFalse);
    });
  });
}
