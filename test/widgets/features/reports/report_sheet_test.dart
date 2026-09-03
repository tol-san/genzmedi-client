import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';
import 'package:client/features/reports/presentation/widgets/report_sheet.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late MockReportRepository repository;

  setUpAll(() {
    registerFallbackValue(ReportTargetType.post);
    registerFallbackValue(ReportReason.spam);
  });

  setUp(() {
    repository = MockReportRepository();
    when(
      () => repository.submitReport(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
        communityId: any(named: 'communityId'),
      ),
    ).thenAnswer(
      (_) async => const ReportModel(
        id: 'report-1',
        reporterId: 'user-1',
        targetType: ReportTargetType.post,
        targetId: 'post-1',
        reason: 'spam',
        status: 'PENDING',
      ),
    );
  });

  testWidgets('requires a reason and submits optional details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reportRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(
            body: ReportSheet(
              targetType: ReportTargetType.post,
              targetId: 'post-1',
              targetLabel: 'post',
              communityId: 'community-1',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Report post'), findsOneWidget);
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
    verifyNever(
      () => repository.submitReport(
        targetType: any(named: 'targetType'),
        targetId: any(named: 'targetId'),
        reason: any(named: 'reason'),
        description: any(named: 'description'),
        communityId: any(named: 'communityId'),
      ),
    );

    await tester.ensureVisible(find.text('Spam'));
    await tester.tap(find.text('Spam'));
    await tester.enterText(find.byType(TextField), 'Repeated scam links');
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    verify(
      () => repository.submitReport(
        targetType: ReportTargetType.post,
        targetId: 'post-1',
        reason: ReportReason.spam,
        description: 'Repeated scam links',
        communityId: 'community-1',
      ),
    ).called(1);
  });
}
