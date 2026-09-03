import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:client/app/router/route_names.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/empty_state_widget.dart';
import 'package:client/core/widgets/error_state_widget.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/presentation/notifiers/reports_notifier.dart';

class ReportsScreen extends ConsumerWidget {
  final String? communityId;
  final String? communityName;

  const ReportsScreen({super.key, this.communityId, this.communityName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsNotifierProvider(communityId));
    final notifier = ref.read(reportsNotifierProvider(communityId).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          communityName == null
              ? 'Moderation center'
              : '$communityName reports',
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCrimson.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.primaryCrimson,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.total} reports',
                            style: AppTypography.title,
                          ),
                          Text(
                            communityId == null
                                ? 'Review safety reports across the platform.'
                                : 'Review reports scoped to this community.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: state.statusFilter ?? 'All statuses',
                        icon: Icons.tune_rounded,
                        onTap: () => _chooseStatus(context, notifier.setStatus),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: state.typeFilter?.label ?? 'All targets',
                        icon: Icons.category_outlined,
                        onTap: () => _chooseType(context, notifier.setType),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.reports.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryCrimson,
                    ),
                  );
                }
                if (state.errorMessage != null && state.reports.isEmpty) {
                  return ErrorStateWidget(
                    title: 'Reports unavailable',
                    message: state.errorMessage!,
                    onRetry: notifier.loadReports,
                  );
                }
                if (state.reports.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.verified_user_outlined,
                    title: 'No reports found',
                    subtitle: 'There are no reports matching these filters.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primaryCrimson,
                  onRefresh: notifier.loadReports,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 240) {
                        notifier.loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      itemCount:
                          state.reports.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.space12),
                      itemBuilder: (context, index) {
                        if (index == state.reports.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryCrimson,
                              ),
                            ),
                          );
                        }
                        return _ReportCard(
                          report: state.reports[index],
                          onTap: () async {
                            final updated = await context
                                .pushNamed<ReportModel>(
                                  RouteNames.reportDetail,
                                  pathParameters: {
                                    'reportId': state.reports[index].id,
                                  },
                            );
                            if (updated != null) {
                              notifier.replaceReport(updated);
                            } else {
                              await notifier.loadReports();
                            }
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseStatus(
    BuildContext context,
    Future<void> Function(String?) onSelected,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Filter by status')),
            for (final status in [
              'ALL',
              'PENDING',
              'REVIEWING',
              'RESOLVED',
              'REJECTED',
            ])
              ListTile(
                leading: Icon(
                  status == 'ALL' ? Icons.all_inclusive : Icons.circle_outlined,
                ),
                title: Text(status == 'ALL' ? 'All statuses' : status),
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (result != null) await onSelected(result == 'ALL' ? null : result);
  }

  Future<void> _chooseType(
    BuildContext context,
    Future<void> Function(ReportTargetType?) onSelected,
  ) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Filter by target')),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All targets'),
              onTap: () => Navigator.pop(context, -1),
            ),
            for (var i = 0; i < ReportTargetType.values.length; i++)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(ReportTargetType.values[i].label),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (result != null) {
      await onSelected(result < 0 ? null : ReportTargetType.values[result]);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    onPressed: onTap,
  );
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  Color get _statusColor => switch (report.status) {
    'PENDING' => AppColors.warning,
    'REVIEWING' => AppColors.primaryElectricBlue,
    'RESOLVED' => AppColors.success,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: AppSpacing.roundedMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${report.targetType.label.toUpperCase()} · ${report.reason.replaceAll('_', ' ')}',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      report.status,
                      style: AppTypography.caption.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description?.trim().isNotEmpty == true
                    ? report.description!
                    : 'No additional details provided.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '@${report.reporterUsername ?? 'unknown'}',
                    style: AppTypography.caption,
                  ),
                  const Spacer(),
                  Text(
                    report.createdAt == null
                        ? ''
                        : DateFormat('MMM d, y')
                              .format(report.createdAt!.toLocal()),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
