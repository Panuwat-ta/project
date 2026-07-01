import 'package:equatable/equatable.dart';
import '../../../result/domain/entities/analysis_result.dart';

class ScanHistoryItem extends Equatable {
  final String scanId;
  final String? thumbnailUrl;
  final int riskScore;
  final RiskLevel riskLevel;
  final String status; // "completed" | "failed" | "processing"
  final DateTime createdAt;
  final String? title; // Optional display title

  const ScanHistoryItem({
    required this.scanId,
    this.thumbnailUrl,
    required this.riskScore,
    required this.riskLevel,
    required this.status,
    required this.createdAt,
    this.title,
  });

  @override
  List<Object?> get props => [
        scanId,
        thumbnailUrl,
        riskScore,
        riskLevel,
        status,
        createdAt,
        title,
      ];
}
