import 'package:flutter/material.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_text_field.dart';

class ReportUserSheet extends StatefulWidget {
  final String username;
  final Future<bool> Function(String reason, String? description) onReport;

  const ReportUserSheet({
    super.key,
    required this.username,
    required this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    required String username,
    required Future<bool> Function(String reason, String? description) onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => ReportUserSheet(
        username: username,
        onReport: onReport,
      ),
    );
  }

  @override
  State<ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<ReportUserSheet> {
  final _descriptionController = TextEditingController();
  String _selectedReason = 'spam';
  bool _isSubmitting = false;

  static const List<Map<String, String>> _reasons = [
    {'value': 'spam', 'label': 'Spam or automated bots'},
    {'value': 'harassment', 'label': 'Harassment or cyberbullying'},
    {'value': 'inappropriate_content', 'label': 'Inappropriate or explicit content'},
    {'value': 'hate_speech', 'label': 'Hate speech or discrimination'},
    {'value': 'violence', 'label': 'Violence or dangerous acts'},
    {'value': 'copyright', 'label': 'Intellectual property / copyright'},
    {'value': 'other', 'label': 'Other reason'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final success = await widget.onReport(
      _selectedReason,
      _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report against @${widget.username} submitted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space20,
        right: AppSpacing.space20,
        top: AppSpacing.space16,
        bottom: AppSpacing.space20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Report @${widget.username}',
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Help us keep the community safe. Reports are reviewed by our moderation team.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Select Reason',
              style: AppTypography.label.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.space8),
            ..._reasons.map((r) {
              final isSelected = _selectedReason == r['value'];
              return InkWell(
                onTap: () => setState(() => _selectedReason = r['value']!),
                borderRadius: AppSpacing.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isSelected ? AppColors.primaryCrimson : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r['label']!,
                          style: AppTypography.body.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.space12),
            AppTextField(
              controller: _descriptionController,
              label: 'Additional Details (Optional)',
              hintText: 'Provide any context to assist moderators...',
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: AppSpacing.space20),
            AppButton.destructive(
              text: 'Submit Report',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
