import '../../domain/entities/scan_history_item.dart';
import '../../../../core/utils/risk_level_helper.dart';
import '../../../result/domain/entities/analysis_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    RiskLevel riskLevel;
    if (riskLevelStr != null) {
      switch (riskLevelStr.toLowerCase()) {
        case 'high':
          riskLevel = RiskLevel.high;
          break;
        case 'medium':
          riskLevel = RiskLevel.medium;
          break;
        case 'low':
          riskLevel = RiskLevel.low;
          break;
        default:
          riskLevel = RiskLevel.safe;
      }
    } else {
      riskLevel = RiskLevelHelper.fromScore(riskScore);
    }
        
    String? parseUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('http')) return url;
      
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api/v1';
      final uri = Uri.parse(baseUrl);
      final hostUrl = '${uri.scheme}://${uri.host}:${uri.port}';

      String cleanUrl = url.replaceAll(r'\', '/');
      if (cleanUrl.startsWith('./')) {
        cleanUrl = cleanUrl.substring(2);
      }
      if (!cleanUrl.startsWith('/')) {
        cleanUrl = '/$cleanUrl';
      }
      if (!cleanUrl.toLowerCase().startsWith('/uploads')) {
        cleanUrl = '/uploads$cleanUrl';
      }
      
      return '$hostUrl$cleanUrl';
    }
        
    return ScanHistoryItemModel(
      scanId: json['scanId'] as String? ?? json['scan_id'] as String? ?? '',
      thumbnailUrl: parseUrl(
          json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?),
      riskScore: riskScore,
      riskLevel: riskLevel,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
      title: json['title'] as String?,
    );
  }
}
