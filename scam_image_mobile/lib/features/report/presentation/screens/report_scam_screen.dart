import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/scam_report.dart';
import '../bloc/report_bloc.dart';
import '../report_form_mapper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../history/domain/entities/scan_history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';

class ReportScamScreen extends StatefulWidget {
  const ReportScamScreen({super.key, this.scanId, this.imageUrl});

  /// Optional — set when navigating from an analysis result.
  final String? scanId;
  final String? imageUrl;

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _platformController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final _detailsController = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  String? _selectedCategory;
  String? _selectedPlatform;
  bool _allowAIModel = false;

  // ── BLoC ──────────────────────────────────────────────────────────────────
  late final ReportBloc _bloc;
  String? _activeScanId;
  String? _activeImageUrl;

  bool get _hasSelectedScan => _activeScanId?.trim().isNotEmpty == true;

  // ── Categories: backend canonical keys (DOC-08) + i18n labels ──
  // ส่ง key ภาษาอังกฤษคงที่ไป backend เสมอ ห้ามส่ง label ที่แปลแล้ว
  List<({String key, String label})> get _categories => [
    (key: 'romance_scam', label: 'cat_romance'.tr(context)),
    (key: 'online_shopping', label: 'cat_ecommerce'.tr(context)),
    (key: 'fake_slip', label: 'cat_fake_slip'.tr(context)),
    (key: 'investment', label: 'cat_investment'.tr(context)),
    (key: 'identity_theft', label: 'cat_impersonation'.tr(context)),
    (key: 'ai_deepfake', label: 'cat_ai'.tr(context)),
    (key: 'other', label: 'cat_other'.tr(context)),
  ];

  List<({String key, String label})> get _platforms => [
    (key: 'Facebook', label: 'Facebook'),
    (key: 'Instagram', label: 'Instagram'),
    (key: 'LINE', label: 'LINE'),
    (key: 'TikTok', label: 'TikTok'),
    (key: 'X (Twitter)', label: 'X (Twitter)'),
    (key: 'other', label: 'cat_other'.tr(context)),
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ReportBloc(repository: ServiceLocator.reportRepository);
    _activeScanId = widget.scanId;
    _activeImageUrl = widget.imageUrl;
    if (!_hasSelectedScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<HistoryBloc>().add(const HistoryLoaded());
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReportScamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanId != oldWidget.scanId ||
        widget.imageUrl != oldWidget.imageUrl) {
      _activeScanId = widget.scanId;
      _activeImageUrl = widget.imageUrl;
    }
  }

  @override
  void dispose() {
    _platformController.dispose();
    _otherCategoryController.dispose();
    _detailsController.dispose();
    _bloc.close();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submit() {
    if (!_hasSelectedScan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('report_scan_required'.tr(context)),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'report_cat_error_toast'.tr(context),
            style: AppTypography.bodyBase(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final finalCategory = _selectedCategory!;
    final finalDescription = buildReportDescription(
      category: finalCategory,
      customCategory: _otherCategoryController.text,
      details: _detailsController.text,
    );
    final finalPlatform = resolveReportPlatform(
      selectedPlatform: _selectedPlatform,
      customPlatform: _platformController.text,
    );

    _bloc.add(
      ReportSubmitted(
        ScamReport(
          scanId: _activeScanId,
          category: finalCategory,
          description: finalDescription,
          platform: (finalPlatform == null || finalPlatform.isEmpty)
              ? null
              : finalPlatform,
          referenceUrl: null,
          allowResearchUse: _allowAIModel,
        ),
      ),
    );
  }

  void _selectScan(ScanHistoryItem item) {
    setState(() {
      _activeScanId = item.scanId;
      _activeImageUrl = item.thumbnailUrl;
    });
  }

  void _changeScan() {
    setState(() {
      _activeScanId = null;
      _activeImageUrl = null;
    });
    context.read<HistoryBloc>().add(const HistoryLoaded());
  }

  Widget _buildScanSelector(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppTopBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'notifications'.tr(context),
            onPressed: () => context.push('/notifications'),
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AdaptiveContent(
          maxWidth: 600,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.safeMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'report_select_scan_title'.tr(context),
                  style: AppTypography.headlineLgMobile(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'report_select_scan_desc'.tr(context),
                  style: AppTypography.bodyBase(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: BlocBuilder<HistoryBloc, HistoryState>(
                    builder: (context, state) {
                      if (state is HistoryInitial || state is HistoryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is HistoryError) {
                        return ErrorStateView(
                          message: state.message,
                          onRetry: () => context.read<HistoryBloc>().add(
                            const HistoryLoaded(),
                          ),
                        );
                      }
                      final items = state is HistoryDataLoaded
                          ? state.items
                                .where(
                                  (item) =>
                                      item.status.toLowerCase() == 'completed',
                                )
                                .toList()
                          : <ScanHistoryItem>[];
                      if (items.isEmpty) {
                        return EmptyStateView(
                          icon: Icons.history_outlined,
                          title: 'report_select_scan_empty'.tr(context),
                          subtitle: 'report_select_scan_empty_desc'.tr(context),
                        );
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Material(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: AppRadius.mdBorder,
                            child: ListTile(
                              minTileHeight: 72,
                              onTap: () => _selectScan(item),
                              leading: ClipRRect(
                                borderRadius: AppRadius.smBorder,
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: item.thumbnailUrl?.isNotEmpty == true
                                      ? CachedNetworkImage(
                                          imageUrl: item.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) =>
                                              const Icon(Icons.image_outlined),
                                        )
                                      : const ColoredBox(
                                          color: AppColors.inverseSurface,
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: AppColors.outlineVariant,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                item.title?.trim().isNotEmpty == true
                                    ? item.title!
                                    : 'report_untitled_scan'.tr(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.sectionHeader(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                '${item.riskScore}% • ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                style: AppTypography.caption(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Listener ─────────────────────────────────────────────────────────────
  void _onStateChanged(BuildContext context, ReportState state) {
    if (state is ReportSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'report_success'.tr(context),
            style: AppTypography.bodyBase(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      // Pop after snackbar is visible
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (context.mounted) {
          if (GoRouter.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/main/home');
          }
        }
      });
    } else if (state is ReportError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.message.tr(context),
            style: AppTypography.bodyBase(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasSelectedScan) {
      return _buildScanSelector(context, isDark);
    }

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: _onStateChanged,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppTopBar(
            automaticallyImplyLeading:
                false, // In Figma, this acts like a main tab
            actions: [
              IconButton(
                tooltip: 'notifications'.tr(context),
                onPressed: () => context.push('/notifications'),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark
                      ? AppColors.outlineVariant
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: AdaptiveContent(
              maxWidth: 600,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.safeMargin,
                    vertical: AppSpacing.md,
                  ),
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    Text(
                      'report_title'.tr(context),
                      style: AppTypography.headlineLgMobile(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'report_subtitle'.tr(context),
                      style: AppTypography.bodyBase(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Image Card ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'report_image_label'.tr(context),
                                  style: AppTypography.titleMd(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              TextButton.icon(
                                onPressed: _changeScan,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: Text('report_change_image'.tr(context)),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Scan reference card
                          ClipRRect(
                            borderRadius: AppRadius.smBorder,
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: isDark
                                  ? AppColors.inverseSurface
                                  : AppColors.bgLight,
                              child:
                                  _activeImageUrl != null &&
                                      _activeImageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _activeImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 180,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 48,
                                              color: AppColors.outlineVariant,
                                            ),
                                          ),
                                    )
                                  : Center(
                                      child: Icon(
                                        _activeScanId == null
                                            ? Icons.add_photo_alternate_outlined
                                            : Icons.image_search_outlined,
                                        size: 56,
                                        color: AppColors.outlineVariant,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Category Dropdown ──────────────────────────────────
                    _SectionLabel(
                      label: 'report_cat_label'.tr(context),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FormField<String>(
                      initialValue: _selectedCategory,
                      validator: (v) =>
                          v == null ? 'report_cat_error'.tr(context) : null,
                      builder: (FormFieldState<String> state) {
                        return DropdownMenu<String>(
                          initialSelection: state.value,
                          hintText: 'report_cat_hint'.tr(context),
                          expandedInsets: EdgeInsets.zero,
                          errorText: state.errorText,
                          menuStyle: MenuStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: AppRadius.lgBorder,
                              ),
                            ),
                            elevation: WidgetStateProperty.all(4),
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: isDark
                                ? AppColors.inverseSurface
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.primaryFixedDim
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1,
                              ),
                            ),
                          ),
                          textStyle: AppTypography.bodyBase(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onSelected: (v) {
                            if (v != null) {
                              state.didChange(v);
                              setState(() => _selectedCategory = v);
                            }
                          },
                          dropdownMenuEntries: _categories.map((cat) {
                            return DropdownMenuEntry<String>(
                              value: cat.key,
                              label: cat.label,
                              style: MenuItemButton.styleFrom(
                                textStyle: AppTypography.bodyBase(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (_selectedCategory == 'other') ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _otherCategoryController,
                        style: AppTypography.bodyBase(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _inputDecoration(
                          hint: 'report_specify_hint'.tr(context),
                          isDark: isDark,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'report_other_category_error'.tr(context)
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // ── Platform TextField ─────────────────────────────────
                    _SectionLabel(
                      label: 'report_platform_label'.tr(context),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FormField<String>(
                      initialValue: _selectedPlatform,
                      builder: (FormFieldState<String> state) {
                        return DropdownMenu<String>(
                          initialSelection: state.value,
                          hintText: 'report_platform_hint'.tr(context),
                          expandedInsets: EdgeInsets.zero,
                          errorText: state.errorText,
                          menuStyle: MenuStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: AppRadius.lgBorder,
                              ),
                            ),
                            elevation: WidgetStateProperty.all(4),
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surface,
                            ),
                          ),
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: isDark
                                ? AppColors.inverseSurface
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.smBorder,
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.primaryFixedDim
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          textStyle: AppTypography.bodyBase(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onSelected: (v) {
                            if (v != null) {
                              state.didChange(v);
                              setState(() => _selectedPlatform = v);
                            }
                          },
                          dropdownMenuEntries: _platforms.map((plat) {
                            return DropdownMenuEntry<String>(
                              value: plat.key,
                              label: plat.label,
                              style: MenuItemButton.styleFrom(
                                textStyle: AppTypography.bodyBase(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (_selectedPlatform == 'other') ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _platformController,
                        style: AppTypography.bodyBase(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: _inputDecoration(
                          hint: 'report_specify_hint'.tr(context),
                          isDark: isDark,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'report_other_platform_error'.tr(context)
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // ── Details Field ──────────────────────────────────────
                    _SectionLabel(
                      label: 'report_details_label'.tr(context),
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _detailsController,
                      minLines: 4,
                      maxLines: 6,
                      style: AppTypography.bodyBase(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: _inputDecoration(
                        hint: 'report_details_hint'.tr(context),
                        isDark: isDark,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'report_details_error'.tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Consent Checkbox ───────────────────────────────────
                    Semantics(
                      toggled: _allowAIModel,
                      label: 'report_consent'.tr(context),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _allowAIModel = !_allowAIModel),
                        borderRadius: AppRadius.smBorder,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _allowAIModel,
                                onChanged: (v) =>
                                    setState(() => _allowAIModel = v ?? false),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'report_consent'.tr(context),
                                  style: AppTypography.bodyBase(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Submit button ──────────────────────────────────────
                    BlocBuilder<ReportBloc, ReportState>(
                      builder: (context, state) {
                        final isLoading = state is ReportSubmitting;
                        return PrimaryButton(
                          label: 'report_submit'.tr(context),
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                          leadingIcon: isLoading
                              ? null
                              : const Icon(Icons.send, size: 20),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Footer note ────────────────────────────────────────
                    Text(
                      'report_footer'.tr(context),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    Widget? prefixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodyBase(color: AppColors.outlineVariant),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: isDark ? AppColors.inverseSurface : Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: AppRadius.smBorder,
      borderSide: BorderSide(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.smBorder,
      borderSide: BorderSide(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.smBorder,
      borderSide: BorderSide(
        color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.smBorder,
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.smBorder,
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
    errorStyle: AppTypography.caption(color: AppColors.danger),
  );
}

// ── Private helper widget ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTypography.titleMd(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}
