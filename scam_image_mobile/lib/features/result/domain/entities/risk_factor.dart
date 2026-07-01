import 'package:equatable/equatable.dart';

class RiskFactor extends Equatable {
  final String type; // "textual" | "source" | "visual"
  final int score;   // 0-100
  final String title;
  final List<String> details;

  const RiskFactor({
    required this.type,
    required this.score,
    required this.title,
    required this.details,
  });

  @override
  List<Object?> get props => [type, score, title, details];
}
