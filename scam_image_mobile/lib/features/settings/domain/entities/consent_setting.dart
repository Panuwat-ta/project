import 'package:equatable/equatable.dart';

/// Represents user consent preferences for data processing.
class ConsentSetting extends Equatable {
  /// Required for basic app use — image processing consent.
  final bool processingConsent;

  /// Consent to save scan history.
  final bool historyConsent;

  /// Optional consent for research/model improvement use.
  final bool researchConsent;

  const ConsentSetting({
    this.processingConsent = true,
    this.historyConsent = true,
    this.researchConsent = false,
  });

  ConsentSetting copyWith({
    bool? processingConsent,
    bool? historyConsent,
    bool? researchConsent,
  }) =>
      ConsentSetting(
        processingConsent: processingConsent ?? this.processingConsent,
        historyConsent: historyConsent ?? this.historyConsent,
        researchConsent: researchConsent ?? this.researchConsent,
      );

  @override
  List<Object?> get props => [processingConsent, historyConsent, researchConsent];
}
