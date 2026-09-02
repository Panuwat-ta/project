import 'package:equatable/equatable.dart';
import 'risk_factor.dart';

enum RiskLevel { low, medium, high }

class AnalysisResult extends Equatable {
  final String scanId;
  final String taskId;
  final String status;      // "completed" | "failed"
  final int riskScore;      // 0-100
  final RiskLevel riskLevel;
  final String summary;
  final String? imageUrl;
  final String? heatmapUrl;
  final String? xaiExplanation;
  final double? aiGenProbability;
  final String? ocrText;
  final List<String>? scamKeywords;
  final DateTime createdAt;
  final List<RiskFactor> factors;

  const AnalysisResult({
    required this.scanId,
    required this.taskId,
    required this.status,
    required this.riskScore,
    required this.riskLevel,
    required this.summary,
    this.imageUrl,
    this.heatmapUrl,
    this.xaiExplanation,
    this.aiGenProbability,
    this.ocrText,
    this.scamKeywords,
    required this.createdAt,
    required this.factors,
  });

  @override
  List<Object?> get props => [
        scanId,
        taskId,
        status,
        riskScore,
        riskLevel,
        summary,
        imageUrl,
        heatmapUrl,
        xaiExplanation,
        aiGenProbability,
        ocrText,
        scamKeywords,
        createdAt,
        factors,
      ];
}
