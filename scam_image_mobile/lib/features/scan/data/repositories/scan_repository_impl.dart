import '../../../../core/utils/scan_image_validator.dart';

import '../../domain/entities/analysis_task.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';

/// Validates the selected local image before making an upload request.
class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({required this.remoteDataSource});

  final ScanRemoteDataSource remoteDataSource;

  @override
  Future<String> submitImage({
    required String filePath,
    String? scanName,
  }) async {
    await validateScanImage(filePath);

    return remoteDataSource.submitScan(filePath: filePath, scanName: scanName);
  }

  @override
  Future<AnalysisTask> getAnalysisStatus(String taskId) =>
      remoteDataSource.getScanStatus(taskId);
}
