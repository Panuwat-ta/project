import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import '../errors/exceptions.dart';
import '../constants/scan_upload_limits.dart';

Future<void> validateScanImage(String filePath) async {
  if (!filePath.startsWith('/') ||
      await FileSystemEntity.type(filePath, followLinks: false) !=
          FileSystemEntityType.file) {
    throw const ValidationException('scan_error_invalid_image');
  }
  final file = File(filePath);
  final size = await file.length();
  if (size == 0) {
    throw const ValidationException('scan_error_invalid_image');
  }
  if (size > maxScanUploadBytes) {
    throw const ValidationException('scan_error_image_size');
  }
  final handle = await file.open();
  late Uint8List bytes;
  try {
    bytes = await handle.read(maxScanUploadBytes + 1);
  } finally {
    await handle.close();
  }
  if (bytes.length > maxScanUploadBytes) {
    throw const ValidationException('scan_error_image_size');
  }
  final error = await compute(_imageError, bytes);
  if (error != null) {
    throw ValidationException(error);
  }
}

String? _imageError(Uint8List bytes) {
  try {
    final decoder = image.findDecoderForData(bytes);
    if (decoder == null ||
        !const {
          image.ImageFormat.jpg,
          image.ImageFormat.png,
          image.ImageFormat.webp,
        }.contains(decoder.format)) {
      return 'scan_error_image_format';
    }
    final info = decoder.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) {
      return 'scan_error_invalid_image';
    }
    if (info.width * info.height > maxScanImagePixels) {
      return 'scan_error_image_size';
    }
    // Decode a single frame off the UI isolate to reject corrupted content.
    if (decoder.decodeFrame(0) == null) {
      return 'scan_error_invalid_image';
    }
    return null;
  } catch (_) {
    return 'scan_error_invalid_image';
  }
}
