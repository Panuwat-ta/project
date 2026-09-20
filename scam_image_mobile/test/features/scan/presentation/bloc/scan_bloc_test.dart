import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';
import 'package:scam_image_mobile/features/scan/domain/repositories/scan_repository.dart';
import 'package:scam_image_mobile/features/scan/presentation/bloc/scan_bloc.dart';

class MockScanRepo extends Mock implements ScanRepository {}

AnalysisTask _task(
  String taskId,
  AnalysisTaskStatus status, {
  int progress = 0,
  String? errorMessage,
}) => AnalysisTask(
  taskId: taskId,
  status: status,
  progress: progress,
  errorMessage: errorMessage,
);

void _stubSubmit(MockScanRepo repo, String taskId) {
  when(
    () => repo.submitImage(
      filePath: any(named: 'filePath'),
      scanName: any(named: 'scanName'),
    ),
  ).thenAnswer((_) async => taskId);
}

Future<void> _startScan(ScanBloc bloc, {String path = '/image.jpg'}) async {
  final ready = bloc.stream.firstWhere((state) => state is ScanPolling);
  bloc.add(CropConfirmed(path));
  await ready.timeout(const Duration(seconds: 1));
}

void main() {
  late MockScanRepo repo;

  setUp(() {
    repo = MockScanRepo();
  });

  group('CropConfirmed', () {
    blocTest<ScanBloc, ScanState>(
      'emits uploading then polling for a successful upload',
      build: () {
        _stubSubmit(repo, 'task-1');
        return ScanBloc(repository: repo);
      },
      act: (bloc) => bloc.add(CropConfirmed('/image.jpg')),
      expect: () => [
        isA<ScanUploading>(),
        isA<ScanPolling>().having((s) => s.taskId, 'taskId', 'task-1'),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'maps network upload failures to the connectivity message case-insensitively',
      build: () {
        when(
          () => repo.submitImage(
            filePath: any(named: 'filePath'),
            scanName: any(named: 'scanName'),
          ),
        ).thenThrow(Exception('NetworkException: connection failed'));
        return ScanBloc(repository: repo);
      },
      act: (bloc) => bloc.add(CropConfirmed('/image.jpg')),
      expect: () => [
        isA<ScanUploading>(),
        isA<ScanError>().having(
          (s) => s.message,
          'message',
          'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้',
        ),
      ],
    );

    test(
      'late completion from an older upload cannot replace the newer scan',
      () async {
        final oldUpload = Completer<String>();
        when(
          () => repo.submitImage(
            filePath: '/old.jpg',
            scanName: any(named: 'scanName'),
          ),
        ).thenAnswer((_) => oldUpload.future);
        when(
          () => repo.submitImage(
            filePath: '/new.jpg',
            scanName: any(named: 'scanName'),
          ),
        ).thenAnswer((_) async => 'task-new');

        final bloc = ScanBloc(repository: repo);
        final emitted = <ScanState>[];
        final sub = bloc.stream.listen(emitted.add);
        bloc.add(CropConfirmed('/old.jpg'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(CropConfirmed('/new.jpg'));
        await bloc.stream.firstWhere(
          (s) => s is ScanPolling && s.taskId == 'task-new',
        );
        oldUpload.complete('task-old');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(bloc.state, isA<ScanPolling>());
        expect((bloc.state as ScanPolling).taskId, 'task-new');
        expect(
          emitted.whereType<ScanPolling>().any((s) => s.taskId == 'task-old'),
          isFalse,
        );
        await sub.cancel();
        await bloc.close();
      },
    );
  });

  group('AnalysisPollTick', () {
    test(
      'updates active task progress and clamps malformed progress to 100',
      () async {
        _stubSubmit(repo, 'task-1');
        when(() => repo.getAnalysisStatus('task-1')).thenAnswer(
          (_) async => _task(
            'task-1',
            AnalysisTaskStatus.processingVisual,
            progress: 140,
          ),
        );
        final bloc = ScanBloc(repository: repo);
        await _startScan(bloc);

        final updated = bloc.stream.firstWhere(
          (s) => s is ScanPolling && s.progress == 100,
        );
        bloc.add(AnalysisPollTick('task-1'));
        await updated.timeout(const Duration(seconds: 1));

        expect((bloc.state as ScanPolling).progress, 100);
        await bloc.close();
      },
    );

    test('completed and failed terminal states stop the active task', () async {
      _stubSubmit(repo, 'task-1');
      when(() => repo.getAnalysisStatus('task-1')).thenAnswer(
        (_) async =>
            _task('task-1', AnalysisTaskStatus.completed, progress: 100),
      );
      final completedBloc = ScanBloc(repository: repo);
      await _startScan(completedBloc);
      final completed = completedBloc.stream.firstWhere(
        (s) => s is ScanCompleted,
      );
      completedBloc.add(AnalysisPollTick('task-1'));
      await completed.timeout(const Duration(seconds: 1));
      expect(completedBloc.state, isA<ScanCompleted>());
      completedBloc.add(AnalysisPollTick('task-1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      verify(() => repo.getAnalysisStatus('task-1')).called(1);
      await completedBloc.close();

      reset(repo);
      _stubSubmit(repo, 'task-2');
      when(() => repo.getAnalysisStatus('task-2')).thenAnswer(
        (_) async => _task(
          'task-2',
          AnalysisTaskStatus.failed,
          errorMessage: 'Server error',
        ),
      );
      final failedBloc = ScanBloc(repository: repo);
      await _startScan(failedBloc);
      final failed = failedBloc.stream.firstWhere((s) => s is ScanError);
      failedBloc.add(AnalysisPollTick('task-2'));
      await failed.timeout(const Duration(seconds: 1));
      expect((failedBloc.state as ScanError).message, 'Server error');
      await failedBloc.close();
    });

    test(
      'duplicate poll ticks do not issue overlapping status requests',
      () async {
        _stubSubmit(repo, 'task-1');
        final status = Completer<AnalysisTask>();
        when(
          () => repo.getAnalysisStatus('task-1'),
        ).thenAnswer((_) => status.future);
        final bloc = ScanBloc(repository: repo);
        await _startScan(bloc);

        bloc.add(AnalysisPollTick('task-1'));
        bloc.add(AnalysisPollTick('task-1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        verify(() => repo.getAnalysisStatus('task-1')).called(1);
        status.complete(
          _task('task-1', AnalysisTaskStatus.processingText, progress: 20),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await bloc.close();
      },
    );

    test(
      'late poll response from an old task cannot overwrite a newer scan',
      () async {
        when(
          () => repo.submitImage(
            filePath: '/one.jpg',
            scanName: any(named: 'scanName'),
          ),
        ).thenAnswer((_) async => 'task-1');
        when(
          () => repo.submitImage(
            filePath: '/two.jpg',
            scanName: any(named: 'scanName'),
          ),
        ).thenAnswer((_) async => 'task-2');
        final oldStatus = Completer<AnalysisTask>();
        when(
          () => repo.getAnalysisStatus('task-1'),
        ).thenAnswer((_) => oldStatus.future);

        final bloc = ScanBloc(repository: repo);
        await _startScan(bloc, path: '/one.jpg');
        bloc.add(AnalysisPollTick('task-1'));
        await Future<void>.delayed(Duration.zero);
        await _startScan(bloc, path: '/two.jpg');
        oldStatus.complete(
          _task('task-1', AnalysisTaskStatus.completed, progress: 100),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(bloc.state, isA<ScanPolling>());
        expect((bloc.state as ScanPolling).taskId, 'task-2');
        await bloc.close();
      },
    );

    test(
      'transient status failure keeps the task active for a later poll',
      () async {
        _stubSubmit(repo, 'task-1');
        var calls = 0;
        when(() => repo.getAnalysisStatus('task-1')).thenAnswer((_) async {
          calls += 1;
          if (calls == 1) throw Exception('socket closed');
          return _task(
            'task-1',
            AnalysisTaskStatus.processingText,
            progress: 35,
          );
        });
        final bloc = ScanBloc(repository: repo);
        await _startScan(bloc);
        bloc.add(AnalysisPollTick('task-1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state, isA<ScanPolling>());

        final recovered = bloc.stream.firstWhere(
          (s) => s is ScanPolling && s.progress == 35,
        );
        bloc.add(AnalysisPollTick('task-1'));
        await recovered.timeout(const Duration(seconds: 1));
        expect(calls, 2);
        await bloc.close();
      },
    );

    test('timeout stops before making another status request', () async {
      _stubSubmit(repo, 'task-1');
      final bloc = ScanBloc(
        repository: repo,
        timeoutSeconds: 3,
        pollInterval: const Duration(seconds: 3),
      );
      await _startScan(bloc);
      final timedOut = bloc.stream.firstWhere((s) => s is ScanTimeout);
      bloc.add(AnalysisPollTick('task-1'));
      await timedOut.timeout(const Duration(seconds: 1));
      verifyNever(() => repo.getAnalysisStatus(any()));
      await bloc.close();
    });
  });

  group('AnalysisCancelled', () {
    test(
      'cancel during upload invalidates the eventual upload response',
      () async {
        final upload = Completer<String>();
        when(
          () => repo.submitImage(
            filePath: any(named: 'filePath'),
            scanName: any(named: 'scanName'),
          ),
        ).thenAnswer((_) => upload.future);
        final bloc = ScanBloc(repository: repo);
        bloc.add(CropConfirmed('/image.jpg'));
        await bloc.stream.firstWhere((s) => s is ScanUploading);
        bloc.add(AnalysisCancelled());
        await bloc.stream.firstWhere((s) => s is ScanInitial);
        upload.complete('task-late');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state, isA<ScanInitial>());
        await bloc.close();
      },
    );

    blocTest<ScanBloc, ScanState>(
      'cancel with no active task remains safe',
      build: () => ScanBloc(repository: repo),
      act: (bloc) => bloc.add(AnalysisCancelled()),
      expect: () => [isA<ScanInitial>()],
    );
  });
}
