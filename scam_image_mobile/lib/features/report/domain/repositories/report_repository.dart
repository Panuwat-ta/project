import '../entities/scam_report.dart';

/// Abstract contract for the report feature data layer.
abstract class ReportRepository {
  /// Submits a [ScamReport] to the remote backend.
  Future<void> submitReport(ScamReport report);

  /// Returns the list of available scam category labels.
  Future<List<String>> getCategories();
}
