import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/scam_report.dart';
import '../bloc/report_bloc.dart';

/// Screen that lets the user submit a scam-image report.
class ReportScamScreen extends StatefulWidget {
  const ReportScamScreen({super.key, this.scanId});

  /// Optional — set when navigating from an analysis result.
  final String? scanId;

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _platformController = TextEditingController();
  final _detailsController = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  String? _selectedCategory;
  bool _allowAIModel = false;

  // ── BLoC ──────────────────────────────────────────────────────────────────
  late final ReportBloc _bloc;

  // ── Categories ────────────────────────────────────────────────────────────
  static const _categories = [
    'Romance Scam',
    'ซื้อขายออนไลน์',
    'สลิปปลอม',
    'ลงทุนหรือผลตอบแทนสูง',
    'ปลอมแปลงตัวตน',
    'ภาพ AI หรือ Deepfake',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ReportBloc(repository: MockReportRepository());
  }

  @override
  void dispose() {
    _platformController.dispose();
    _detailsController.dispose();
    _bloc.close();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกประเภทเหตุการณ์',
            style: AppTypography.bodyBase(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    _bloc.add(
      ReportSubmitted(
        ScamReport(
          scanId: widget.scanId,
          category: _selectedCategory!,
          description: _detailsController.text.trim(),
          platform: _platformController.text.trim().isEmpty
              ? null
              : _platformController.text.trim(),
          referenceUrl: null,
          allowResearchUse: _allowAIModel,
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
            'ส่งรายงานสำเร็จ ขอบคุณที่ช่วยปกป้องผู้ใช้คนอื่น',
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
            state.message,
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
    
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: _onStateChanged,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppTopBar(
            automaticallyImplyLeading: false, // In Figma, this acts like a main tab
            actions: [
              IconButton(
                tooltip: 'การแจ้งเตือน',
                onPressed: () => context.push('/notifications'),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          body: SafeArea(
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
                    'แจ้งรายงานการหลอกลวง',
                    style: AppTypography.headlineLgMobile(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ช่วยเราสร้างสังคมดิจิทัลที่ปลอดภัยยิ่งขึ้นโดยการแจ้งเบาะแส',
                    style: AppTypography.bodyBase(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Image Card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                      boxShadow: isDark ? [] : [
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'รูปภาพที่ตรวจสอบ',
                              style: AppTypography.titleMd(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // TODO: Pick or change image
                              },
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('เปลี่ยนรูป'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Mock Image Placeholder (QR Code)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            color: isDark ? AppColors.inverseSurface : AppColors.bgLight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 64,
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Category Dropdown ──────────────────────────────────
                  _SectionLabel(label: 'ประเภทเหตุการณ์', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration(
                      hint: 'เลือกประเภทการหลอกลวง',
                      isDark: isDark,
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: AppTypography.bodyBase(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.outlineVariant,
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'กรุณาเลือกประเภทการหลอกลวง' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Platform TextField ─────────────────────────────────
                  _SectionLabel(label: 'แพลตฟอร์มที่พบ', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _platformController,
                    style: AppTypography.bodyBase(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration(
                      hint: 'เช่น Facebook, Line, TikTok',
                      isDark: isDark,
                      prefixIcon: const Icon(
                        Icons.public,
                        size: 20,
                        color: AppColors.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Details Field ──────────────────────────────────────
                  _SectionLabel(label: 'รายละเอียดเพิ่มเติม', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _detailsController,
                    minLines: 4,
                    maxLines: 6,
                    style: AppTypography.bodyBase(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration(
                      hint: 'ระบุลำดับเหตุการณ์ หรือข้อมูลที่น่าสงสัย...',
                      isDark: isDark,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'กรุณาระบุรายละเอียดเพิ่มเติม';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Consent Checkbox ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _allowAIModel,
                          onChanged: (v) => setState(() => _allowAIModel = v ?? false),
                          activeColor: isDark ? AppColors.primaryFixedDim : AppColors.primary,
                          checkColor: isDark ? AppColors.bgDark : Colors.white,
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _allowAIModel = !_allowAIModel),
                          child: Text(
                            'ยินยอมให้ใช้ข้อมูลเพื่อพัฒนาโมเดล AI ในการตรวจสอบและป้องกันภัยไซเบอร์',
                            style: AppTypography.bodyBase(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Submit button ──────────────────────────────────────
                  BlocBuilder<ReportBloc, ReportState>(
                    builder: (context, state) {
                      final isLoading = state is ReportSubmitting;
                      return PrimaryButton(
                        label: 'ส่งรายงาน',
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
                    'ข้อมูลของคุณจะถูกเก็บเป็นความลับและใช้เพื่อความปลอดภัยส่วนรวมเท่านั้น',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
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
  }) =>
      InputDecoration(
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? AppColors.primaryFixedDim : AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
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
            color: Theme.of(context).colorScheme.onSurface),
      );
}
