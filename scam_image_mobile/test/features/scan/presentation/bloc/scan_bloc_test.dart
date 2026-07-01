import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/scan/domain/entities/analysis_task.dart';
import 'package:scam_image_mobile/features/scan/domain/repositories/scan_repository.dart';
import 'package:scam_image_mobile/features/scan/presentation/bloc/scan_bloc.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockScanRepo extends Mock implements ScanRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

AnalysisTask _task(AnalysisTaskStatus status, {int progress = 0}) =>
    AnalysisTask(taskId: 'task-1', status: status, progress: progress);

void main() {
  late MockScanRepo mockRepo;

  setUp(() {
    mockRepo = MockScanRepo();
  });

  // ── CropConfirmed → upload + initial polling state ────────────────────────

  group('CropConfirmed', () {
    blocTest<ScanBloc, ScanState>(
      'emits [ScanUploading, ScanPolling] when submitImage succeeds',
      build: () {
        when(() => mockRepo.submitImage(
              filePath: any(named: 'filePath'),
              consentForResearch: any(named: 'consentForResearch'),
              clientRequestId: any(named: 'clientRequestId'),
            )).thenAnswer((_) async => 'task-1');
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(CropConfirmed('/path/to/image.jpg')),
      expect: () => [
        isA<ScanUploading>(),
        isA<ScanPolling>().having((s) => s.taskId, 'taskId', 'task-1'),
      ],
      // The timer started inside the BLoC would fire additional poll ticks;
      // tearDown closes the bloc which cancels the timer cleanly.
    );

    blocTest<ScanBloc, ScanState>(
      'emits [ScanUploading, ScanError] when submitImage throws',
      build: () {
        when(() => mockRepo.submitImage(
              filePath: any(named: 'filePath'),
              consentForResearch: any(named: 'consentForResearch'),
              clientRequestId: any(named: 'clientRequestId'),
            )).thenThrow(Exception('network error'));
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(CropConfirmed('/path/to/image.jpg')),
      expect: () => [
        isA<ScanUploading>(),
        isA<ScanError>(),
      ],
    );
  });

  // ── AnalysisPollTick → Polling state transitions ──────────────────────────

  group('AnalysisPollTick', () {
    blocTest<ScanBloc, ScanState>(
      'emits ScanPolling with updated progress when task is still processing',
      build: () {
        when(() => mockRepo.getAnalysisStatus('task-1')).thenAnswer(
          (_) async => _task(AnalysisTaskStatus.processingText, progress: 45),
        );
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AnalysisPollTick('task-1')),
      expect: () => [
        isA<ScanPolling>()
            .having((s) => s.taskId, 'taskId', 'task-1')
            .having((s) => s.progress, 'progress', 45)
            .having(
              (s) => s.step,
              'step',
              AnalysisTaskStatus.processingText,
            ),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'emits ScanCompleted when task status is completed',
      build: () {
        when(() => mockRepo.getAnalysisStatus('task-1')).thenAnswer(
          (_) async => _task(AnalysisTaskStatus.completed, progress: 100),
        );
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AnalysisPollTick('task-1')),
      expect: () => [
        isA<ScanCompleted>().having((s) => s.taskId, 'taskId', 'task-1'),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'emits ScanError when task status is failed',
      build: () {
        when(() => mockRepo.getAnalysisStatus('task-1')).thenAnswer(
          (_) async => AnalysisTask(
            taskId: 'task-1',
            status: AnalysisTaskStatus.failed,
            progress: 0,
            errorMessage: 'Server error',
          ),
        );
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AnalysisPollTick('task-1')),
      expect: () => [
        isA<ScanError>().having((s) => s.message, 'message', 'Server error'),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'silently keeps polling when getAnalysisStatus throws (transient error)',
      build: () {
        when(() => mockRepo.getAnalysisStatus('task-1'))
            .thenThrow(Exception('socket closed'));
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(AnalysisPollTick('task-1')),
      // BLoC swallows transient network errors – no state change expected
      expect: () => [],
    );

    blocTest<ScanBloc, ScanState>(
      'emits ScanTimeout when elapsed seconds reach the limit',
      build: () => ScanBloc(repository: mockRepo),
      seed: () => ScanInitial(),
      act: (bloc) {
        // Drive the elapsed counter past the 120-second threshold by adding
        // 41 poll ticks (41 × 3 s = 123 s > 120 s). Repository is never
        // called because the timeout check happens first.
        when(() => mockRepo.getAnalysisStatus(any()))
            .thenAnswer((_) async => _task(AnalysisTaskStatus.queued));

        for (var i = 0; i < 41; i++) {
          bloc.add(AnalysisPollTick('task-1'));
        }
      },
      expect: () => contains(isA<ScanTimeout>()),
    );
  });

  // ── AnalysisCancelled ─────────────────────────────────────────────────────

  group('AnalysisCancelled', () {
    blocTest<ScanBloc, ScanState>(
      'emits ScanInitial and calls cancelScan when a task is in progress',
      build: () {
        // First upload so the BLoC tracks a taskId
        when(() => mockRepo.submitImage(
              filePath: any(named: 'filePath'),
              consentForResearch: any(named: 'consentForResearch'),
              clientRequestId: any(named: 'clientRequestId'),
            )).thenAnswer((_) async => 'task-1');
        when(() => mockRepo.cancelScan('task-1'))
            .thenAnswer((_) async {});
        return ScanBloc(repository: mockRepo);
      },
      act: (bloc) async {
        bloc.add(CropConfirmed('/path/to/image.jpg'));
        // Allow the upload to complete before cancelling
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(AnalysisCancelled());
      },
      expect: () => [
        isA<ScanUploading>(),
        isA<ScanPolling>(),
        isA<ScanInitial>(),
      ],
      verify: (_) {
        verify(() => mockRepo.cancelScan('task-1')).called(1);
      },
    );

    blocTest<ScanBloc, ScanState>(
      'emits ScanInitial without calling cancelScan when no task is running',
      build: () => ScanBloc(repository: mockRepo),
      act: (bloc) => bloc.add(AnalysisCancelled()),
      expect: () => [isA<ScanInitial>()],
      verify: (_) {
        verifyNever(() => mockRepo.cancelScan(any()));
      },
    );
  });
}
