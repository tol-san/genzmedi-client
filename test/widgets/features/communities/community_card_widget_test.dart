import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/features/communities/data/models/community_models.dart';
import 'package:client/features/communities/presentation/widgets/community_card_widget.dart';

void main() {
  const testCommunity = CommunityModel(
    id: 'comm-widget-1',
    ownerId: 'owner-1',
    name: 'Design Systems Daily',
    slug: 'design-systems-daily',
    description: 'A community sharing UI/UX tokens and widgets.',
    isPrivate: false,
    memberCount: 120,
    postCount: 45,
  );

  group('CommunityCardWidget Tests', () {
    testWidgets('renders name, member count, post count, and public badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommunityCardWidget(community: testCommunity),
          ),
        ),
      );

      expect(find.text('Design Systems Daily'), findsOneWidget);
      expect(find.text('120 members · 45 posts'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(
          find.text('A community sharing UI/UX tokens and widgets.'), findsOneWidget);
    });

    testWidgets('fires onTap callback on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityCardWidget(
              community: testCommunity,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Design Systems Daily'));
      expect(tapped, isTrue);
    });
  });
}
