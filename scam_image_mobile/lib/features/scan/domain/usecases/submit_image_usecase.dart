import 'package:uuid/uuid.dart';

import '../repositories/scan_repository.dart';

class SubmitImageParams {
  final String filePath;
  final bool consentForResearch;

  const SubmitImageParams({
    required this.filePath,
    this.consentForResearch = false,
  });
}

/// Submits a validated image to the backend and returns the taskId.
///
/// A [clientRequestId] (UUID v4) is generated automatically to allow
/// idempotent retries on the server side.
class SubmitImageUseCase {
  final ScanRepository repository;
  final Uuid _uuid;

  SubmitImageUseCase(this.repository, {this._uuid = const Uuid()});

  Future<String> call(SubmitImageParams params) {
    final clientRequestId = _uuid.v4();
    return repository.submitImage(
      filePath: params.filePath,
      consentForResearch: params.consentForResearch,
      clientRequestId: clientRequestId,
    );
  }
}
