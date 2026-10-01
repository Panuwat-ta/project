import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';
import 'package:scam_image_mobile/features/result/domain/repositories/result_repository.dart';
import 'package:scam_image_mobile/features/result/presentation/bloc/result_bloc.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockResultRepository extends Mock implements ResultRepository {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final tResult = AnalysisResult(
  scanId: 'scan-1',
  taskId: 'task-1',
  status: 'completed',
  riskScore: 75,
  riskLevel: RiskLevel.high,
  summary: 'High risk detected',
  imageUrl: 'http://example.com/image.jpg',
  heatmapUrl: 'http://example.com/heatmap.jpg',
  createdAt: DateTime(2026, 1, 1),
  factors: const [],
);

void main() {
  late MockResultRepository mockRepo;

  setUp(() {
    mockRepo = MockResultRepository();
  });

  group('ResultLoadRequested', () {
    blocTest<ResultBloc, ResultState>(
      'emits [ResultLoading, ResultLoaded] on success',
      build: () {
        when(
          () => mockRepo.getAnalysisResult('task-1'),
        ).thenAnswer((_) async => tResult);
        return ResultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ResultLoadRequested('task-1')),
      expect: () => [const ResultLoading(), ResultLoaded(tResult)],
      verify: (_) {
        verify(() => mockRepo.getAnalysisResult('task-1')).called(1);
      },
    );

    blocTest<ResultBloc, ResultState>(
      'emits [ResultLoading, ResultError] on failure',
      build: () {
        when(
          () => mockRepo.getAnalysisResult('task-1'),
        ).thenThrow(Exception('Server error'));
        return ResultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ResultLoadRequested('task-1')),
      expect: () => [
        const ResultLoading(),
        isA<ResultError>().having(
          (s) => s.message,
          'message',
          contains('Server error'),
        ),
      ],
    );

    blocTest<ResultBloc, ResultState>(
      'emits [ResultLoading, ResultError] on network failure',
      build: () {
        when(
          () => mockRepo.getAnalysisResult('task-1'),
        ).thenThrow(Exception('NetworkException: Connection error'));
        return ResultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ResultLoadRequested('task-1')),
      expect: () => [
        const ResultLoading(),
        isA<ResultError>().having(
          (s) => s.message,
          'message',
          contains('NetworkException'),
        ),
      ],
    );
  });

  group('XAI polling (ResultPollRequested)', () {
    AnalysisResult pendingResult() => AnalysisResult(
      scanId: 'scan-1',
      taskId: 'task-1',
      status: 'processing_text',
      riskScore: 50,
      riskLevel: RiskLevel.medium,
      summary: '',
      createdAt: DateTime(2026, 1, 1),
      factors: const [],
    );

    AnalysisResult withStatus(String status, String summary) => AnalysisResult(
      scanId: 'scan-1',
      taskId: 'task-1',
      status: status,
      riskScore: 50,
      riskLevel: RiskLevel.medium,
      summary: summary,
      createdAt: DateTime(2026, 1, 1),
      factors: const [],
    );

    bool isXaiPendingFor(String status, String summary) =>
        ResultBloc.isXaiPending(withStatus(status, summary));

    test('isXaiPending true เฉพาะตอนสแกนยังไม่เสร็จและไม่มีคำอธิบาย', () {
      expect(ResultBloc.isXaiPending(pendingResult()), isTrue);
      // เสร็จแล้วแต่ไม่มีคำอธิบาย = ไม่ต้องโพล (แสดง unavailable)
      expect(isXaiPendingFor('completed', ''), isFalse);
      // ล้มเหลว = ไม่ต้องโพล
      expect(isXaiPendingFor('failed', ''), isFalse);
      // มีคำอธิบายแล้ว = ไม่ต้องโพล
      expect(isXaiPendingFor('completed', 'เสร็จแล้ว'), isFalse);
      expect(isXaiPendingFor('processing_text', 'เสร็จแล้ว'), isFalse);
    });

    blocTest<ResultBloc, ResultState>(
      'poll ไม่ออก loading ซ้ำ เพื่อไม่ให้จอกระพริบ',
      build: () {
        when(
          () => mockRepo.getAnalysisResult('task-1'),
        ).thenAnswer((_) async => tResult);
        return ResultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ResultPollRequested('task-1')),
      expect: () => [ResultLoaded(tResult)],
    );
  });

  for (final oldFails in [false, true]) {
    test(
      'new result is not overwritten by stale load failure=$oldFails',
      () async {
        final old = Completer<AnalysisResult>();
        when(
          () => mockRepo.getAnalysisResult('old'),
        ).thenAnswer((_) => old.future);
        when(
          () => mockRepo.getAnalysisResult('new'),
        ).thenAnswer((_) async => tResult);
        final bloc = ResultBloc(repository: mockRepo);
        bloc.add(const ResultLoadRequested('old'));
        await bloc.stream.firstWhere((state) => state is ResultLoading);
        bloc.add(const ResultLoadRequested('new'));
        await bloc.stream.firstWhere((state) => state is ResultLoaded);
        if (oldFails) {
          old.completeError(Exception('old failure'));
        } else {
          old.complete(
            AnalysisResult(
              scanId: 'old',
              taskId: 'old',
              status: 'completed',
              riskScore: 1,
              riskLevel: RiskLevel.low,
              summary: 'old result',
              createdAt: DateTime(2026),
              factors: const [],
            ),
          );
        }
        await Future<void>.delayed(Duration.zero);
        expect((bloc.state as ResultLoaded).result, tResult);
        await bloc.close();
      },
    );
  }

  test(
    'concurrent result poll events request once and stale task is ignored',
    () async {
      final pending = Completer<AnalysisResult>();
      when(
        () => mockRepo.getAnalysisResult('task-1'),
      ).thenAnswer((_) => pending.future);
      final bloc = ResultBloc(repository: mockRepo);
      bloc.add(const ResultPollRequested('task-1'));
      bloc.add(const ResultPollRequested('task-1'));
      bloc.add(const ResultPollRequested('other-task'));
      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.getAnalysisResult('task-1')).called(1);
      verifyNever(() => mockRepo.getAnalysisResult('other-task'));
      pending.complete(tResult);
      await bloc.stream.firstWhere((state) => state is ResultLoaded);
      await bloc.close();
    },
  );

  test(
    'leaving result screen invalidates request and ignores queued polls',
    () async {
      final pending = Completer<AnalysisResult>();
      when(
        () => mockRepo.getAnalysisResult('task-1'),
      ).thenAnswer((_) => pending.future);
      final bloc = ResultBloc(repository: mockRepo);
      bloc.add(const ResultLoadRequested('task-1'));
      await bloc.stream.firstWhere((state) => state is ResultLoading);
      bloc.add(const ResultPollingStopped('task-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ResultPollRequested('task-1'));
      pending.complete(tResult);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<ResultLoading>());
      verify(() => mockRepo.getAnalysisResult('task-1')).called(1);
      await bloc.close();
    },
  );

  group('ResultState equality', () {
    test('ResultInitial instances are equal', () {
      expect(const ResultInitial(), equals(const ResultInitial()));
    });

    test('ResultLoading instances are equal', () {
      expect(const ResultLoading(), equals(const ResultLoading()));
    });

    test('ResultLoaded instances with same result are equal', () {
      expect(ResultLoaded(tResult), equals(ResultLoaded(tResult)));
    });

    test('ResultError instances with same message are equal', () {
      expect(const ResultError('error'), equals(const ResultError('error')));
    });
  });
}
