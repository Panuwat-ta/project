import '../../domain/entities/scam_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';
import '../models/scam_report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({required this.remoteDataSource});

  final ReportRemoteDataSource remoteDataSource;

  @override
  Future<void> submitReport(ScamReport report) =>
      remoteDataSource.submitReport(ScamReportModel.fromDomain(report));

  @override
  Future<List<String>> getCategories() =>
      remoteDataSource.getCategories();
}
