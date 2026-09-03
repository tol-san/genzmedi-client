import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';
import 'package:client/features/reports/presentation/notifiers/reports_notifier.dart';

class MockReportRepository extends Mock implements ReportRepository {}

const report = ReportModel(
  id: 'report-1',
  reporterId: 'user-1',
  targetType: ReportTargetType.comment,
  targetId: 'comment-1',
  reason: 'harassment',
  status: 'PENDING',
);

void main() {
  late MockReportRepository repository;

  setUp(() {
    repository = MockReportRepository();
    when(
      () => repository.getReports(
        status: any(named: 'status'),
        targetType: any(named: 'targetType'),
        communityId: any(named: 'communityId'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedReports(
        items: [report],
        total: 1,
        limit: 20,
        offset: 0,
      ),
    );
  });

  test('loads community-scoped reports and applies status filter', () async {
    final notifier = ReportsNotifier(
      repository: repository,
      communityId: 'community-1',
    );
    await pumpEventQueue();
    expect(notifier.state.reports, [report]);

    await notifier.setStatus('REVIEWING');

    expect(notifier.state.statusFilter, 'REVIEWING');
    verify(
      () => repository.getReports(
        status: 'REVIEWING',
        targetType: null,
        communityId: 'community-1',
        limit: 20,
        offset: 0,
      ),
    ).called(1);
  });
}
