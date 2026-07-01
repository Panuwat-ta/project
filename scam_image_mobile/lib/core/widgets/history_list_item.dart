import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'risk_badge.dart';

/// A card-style list item that represents a single scan history entry.
///
/// Displays a colored thumbnail placeholder, title, date, and a [RiskBadge].
class HistoryListItem extends StatelessWidget {
  const HistoryListItem({
    super.key,
    required this.title,
    required this.date,
    required this.riskLevel,
    this.thumbnailUrl,
    this.onTap,
  });

  final String title;
  final String date;
  final RiskLevel riskLevel;

  /// Optional remote image URL. Falls back to a coloured placeholder.
  final String? thumbnailUrl;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: isDark
                    ? AppColors.inverseSurface
                    : const Color(0xFFE4EFFD),
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined,
                                size: 24),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: isDark
                            ? AppColors.outlineVariant
                            : AppColors.outline,
                      ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBase(
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTypography.caption(
                      color: isDark
                          ? AppColors.outlineVariant
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Risk badge
            RiskBadge(riskLevel: riskLevel),
          ],
        ),
      ),
    );
  }
}
