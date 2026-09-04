import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scam_image_mobile/features/history/domain/entities/scan_history_item.dart';
import 'package:scam_image_mobile/features/history/domain/repositories/history_repository.dart';
import 'package:scam_image_mobile/features/history/presentation/bloc/history_bloc.dart';
import 'package:scam_image_mobile/features/result/domain/entities/analysis_result.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockHistoryRepository extends Mock implements HistoryRepository {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final tItems = [
  ScanHistoryItem(
    scanId: 'scan-1',
    riskScore: 80,
    riskLevel: RiskLevel.high,
    status: 'completed',
    createdAt: DateTime(2026, 1, 1),
    title: 'Scan Result: HIGH',
  ),
  ScanHistoryItem(
    scanId: 'scan-2',
    riskScore: 20,
    riskLevel: RiskLevel.low,
    status: 'completed',
    createdAt: DateTime(2026, 1, 2),
    title: 'Scan Result: LOW',
  ),
];

void main() {
  late MockHistoryRepository mockRepo;

  setUp(() {
    mockRepo = MockHistoryRepository();
  });

  group('HistoryLoaded', () {
    blocTest<HistoryBloc, HistoryState>(
      'emits [HistoryLoading, HistoryDataLoaded] when items are available',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenAnswer((_) async => tItems);
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistoryLoaded()),
      expect: () => [
        const HistoryLoading(),
        isA<HistoryDataLoaded>()
            .having((s) => s.items.length, 'items.length', 2),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits [HistoryLoading, HistoryEmpty] when no items',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenAnswer((_) async => []);
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistoryLoaded()),
      expect: () => const [
        HistoryLoading(),
        HistoryEmpty(),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits [HistoryLoading, HistoryError] on failure',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenThrow(Exception('Network error'));
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistoryLoaded()),
      expect: () => [
        const HistoryLoading(),
        isA<HistoryError>(),
      ],
    );
  });

  group('HistoryRefreshed', () {
    blocTest<HistoryBloc, HistoryState>(
      'emits HistoryDataLoaded on refresh',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenAnswer((_) async => tItems);
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistoryRefreshed()),
      expect: () => [
        isA<HistoryDataLoaded>()
            .having((s) => s.items.length, 'items.length', 2),
      ],
    );

    test('completes completer on refresh completion', () async {
      when(() => mockRepo.getScanHistory(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            riskLevel: any(named: 'riskLevel'),
            fromDate: any(named: 'fromDate'),
            toDate: any(named: 'toDate'),
            keyword: any(named: 'keyword'),
          )).thenAnswer((_) async => tItems);

      final bloc = HistoryBloc(repository: mockRepo);
      final completer = Completer<void>();

      bloc.add(HistoryRefreshed(completer));
      await completer.future.timeout(const Duration(seconds: 2));

      expect(completer.isCompleted, isTrue);
      await bloc.close();
    });
  });

  group('HistorySearched', () {
    blocTest<HistoryBloc, HistoryState>(
      'fetches with keyword and emits HistoryDataLoaded',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenAnswer((_) async => [tItems.first]);
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistorySearched('HIGH')),
      expect: () => [
        isA<HistoryDataLoaded>()
            .having((s) => s.items.length, 'items.length', 1),
      ],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits HistoryEmpty when search returns no results',
      build: () {
        when(() => mockRepo.getScanHistory(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              riskLevel: any(named: 'riskLevel'),
              fromDate: any(named: 'fromDate'),
              toDate: any(named: 'toDate'),
              keyword: any(named: 'keyword'),
            )).thenAnswer((_) async => []);
        return HistoryBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const HistorySearched('nonexistent')),
      expect: () => const [HistoryEmpty()],
    );
  });

  group('HistoryItemDeleted', () {
    blocTest<HistoryBloc, HistoryState>(
      'removes item and emits updated HistoryDataLoaded',
      build: () {
        when(() => mockRepo.deleteScanHistoryItem('scan-1'))
            .thenAnswer((_) async {});
        return HistoryBloc(repository: mockRepo);
      },
      seed: () => HistoryDataLoaded(tItems),
      act: (bloc) => bloc.add(const HistoryItemDeleted('scan-1')),
      expect: () => [
        isA<HistoryDataLoaded>()
            .having((s) => s.items.length, 'items.length', 1)
            .having((s) => s.items.first.scanId, 'first.scanId', 'scan-2'),
      ],
      verify: (_) {
        verify(() => mockRepo.deleteScanHistoryItem('scan-1')).called(1);
      },
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits HistoryEmpty when last item is deleted',
      build: () {
        when(() => mockRepo.deleteScanHistoryItem('scan-1'))
            .thenAnswer((_) async {});
        return HistoryBloc(repository: mockRepo);
      },
      seed: () => HistoryDataLoaded([tItems.first]),
      act: (bloc) => bloc.add(const HistoryItemDeleted('scan-1')),
      expect: () => const [HistoryEmpty()],
    );

    blocTest<HistoryBloc, HistoryState>(
      'emits HistoryError when delete fails',
      build: () {
        when(() => mockRepo.deleteScanHistoryItem('scan-1'))
            .thenThrow(Exception('Delete failed'));
        return HistoryBloc(repository: mockRepo);
      },
      seed: () => HistoryDataLoaded(tItems),
      act: (bloc) => bloc.add(const HistoryItemDeleted('scan-1')),
      expect: () => [isA<HistoryError>()],
    );
  });

  group('HistoryState equality', () {
    test('HistoryInitial instances are equal', () {
      expect(const HistoryInitial(), equals(const HistoryInitial()));
    });

    test('HistoryLoading instances are equal', () {
      expect(const HistoryLoading(), equals(const HistoryLoading()));
    });

    test('HistoryEmpty instances are equal', () {
      expect(const HistoryEmpty(), equals(const HistoryEmpty()));
    });

    test('HistoryError instances with same message are equal', () {
      expect(const HistoryError('err'), equals(const HistoryError('err')));
    });
  });

  group('HistoryEvent equality', () {
    test('HistoryLoaded instances are equal', () {
      expect(const HistoryLoaded(), equals(const HistoryLoaded()));
    });

    test('HistoryRefreshed instances are equal', () {
      expect(const HistoryRefreshed(), equals(const HistoryRefreshed()));
    });

    test('HistorySearched with same keyword are equal', () {
      expect(
        const HistorySearched('test'),
        equals(const HistorySearched('test')),
      );
    });

    test('HistoryItemDeleted with same id are equal', () {
      expect(
        const HistoryItemDeleted('scan-1'),
        equals(const HistoryItemDeleted('scan-1')),
      );
    });
  });
}
