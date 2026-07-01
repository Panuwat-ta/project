import 'package:equatable/equatable.dart';

/// Domain entity representing a user-submitted scam report.
class ScamReport extends Equatable {
  const ScamReport({
    this.scanId,
    required this.category,
    required this.description,
    this.platform,
    this.referenceUrl,
    this.allowResearchUse = false,
  });

  /// Optional — scanId of the analysed image being reported.
  final String? scanId;

  /// Category of the scam (e.g. "Romance Scam", "สลิปปลอม").
  final String category;

  /// Free-form description of the incident (minimum 10 characters).
  final String description;

  /// Platform where the scam was encountered (e.g. "Facebook").
  final String? platform;

  /// Optional URL or account name of the suspect.
  final String? referenceUrl;

  /// Whether the user consents to the data being used for research.
  final bool allowResearchUse;

  @override
  List<Object?> get props => [
        scanId,
        category,
        description,
        platform,
        referenceUrl,
        allowResearchUse,
      ];
}
