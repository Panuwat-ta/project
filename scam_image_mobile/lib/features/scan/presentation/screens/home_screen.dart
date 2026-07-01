import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/home_cubit.dart';

/// Main home / scan screen — REQ-005.
///
/// Provides:
///  • Greeting section
///  • Upload card (opens image picker via [HomeCubit.pickImage])
///  • Safety Tips bento grid
///  • Recent scan history (3 mock items)
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

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeImageSelected) {
          context.push('/crop', extra: {
            'filePath': state.filePath,
            'fileSizeBytes': state.fileSizeBytes,
          });
        }
      },
      builder: (context, state) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor:
              Theme.of(context).scaffoldBackgroundColor,
          appBar: AppTopBar(
            automaticallyImplyLeading: false,
            actions: [
              // Search button
              IconButton(
                tooltip: 'ค้นหา',
                onPressed: () {},
                icon: Icon(
                  Icons.search_outlined,
                  color: isDark
                      ? AppColors.outlineVariant
                      : AppColors.onSurfaceVariant,
                  semanticLabel: 'ค้นหา',
                ),
              ),
              // Notifications button with red dot badge
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'การแจ้งเตือน',
                      onPressed: () => context.push('/notifications'),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark
                            ? AppColors.outlineVariant
                            : AppColors.onSurfaceVariant,
                        semanticLabel: 'การแจ้งเตือน',
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // ── Greeting ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สวัสดี, ผู้ใช้งาน',
                        style: AppTypography.headlineLgMobile(
                          color: isDark
                              ? AppColors.inverseOnSurface
                              : AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ยินดีต้อนรับกลับสู่ระบบรักษาความปลอดภัยของคุณ',
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
                      horizontal: AppSpacing.safeMargin),
                  child: _UploadCard(
                    isDark: isDark,
                    state: state,
                    pulseAnimation: _pulseAnimation,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Safety Tips ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin),
                  child: _SafetyTipsSection(isDark: isDark),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Recent History ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.safeMargin),
                  child: _RecentHistorySection(isDark: isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Upload Card ───────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.isDark,
    required this.state,
    required this.pulseAnimation,
  });

  final bool isDark;
  final HomeState state;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Theme.of(context).colorScheme.surface, Theme.of(context).scaffoldBackgroundColor]
              : [Colors.white, const Color(0xFFEDF4FF)],
          stops: const [0.0, 1.0],
          transform:
              const GradientRotation(135 * 3.141592653589793 / 180),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upload icon circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryFixedDim : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_outlined,
              size: 40,
              color:
                  isDark ? AppColors.primaryFixedDim : AppColors.primary,
              semanticLabel: 'อัปโหลดรูปภาพ',
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Card title
          Text(
            'ตรวจสอบรูปภาพต้องสงสัย',
            style: AppTypography.sectionHeader(
              color:
                  isDark ? AppColors.primaryFixedDim : AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Description
          Text(
            'เลือกรูปภาพจากอุปกรณ์เพื่อตรวจสอบความเสี่ยง',
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
              color: (isDark
                      ? AppColors.outlineVariant
                      : AppColors.textSecondary)
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Upload button or permission view
          if (state is HomePermissionDenied)
            PermissionRequestView(
              onOpenSettings: () {
                // Platform open-settings is handled at app level or via
                // app_settings package in a later integration task.
              },
              onRetry: () =>
                  context.read<HomeCubit>().pickImage(),
            )
          else
            ScaleTransition(
              scale: pulseAnimation,
              child: PrimaryButton(
                label: 'อัปโหลดรูปภาพ',
                isLoading: state is HomeImagePickerLoading,
                onPressed: state is HomeImagePickerLoading
                    ? null
                    : () => context.read<HomeCubit>().pickImage(),
                leadingIcon: const Icon(
                  Icons.add_photo_alternate,
                  size: 20,
                ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              size: 20,
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'เคล็ดลับความปลอดภัย',
              style: AppTypography.sectionHeader(
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // 2-column grid + 1 full-width card
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TipCard(
                    isDark: isDark,
                    icon: Icons.verified_user_outlined,
                    iconColor: isDark
                        ? const Color(0xFF62DF7D) // secondary-fixed-dim
                        : AppColors.success,
                    text: 'เช็คเครื่องหมายยืนยันตัวตนเสมอ',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TipCard(
                    isDark: isDark,
                    icon: Icons.link_off_outlined,
                    iconColor: isDark
                        ? const Color(0xFFFFB95F) // tertiary-fixed-dim
                        : AppColors.tertiary,
                    text: 'ระวังลิงก์แปลกปลอมในข้อความ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _TipCard(
              isDark: isDark,
              icon: Icons.error_outline,
              iconColor: isDark
                  ? AppColors.inversePrimary // #6CD2FF
                  : AppColors.error,
              text: 'อย่าโอนเงินให้บัญชีบุคคลที่ไม่รู้จัก',
              fullWidth: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.text,
    this.fullWidth = false,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String text;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.caption(
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  text,
                  style: AppTypography.caption(
                    color: isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: content) : content;
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
              'ประวัติการสแกนล่าสุด',
              style: AppTypography.sectionHeader(
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/main/history'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'ดูทั้งหมด',
                style: AppTypography.caption(
                  color: isDark
                      ? AppColors.primaryFixedDim
                      : AppColors.primary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Mock history items (will be replaced with real data in Task 17)
        HistoryListItem(
          title: 'สลิปโอนเงินต้องสงสัย',
          date: '10 ต.ค. 2566 • 14:20',
          riskLevel: RiskLevel.high,
        ),
        const SizedBox(height: AppSpacing.md),
        HistoryListItem(
          title: 'ใบแจ้งหนี้ปลอม',
          date: '09 ต.ค. 2566 • 09:15',
          riskLevel: RiskLevel.safe,
        ),
        const SizedBox(height: AppSpacing.md),
        HistoryListItem(
          title: 'ข้อความจาก SMS',
          date: '08 ต.ค. 2566 • 18:45',
          riskLevel: RiskLevel.medium,
        ),
      ],
    );
  }
}
