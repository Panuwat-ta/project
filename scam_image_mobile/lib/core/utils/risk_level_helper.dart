import '../../features/result/domain/entities/analysis_result.dart';

/// Converts a numeric risk score (0-100) to a [RiskLevel].
///
///
/// 0-39  → safe
/// 40-59 → low
/// 60-79 → medium
/// 80-100 → high
class RiskLevelHelper {
  RiskLevelHelper._();

  static RiskLevel fromScore(int score) {
    if (score < 40) return RiskLevel.safe;
    if (score < 60) return RiskLevel.low;
    if (score < 80) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static String toThaiLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return 'ปลอดภัย';
      case RiskLevel.low:
        return 'เสี่ยงต่ำ';
      case RiskLevel.medium:
        return 'เสี่ยง';
      case RiskLevel.high:
        return 'เสี่ยงสูง';
    }
  }
}
