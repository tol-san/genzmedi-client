import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/core/auth/auth_notifier.dart';
import 'package:client/core/theme/app_colors.dart';
import 'package:client/core/theme/app_spacing.dart';
import 'package:client/core/theme/app_typography.dart';
import 'package:client/core/widgets/app_button.dart';
import 'package:client/core/widgets/app_logo.dart';
import 'package:client/features/auth/data/models/auth_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository.dart';

class InterestOnboardingScreen extends ConsumerStatefulWidget {
  const InterestOnboardingScreen({super.key});

  @override
  ConsumerState<InterestOnboardingScreen> createState() =>
      _InterestOnboardingScreenState();
}

class _InterestOnboardingScreenState
    extends ConsumerState<InterestOnboardingScreen> {
  final Set<String> _selectedInterests = {};
  List<InterestModel> _availableInterests = [];
  bool _isLoadingCatalog = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const int _minSelectedRequired = 3;

  // Curated fallback interests if backend catalog is empty or initial network cold start
  static const List<InterestModel> _defaultInterests = [
    InterestModel(id: '1', name: 'Technology', slug: 'technology', icon: '💻'),
    InterestModel(id: '2', name: 'Gaming', slug: 'gaming', icon: '🎮'),
    InterestModel(id: '3', name: 'Music', slug: 'music', icon: '🎵'),
    InterestModel(id: '4', name: 'Movies & Anime', slug: 'movies-anime', icon: '🎬'),
    InterestModel(id: '5', name: 'Sports & Fitness', slug: 'sports-fitness', icon: '💪'),
    InterestModel(id: '6', name: 'Art & Design', slug: 'art-design', icon: '🎨'),
    InterestModel(id: '7', name: 'Photography', slug: 'photography', icon: '📸'),
    InterestModel(id: '8', name: 'Travel & Adventure', slug: 'travel-adventure', icon: '✈️'),
    InterestModel(id: '9', name: 'Fashion & Lifestyle', slug: 'fashion-lifestyle', icon: '✨'),
    InterestModel(id: '10', name: 'Food & Cooking', slug: 'food-cooking', icon: '🍜'),
    InterestModel(id: '11', name: 'Programming & AI', slug: 'programming-ai', icon: '🤖'),
  ];

  @override
  void initState() {
    super.initState();
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final list = await repository.getInterests();
      if (mounted) {
        setState(() {
          _availableInterests = list.isNotEmpty ? list : _defaultInterests;
          _isLoadingCatalog = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableInterests = _defaultInterests;
          _isLoadingCatalog = false;
        });
      }
    }
  }

  void _toggleInterest(String slug) {
    setState(() {
      if (_selectedInterests.contains(slug)) {
        _selectedInterests.remove(slug);
      } else {
        _selectedInterests.add(slug);
      }
      _errorMessage = null;
    });
  }

  Future<void> _handleComplete() async {
    if (_selectedInterests.length < _minSelectedRequired) {
      setState(() {
        _errorMessage =
            'Please select at least $_minSelectedRequired interests to continue.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .completeOnboarding(_selectedInterests.toList());
      // GoRouter automatically redirects to /feed when state becomes AuthAuthenticated
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to save interests. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = _minSelectedRequired - _selectedInterests.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.midnightNavy : AppColors.lightCanvas,
      body: SafeArea(
        child: _isLoadingCatalog
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryCrimson),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space24,
                  vertical: AppSpacing.space20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.space16),
                    const Center(child: AppLogo.icon(width: 48, height: 48)),
                    const SizedBox(height: AppSpacing.space20),
                    Text(
                      'Choose what you\'re into',
                      textAlign: TextAlign.center,
                      style: AppTypography.headingLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'We\'ll personalize your feeds, communities, and recommendations based on your topics.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),

                    // Counter Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space12,
                          vertical: AppSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedInterests.length >= _minSelectedRequired
                              ? AppColors.success.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                          borderRadius: AppSpacing.roundedFull,
                          border: Border.all(
                            color: _selectedInterests.length >= _minSelectedRequired
                                ? AppColors.success.withValues(alpha: 0.4)
                                : (isDark
                                    ? AppColors.navyBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          _selectedInterests.length >= _minSelectedRequired
                              ? '✓ ${_selectedInterests.length} selected'
                              : 'Select $remaining more',
                          style: AppTypography.caption.copyWith(
                            color: _selectedInterests.length >= _minSelectedRequired
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space20),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Center(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                    ],

                    // Multi-select Interest Chips Wrap
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: AppSpacing.space12,
                          runSpacing: AppSpacing.space12,
                          alignment: WrapAlignment.center,
                          children: _availableInterests.map((interest) {
                            final isSelected =
                                _selectedInterests.contains(interest.slug);

                            return InkWell(
                              onTap: () => _toggleInterest(interest.slug),
                              borderRadius: AppSpacing.roundedFull,
                              child: AnimatedContainer(
                                duration: AppSpacing.durationFast,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.space16,
                                  vertical: AppSpacing.space12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.primaryCrimson
                                          : AppColors.primaryCrimson)
                                      : (isDark
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurface),
                                  borderRadius: AppSpacing.roundedFull,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryCrimson
                                        : (isDark
                                            ? AppColors.navyBorder
                                            : AppColors.lightBorder),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryCrimson
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (interest.icon != null) ...[
                                      Text(
                                        interest.icon!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: AppSpacing.space8),
                                    ],
                                    Text(
                                      interest.name,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // Continue CTA Button
                    AppButton(
                      key: const Key('onboarding_continue_button'),
                      text: 'Continue to Feed',
                      isLoading: _isSubmitting,
                      onPressed: _selectedInterests.length >= _minSelectedRequired
                          ? (_isSubmitting ? null : _handleComplete)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                  ],
                ),
              ),
      ),
    );
  }
}
