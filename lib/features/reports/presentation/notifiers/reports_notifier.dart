import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';
import 'package:client/features/reports/presentation/notifiers/reports_state.dart';

final reportsNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReportsNotifier, ReportsState, String?>((ref, communityId) {
      return ReportsNotifier(
        repository: ref.watch(reportRepositoryProvider),
        communityId: communityId,
      );
    });

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportRepository repository;
  final String? communityId;
  static const _pageSize = 20;

  ReportsNotifier({required this.repository, this.communityId})
    : super(const ReportsState(isLoading: true)) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await repository.getReports(
        status: state.statusFilter,
        targetType: state.typeFilter,
        communityId: communityId,
        limit: _pageSize,
      );
      state = state.copyWith(
        reports: page.items,
        total: page.total,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await repository.getReports(
        status: state.statusFilter,
        targetType: state.typeFilter,
        communityId: communityId,
        limit: _pageSize,
        offset: state.reports.length,
      );
      state = state.copyWith(
        reports: [...state.reports, ...page.items],
        total: page.total,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setStatus(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadReports();
  }

  Future<void> setType(ReportTargetType? type) async {
    state = state.copyWith(typeFilter: type, clearTypeFilter: type == null);
    await loadReports();
  }

  void replaceReport(ReportModel report) {
    state = state.copyWith(
      reports: [
        for (final item in state.reports)
          if (item.id == report.id) report else item,
      ],
    );
  }

  String _message(Object error) => error is AppException
      ? error.message
      : 'Could not load moderation reports. Please try again.';
}
