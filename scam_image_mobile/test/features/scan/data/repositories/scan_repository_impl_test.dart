import 'dart:io';
import 'package:image/image.dart' as image;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:scam_image_mobile/features/scan/data/models/analysis_task_model.dart';
import 'package:scam_image_mobile/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';

class MockScanRemote extends Mock implements ScanRemoteDataSource {}

void main() {
  late MockScanRemote remote;
  late ScanRepositoryImpl repository;
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('scamguard-upload-test-');
    path = '${directory.path}/a.jpg';
    await File(
      path,
    ).writeAsBytes(image.encodeJpg(image.Image(width: 2, height: 2)));
    remote = MockScanRemote();
    repository = ScanRepositoryImpl(remoteDataSource: remote);
  });

  tearDown(() => directory.delete(recursive: true));

  test(
    'submitImage delegates only backend-supported file/title fields',
    () async {
      when(
        () => remote.submitScan(filePath: path, scanName: 'Example'),
      ).thenAnswer((_) async => 'scan-1');

      expect(
        await repository.submitImage(filePath: path, scanName: 'Example'),
        'scan-1',
      );
      verify(
        () => remote.submitScan(filePath: path, scanName: 'Example'),
      ).called(1);
    },
  );

  test('getAnalysisStatus delegates status lookup', () async {
    const task = AnalysisTaskModel(
      taskId: 'scan-1',
      status: AnalysisTaskStatus.processingText,
      progress: 30,
    );
    when(() => remote.getScanStatus('scan-1')).thenAnswer((_) async => task);

    expect(await repository.getAnalysisStatus('scan-1'), task);
  });
}
