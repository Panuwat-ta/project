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

  setUp(() {
    remote = MockScanRemote();
    repository = ScanRepositoryImpl(remoteDataSource: remote);
  });

  test(
    'submitImage delegates only backend-supported file/title fields',
    () async {
      when(
        () => remote.submitScan(filePath: '/tmp/a.jpg', scanName: 'Example'),
      ).thenAnswer((_) async => 'scan-1');

      expect(
        await repository.submitImage(
          filePath: '/tmp/a.jpg',
          scanName: 'Example',
        ),
        'scan-1',
      );
      verify(
        () => remote.submitScan(filePath: '/tmp/a.jpg', scanName: 'Example'),
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
