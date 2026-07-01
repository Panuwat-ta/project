import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/widgets.dart' as core_widgets;
import '../../../result/domain/entities/analysis_result.dart' as domain;
import '../../../result/domain/entities/risk_factor.dart';
import '../../../result/presentation/bloc/result_bloc.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.scanId});

  final String scanId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final ResultBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ResultBloc(repository: MockResultRepository());
    _bloc.add(ResultLoadRequested(widget.scanId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'รายละเอียดประวัติ',
            style: AppTypography.sectionHeader(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'ย้อนกลับ',
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/main/home'),
          backgroundColor: AppColors.primaryFixedDim,
          foregroundColor: AppColors.bgDark,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            'สแกนภาพใหม่',
            style: AppTypography.buttonLabel(color: AppColors.bgDark),
          ),
        ),
        body: BlocBuilder<ResultBloc, ResultState>(
          builder: (context, state) {
            if (state is ResultLoading || state is ResultInitial) {
              return const core_widgets.LoadingOverlay(
                message: 'กำลังโหลดผลวิเคราะห์...',
              );
            }
            if (state is ResultError) {
              return core_widgets.ErrorStateView(
                message: state.message,
                onRetry: () =>
                    _bloc.add(ResultLoadRequested(widget.scanId)),
              );
            }
            if (state is ResultLoaded) {
              return _HistoryDetailBody(result: state.result);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Detail body ───────────────────────────────────────────────────────────────

class _HistoryDetailBody extends StatelessWidget {
  const _HistoryDetailBody({required this.result});

  final domain.AnalysisResult result;

  core_widgets.RiskLevel _toWidgetLevel(domain.RiskLevel l) {
    switch (l) {
      case domain.RiskLevel.high:
        return core_widgets.RiskLevel.high;
      case domain.RiskLevel.medium:
        return core_widgets.RiskLevel.medium;
      case domain.RiskLevel.low:
        return core_widgets.RiskLevel.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.safeMargin,
        AppSpacing.lg,
        AppSpacing.safeMargin,
        100,
      ),
      child: Column(
        children: [
          // Risk gauge
          core_widgets.RiskGauge(score: result.riskScore),
          const SizedBox(height: AppSpacing.sm),
          core_widgets.RiskBadge(riskLevel: _toWidgetLevel(result.riskLevel)),
          const SizedBox(height: AppSpacing.lg),

          // Summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primaryFixedDim,
                  size: 40,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สรุปผลการวิเคราะห์',
                        style:
                            AppTypography.sectionHeader(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        result.summary,
                        style: AppTypography.bodyBase(
                            color: AppColors.outlineVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Risk factors
          ...result.factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _RiskFactorCard(factor: f),
              )),
        ],
      ),
    );
  }
}

// ── Risk factor card ──────────────────────────────────────────────────────────

class _RiskFactorCard extends StatelessWidget {
  const _RiskFactorCard({required this.factor});

  final RiskFactor factor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            factor.title,
            style: AppTypography.bodyBase(color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          core_widgets.RiskProgressBar(score: factor.score),
          const SizedBox(height: AppSpacing.sm),
          ...factor.details.map(
            (d) => Text(
              '• $d',
              style:
                  AppTypography.caption(color: AppColors.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }
}
