import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/scam_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';
import '../models/scam_report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required this.remoteDataSource});

  final ReportRemoteDataSource remoteDataSource;

  @override
  Future<void> submitReport(ScamReport report) {
    if (report.scanId == null || report.scanId!.trim().isEmpty) {
      throw const ValidationException('A scanned image is required');
    }
    return remoteDataSource.submitReport(ScamReportModel.fromDomain(report));
  }

  @override
  Future<List<String>> getCategories() => remoteDataSource.getCategories();
}
