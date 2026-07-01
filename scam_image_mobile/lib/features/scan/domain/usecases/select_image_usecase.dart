import '../../../../core/errors/exceptions.dart';
import '../entities/scan_image.dart';

/// Validates a file path to ensure it meets requirements (valid format).
/// Returns [ScanImage] on success, throws [ValidationException] on failure.
///
/// Note: large files (> 10 MB) are allowed — compression is handled in the
/// data layer before uploading.
class SelectImageUseCase {
  Future<ScanImage> call({
    required String filePath,
    required int fileSizeBytes,
  }) {
    final ext = filePath.split('.').last.toLowerCase();
    final image = ScanImage(
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      format: ext,
    );

    if (!image.isValidFormat) {
      throw const ValidationException(
        'รูปแบบไฟล์ไม่รองรับ รองรับเฉพาะ jpg, jpeg, png, webp',
      );
    }

    return Future.value(image);
  }
}
