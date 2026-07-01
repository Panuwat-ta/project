import '../entities/scam_report.dart';
import '../repositories/report_repository.dart';

/// Submits a [ScamReport] via the [ReportRepository].
class SubmitScamReportUseCase {
  const SubmitScamReportUseCase(this.repository);

  final ReportRepository repository;

  Future<void> call(ScamReport report) => repository.submitReport(report);
}
