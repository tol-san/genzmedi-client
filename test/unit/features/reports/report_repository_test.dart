import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> reportJson({String status = 'PENDING'}) => {
  'id': 'report-1',
  'reporter_id': 'user-1',
  'reporter_username': 'reporter',
  'report_type': 'post',
  'target_id': 'post-1',
  'community_id': 'community-1',
  'reason': 'spam',
  'description': 'Repeated scam links',
  'status': status,
  'created_at': '2026-09-03T10:00:00Z',
  'updated_at': '2026-09-03T10:00:00Z',
};

void main() {
  late MockDio dio;
  late ReportRepository repository;

  setUp(() {
    dio = MockDio();
    repository = ReportRepository(dio: dio);
  });

  test('submits a typed report with community scope and description', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        ApiEndpoints.reports,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (invocation) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.reports),
        statusCode: 201,
        data: reportJson(),
      ),
    );

    final result = await repository.submitReport(
      targetType: ReportTargetType.post,
      targetId: 'post-1',
      reason: ReportReason.spam,
      description: 'Repeated scam links',
      communityId: 'community-1',
    );

    expect(result.status, 'PENDING');
    expect(result.targetType, ReportTargetType.post);
    final captured =
        verify(
              () => dio.post<Map<String, dynamic>>(
                ApiEndpoints.reports,
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['report_type'], 'post');
    expect(captured['community_id'], 'community-1');
    expect(captured['description'], 'Repeated scam links');
  });

  test('loads filtered paginated moderation reports', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        ApiEndpoints.reports,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.reports),
        data: {
          'items': [reportJson()],
          'total': 1,
          'limit': 20,
          'offset': 0,
        },
      ),
    );

    final page = await repository.getReports(
      status: 'PENDING',
      targetType: ReportTargetType.post,
      communityId: 'community-1',
    );

    expect(page.total, 1);
    expect(page.items.single.reason, 'spam');
    final query =
        verify(
              () => dio.get<Map<String, dynamic>>(
                ApiEndpoints.reports,
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(query, containsPair('status', 'PENDING'));
    expect(query, containsPair('report_type', 'post'));
  });

  test('updates a report resolution', () async {
    when(
      () => dio.patch<Map<String, dynamic>>(
        ApiEndpoints.reportStatus('report-1'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiEndpoints.reportStatus('report-1'),
        ),
        data: reportJson(status: 'RESOLVED'),
      ),
    );

    final result = await repository.updateStatus(
      reportId: 'report-1',
      status: 'RESOLVED',
      resolutionAction: 'none',
      resolutionNotes: 'Reviewed evidence',
    );

    expect(result.isClosed, isTrue);
  });
}
