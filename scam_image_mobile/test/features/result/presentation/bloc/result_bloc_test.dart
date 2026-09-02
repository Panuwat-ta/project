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
        when(() => mockRepo.getAnalysisResult('task-1'))
            .thenAnswer((_) async => tResult);
        return ResultBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const ResultLoadRequested('task-1')),
      expect: () => [
        const ResultLoading(),
        ResultLoaded(tResult),
      ],
      verify: (_) {
        verify(() => mockRepo.getAnalysisResult('task-1')).called(1);
      },
    );

    blocTest<ResultBloc, ResultState>(
      'emits [ResultLoading, ResultError] on failure',
      build: () {
        when(() => mockRepo.getAnalysisResult('task-1'))
            .thenThrow(Exception('Server error'));
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
        when(() => mockRepo.getAnalysisResult('task-1'))
            .thenThrow(Exception('NetworkException: Connection error'));
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
      expect(
        const ResultError('error'),
        equals(const ResultError('error')),
      );
    });
  });
}
