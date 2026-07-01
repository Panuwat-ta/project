import '../../domain/entities/scan_history_item.dart';
import '../../../../core/utils/risk_level_helper.dart';
import '../../../result/domain/entities/analysis_result.dart';

class ScanHistoryItemModel extends ScanHistoryItem {
  const ScanHistoryItemModel({
    required super.scanId,
    super.thumbnailUrl,
    required super.riskScore,
    required super.riskLevel,
    required super.status,
    required super.createdAt,
    super.title,
  });

  factory ScanHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final riskScore =
        json['riskScore'] as int? ?? json['risk_score'] as int? ?? 0;
    final riskLevelStr =
        json['riskLevel'] as String? ?? json['risk_level'] as String?;
    final riskLevel = riskLevelStr != null
        ? (riskLevelStr == 'high'
            ? RiskLevel.high
            : riskLevelStr == 'medium'
                ? RiskLevel.medium
                : RiskLevel.low)
        : RiskLevelHelper.fromScore(riskScore);
    return ScanHistoryItemModel(
      scanId: json['scanId'] as String? ?? json['scan_id'] as String? ?? '',
      thumbnailUrl:
          json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      riskScore: riskScore,
      riskLevel: riskLevel,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      title: json['title'] as String?,
    );
  }
}
