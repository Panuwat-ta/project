import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:scam_image_mobile/core/constants/scan_upload_limits.dart';
import 'package:scam_image_mobile/core/errors/exceptions.dart';
import 'package:scam_image_mobile/core/utils/scan_image_validator.dart';

void main() {
  late Directory directory;
  setUp(
    () async => directory = await Directory.systemTemp.createTemp(
      'scamguard-validation-',
    ),
  );
  tearDown(() => directory.delete(recursive: true));
  for (final format in ['png', 'jpeg']) {
    test(
      'valid $format is accepted from content even with a .txt filename',
      () async {
        final pixels = image.Image(width: 3, height: 3);
        final bytes = format == 'png'
            ? image.encodePng(pixels)
            : image.encodeJpg(pixels);
        final file = await File(
          '${directory.path}/image.txt',
        ).writeAsBytes(bytes);
        await expectLater(validateScanImage(file.path), completes);
      },
    );
  }
  test('empty and non-image content never uploads', () async {
    for (final bytes in [
      <int>[],
      'not an image'.codeUnits,
      <int>[137, 80, 78, 71, 13, 10, 26, 10],
    ]) {
      final file = await File(
        '${directory.path}/invalid.png',
      ).writeAsBytes(bytes);
      await expectLater(
        validateScanImage(file.path),
        throwsA(isA<ValidationException>()),
      );
    }
  });
  test('oversized file is rejected before decoding', () async {
    final file = File('${directory.path}/oversized.png');
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(maxScanUploadBytes + 1);
    await handle.close();
    await expectLater(
      validateScanImage(file.path),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'key',
          'scan_error_image_size',
        ),
      ),
    );
  });
  test(
    'URI, relative path, missing file, directory and symlink are rejected',
    () async {
      final file = await File(
        '${directory.path}/real.png',
      ).writeAsBytes(image.encodePng(image.Image(width: 2, height: 2)));
      final link = await Link('${directory.path}/linked.png').create(file.path);
      for (final path in [
        'content://media/images/1',
        'relative.png',
        '${directory.path}/missing.png',
        directory.path,
        link.path,
      ]) {
        await expectLater(
          validateScanImage(path),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );
}
