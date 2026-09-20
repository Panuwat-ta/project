import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scam_image_mobile/core/utils/image_file_transform.dart';

void main() {
  test('rotateImageFile persists a real 90-degree rotated image', () async {
    final dir = await Directory.systemTemp.createTemp('scamguard-rotate-test-');
    final source = File('${dir.path}/source.png');
    final original = img.Image(width: 2, height: 1);
    original.setPixelRgb(0, 0, 255, 0, 0);
    original.setPixelRgb(1, 0, 0, 255, 0);
    await source.writeAsBytes(img.encodePng(original));

    final outputPath = await rotateImageFile(
      sourcePath: source.path,
      angleDegrees: 90,
      outputDirectory: dir,
      jpegQuality: 100,
    );
    final rotated = img.decodeImage(await File(outputPath).readAsBytes());

    expect(rotated, isNotNull);
    expect(rotated!.width, 1);
    expect(rotated.height, 2);
    expect(outputPath, isNot(source.path));
    await dir.delete(recursive: true);
  });

  test(
    'rotateImageFile rejects corrupt input instead of writing garbage',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'scamguard-rotate-test-',
      );
      final source = File('${dir.path}/broken.jpg');
      await source.writeAsString('not an image');

      expect(
        rotateImageFile(
          sourcePath: source.path,
          angleDegrees: 90,
          outputDirectory: dir,
        ),
        throwsFormatException,
      );
      await dir.delete(recursive: true);
    },
  );
}
