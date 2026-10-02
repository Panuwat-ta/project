import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// The cropper platform interface is the plugin boundary exercised by this widget.
// ignore_for_file: depend_on_referenced_packages
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
import 'package:scam_image_mobile/features/scan/presentation/screens/image_crop_screen.dart';

const _pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final originalCropper = ImageCropperPlatform.instance;
  tearDown(() {
    ImageCropperPlatform.instance = originalCropper;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, null);
  });

  testWidgets('crop result becomes the image sent to analysis', (tester) async {
    const sourcePath = '/fixture/source.jpg';
    const croppedPath = '/cache/cropped.jpg';
    ImageCropperPlatform.instance = _FakeImageCropperPlatform((path) async {
      expect(path, sourcePath);
      return CroppedFile(croppedPath);
    });
    await _pumpCrop(tester, sourcePath);

    await tester.tap(find.text('สัดส่วน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เริ่มวิเคราะห์'));
    await tester.pumpAndSettle();

    expect(find.textContaining(croppedPath), findsOneWidget);
  });

  testWidgets('cancelled crop keeps the original image for analysis', (
    tester,
  ) async {
    const sourcePath = '/fixture/source.jpg';
    ImageCropperPlatform.instance = _FakeImageCropperPlatform(
      (_) async => null,
    );
    await _pumpCrop(tester, sourcePath);

    await tester.tap(find.text('สัดส่วน'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('เริ่มวิเคราะห์'));
    await tester.pumpAndSettle();

    expect(find.textContaining(sourcePath), findsOneWidget);
  });

  testWidgets('crop plugin failure reports an image editing error', (
    tester,
  ) async {
    ImageCropperPlatform.instance = _FakeImageCropperPlatform((_) async {
      throw const FormatException('crop failed');
    });
    await _pumpCrop(tester, '/fixture/source.jpg');

    await tester.tap(find.text('สัดส่วน'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('ไม่สามารถแก้ไขรูปภาพได้ กรุณาลองอีกครั้ง'),
      findsOneWidget,
    );
  });

  testWidgets('back confirmation can cancel discard or leave the crop screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/crop'),
              child: const Text('Open crop'),
            ),
          ),
        ),
        GoRoute(
          path: '/crop',
          builder: (_, _) =>
              const ImageCropScreen(filePath: '/fixture/source.jpg'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open crop'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ย้อนกลับ'));
    await tester.pumpAndSettle();
    expect(find.text('ยกเลิกการแก้ไข?'), findsOneWidget);
    await tester.tap(find.text('ไม่'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageCropScreen), findsOneWidget);

    await tester.tap(find.byTooltip('ย้อนกลับ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ใช่'));
    await tester.pumpAndSettle();
    expect(find.text('Open crop'), findsOneWidget);
  });

  testWidgets('notification action opens notifications', (tester) async {
    await _pumpCrop(tester, '/fixture/source.jpg');

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('selected replacement image is used for analysis', (
    tester,
  ) async {
    const replacementPath = '/picker/replacement.jpg';
    var pickerCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, (call) async {
          pickerCalled = true;
          expect(call.method, 'pickImage');
          expect(call.arguments['source'], 1);
          return replacementPath;
        });
    await _pumpCrop(tester, '/fixture/source.jpg');

    await tester.ensureVisible(find.text('เปลี่ยนรูป'));
    await tester.tap(find.text('เปลี่ยนรูป'));
    await tester.pumpAndSettle();
    expect(pickerCalled, isTrue);
    final selectedPreview = tester.widget<Image>(find.byType(Image).first);
    expect((selectedPreview.image as FileImage).file.path, replacementPath);
    await tester.tap(find.text('เริ่มวิเคราะห์'));
    await tester.pumpAndSettle();

    expect(find.textContaining(replacementPath), findsOneWidget);
  });

  testWidgets('picker failure reports image editing error', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pickerChannel, (call) async {
          throw PlatformException(
            code: 'picker_failed',
            message: 'gallery unavailable',
          );
        });
    await _pumpCrop(tester, '/fixture/source.jpg');

    await tester.ensureVisible(find.text('เปลี่ยนรูป'));
    await tester.tap(find.text('เปลี่ยนรูป'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('ไม่สามารถแก้ไขรูปภาพได้ กรุณาลองอีกครั้ง'),
      findsOneWidget,
    );
  });

  testWidgets('reset after crop restores the original preview', (tester) async {
    const sourcePath = '/fixture/source.jpg';
    const croppedPath = '/cache/cropped.jpg';
    ImageCropperPlatform.instance = _FakeImageCropperPlatform(
      (_) async => CroppedFile(croppedPath),
    );
    await _pumpCrop(tester, sourcePath);

    await tester.tap(find.text('สัดส่วน'));
    await tester.pumpAndSettle();
    expect(
      (tester.widget<Image>(find.byType(Image).first).image as FileImage)
          .file
          .path,
      croppedPath,
    );
    await tester.tap(find.text('รีเซ็ต'));
    await tester.pump();
    expect(
      (tester.widget<Image>(find.byType(Image).first).image as FileImage)
          .file
          .path,
      sourcePath,
    );
  });

  testWidgets('zoom cycles back to original scale and reset restores preview', (
    tester,
  ) async {
    await _pumpCrop(tester, '/fixture/source.jpg');
    final image = find.byType(Image).first;
    final transform = find.ancestor(
      of: image,
      matching: find.byType(Transform),
    );

    Future<double> scale() async =>
        tester.widget<Transform>(transform.first).transform.getMaxScaleOnAxis();

    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    expect(await scale(), 1.5);
    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    expect(await scale(), 1.0);

    await tester.tap(find.text('ขยาย'));
    await tester.pump();
    await tester.tap(find.text('รีเซ็ต'));
    await tester.pump();
    expect(await scale(), 1.0);
  });
}

class _FakeImageCropperPlatform extends ImageCropperPlatform {
  _FakeImageCropperPlatform(this.crop);

  final Future<CroppedFile?> Function(String sourcePath) crop;

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) => crop(sourcePath);
}

Future<void> _pumpCrop(WidgetTester tester, String filePath) async {
  final router = GoRouter(
    initialLocation: '/crop',
    routes: [
      GoRoute(
        path: '/crop',
        builder: (_, _) => ImageCropScreen(filePath: filePath),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, state) =>
            Scaffold(body: Text('Analysis extra: ${state.extra}')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const Scaffold(body: Text('Notifications')),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  addTearDown(router.dispose);
}
