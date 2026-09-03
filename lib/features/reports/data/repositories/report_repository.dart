import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/error_mapper.dart';
import 'package:client/core/network/api_client.dart';
import 'package:client/core/network/api_endpoints.dart';
import 'package:client/features/reports/data/models/report_models.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(dio: ref.watch(dioClientProvider));
});

class ReportRepository {
  final Dio dio;

  ReportRepository({required this.dio});

  Future<ReportModel> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? description,
    String? communityId,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.reports,
        data: {
          'report_type': targetType.apiValue,
          'target_id': targetId,
          'reason': reason.apiValue,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'community_id': ?communityId,
        },
      );
      return ReportModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<PaginatedReports> getReports({
    String? status,
    ReportTargetType? targetType,
    String? communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.reports,
        queryParameters: {
          'status': ?status,
          if (targetType case final targetType?)
            'report_type': targetType.apiValue,
          'community_id': ?communityId,
          'limit': limit,
          'offset': offset,
        },
      );
      return PaginatedReports.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<ReportModel> getReport(String reportId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.reportDetail(reportId),
      );
      return ReportModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }

  Future<ReportModel> updateStatus({
    required String reportId,
    required String status,
    String resolutionAction = 'none',
    String? resolutionNotes,
  }) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        ApiEndpoints.reportStatus(reportId),
        data: {
          'status': status,
          'resolution_action': resolutionAction,
          if (resolutionNotes != null && resolutionNotes.trim().isNotEmpty)
            'resolution_notes': resolutionNotes.trim(),
        },
      );
      return ReportModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(error);
    }
  }
}
