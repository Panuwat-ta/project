import '../../domain/entities/scam_report.dart';

/// Data-layer model that extends [ScamReport] with JSON serialisation.
class ScamReportModel extends ScamReport {
  const ScamReportModel({
    super.scanId,
    required super.category,
    required super.description,
    super.platform,
    super.referenceUrl,
    super.allowResearchUse,
  });

  /// Creates a [ScamReportModel] from a domain [ScamReport].
  factory ScamReportModel.fromDomain(ScamReport report) => ScamReportModel(
        scanId: report.scanId,
        category: report.category,
        description: report.description,
        platform: report.platform,
        referenceUrl: report.referenceUrl,
        allowResearchUse: report.allowResearchUse,
      );

  Map<String, dynamic> toJson() => {
        if (scanId != null) 'scanId': scanId,
        'category': category,
        'description': description,
        if (platform != null) 'platform': platform,
        if (referenceUrl != null) 'referenceUrl': referenceUrl,
        'allowResearchUse': allowResearchUse,
      };
}
