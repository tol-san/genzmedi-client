import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/errors/app_exception.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/features/reports/data/models/report_models.dart';
import 'package:client/features/reports/data/repositories/report_repository.dart';

class ReportSheet extends ConsumerStatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String targetLabel;
  final String? communityId;
  final Future<bool> Function(ReportReason reason, String? description)?
  onSubmit;

  const ReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    this.communityId,
    this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    required String targetLabel,
    String? communityId,
    Future<bool> Function(ReportReason reason, String? description)? onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
        communityId: communityId,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _descriptionController = TextEditingController();
  ReportReason? _selectedReason;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final description = _descriptionController.text.trim();
    try {
      final customSubmit = widget.onSubmit;
      if (customSubmit != null) {
        final success = await customSubmit(
          reason,
          description.isEmpty ? null : description,
        );
        if (!success) {
          throw const AppExceptionForReport('Could not submit this report.');
        }
      } else {
        await ref
            .read(reportRepositoryProvider)
            .submitReport(
              targetType: widget.targetType,
              targetId: widget.targetId,
              reason: reason,
              description: description.isEmpty ? null : description,
              communityId: widget.communityId,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_sentenceCase(widget.targetType.label)} report submitted for review.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error is AppException
            ? error.message
            : error is AppExceptionForReport
            ? error.message
            : 'We could not submit your report. Please try again.';
      });
    }
  }

  String _sentenceCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space20,
          AppSpacing.space12,
          AppSpacing.space20,
          AppSpacing.space20 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report ${widget.targetLabel}',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Your report is private and will be reviewed by the moderation team.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space20),
            Text(
              'What is the problem?',
              style: AppTypography.label.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.space8),
            ...ReportReason.values.map((reason) {
              final selected = reason == _selectedReason;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _selectedReason = reason),
                  borderRadius: AppSpacing.roundedMd,
                  child: AnimatedContainer(
                    duration: AppSpacing.durationFast,
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryCrimson.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryCrimson
                            : (isDark
                                  ? AppColors.navyBorder
                                  : AppColors.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected
                              ? AppColors.primaryCrimson
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reason.label, style: AppTypography.label),
                              const SizedBox(height: 2),
                              Text(
                                reason.helper,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.space8),
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Add context that will help the moderator understand what happened.',
                alignLabelWithHint: true,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space16),
            AppButton.destructive(
              text: 'Submit Report',
              icon: Icons.flag_outlined,
              isLoading: _isSubmitting,
              onPressed: _selectedReason == null ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.space8),
            Center(
              child: Text(
                'False reports may violate our community guidelines.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppExceptionForReport implements Exception {
  final String message;
  const AppExceptionForReport(this.message);
}
