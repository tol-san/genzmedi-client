import 'package:equatable/equatable.dart';
import 'package:client/features/reports/data/models/report_models.dart';

class ReportsState extends Equatable {
  final List<ReportModel> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? statusFilter;
  final ReportTargetType? typeFilter;
  final int total;

  const ReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.statusFilter,
    this.typeFilter,
    this.total = 0,
  });

  bool get hasMore => reports.length < total;

  ReportsState copyWith({
    List<ReportModel>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    ReportTargetType? typeFilter,
    bool clearTypeFilter = false,
    int? total,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [
    reports,
    isLoading,
    isLoadingMore,
    errorMessage,
    statusFilter,
    typeFilter,
    total,
  ];
}
