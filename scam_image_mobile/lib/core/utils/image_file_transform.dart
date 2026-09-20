import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Rotates [sourcePath] and writes a JPEG copy suitable for upload.
///
/// The source file is never mutated. [outputDirectory] exists mainly to make
/// the file transform deterministic and testable without platform channels.
Future<String> rotateImageFile({
  required String sourcePath,
  required int angleDegrees,
  Directory? outputDirectory,
  int jpegQuality = 85,
}) async {
  final source = File(sourcePath);
  final decoded = img.decodeImage(await source.readAsBytes());
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupted image');
  }

  final rotated = img.copyRotate(decoded, angle: angleDegrees);
  final directory = outputDirectory ?? await getTemporaryDirectory();
  await directory.create(recursive: true);
  final output = File(
    '${directory.path}/scamguard_rotated_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await output.writeAsBytes(
    img.encodeJpg(rotated, quality: jpegQuality.clamp(1, 100)),
    flush: true,
  );
  return output.path;
}
