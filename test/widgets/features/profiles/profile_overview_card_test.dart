import 'package:client/core/widgets/app_button.dart';
import 'package:client/features/profiles/presentation/widgets/profile_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({required VoidCallback onShare}) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileOverviewCard(
          displayName: 'Alex Creator',
          bio: 'Digital content and UI builder',
          isVerified: true,
          postCount: '12',
          followersCount: '1.5K',
          followingCount: '320',
          interests: const ['gaming', 'music'],
          primaryAction: const AppButton.secondary(text: 'Edit Profile'),
          onShare: onShare,
        ),
      ),
    );
  }

  testWidgets('groups profile identity, stats, interests, and action', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(onShare: () {}));

    expect(find.text('Alex Creator'), findsOneWidget);
    expect(find.text('Digital content and UI builder'), findsOneWidget);
    expect(find.text('1.5K'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('#gaming'), findsOneWidget);
    expect(find.text('#music'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byTooltip('Verified creator'), findsOneWidget);
    expect(find.byTooltip('Copy profile link'), findsOneWidget);
  });

  testWidgets(
    'share control exposes a full touch target and invokes callback',
    (tester) async {
      var shareCount = 0;
      await tester.pumpWidget(buildSubject(onShare: () => shareCount++));

      final shareControl = find.byIcon(Icons.ios_share_rounded);
      expect(shareControl, findsOneWidget);

      final touchTarget = tester.getSize(
        find.ancestor(of: shareControl, matching: find.byType(Container)).first,
      );
      expect(touchTarget.width, greaterThanOrEqualTo(48));
      expect(touchTarget.height, greaterThanOrEqualTo(48));

      await tester.tap(shareControl);
      expect(shareCount, 1);
    },
  );
}
