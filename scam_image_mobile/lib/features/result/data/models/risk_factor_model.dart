import '../../domain/entities/risk_factor.dart';

class RiskFactorModel extends RiskFactor {
  const RiskFactorModel({
    required super.type,
    required super.score,
    required super.title,
    required super.details,
  });

  factory RiskFactorModel.fromJson(Map<String, dynamic> json) {
    return RiskFactorModel(
      type: json['type'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'score': score,
        'title': title,
        'details': details,
      };
}
