import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/scan/presentation/bloc/home_cubit.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockImagePicker picker;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    picker = MockImagePicker();
  });

  Future<XFile?> pick() => picker.pickImage(
    source: any(named: 'source'),
    imageQuality: any(named: 'imageQuality'),
    maxWidth: any(named: 'maxWidth'),
    maxHeight: any(named: 'maxHeight'),
  );

  blocTest<HomeCubit, HomeState>(
    'cancelled picker returns to initial state',
    build: () {
      when(pick).thenAnswer((_) async => null);
      return HomeCubit(imagePicker: picker);
    },
    act: (cubit) => cubit.pickImage(),
    expect: () => const [HomeImagePickerLoading(), HomeInitial()],
  );

  test('selected image reports actual file path and size', () async {
    final file = File('${Directory.systemTemp.path}/home-cubit-image.jpg');
    await file.writeAsBytes([1, 2, 3, 4, 5, 6]);
    when(pick).thenAnswer((_) async => XFile(file.path));
    final cubit = HomeCubit(imagePicker: picker);

    final selected = cubit.stream.firstWhere((s) => s is HomeImageSelected);
    await cubit.pickImage();
    final state = await selected as HomeImageSelected;

    expect(state.filePath, file.path);
    expect(state.fileSizeBytes, 6);
    verify(
      () => picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      ),
    ).called(1);
    await cubit.close();
    await file.delete();
  });

  for (final code in ['photo_access_denied', 'camera_access_denied']) {
    blocTest<HomeCubit, HomeState>(
      '$code maps to permission denied',
      build: () {
        when(pick).thenThrow(PlatformException(code: code));
        return HomeCubit(imagePicker: picker);
      },
      act: (cubit) => cubit.pickImage(),
      expect: () => const [HomeImagePickerLoading(), HomePermissionDenied()],
    );
  }

  blocTest<HomeCubit, HomeState>(
    'other platform errors preserve plugin message',
    build: () {
      when(pick).thenThrow(
        PlatformException(code: 'picker_failed', message: 'Picker failed'),
      );
      return HomeCubit(imagePicker: picker);
    },
    act: (cubit) => cubit.pickImage(),
    expect: () => [
      const HomeImagePickerLoading(),
      const HomeError('Picker failed'),
    ],
  );

  blocTest<HomeCubit, HomeState>(
    'unexpected exceptions become HomeError instead of escaping',
    build: () {
      when(pick).thenThrow(StateError('unexpected'));
      return HomeCubit(imagePicker: picker);
    },
    act: (cubit) => cubit.pickImage(),
    expect: () => [
      const HomeImagePickerLoading(),
      isA<HomeError>().having(
        (s) => s.message,
        'message',
        contains('unexpected'),
      ),
    ],
  );
}
