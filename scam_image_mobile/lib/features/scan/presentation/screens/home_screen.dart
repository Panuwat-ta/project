import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/home_cubit.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Main home / scan screen — REQ-005.
///
/// Provides:
///  • Greeting section
///  • Upload card (opens image picker via [HomeCubit.pickImage])
///  • Safety Tips bento grid
///  • Recent scan history (up to 3 items from HistoryBloc)
///
/// Navigation:
///  • On [HomeImageSelected] → navigates to `/crop` with file info in `extra`
///  • On [HomePermissionDenied] → shows [PermissionRequestView] inside the card
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => HomeCubit(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  void initState() {
    super.initState();
    // Fetch history if not loaded yet
    if (context.read<HistoryBloc>().state is HistoryInitial) {
      context.read<HistoryBloc>().add(const HistoryLoaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeImageSelected) {
          context.push(
            '/crop',
            extra: {
              'filePath': state.filePath,
              'fileSizeBytes': state.fileSizeBytes,
            },
          );
        } else if (state is HomeError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message.tr(context))));
        }
      },
      builder: (context, state) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppTopBar(
            automaticallyImplyLeading: false,
            actions: [
              // Notifications button with red dot badge
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'notifications'.tr(context),
                      onPressed: () => context.push('/notifications'),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark
                            ? AppColors.outlineVariant
                            : AppColors.onSurfaceVariant,
                        semanticLabel: 'notifications'.tr(context),
                      ),
                    ),
                    // Unread indicator dot
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: AdaptiveContent(
            maxWidth: 720,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // ── Greeting ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            String name = 'default_user'.tr(context);
                            if (state is AuthAuthenticated) {
                              name = state.user.displayName;
                            }
                            return Text(
                              'greeting_name'
                                  .tr(context)
                                  .replaceAll('{name}', name),
                              style: AppTypography.headlineLgMobile(
                                color: isDark
                                    ? AppColors.inverseOnSurface
                                    : AppColors.onBackground,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'greeting_subtitle'.tr(context),
                          style: AppTypography.bodyBase(
                            color: isDark
                                ? AppColors.outlineVariant
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Upload Card ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin,
                    ),
                    child: _UploadCard(isDark: isDark, state: state),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Safety Tips ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin,
                    ),
                    child: _SafetyTipsSection(isDark: isDark),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Recent History ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin,
                    ),
                    child: _RecentHistorySection(isDark: isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Upload Card ───────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.isDark, required this.state});

  final bool isDark;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Upload icon circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryFixedDim : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_outlined,
              size: 28,
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
              semanticLabel: 'upload_btn'.tr(context),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Card title
          Text(
            'upload_title'.tr(context),
            style: AppTypography.sectionHeader(
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Description
          Text(
            'upload_desc'.tr(context),
            style: AppTypography.bodyBase(
              color: isDark
                  ? AppColors.outlineVariant
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '(jpg, jpeg, png, webp)',
            style: AppTypography.caption(
              color:
                  (isDark ? AppColors.outlineVariant : AppColors.textSecondary)
                      .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Upload button or permission view
          if (state is HomePermissionDenied)
            PermissionRequestView(
              onOpenSettings: () {
                // Platform open-settings is handled at app level or via
                // app_settings package in a later integration task.
              },
              onRetry: () => context.read<HomeCubit>().pickImage(),
            )
          else
            PrimaryButton(
              label: 'upload_btn'.tr(context),
              isLoading: state is HomeImagePickerLoading,
              onPressed: state is HomeImagePickerLoading
                  ? null
                  : () => context.read<HomeCubit>().pickImage(),
              leadingIcon: const Icon(Icons.add_photo_alternate, size: 20),
            ),
        ],
      ),
    );
  }
}

// ── Safety Tips ───────────────────────────────────────────────────────────────

class _SafetyTipsSection extends StatelessWidget {
  const _SafetyTipsSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'safety_tips'.tr(context),
          style: AppTypography.sectionHeader(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SafetyTipRow(
          icon: Icons.verified_user_outlined,
          iconColor: isDark ? AppColors.successDark : AppColors.success,
          text: 'tip_1'.tr(context),
        ),
        _SafetyTipRow(
          icon: Icons.link_off_outlined,
          iconColor: isDark ? AppColors.warningDark : AppColors.warning,
          text: 'tip_2'.tr(context),
        ),
        _SafetyTipRow(
          icon: Icons.error_outline,
          iconColor: scheme.error,
          text: 'tip_3'.tr(context),
        ),
      ],
    );
  }
}

class _SafetyTipRow extends StatelessWidget {
  const _SafetyTipRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyBase(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent History ────────────────────────────────────────────────────────────

class _RecentHistorySection extends StatelessWidget {
  const _RecentHistorySection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_history'.tr(context),
              style: AppTypography.sectionHeader(
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/main/history'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                'see_all'.tr(context),
                style: AppTypography.caption(
                  color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state is HistoryLoading || state is HistoryInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is HistoryEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'home_no_history'.tr(context),
                    style: AppTypography.bodyBase(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              );
            } else if (state is HistoryDataLoaded) {
              final recentItems = state.items.take(3).toList();
              if (recentItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: recentItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: HistoryListItem(
                      title: item.title?.trim().isNotEmpty == true
                          ? item.title!.trim()
                          : 'home_untitled_scan'.tr(context),
                      date: 'home_scanned_at'
                          .tr(context)
                          .replaceAll(
                            '{time}',
                            DateFormat('HH:mm').format(item.createdAt),
                          ),
                      riskLevel: RiskBadge.levelFromString(item.riskLevel.name),
                      thumbnailUrl: item.thumbnailUrl,
                      onTap: () => context.push('/result/${item.scanId}'),
                    ),
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
