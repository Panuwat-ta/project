import '../../domain/entities/analysis_result.dart';
import '../../../../core/utils/risk_level_helper.dart';
import 'risk_factor_model.dart';

class AnalysisResultModel extends AnalysisResult {
  const AnalysisResultModel({
    required super.scanId,
    required super.taskId,
    required super.status,
    required super.riskScore,
    required super.riskLevel,
    required super.summary,
    super.imageUrl,
    super.heatmapUrl,
    required super.createdAt,
    required super.factors,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    final riskScore =
        json['riskScore'] as int? ?? json['risk_score'] as int? ?? 0;
    final riskLevelStr =
        json['riskLevel'] as String? ?? json['risk_level'] as String?;

    RiskLevel riskLevel;
    if (riskLevelStr != null) {
      switch (riskLevelStr.toLowerCase()) {
        case 'high':
          riskLevel = RiskLevel.high;
          break;
        case 'medium':
          riskLevel = RiskLevel.medium;
          break;
        default:
          riskLevel = RiskLevel.low;
      }
    } else {
      riskLevel = RiskLevelHelper.fromScore(riskScore);
    }

    return AnalysisResultModel(
      scanId: json['scanId'] as String? ?? json['scan_id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? json['task_id'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      riskScore: riskScore,
      riskLevel: riskLevel,
      summary: json['summary'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      heatmapUrl:
          json['heatmapUrl'] as String? ?? json['heatmap_url'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      factors: (json['factors'] as List<dynamic>?)
              ?.map((e) => RiskFactorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
