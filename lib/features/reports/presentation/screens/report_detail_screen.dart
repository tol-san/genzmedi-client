import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/auth/auth_state.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportModel? _report;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final report = await ref
          .read(reportRepositoryProvider)
          .getReport(widget.reportId);
      if (mounted) setState(() => _report = report);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = _message(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markReviewing() async {
    await _update(status: 'REVIEWING');
  }

  Future<void> _showResolutionSheet() async {
    final report = _report;
    if (report == null) return;
    final authState = ref.read(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isSuperuser;
    final result = await showModalBottomSheet<_Resolution>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResolutionSheet(allowUserSuspension: isAdmin),
    );
    if (result == null) return;
    await _update(
      status: result.status,
      action: result.action,
      notes: result.notes,
    );
  }

  Future<void> _update({
    required String status,
    String action = 'none',
    String? notes,
  }) async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });
    try {
      final updated = await ref
          .read(reportRepositoryProvider)
          .updateStatus(
            reportId: widget.reportId,
            status: status,
            resolutionAction: action,
            resolutionNotes: notes,
          );
      if (!mounted) return;
      setState(() => _report = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report updated to ${updated.status.toLowerCase()}.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _errorMessage = _message(error));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _message(Object error) =>
      error is AppException ? error.message : 'Could not update this report.';

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_report),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryCrimson,
                ),
              )
            : report == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ?? 'Report not found',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppButton.secondary(text: 'Try again', onPressed: _load),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: [
                  _StatusHero(report: report),
                  const SizedBox(height: AppSpacing.space16),
                  _InfoCard(
                    title: 'Report summary',
                    children: [
                      _DetailRow(
                        label: 'Target',
                        value: report.targetType.label,
                      ),
                      _DetailRow(label: 'Target ID', value: report.targetId),
                      _DetailRow(
                        label: 'Reason',
                        value: report.reason.replaceAll('_', ' '),
                      ),
                      _DetailRow(
                        label: 'Submitted',
                        value: report.createdAt == null
                            ? 'Unknown'
                            : DateFormat('MMM d, y · h:mm a')
                                  .format(report.createdAt!.toLocal()),
                      ),
                      _DetailRow(
                        label: 'Reporter',
                        value: '@${report.reporterUsername ?? 'unknown'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _InfoCard(
                    title: 'Reporter context',
                    children: [
                      Text(
                        report.description?.trim().isNotEmpty == true
                            ? report.description!
                            : 'No additional details were provided.',
                        style: AppTypography.body.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                  if (report.resolutionAction != null ||
                      report.resolutionNotes != null) ...[
                    const SizedBox(height: AppSpacing.space12),
                    _InfoCard(
                      title: 'Resolution',
                      children: [
                        _DetailRow(
                          label: 'Action',
                          value: report.resolutionAction ?? 'none',
                        ),
                        if (report.resolutionNotes != null)
                          _DetailRow(
                            label: 'Notes',
                            value: report.resolutionNotes!,
                          ),
                      ],
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  if (!report.isClosed) ...[
                    const SizedBox(height: AppSpacing.space20),
                    if (report.status == 'PENDING')
                      AppButton(
                        text: 'Start review',
                        icon: Icons.manage_search_rounded,
                        isLoading: _isUpdating,
                        onPressed: _markReviewing,
                      ),
                    const SizedBox(height: AppSpacing.space8),
                    AppButton.secondary(
                      text: 'Resolve report',
                      icon: Icons.gavel_rounded,
                      onPressed: _isUpdating ? null : _showResolutionSheet,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space32),
                ],
              ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  final ReportModel report;
  const _StatusHero({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = switch (report.status) {
      'PENDING' => AppColors.warning,
      'REVIEWING' => AppColors.primaryElectricBlue,
      'RESOLVED' => AppColors.success,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            report.isClosed ? Icons.task_alt_rounded : Icons.shield_outlined,
            color: color,
            size: 34,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.status,
                style: AppTypography.title.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                report.isClosed
                    ? 'This report is closed'
                    : 'Moderator action is available',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.navyBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Resolution {
  final String status;
  final String action;
  final String? notes;
  const _Resolution(this.status, this.action, this.notes);
}

class _ResolutionSheet extends StatefulWidget {
  final bool allowUserSuspension;
  const _ResolutionSheet({required this.allowUserSuspension});
  @override
  State<_ResolutionSheet> createState() => _ResolutionSheetState();
}

class _ResolutionSheetState extends State<_ResolutionSheet> {
  final _notes = TextEditingController();
  String _status = 'RESOLVED';
  String _action = 'none';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete review',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Closed reports cannot be reopened.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'RESOLVED',
                label: Text('Resolve'),
                icon: Icon(Icons.check_circle_outline),
              ),
              ButtonSegment(
                value: 'REJECTED',
                label: Text('Reject'),
                icon: Icon(Icons.cancel_outlined),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (selection) {
              setState(() {
                _status = selection.first;
                if (_status == 'REJECTED') _action = 'dismissed';
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _action,
            decoration: const InputDecoration(labelText: 'Resolution action'),
            items: [
              const DropdownMenuItem(
                value: 'none',
                child: Text('No account action'),
              ),
              if (widget.allowUserSuspension)
                const DropdownMenuItem(
                  value: 'user_suspended',
                  child: Text('Suspend responsible user'),
                ),
              const DropdownMenuItem(
                value: 'dismissed',
                child: Text('Dismiss report'),
              ),
            ],
            onChanged: (value) => setState(() => _action = value ?? 'none'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLength: 1000,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Moderator notes (optional)',
              hintText: 'Record the evidence reviewed and decision made.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Confirm decision',
            icon: Icons.gavel_rounded,
            onPressed: () => Navigator.pop(
              context,
              _Resolution(
                _status,
                _action,
                _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
