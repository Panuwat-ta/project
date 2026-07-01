import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/scam_report.dart';
import '../bloc/report_bloc.dart';

/// Screen that lets the user submit a scam-image report.
///
/// Creates its own [ReportBloc] backed by [MockReportRepository] so it
/// works in isolation during development. Swap to a real repository via DI
/// in Task 23.
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
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();

  // ── Form state ────────────────────────────────────────────────────────────
  String? _selectedCategory;
  String? _selectedPlatform;
  bool _allowResearch = false;

  // ── BLoC ──────────────────────────────────────────────────────────────────
  late final ReportBloc _bloc;

  // ── Categories / Platforms ────────────────────────────────────────────────
  static const _categories = [
    'Romance Scam',
    'ซื้อขายออนไลน์',
    'สลิปปลอม',
    'ลงทุนหรือผลตอบแทนสูง',
    'ปลอมแปลงตัวตน',
    'ภาพ AI หรือ Deepfake',
    'อื่นๆ',
  ];

  static const _platforms = [
    'Facebook',
    'LINE',
    'Instagram',
    'Marketplace',
    'Website',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ReportBloc(repository: MockReportRepository());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
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
          description: _descriptionController.text.trim(),
          platform: _selectedPlatform,
          referenceUrl: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          allowResearchUse: _allowResearch,
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
        if (context.mounted) Navigator.of(context).pop();
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
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: _onStateChanged,
        child: Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.primaryFixedDim,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'กลับ',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'รายงานภาพต้องสงสัย',
              style: AppTypography.sectionHeader(
                  color: AppColors.primaryFixedDim),
            ),
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
                        color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'ช่วยเราสร้างสังคมดิจิทัลที่ปลอดภัยยิ่งขึ้นโดยการแจ้งเบาะแส',
                    style: AppTypography.bodyBase(
                        color: AppColors.outlineVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Category chips ─────────────────────────────────────
                  _SectionLabel(label: 'ประเภทเหตุการณ์ *'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return FilterChip(
                        label: Text(
                          cat,
                          style: AppTypography.caption(
                            color: selected
                                ? AppColors.bgDark
                                : Colors.white,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primaryFixedDim,
                        backgroundColor: AppColors.inverseSurface,
                        checkmarkColor: AppColors.bgDark,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryFixedDim
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.5),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Description field ──────────────────────────────────
                  _SectionLabel(label: 'รายละเอียดเหตุการณ์ *'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 5,
                    maxLines: 8,
                    style: AppTypography.bodyBase(color: Colors.white),
                    decoration: _inputDecoration(
                      hint:
                          'ระบุลำดับเหตุการณ์ หรือข้อมูลที่น่าสงสัย...',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return 'กรุณาระบุรายละเอียดอย่างน้อย 10 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Platform chips ─────────────────────────────────────
                  _SectionLabel(label: 'แพลตฟอร์มที่พบ'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _platforms.map((p) {
                      final selected = _selectedPlatform == p;
                      return FilterChip(
                        label: Text(
                          p,
                          style: AppTypography.caption(
                            color: selected
                                ? AppColors.bgDark
                                : Colors.white,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedPlatform = p),
                        selectedColor: AppColors.primaryFixedDim,
                        backgroundColor: AppColors.inverseSurface,
                        checkmarkColor: AppColors.bgDark,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryFixedDim
                              : AppColors.outlineVariant.withValues(
                                  alpha: 0.5),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Reference URL ──────────────────────────────────────
                  _SectionLabel(
                      label: 'ลิงก์หรือชื่อบัญชีผู้ต้องสงสัย (ถ้ามี)'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _referenceController,
                    style: AppTypography.bodyBase(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'https://... หรือ @username',
                      prefixIcon: const Icon(
                        Icons.link,
                        size: 20,
                        color: AppColors.outline,
                      ),
                    ),
                    // Optional — no validator
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Consent ────────────────────────────────────────────
                  ConsentCheckboxTile(
                    value: _allowResearch,
                    onChanged: (v) =>
                        setState(() => _allowResearch = v ?? false),
                    label:
                        'ยินยอมให้ใช้ข้อมูลเพื่อปรับปรุงระบบ',
                    description:
                        'ข้อมูลของคุณจะถูกเก็บเป็นความลับและใช้เพื่อความปลอดภัยส่วนรวมเท่านั้น',
                  ),
                  const SizedBox(height: AppSpacing.lg),

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
                            : const Icon(Icons.send, size: 18),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Footer note ────────────────────────────────────────
                  Text(
                    'ข้อมูลของคุณจะถูกเก็บเป็นความลับและใช้เพื่อความปลอดภัยส่วนรวมเท่านั้น',
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.caption(color: AppColors.outline),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
    Widget? prefixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyBase(color: AppColors.outline),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.inverseSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.gutter,
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
          borderSide: const BorderSide(
              color: AppColors.primaryFixedDim, width: 1.5),
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
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: AppTypography.buttonLabel(color: Colors.white),
      );
}
