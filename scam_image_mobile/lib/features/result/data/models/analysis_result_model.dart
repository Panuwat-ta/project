import '../../domain/entities/analysis_result.dart';
import '../../../../core/utils/risk_level_helper.dart';
import 'risk_factor_model.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    super.xaiExplanation,
    super.aiGenProbability,
    super.ocrText,
    super.scamKeywords,
    required super.createdAt,
    required super.factors,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    final riskScore =
        json['riskScore'] as int? ?? json['total_risk_score'] as int? ?? json['risk_score'] as int? ?? 0;
    final riskLevelStr =
        json['riskLevel'] as String? ?? json['risk_grade'] as String? ?? json['risk_level'] as String?;

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
          riskLevel = RiskLevel.low;
      }
    } else {
      riskLevel = RiskLevelHelper.fromScore(riskScore);
    }

    final List<RiskFactorModel> factors = [];
    if (json['factors'] != null) {
      factors.addAll((json['factors'] as List<dynamic>)
          .map((e) => RiskFactorModel.fromJson(e as Map<String, dynamic>)));
    } else {
      // Map from server flat scores if factors array is missing
      if (json['text_score'] != null) {
        factors.add(RiskFactorModel(
          type: 'textual',
          score: json['text_score'] as int,
          title: 'ข้อความน่าสงสัย',
          details: List<String>.from(json['scam_keywords_found'] ?? []),
        ));
      }
      if (json['visual_score'] != null) {
        factors.add(RiskFactorModel(
          type: 'visual',
          score: json['visual_score'] as int,
          title: 'ภาพน่าสงสัย',
          details: json['ai_gen_probability'] != null ? ['AI Probability: ${json['ai_gen_probability']}'] : [],
        ));
      }
      if (json['source_score'] != null) {
        factors.add(RiskFactorModel(
          type: 'source',
          score: json['source_score'] as int,
          title: 'แหล่งที่มา',
          details: [],
        ));
      }
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

    final xaiExplanation = json['xai_explanation'] as String? ?? json['xaiExplanation'] as String?;
    final aiGenProb = (json['ai_gen_probability'] as num?)?.toDouble() ??
        (json['aiGenProbability'] as num?)?.toDouble();
    final ocrText = json['ocr_text'] as String? ?? json['ocrText'] as String?;
    final scamKeywords = json['scam_keywords_found'] != null
        ? List<String>.from(json['scam_keywords_found'] as List)
        : (json['scamKeywords'] != null ? List<String>.from(json['scamKeywords'] as List) : null);

    return AnalysisResultModel(
      scanId: json['scanId'] as String? ?? json['scan_id'] as String? ?? json['id'] as String? ?? '',
      taskId: json['taskId'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      riskScore: riskScore,
      riskLevel: riskLevel,
      summary: json['summary'] as String? ?? xaiExplanation ?? 'ตรวจพบความเสี่ยงระดับ ${riskLevelStr ?? 'ปกติ'}',
      imageUrl: parseUrl(json['imageUrl'] as String? ?? json['raw_image_url'] as String?),
      heatmapUrl: parseUrl(json['heatmapUrl'] as String? ?? json['heatmap_image_url'] as String?),
      xaiExplanation: xaiExplanation,
      aiGenProbability: aiGenProb,
      ocrText: ocrText,
      scamKeywords: scamKeywords,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String).toLocal() : DateTime.now().toLocal()),
      factors: factors,
    );
  }
}
