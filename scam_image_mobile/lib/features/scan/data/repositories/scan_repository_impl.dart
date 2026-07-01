import 'dart:io';

import '../../domain/entities/analysis_task.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';

/// Threshold in bytes above which the caller is expected to compress the
/// image before it reaches the data source (10 MB).
const int _maxFileSizeBytes = 10 * 1024 * 1024;

/// Concrete implementation of [ScanRepository].
///
/// Image compression for files > 10 MB is expected to be handled at the
/// presentation layer (via `image_picker` quality settings) before the file
/// path reaches this repository.  The repository documents this contract and
/// falls through to the data source regardless, so the app never silently
/// drops an oversized file.
class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl({required this.remoteDataSource});

  final ScanRemoteDataSource remoteDataSource;

  @override
  Future<String> submitImage({
    required String filePath,
    required bool consentForResearch,
    required String clientRequestId,
  }) async {
    // Log a debug warning when the file exceeds the recommended size.
    // Real compression is applied by the ImagePicker quality setting in the
    // presentation layer before this method is called.
    assert(
      () {
        final file = File(filePath);
        if (file.existsSync() && file.lengthSync() > _maxFileSizeBytes) {
          // ignore: avoid_print
          print(
            'ScanRepositoryImpl: file exceeds 10 MB — '
            'ensure image_picker quality compression was applied.',
          );
        }
        return true;
      }(),
    );

    return remoteDataSource.submitScan(
      filePath: filePath,
      consentForResearch: consentForResearch,
      clientRequestId: clientRequestId,
    );
  }

  @override
  Future<AnalysisTask> getAnalysisStatus(String taskId) =>
      remoteDataSource.getScanStatus(taskId);

  @override
  Future<void> cancelScan(String taskId) =>
      remoteDataSource.cancelScan(taskId);
}
