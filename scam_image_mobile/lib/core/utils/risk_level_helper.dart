import '../../features/result/domain/entities/analysis_result.dart';

/// Converts a numeric risk score (0-100) to a [RiskLevel].
///
/// 0-39  → low
/// 40-69 → medium
/// 70-100 → high
class RiskLevelHelper {
  RiskLevelHelper._();

  static RiskLevel fromScore(int score) {
    if (score < 40) return RiskLevel.low;
    if (score < 70) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static String toThaiLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'ต่ำ';
      case RiskLevel.medium:
        return 'ปานกลาง';
      case RiskLevel.high:
        return 'สูง';
    }
  }
}
